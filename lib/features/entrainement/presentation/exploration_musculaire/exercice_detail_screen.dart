import 'package:flutter/material.dart';

import 'package:coach_app/features/entrainement/data/models/exercice_api.dart';
import 'package:coach_app/features/entrainement/data/services/exercise_db_service.dart';
import 'libelles_exercice.dart';

class ExerciceDetailScreen extends StatelessWidget {
  final ExerciceApi exercice;

  const ExerciceDetailScreen({super.key, required this.exercice});

  // Titre de section avec une barre violette à gauche.
  Widget titreSection(String texte) {
    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 22,
            color: Colors.deepPurple,
          ),
          Container(
            margin: const EdgeInsets.only(left: 10),
            child: Text(
              texte,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Une ligne d'information : icône, petit libellé gris, valeur en gras.
  Widget ligneInfo(IconData icone, String libelle, String valeur) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icone, color: Colors.deepPurple),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    libelle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    valeur,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Pastille colorée (difficulté, catégorie).
  Widget pastille(String texte, Color couleur) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha:0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: couleur),
      ),
      child: Text(
        texte,
        style: TextStyle(
          color: couleur,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Une étape numérotée.
  Widget etape(int numero, String texte) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.deepPurple,
            child: Text(
              '$numero',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 12),
              child: Text(
                texte,
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget imageExercice() {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          ExerciseDbService.urlGif(exercice.id),
          headers: ExerciseDbService.entetes,
          width: 220,
          height: 220,
          fit: BoxFit.contain,
          loadingBuilder: (context, enfant, progression) {
            if (progression == null) {
              return enfant;
            }

            return const SizedBox(
              width: 220,
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (context, erreur, trace) {
            return const SizedBox(
              width: 220,
              height: 220,
              child: Center(child: Text('Image indisponible')),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exercice')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          imageExercice(),

          // Nom de l'exercice.
          Container(
            margin: const EdgeInsets.only(top: 16, bottom: 10),
            child: Text(
              titreExercice(exercice.nom),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Pastilles : difficulté et catégorie.
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              pastille(
                libelleDifficulte(exercice.difficulte),
                couleurDifficulte(exercice.difficulte),
              ),
              pastille(
                libelleCategorie(exercice.categorie),
                Colors.deepPurple,
              ),
            ],
          ),

          titreSection('En bref'),
          Card(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                children: [
                  ligneInfo(
                    Icons.accessibility_new,
                    'Muscle ciblé',
                    libelleMuscle(exercice.cible),
                  ),
                  const Divider(height: 1),
                  ligneInfo(
                    Icons.fitness_center,
                    'Matériel',
                    libelleEquipement(exercice.equipement),
                  ),
                  const Divider(height: 1),
                  ligneInfo(
                    Icons.person,
                    'Zone du corps',
                    libellePartieCorps(exercice.partieCorps),
                  ),
                ],
              ),
            ),
          ),

          if (exercice.musclesSecondaires.isNotEmpty) ...[
            titreSection('Muscles secondaires'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: exercice.musclesSecondaires.map((muscle) {
                return Chip(label: Text(libelleMuscle(muscle)));
              }).toList(),
            ),
          ],

          titreSection('Description'),
          Card(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                exercice.description,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ),
          ),

          titreSection('Comment faire'),
          Card(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ...exercice.instructions.asMap().entries.map((entree) {
                    return etape(entree.key + 1, entree.value);
                  }),
                ],
              ),
            ),
          ),

          Container(
            margin: const EdgeInsets.only(top: 12),
            child: const Text(
              'Textes en anglais · Données : ExerciseDB',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}