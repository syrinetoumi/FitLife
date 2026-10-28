import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:coach_app/features/entrainement/data/services/adaptation_programme.dart';
import 'package:coach_app/core/utils/alertes.dart';
import 'package:coach_app/core/utils/outils.dart';
import 'package:coach_app/features/entrainement/data/models/mesure_progression.dart';
import 'package:coach_app/features/entrainement/data/models/suivi_objectif.dart';
import 'package:coach_app/features/entrainement/data/repositories/mesure_progression_repository.dart';
import 'package:coach_app/features/entrainement/data/repositories/suivi_objectif_repository.dart';
import 'package:coach_app/features/entrainement/data/services/calcul_progression.dart';
import 'package:coach_app/features/entrainement/presentation/widgets/ligne_info.dart';
import 'libelles_suivi.dart';

class SuiviDetailScreen extends StatefulWidget {
  final int idSuivi;

  const SuiviDetailScreen({super.key, required this.idSuivi});

  @override
  State<SuiviDetailScreen> createState() => _SuiviDetailScreenState();
}

class _SuiviDetailScreenState extends State<SuiviDetailScreen> {
  final SuiviObjectifRepository suiviRepository = SuiviObjectifRepository();
  final MesureProgressionRepository mesureRepository =
  MesureProgressionRepository();

  SuiviObjectif? suivi;
  List<MesureProgression> mesures = [];
  ResultatProgression? resultat;
  bool chargement = true;

  // Seul l'athlète concerné peut saisir ou supprimer. Le coach lit.
  bool get proprietaire {
    String? uid = Supabase.instance.client.auth.currentUser?.id;
    return suivi != null && uid != null && suivi!.idAthlete == uid;
  }

  @override
  void initState() {
    super.initState();
    charger();
  }

  Future<void> charger() async {
    try {
      SuiviObjectif s = await suiviRepository.getSuivi(widget.idSuivi);
      List<MesureProgression> m = await mesureRepository.getMesures(s.id!);
      ResultatProgression r = CalculProgression.calculer(s, m);

      // Objectif atteint : le statut passe automatiquement à ATTEINT.
      String? uid = Supabase.instance.client.auth.currentUser?.id;

      if (r.statut == StatutProgression.atteint &&
          s.statut == 'EN_COURS' &&
          s.idAthlete == uid) {
        await suiviRepository.modifier(s.id!, statut: 'ATTEINT');
        s = await suiviRepository.getSuivi(widget.idSuivi);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        suivi = s;
        mesures = m;
        resultat = r;
        chargement = false;
      });
    } catch (erreur) {
      if (mounted) {
        setState(() {
          chargement = false;
        });

        afficherAlerteErreur(
          context,
          titre: 'Chargement impossible',
          message: messageErreur(erreur),
        );
      }
    }
  }

  Future<void> dialogueMesure({MesureProgression? existante}) async {
    TextEditingController valeurController = TextEditingController(
      text: existante == null ? '' : formaterValeur(existante.valeur),
    );
    TextEditingController noteController =
    TextEditingController(text: existante?.note ?? '');

    bool? valide = await showDialog<bool>(
      context: context,
      builder: (contexteDialogue) {
        return AlertDialog(
          title: Text(existante == null ? 'Nouvelle mesure' : 'Modifier la mesure'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: valeurController,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Valeur (${suivi!.unite})',
                ),
              ),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (facultatif)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(contexteDialogue, false);
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(contexteDialogue, true);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );

    if (valide != true) {
      return;
    }

    double? valeur =
    double.tryParse(valeurController.text.trim().replaceAll(',', '.'));
    String note = noteController.text.trim();

    if (!mounted) {
      return;
    }

    if (valeur == null || valeur <= 0) {
      afficherAlerteErreur(
        context,
        titre: 'Valeur invalide',
        message: 'Saisis un nombre supérieur à 0.',
      );
      return;
    }

    try {
      if (existante == null) {
        await mesureRepository.ajouter(
          MesureProgression(
            idSuivi: suivi!.id!,
            dateMesure: DateTime.now(),
            valeur: valeur,
            note: note.isEmpty ? null : note,
          ),
        );
      } else {
        await mesureRepository.modifier(
          existante.id!,
          valeur: valeur,
          note: note.isEmpty ? null : note,
        );
      }

      await charger();
    } catch (erreur) {
      if (mounted) {
        afficherAlerteErreur(
          context,
          titre: 'Enregistrement impossible',
          message: messageErreur(erreur),
        );
      }
    }
  }

  Future<void> supprimerMesure(MesureProgression mesure) async {
    bool confirme = await confirmerAction(
      context,
      titre: 'Supprimer',
      message: 'Supprimer la mesure du ${afficherDate(mesure.dateMesure)} ?',
    );

    if (!confirme) {
      return;
    }

    try {
      await mesureRepository.supprimer(mesure.id!);
      await charger();
    } catch (erreur) {
      if (mounted) {
        afficherAlerteErreur(
          context,
          titre: 'Suppression impossible',
          message: messageErreur(erreur),
        );
      }
    }
  }

  Future<void> supprimerObjectif() async {
    bool confirme = await confirmerAction(
      context,
      titre: 'Supprimer',
      message: 'Supprimer cet objectif et toutes ses mesures ?',
    );

    if (!confirme) {
      return;
    }

    try {
      await suiviRepository.supprimer(suivi!.id!);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (erreur) {
      if (mounted) {
        afficherAlerteErreur(
          context,
          titre: 'Suppression impossible',
          message: messageErreur(erreur),
        );
      }
    }
  }
  Future<void> appliquer(Proposition proposition) async {
    String message;

    if (proposition.type == TypeProposition.prolongerDate) {
      message =
      'Reporter la date limite au ${afficherDate(proposition.nouvelleDate!)} ?';
    } else {
      message =
      'Changer la cible à ${formaterValeur(proposition.nouvelleCible!)} '
          '${suivi!.unite} ?';
    }

    bool confirme = await confirmerAction(
      context,
      titre: 'Appliquer',
      message: message,
      libelleBouton: 'Appliquer',
    );

    if (!confirme) {
      return;
    }

    try {
      await suiviRepository.modifier(
        suivi!.id!,
        valeurCible: proposition.nouvelleCible,
        dateLimite: proposition.nouvelleDate,
      );

      await charger();

      if (mounted) {
        afficherMessage(context, 'Adaptation appliquée.');
      }
    } catch (erreur) {
      if (mounted) {
        afficherAlerteErreur(
          context,
          titre: 'Adaptation impossible',
          message: messageErreur(erreur),
        );
      }
    }
  }

  Widget sectionAdaptation() {
    List<Proposition> propositions =
    AdaptationProgramme.proposer(suivi!, resultat!);

    return Column(
      children: propositions.map((proposition) {
        bool applicable = proposition.type != TypeProposition.conseil;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      applicable ? Icons.auto_fix_high : Icons.lightbulb_outline,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        proposition.titre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(proposition.explication),
                // Seul le coach valide une adaptation.
                if (applicable && !proprietaire)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ElevatedButton(
                        onPressed: () {
                          appliquer(proposition);
                        },
                        child: const Text('APPLIQUER'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
  String dateCourte(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}';
  }

  // Courbe : valeurs réelles (pleine) et trajectoire prévue (pointillée).
  Widget courbe() {
    SuiviObjectif s = suivi!;

    if (mesures.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Ajoute ta première mesure pour voir la courbe.'),
        ),
      );
    }

    double duree = s.dateLimite.difference(s.dateDebut).inDays.toDouble();

    double abscisse(DateTime date) {
      return date.difference(s.dateDebut).inDays.toDouble();
    }

    List<FlSpot> reel = [FlSpot(0, s.valeurDepart)];

    for (var mesure in mesures) {
      reel.add(FlSpot(abscisse(mesure.dateMesure), mesure.valeur));
    }

    List<FlSpot> prevu = [
      FlSpot(0, s.valeurDepart),
      FlSpot(duree, s.valeurCible),
    ];

    double maxX = duree;
    for (var point in reel) {
      if (point.x > maxX) {
        maxX = point.x;
      }
    }

    List<double> valeurs = [
      s.valeurDepart,
      s.valeurCible,
      ...mesures.map((m) => m.valeur),
    ];
    double minY = valeurs.reduce((a, b) => a < b ? a : b);
    double maxY = valeurs.reduce((a, b) => a > b ? a : b);
    double marge = (maxY - minY) * 0.1;
    if (marge < 1) {
      marge = 1;
    }

    double intervalle = (maxX / 4).ceilToDouble();
    if (intervalle < 1) {
      intervalle = 1;
    }

    Color couleur = Theme.of(context).colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: SizedBox(
          height: 230,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: maxX,
              minY: minY - marge,
              maxY: maxY + marge,
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: intervalle,
                    getTitlesWidget: (valeur, meta) {
                      DateTime date =
                      s.dateDebut.add(Duration(days: valeur.toInt()));
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          dateCourte(date),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: prevu,
                  isCurved: false,
                  color: Colors.grey,
                  barWidth: 2,
                  dashArray: [6, 4],
                  dotData: const FlDotData(show: false),
                ),
                LineChartBarData(
                  spots: reel,
                  isCurved: false,
                  color: couleur,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget titreSection(String texte) {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 10),
      child: Row(
        children: [
          Container(width: 4, height: 22, color: Colors.deepPurple),
          Container(
            margin: const EdgeInsets.only(left: 10),
            child: Text(
              texte,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget carteResume() {
    SuiviObjectif s = suivi!;
    ResultatProgression r = resultat!;
    Color couleur = couleurStatutProgression(r.statut);
    double pourcentage = r.pourcentage.clamp(0.0, 100.0).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.nomProgramme ?? 'Programme supprimé',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                pastilleProgression(r.statut),
              ],
            ),
            if (!proprietaire && s.nomAthlete != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Athlète : ${s.nomAthlete}'),
              ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: pourcentage / 100,
              minHeight: 10,
              color: couleur,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 6),
            Text(
              '${pourcentage.toStringAsFixed(0)} % réalisé · '
                  '${r.pourcentageAttendu.toStringAsFixed(0)} % attendu',
            ),
            const Divider(height: 24),
            ligneInfo(
              Icons.play_arrow,
              'Départ',
              '${formaterValeur(s.valeurDepart)} ${s.unite}',
            ),
            ligneInfo(
              Icons.monitor_weight,
              'Actuel',
              '${formaterValeur(r.valeurActuelle)} ${s.unite}',
            ),
            ligneInfo(
              Icons.flag,
              'Cible',
              '${formaterValeur(s.valeurCible)} ${s.unite}',
            ),
            ligneInfo(
              Icons.trending_flat,
              'Reste à faire',
              '${formaterValeur(r.resteAFaire)} ${s.unite}',
            ),
            ligneInfo(
              Icons.event,
              'Date limite',
              '${afficherDate(s.dateLimite)} (${r.joursRestants} j)',
            ),
            if (r.rythmeParSemaine != null)
              ligneInfo(
                Icons.speed,
                'Rythme',
                '${r.rythmeParSemaine!.toStringAsFixed(2)} ${s.unite} / semaine',
              ),
            if (r.dateEstimee != null)
              ligneInfo(
                Icons.insights,
                'Arrivée estimée',
                afficherDate(r.dateEstimee!),
              ),
          ],
        ),
      ),
    );
  }

  Widget listeMesures() {
    if (mesures.isEmpty) {
      return const SizedBox.shrink();
    }

    // Plus récente en premier.
    List<MesureProgression> inversees = mesures.reversed.toList();

    return Column(
      children: inversees.map((mesure) {
        return Card(
          child: ListTile(
            onTap: proprietaire
                ? () {
              dialogueMesure(existante: mesure);
            }
                : null,
            title: Text(
              '${formaterValeur(mesure.valeur)} ${suivi!.unite}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              mesure.note == null || mesure.note!.isEmpty
                  ? afficherDate(mesure.dateMesure)
                  : '${afficherDate(mesure.dateMesure)} · ${mesure.note}',
            ),
            trailing: proprietaire
                ? IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                supprimerMesure(mesure);
              },
            )
                : null,
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (chargement || suivi == null || resultat == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Suivi')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Suivi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          carteResume(),
          titreSection('Progression'),
          courbe(),
          if (suivi!.statut != 'ABANDONNE') ...[
            titreSection(proprietaire ? 'Conseils' : 'Adaptation proposée'),
            sectionAdaptation(),
          ],
          titreSection('Mesures'),
          listeMesures(),
          if (proprietaire && suivi!.statut == 'EN_COURS')
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  dialogueMesure();
                },
                child: const Text('AJOUTER UNE MESURE'),
              ),
            ),
          if (proprietaire)
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                ),
                onPressed: supprimerObjectif,
                child: const Text('SUPPRIMER L\'OBJECTIF'),
              ),
            ),
        ],
      ),
    );
  }
}