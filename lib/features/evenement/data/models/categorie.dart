enum NiveauCategorie {
  debutant,
  intermediaire,
  avance,
  professionnel,
}

// Catalogue indépendant : une catégorie n'est plus liée
// à un événement (c'est l'événement qui en choisit une).
class Categorie {
  String idCategorie;
  String nom;
  int ageMin;
  int ageMax;
  NiveauCategorie niveau;

  Categorie({
    required this.idCategorie,
    required this.nom,
    required this.ageMin,
    required this.ageMax,
    required this.niveau,
  });

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'age_min': ageMin,
      'age_max': ageMax,
      'niveau': niveau.name.toUpperCase(),
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
    );
  }
}
