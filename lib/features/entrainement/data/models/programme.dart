import 'enums.dart';

class Programme {
  final int? id;
  final String nom;
  final String? description;
  final ObjectifProgramme objectif;
  final Niveau niveau;
  final int? dureeSemaines;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final String idCoach;

  Programme({
    this.id, required this.nom, this.description, required this.objectif,
    required this.niveau, this.dureeSemaines, this.dateDebut, this.dateFin,
    required this.idCoach,
  });

  factory Programme.fromJson(Map<String, dynamic> j) => Programme(
    id: j['id_programme'],
    nom: j['nom'],
    description: j['description'],
    objectif: ObjectifProgramme.values.byName(j['objectif']),
    niveau: Niveau.values.byName(j['niveau']),
    dureeSemaines: j['duree_semaines'],
    dateDebut: j['date_debut'] != null ? DateTime.parse(j['date_debut']) : null,
    dateFin: j['date_fin'] != null ? DateTime.parse(j['date_fin']) : null,
    idCoach: j['id_coach'],
  );

  Map<String, dynamic> toJson() => {
    'nom': nom,
    'description': description,
    'objectif': objectif.name,
    'niveau': niveau.name,
    'duree_semaines': dureeSemaines,
    'date_debut': dateDebut?.toIso8601String().split('T').first,
    'date_fin': dateFin?.toIso8601String().split('T').first,
    'id_coach': idCoach,
  };
}