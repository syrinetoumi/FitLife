enum NiveauCategorie {
  debutant,
  intermediaire,
  avance,
  professionnel,
}

class Categorie {
  String idCategorie;
  String nom;
  int ageMin;
  int ageMax;
  NiveauCategorie niveau;
  String idEvenement;

  Categorie({
    required this.idCategorie,
    required this.nom,
    required this.ageMin,
    required this.ageMax,
    required this.niveau,
    required this.idEvenement,
  });

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'age_min': ageMin,
      'age_max': ageMax,
      'niveau': niveau.name.toUpperCase(),
      'id_evenement': idEvenement,
    };
  }

  factory Categorie.fromMap(Map<String, dynamic> data) {
    return Categorie(
      idCategorie: data['id'].toString(),
      nom: data['nom'] ?? '',
      ageMin: int.parse(data['age_min'].toString()),
      ageMax: int.parse(data['age_max'].toString()),
      niveau: NiveauCategorie.values.firstWhere(
            (niveau) => niveau.name.toUpperCase() == data['niveau'],
        orElse: () => NiveauCategorie.debutant,
      ),
      idEvenement: data['id_evenement'].toString(),
    );
  }
}
