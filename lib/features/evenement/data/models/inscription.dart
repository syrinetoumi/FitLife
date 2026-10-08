enum StatutInscription {
  enAttente,
  confirmee,
  annulee,
  refusee,
}

// Texte enregistré dans la base (et affiché dans les écrans).
String statutInscriptionEnTexte(StatutInscription statut) {
  if (statut == StatutInscription.confirmee) {
    return 'CONFIRMEE';
  }

  if (statut == StatutInscription.annulee) {
    return 'ANNULEE';
  }

  if (statut == StatutInscription.refusee) {
    return 'REFUSEE';
  }

  return 'EN_ATTENTE';
}

class Inscription {
  String idInscription;
  String idEvenement;
  String idAthlete;
  String idCategorie;
  DateTime dateInscription;
  StatutInscription statut;

  Inscription({
    required this.idInscription,
    required this.idEvenement,
    required this.idAthlete,
    required this.idCategorie,
    required this.dateInscription,
    required this.statut,
  });

  String statutToString() {
    return statutInscriptionEnTexte(statut);
  }

  Map<String, dynamic> toMap() {
    return {
      'id_evenement': idEvenement,
      'id_athlete': idAthlete,
      'id_categorie': idCategorie,
      'date_inscription': dateInscription.toUtc().toIso8601String(),
      'statut': statutToString(),
    };
  }

  factory Inscription.fromMap(Map<String, dynamic> data) {
    StatutInscription statut = StatutInscription.enAttente;

    if (data['statut'] == 'CONFIRMEE') {
      statut = StatutInscription.confirmee;
    }

    if (data['statut'] == 'ANNULEE') {
      statut = StatutInscription.annulee;
    }

    if (data['statut'] == 'REFUSEE') {
      statut = StatutInscription.refusee;
    }

    return Inscription(
      idInscription: data['id'].toString(),
      idEvenement: data['id_evenement'].toString(),
      idAthlete: data['id_athlete'] ?? '',
      idCategorie: data['id_categorie'].toString(),
      dateInscription: DateTime.parse(data['date_inscription']).toLocal(),
      statut: statut,
    );
  }
}
