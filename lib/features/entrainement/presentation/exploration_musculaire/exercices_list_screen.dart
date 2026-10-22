import 'package:flutter/material.dart';
import 'libelles_exercice.dart';
import 'package:coach_app/features/entrainement/data/models/exercice_api.dart';
import 'package:coach_app/features/entrainement/data/services/exercise_db_service.dart';
import 'exercice_detail_screen.dart';

class ExercicesListScreen extends StatefulWidget {
  final String cible;    // nom ExerciseDB (ex. "biceps")
  final String libelle;  // nom affiché (ex. "Biceps")

  const ExercicesListScreen({
    super.key,
    required this.cible,
    required this.libelle,
  });

  @override
  State<ExercicesListScreen> createState() => _ExercicesListScreenState();
}

class _ExercicesListScreenState extends State<ExercicesListScreen> {
  final ExerciseDbService service = ExerciseDbService();
  late Future<List<ExerciceApi>> exercices;

  @override
  void initState() {
    super.initState();
    exercices = service.exercicesParCible(widget.cible);
  }

  void recharger() {
    setState(() {
      exercices = service.exercicesParCible(widget.cible);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Exercices : ${widget.libelle}')),
      body: FutureBuilder<List<ExerciceApi>>(
        future: exercices,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      snapshot.error.toString().replaceFirst('Exception: ', ''),
                      textAlign: TextAlign.center,
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      child: ElevatedButton(
                        onPressed: recharger,
                        child: const Text('Réessayer'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          List<ExerciceApi> liste = snapshot.data!;

          if (liste.isEmpty) {
            return const Center(child: Text('Aucun exercice trouvé.'));
          }

          return ListView(
            children: [
              ...liste.map((exercice) {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(14),
                    leading: CircleAvatar(
                      backgroundColor:
                      couleurDifficulte(exercice.difficulte).withOpacity(0.15),
                      child: Icon(
                        Icons.fitness_center,
                        color: couleurDifficulte(exercice.difficulte),
                      ),
                    ),
                    title: Text(
                      titreExercice(exercice.nom),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Container(
                      margin: const EdgeInsets.only(top: 6),
                      child: Text(
                        '${libelleEquipement(exercice.equipement)} · '
                            '${libelleDifficulte(exercice.difficulte)}',
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ExerciceDetailScreen(exercice: exercice),
                        ),
                      );
                    },
                  ),
                );
              }),
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Données : ExerciseDB',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}