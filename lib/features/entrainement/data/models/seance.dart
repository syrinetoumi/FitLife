import 'enums.dart';

class Seance {
  final int? id;
  final String titre;
  final String? description;
  final DateTime date;
  final String heureDebut; // "HH:mm:ss"
  final String heureFin;
  final TypeSeance type;
  final int? capacite;
  final double prix;
  final StatutSeance statut;
  final String idCoach;
  final int? idProgramme;
  final int? idEspaceSportif;

  Seance({
    this.id, required this.titre, this.description, required this.date,
    required this.heureDebut, required this.heureFin, required this.type,
    this.capacite, this.prix = 0, this.statut = StatutSeance.PLANIFIEE,
    required this.idCoach, this.idProgramme, this.idEspaceSportif,
  });

  factory Seance.fromJson(Map<String, dynamic> j) => Seance(
    id: j['id_seance'],
    titre: j['titre'],
    description: j['description'],
    date: DateTime.parse(j['date']),
    heureDebut: j['heure_debut'],
    heureFin: j['heure_fin'],
    type: TypeSeance.values.byName(j['type']),
    capacite: j['capacite'],
    prix: (j['prix'] as num?)?.toDouble() ?? 0,
    statut: StatutSeance.values.byName(j['statut']),
    idCoach: j['id_coach'],
    idProgramme: j['id_programme'],
    idEspaceSportif: j['id_espace_sportif'],
  );

  Map<String, dynamic> toJson() => {
    'titre': titre,
    'description': description,
    'date': date.toIso8601String().split('T').first,
    'heure_debut': heureDebut,
    'heure_fin': heureFin,
    'type': type.name,
    'capacite': capacite,
    'prix': prix,
    'statut': statut.name,
    'id_coach': idCoach,
    'id_programme': idProgramme,
    'id_espace_sportif': idEspaceSportif,
  };
}