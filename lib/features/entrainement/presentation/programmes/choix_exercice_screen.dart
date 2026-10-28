import 'package:flutter/material.dart';

import 'package:coach_app/features/entrainement/data/models/exercice_api.dart';
import 'package:coach_app/features/entrainement/data/services/exercise_db_service.dart';
import 'outils_exercice.dart';

// Muscles ExerciseDB (clé de l'API -> libellé français).
const Map<String, String> musclesChoix = {
  'pectorals': 'Pectoraux',
  'lats': 'Dorsaux',
  'upper back': 'Haut du dos',
  'delts': 'Épaules',
  'biceps': 'Biceps',
  'triceps': 'Triceps',
  'forearms': 'Avant-bras',
  'abs': 'Abdominaux',
  'quads': 'Quadriceps',
  'hamstrings': 'Ischio-jambiers',
  'glutes': 'Fessiers',
  'calves': 'Mollets',
  'adductors': 'Adducteurs',
  'abductors': 'Abducteurs',
  'traps': 'Trapèzes',
  'spine': 'Colonne',
  'serratus anterior': 'Dentelé',
  'levator scapulae': 'Cou',
  'cardiovascular system': 'Cardio',
};

class ChoixExerciceScreen extends StatefulWidget {
  const ChoixExerciceScreen({super.key});

  @override
  State<ChoixExerciceScreen> createState() => _ChoixExerciceScreenState();
}

class _ChoixExerciceScreenState extends State<ChoixExerciceScreen> {
  final ExerciseDbService service = ExerciseDbService();

  String cible = 'pectorals';
  List<ExerciceApi> exercices = [];
  bool chargement = false;
  String? erreur;

  @override
  void initState() {
    super.initState();
    charger();
  }

  Future<void> charger() async {
    setState(() {
      chargement = true;
      erreur = null;
    });

    try {
      List<ExerciceApi> resultat = await service.exercicesParCible(cible);

      if (!mounted) {
        return;
      }

      setState(() {
        exercices = resultat;
        chargement = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        erreur = e.toString().replaceFirst('Exception: ', '');
        chargement = false;
      });
    }
  }

  Widget barreMuscles() {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        children: musclesChoix.entries.map((entree) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(entree.value),
              selected: cible == entree.key,
              onSelected: (_) {
                setState(() {
                  cible = entree.key;
                });
                charger();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget ligne(ExerciceApi exercice) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: SizedBox(
          width: 56,
          height: 56,
          child: Image.network(
            ExerciseDbService.urlGif(exercice.id),
            headers: ExerciseDbService.entetes,
            fit: BoxFit.cover,
            errorBuilder: (context, erreur, trace) {
              return const Icon(Icons.fitness_center);
            },
          ),
        ),
        title: Text(nomPropre(exercice.nom)),
        subtitle: Text(nomPropre(exercice.equipement)),
        trailing: const Icon(Icons.add_circle_outline),
        onTap: () {
          Navigator.pop(context, exercice);
        },
      ),
    );
  }

  Widget corps() {
    if (chargement) {
      return const Center(child: CircularProgressIndicator());
    }

    if (erreur != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(erreur!, textAlign: TextAlign.center),
        ),
      );
    }

    if (exercices.isEmpty) {
      return const Center(child: Text('Aucun exercice trouvé.'));
    }

    return ListView(children: exercices.map(ligne).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choisir un exercice')),
      body: Column(
        children: [
          barreMuscles(),
          Expanded(child: corps()),
        ],
      ),
    );
  }
}