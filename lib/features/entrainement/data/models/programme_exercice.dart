class ProgrammeExercice {
  final int idProgramme;
  final String externalId; // identifiant de l'exercice dans ExerciseDB
  final int ordre;
  final int? series;
  final int? repetitions;
  final int? tempsRepos; // en secondes
  final double? charge; // en kg

  ProgrammeExercice({
    required this.idProgramme,
    required this.externalId,
    required this.ordre,
    this.series,
    this.repetitions,
    this.tempsRepos,
    this.charge,
  });

  factory ProgrammeExercice.fromJson(Map<String, dynamic> json) {
    return ProgrammeExercice(
      idProgramme: json['id_programme'] as int,
      externalId: json['external_id'] as String,
      ordre: json['ordre'] as int,
      series: json['series'] as int?,
      repetitions: json['repetitions'] as int?,
      tempsRepos: json['temps_repos'] as int?,
      charge: (json['charge'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id_programme': idProgramme,
    'external_id': externalId,
    'ordre': ordre,
    'series': series,
    'repetitions': repetitions,
    'temps_repos': tempsRepos,
    'charge': charge,
  };
}