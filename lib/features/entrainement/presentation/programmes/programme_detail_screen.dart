import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:coach_app/core/utils/alertes.dart';
import 'package:coach_app/core/utils/outils.dart';
import 'package:coach_app/features/entrainement/data/models/enums.dart';
import 'package:coach_app/features/entrainement/data/models/exercice_api.dart';
import 'package:coach_app/features/entrainement/data/models/programme.dart';
import 'package:coach_app/features/entrainement/data/models/programme_exercice.dart';
import 'package:coach_app/features/entrainement/data/repositories/programme_exercice_repository.dart';
import 'package:coach_app/features/entrainement/data/repositories/programme_repository.dart';
import 'package:coach_app/features/entrainement/data/services/exercise_db_service.dart';
import 'package:coach_app/features/entrainement/presentation/suivi/libelles_suivi.dart';
import 'package:coach_app/features/entrainement/presentation/suivi/suivi_form_screen.dart';
import 'package:coach_app/features/entrainement/presentation/widgets/apparence_entrainement.dart';
import 'package:coach_app/features/entrainement/presentation/widgets/carte_image.dart';
import 'package:coach_app/features/entrainement/presentation/widgets/ligne_info.dart';
import 'choix_exercice_screen.dart';
import 'outils_exercice.dart';
import 'programme_exercice_form_screen.dart';
import 'programme_form_screen.dart';

class ProgrammeDetailScreen extends StatefulWidget {
  final Programme programme;

  const ProgrammeDetailScreen({super.key, required this.programme});

  @override
  State<ProgrammeDetailScreen> createState() => _ProgrammeDetailScreenState();
}

class _ProgrammeDetailScreenState extends State<ProgrammeDetailScreen> {
  final ProgrammeExerciceRepository exerciceRepository =
  ProgrammeExerciceRepository();
  final ExerciseDbService exerciseDbService = ExerciseDbService();

  List<ProgrammeExercice> exercices = [];
  // Infos venant de l'API (jamais enregistrées). Valeur nulle = échec.
  final Map<String, ExerciceApi?> infos = {};
  bool chargementExercices = true;

  Programme get programme => widget.programme;

  bool get proprietaire {
    final utilisateur = Supabase.instance.client.auth.currentUser;
    return utilisateur != null && utilisateur.id == programme.idCoach;
  }

  @override
  void initState() {
    super.initState();
    chargerExercices();
  }

  Future<void> chargerExercices() async {
    try {
      List<ProgrammeExercice> liste =
      await exerciceRepository.getExercices(programme.id!);

      if (!mounted) {
        return;
      }

      setState(() {
        exercices = liste;
        chargementExercices = false;
        infos.clear();
      });

      // Noms et GIF : un appel à la fois, sans bloquer l'affichage.
      for (var element in liste) {
        try {
          ExerciceApi exercice =
          await exerciseDbService.exerciceParId(element.externalId);

          if (!mounted) {
            return;
          }

          setState(() {
            infos[element.externalId] = exercice;
          });
        } catch (_) {
          if (!mounted) {
            return;
          }

          setState(() {
            infos[element.externalId] = null;
          });
        }
      }
    } catch (erreur) {
      if (mounted) {
        setState(() {
          chargementExercices = false;
        });

        afficherAlerteErreur(
          context,
          titre: 'Chargement impossible',
          message: messageErreur(erreur),
        );
      }
    }
  }

  Future<void> ajouterExercice() async {
    ExerciceApi? choisi = await Navigator.push<ExerciceApi>(
      context,
      MaterialPageRoute(builder: (context) => const ChoixExerciceScreen()),
    );

    if (choisi == null || !mounted) {
      return;
    }

    try {
      int ordre = await exerciceRepository.prochainOrdre(programme.id!);

      if (!mounted) {
        return;
      }

      bool? ok = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => ProgrammeExerciceFormScreen(
            idProgramme: programme.id!,
            externalId: choisi.id,
            nomExercice: nomPropre(choisi.nom),
            ordre: ordre,
          ),
        ),
      );

      if (ok == true) {
        chargerExercices();
      }
    } catch (erreur) {
      if (mounted) {
        afficherAlerteErreur(
          context,
          titre: 'Ajout impossible',
          message: messageErreur(erreur),
        );
      }
    }
  }

  Future<void> modifierExercice(ProgrammeExercice element) async {
    ExerciceApi? info = infos[element.externalId];

    bool? ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ProgrammeExerciceFormScreen(
          idProgramme: programme.id!,
          externalId: element.externalId,
          nomExercice:
          info == null ? 'Exercice ${element.externalId}' : nomPropre(info.nom),
          ordre: element.ordre,
          existant: element,
        ),
      ),
    );

    if (ok == true) {
      chargerExercices();
    }
  }

  Future<void> supprimerExercice(ProgrammeExercice element) async {
    bool confirme = await confirmerAction(
      context,
      titre: 'Retirer',
      message: 'Retirer cet exercice du programme ?',
      libelleBouton: 'Retirer',
    );

    if (!confirme) {
      return;
    }

    try {
      await exerciceRepository.supprimer(programme.id!, element.externalId);
      await chargerExercices();
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

  Future<void> modifier(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProgrammeFormScreen(programme: programme),
      ),
    );

    // On revient à la liste, qui se recharge.
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> supprimer(BuildContext context) async {
    bool confirme = await confirmerAction(
      context,
      titre: 'Supprimer',
      message: 'Supprimer le programme "${programme.nom}" ?',
    );

    if (!confirme) {
      return;
    }

    try {
      await ProgrammeRepository().supprimer(programme.id!);

      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (erreur) {
      if (context.mounted) {
        afficherAlerteErreur(
          context,
          titre: 'Suppression impossible',
          message: '$erreur',
        );
      }
    }
  }

  Future<void> choisir(BuildContext context) async {
    bool? cree = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => SuiviFormScreen(programme: programme),
      ),
    );

    if (cree == true && context.mounted) {
      afficherMessage(
        context,
        'Objectif enregistré. Retrouve-le dans l\'onglet Suivi.',
      );
    }
  }

  Widget titreSection(String texte) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 10),
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

  // Ex. : "3 × 12 · repos 60 s · 20 kg"
  String resume(ProgrammeExercice element) {
    List<String> parties = [];

    if (element.series != null && element.repetitions != null) {
      parties.add('${element.series} × ${element.repetitions}');
    } else if (element.series != null) {
      parties.add('${element.series} séries');
    } else if (element.repetitions != null) {
      parties.add('${element.repetitions} répétitions');
    }

    if (element.tempsRepos != null) {
      parties.add('repos ${element.tempsRepos} s');
    }

    if (element.charge != null) {
      parties.add('${formaterValeur(element.charge!)} kg');
    }

    if (parties.isEmpty) {
      return 'Aucun détail';
    }

    return parties.join(' · ');
  }

  Widget ligneExercice(ProgrammeExercice element) {
    bool connu = infos.containsKey(element.externalId);
    ExerciceApi? info = infos[element.externalId];

    String nom;
    if (info != null) {
      nom = nomPropre(info.nom);
    } else if (connu) {
      nom = 'Exercice ${element.externalId}';
    } else {
      nom = 'Chargement...';
    }

    return Card(
      child: ListTile(
        leading: SizedBox(
          width: 56,
          height: 56,
          child: Image.network(
            ExerciseDbService.urlGif(element.externalId),
            headers: ExerciseDbService.entetes,
            fit: BoxFit.cover,
            errorBuilder: (context, erreur, trace) {
              return const Icon(Icons.fitness_center);
            },
          ),
        ),
        title: Text('${element.ordre}. $nom'),
        subtitle: Text(resume(element)),
        trailing: proprietaire
            ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                modifierExercice(element);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                supprimerExercice(element);
              },
            ),
          ],
        )
            : null,
      ),
    );
  }

  Widget sectionExercices() {
    if (chargementExercices) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (exercices.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            proprietaire
                ? 'Aucun exercice pour le moment. Ajoute le premier.'
                : 'Ce programme ne contient pas encore d\'exercices.',
          ),
        ),
      );
    }

    return Column(children: exercices.map(ligneExercice).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Programme')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CarteImage(
            titre: programme.nom,
            sousTitre: enTexte(programme.objectif),
            cheminImage: imageObjectif(programme.objectif),
            couleurs: couleursObjectif(programme.objectif),
            icone: iconeObjectif(programme.objectif),
            hauteur: 200,
          ),
          Card(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                children: [
                  ligneInfo(Icons.flag, 'Objectif', enTexte(programme.objectif)),
                  const Divider(height: 1),
                  ligneInfo(
                    Icons.signal_cellular_alt,
                    'Niveau',
                    enTexte(programme.niveau),
                  ),
                  if (programme.dureeSemaines != null) ...[
                    const Divider(height: 1),
                    ligneInfo(
                      Icons.timelapse,
                      'Durée',
                      '${programme.dureeSemaines} semaines',
                    ),
                  ],
                  if (programme.dateDebut != null) ...[
                    const Divider(height: 1),
                    ligneInfo(
                      Icons.event,
                      'Début',
                      afficherDate(programme.dateDebut!),
                    ),
                  ],
                  if (programme.dateFin != null) ...[
                    const Divider(height: 1),
                    ligneInfo(
                      Icons.event_available,
                      'Fin',
                      afficherDate(programme.dateFin!),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (programme.description != null &&
              programme.description!.isNotEmpty)
            Card(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Text(
                  programme.description!,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
              ),
            ),
          titreSection('Exercices du programme'),
          sectionExercices(),
          if (proprietaire)
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: ajouterExercice,
                child: const Text('AJOUTER UN EXERCICE'),
              ),
            ),
          if (proprietaire)
            Container(
              margin: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        modifier(context);
                      },
                      child: const Text('Modifier'),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(left: 10),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          supprimer(context);
                        },
                        child: const Text('Supprimer'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (!proprietaire)
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  choisir(context);
                },
                child: const Text('CHOISIR CE PROGRAMME'),
              ),
            ),
        ],
      ),
    );
  }
}