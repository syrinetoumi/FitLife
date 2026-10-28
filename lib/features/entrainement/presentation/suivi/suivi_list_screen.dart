import 'package:flutter/material.dart';

import 'package:coach_app/core/utils/outils.dart';
import 'package:coach_app/features/entrainement/data/models/suivi_objectif.dart';
import 'package:coach_app/features/entrainement/data/repositories/mesure_progression_repository.dart';
import 'package:coach_app/features/entrainement/data/repositories/role_repository.dart';
import 'package:coach_app/features/entrainement/data/repositories/suivi_objectif_repository.dart';
import 'package:coach_app/features/entrainement/data/services/calcul_progression.dart';
import 'libelles_suivi.dart';
import 'suivi_detail_screen.dart';

// Un objectif avec son résultat de calcul.
class _Ligne {
  final SuiviObjectif suivi;
  final ResultatProgression resultat;

  _Ligne(this.suivi, this.resultat);
}

class SuiviListScreen extends StatefulWidget {
  final bool integre;

  const SuiviListScreen({super.key, this.integre = false});

  @override
  State<SuiviListScreen> createState() => _SuiviListScreenState();
}

class _SuiviListScreenState extends State<SuiviListScreen> {
  final SuiviObjectifRepository suiviRepository = SuiviObjectifRepository();
  final MesureProgressionRepository mesureRepository =
  MesureProgressionRepository();
  final RoleRepository roleRepository = RoleRepository();

  List<_Ligne> lignes = [];
  bool chargement = true;
  bool coach = false;

  @override
  void initState() {
    super.initState();
    charger();
  }

  Future<void> charger() async {
    try {
      bool estCoach = await roleRepository.estCoach();

      List<SuiviObjectif> suivis = estCoach
          ? await suiviRepository.getSuivisDeMesAthletes()
          : await suiviRepository.getMesSuivis();

      List<_Ligne> resultat = await Future.wait<_Ligne>(
        suivis.map((suivi) async {
          final mesures = await mesureRepository.getMesures(suivi.id!);
          return _Ligne(suivi, CalculProgression.calculer(suivi, mesures));
        }),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        coach = estCoach;
        lignes = resultat;
        chargement = false;
      });
    } catch (erreur) {
      if (mounted) {
        setState(() {
          chargement = false;
        });

        afficherMessage(context, 'Erreur de chargement : ${messageErreur(erreur)}');
      }
    }
  }

  Future<void> ouvrirDetail(SuiviObjectif suivi) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SuiviDetailScreen(idSuivi: suivi.id!),
      ),
    );

    charger();
  }

  Widget carte(_Ligne ligne) {
    SuiviObjectif suivi = ligne.suivi;
    ResultatProgression resultat = ligne.resultat;
    Color couleur = couleurStatutProgression(resultat.statut);

    String programme = suivi.nomProgramme ?? 'Programme supprimé';
    String titre = coach ? (suivi.nomAthlete ?? 'Athlète') : programme;

    String sousTitre = coach
        ? '$programme · ${formaterValeur(suivi.valeurDepart)} → '
        '${formaterValeur(suivi.valeurCible)} ${suivi.unite}'
        : '${formaterValeur(suivi.valeurDepart)} → '
        '${formaterValeur(suivi.valeurCible)} ${suivi.unite}'
        ' · avant le ${afficherDate(suivi.dateLimite)}';

    double pourcentage = resultat.pourcentage.clamp(0.0, 100.0).toDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          ouvrirDetail(suivi);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      titre,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  pastilleProgression(resultat.statut),
                ],
              ),
              const SizedBox(height: 4),
              Text(sousTitre),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: pourcentage / 100,
                minHeight: 8,
                color: couleur,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 6),
              Text(
                '${pourcentage.toStringAsFixed(0)} % réalisé · '
                    '${resultat.pourcentageAttendu.toStringAsFixed(0)} % attendu',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget construireListe() {
    if (chargement) {
      return const Center(child: CircularProgressIndicator());
    }

    if (lignes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            coach
                ? 'Aucun athlète ne suit encore tes programmes.'
                : 'Aucun objectif pour le moment.\n'
                'Ouvre un programme et choisis-le pour commencer.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: charger,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: lignes.map(carte).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.integre) {
      return construireListe();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Suivi')),
      drawer: construireDrawer(context),
      body: construireListe(),
    );
  }
}