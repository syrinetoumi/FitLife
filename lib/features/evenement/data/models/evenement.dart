enum TypeEvenement {
  marathon,
  competition,
  match,
  tournoi,
  gala,
  challenge,
}

enum StatutEvenement {
  brouillon,
  ouvert,
  complet,
  termine,
  annule,
}

class Evenement {
  String idEvenement;
  String nom;
  String description;
  TypeEvenement type;
  DateTime dateDebut;
  DateTime dateFin;
  String heureDebut;
  String lieu;
  int capacite;
  double prix;
  StatutEvenement statut;

  Evenement({
    required this.idEvenement,
    required this.nom,
    required this.description,
    required this.type,
    required this.dateDebut,
    required this.dateFin,
    required this.heureDebut,
    required this.lieu,
    required this.capacite,
    required this.prix,
    required this.statut,
  });

  // Les noms des colonnes sont ceux de la table "evenements" (Supabase).
  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'description': description,
      'type': type.name.toUpperCase(),
      'date_debut': dateDebut.toIso8601String().substring(0, 10),
      'date_fin': dateFin.toIso8601String().substring(0, 10),
      'heure_debut': heureDebut,
      'lieu': lieu,
      'capacite': capacite,
      'prix': prix,
      'statut': statut.name.toUpperCase(),
    };
  }

  factory Evenement.fromMap(Map<String, dynamic> data) {
    return Evenement(
      idEvenement: data['id'].toString(),
      nom: data['nom'] ?? '',
      description: data['description'] ?? '',
      type: TypeEvenement.values.firstWhere(
            (type) => type.name.toUpperCase() == data['type'],
        orElse: () => TypeEvenement.marathon,
      ),
      dateDebut: DateTime.parse(data['date_debut']),
      dateFin: DateTime.parse(data['date_fin']),
      heureDebut: data['heure_debut'] ?? '',
      lieu: data['lieu'] ?? '',
      capacite: int.parse(data['capacite'].toString()),
      prix: double.parse(data['prix'].toString()),
      statut: StatutEvenement.values.firstWhere(
            (statut) => statut.name.toUpperCase() == data['statut'],
        orElse: () => StatutEvenement.brouillon,
      ),
    );
  }
}
