// Une réservation d'un athlète, avec les infos de sa séance.
class LigneAssiduite {
  final int idReservation;
  final String statutReservation; // CONFIRMEE ou ANNULEE
  final bool? presence; // null = non renseignée
  final String statutSeance; // PLANIFIEE, COMPLETE, ANNULEE, TERMINEE
  final String titreSeance;
  final DateTime dateSeance;

  LigneAssiduite({
    required this.idReservation,
    required this.statutReservation,
    required this.presence,
    required this.statutSeance,
    required this.titreSeance,
    required this.dateSeance,
  });

  factory LigneAssiduite.fromJson(Map<String, dynamic> json) {
    final seance = json['seance'] as Map<String, dynamic>;

    return LigneAssiduite(
      idReservation: json['id_reservation'] as int,
      statutReservation: json['statut'] as String,
      presence: json['presence'] as bool?,
      statutSeance: seance['statut'] as String,
      titreSeance: seance['titre'] as String,
      dateSeance: DateTime.parse(seance['date'] as String),
    );
  }
}

// Un participant d'une séance (feuille de présence du coach).
class PresenceParticipant {
  final int idReservation;
  final String nom;
  final bool? presence;

  PresenceParticipant({
    required this.idReservation,
    required this.nom,
    required this.presence,
  });

  factory PresenceParticipant.fromJson(Map<String, dynamic> json) {
    final profil = json['profiles'] as Map<String, dynamic>?;
    String nom = '${profil?['prenom'] ?? ''} ${profil?['nom'] ?? ''}'.trim();

    if (nom.isEmpty) {
      nom = 'Participant';
    }

    return PresenceParticipant(
      idReservation: json['id_reservation'] as int,
      nom: nom,
      presence: json['presence'] as bool?,
    );
  }
}