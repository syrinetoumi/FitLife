class ProgrammeExercice {
  final int idProgramme;
  final int idExercice;
  final int ordre;
  final int? series;
  final int? repetitions;
  final int? tempsRepos;
  final double? charge;

  ProgrammeExercice({
    required this.idProgramme, required this.idExercice, required this.ordre,
    this.series, this.repetitions, this.tempsRepos, this.charge,
  });

  factory ProgrammeExercice.fromJson(Map<String, dynamic> j) => ProgrammeExercice(
    idProgramme: j['id_programme'],
    idExercice: j['id_exercice'],
    ordre: j['ordre'],
    series: j['series'],
    repetitions: j['repetitions'],
    tempsRepos: j['temps_repos'],
    charge: (j['charge'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'id_programme': idProgramme,
    'id_exercice': idExercice,
    'ordre': ordre,
    'series': series,
    'repetitions': repetitions,
    'temps_repos': tempsRepos,
    'charge': charge,
  };
}