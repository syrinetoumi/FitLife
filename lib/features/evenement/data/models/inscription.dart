import 'categorie.dart';

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
  // MÉTIER 1 : on mémorise l'âge et le niveau de l'athlète
  // pour vérifier son éligibilité à la catégorie.
  int ageAthlete;
  NiveauCategorie niveauAthlete;
  DateTime dateInscription;
  StatutInscription statut;

  Inscription({
    required this.idInscription,
    required this.idEvenement,
    required this.idAthlete,
    required this.idCategorie,
    required this.ageAthlete,
    required this.niveauAthlete,
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
      'age_athlete': ageAthlete,
      'niveau_athlete': niveauAthlete.name.toUpperCase(),
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

    // Même principe que Categorie.fromMap pour le niveau.
    // (orElse : anciennes lignes sans niveau => debutant)
    NiveauCategorie niveau = NiveauCategorie.values.firstWhere(
          (n) => n.name.toUpperCase() == data['niveau_athlete'],
      orElse: () => NiveauCategorie.debutant,
    );

    // Âge : les anciennes lignes peuvent être vides (null).
    int age = 0;
    if (data['age_athlete'] != null) {
      age = int.parse(data['age_athlete'].toString());
    }

    return Inscription(
      idInscription: data['id'].toString(),
      idEvenement: data['id_evenement'].toString(),
      idAthlete: data['id_athlete'] ?? '',
      idCategorie: data['id_categorie'].toString(),
      ageAthlete: age,
      niveauAthlete: niveau,
      dateInscription: DateTime.parse(data['date_inscription']).toLocal(),
      statut: statut,
    );
  }
}
