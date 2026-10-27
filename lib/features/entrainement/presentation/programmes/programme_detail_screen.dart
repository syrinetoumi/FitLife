import 'package:flutter/material.dart';

import 'package:coach_app/core/utils/alertes.dart';
import 'package:coach_app/core/utils/outils.dart';
import 'package:coach_app/features/entrainement/data/models/enums.dart';
import 'package:coach_app/features/entrainement/data/models/programme.dart';
import 'package:coach_app/features/entrainement/data/repositories/programme_repository.dart';
import 'package:coach_app/features/entrainement/presentation/widgets/apparence_entrainement.dart';
import 'package:coach_app/features/entrainement/presentation/widgets/carte_image.dart';
import 'package:coach_app/features/entrainement/presentation/widgets/ligne_info.dart';
import 'programme_form_screen.dart';

class ProgrammeDetailScreen extends StatelessWidget {
  final Programme programme;

  const ProgrammeDetailScreen({super.key, required this.programme});

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
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Les exercices de ce programme (séries, répétitions, repos) '
                    's\'afficheront ici.',
              ),
            ),
          ),
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
        ],
      ),
    );
  }
}