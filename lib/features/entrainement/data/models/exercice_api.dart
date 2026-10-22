// Un exercice renvoyé par ExerciseDB.
// Il n'est JAMAIS enregistré (cache interdit par les conditions d'utilisation).
class ExerciceApi {
  final String id;
  final String nom;
  final String partieCorps;
  final String cible;
  final String equipement;
  final List<String> musclesSecondaires;
  final List<String> instructions;
  final String description;
  final String difficulte;
  final String categorie;

  ExerciceApi({
    required this.id,
    required this.nom,
    required this.partieCorps,
    required this.cible,
    required this.equipement,
    required this.musclesSecondaires,
    required this.instructions,
    required this.description,
    required this.difficulte,
    required this.categorie,
  });

  // Chapitre 6 : désérialisation d'un objet JSON (Map).
  factory ExerciceApi.fromJson(Map<String, dynamic> json) {
    return ExerciceApi(
      id: (json['id'] ?? '').toString(),
      nom: (json['name'] ?? '').toString(),
      partieCorps: (json['bodyPart'] ?? '').toString(),
      cible: (json['target'] ?? '').toString(),
      equipement: (json['equipment'] ?? '').toString(),
      musclesSecondaires: List<String>.from(json['secondaryMuscles'] ?? []),
      instructions: List<String>.from(json['instructions'] ?? []),
      description: (json['description'] ?? '').toString(),
      difficulte: (json['difficulty'] ?? '').toString(),
      categorie: (json['category'] ?? '').toString(),
    );
  }
}