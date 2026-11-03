class Profil {
  final String id;
  final String nom;
  final String prenom;
  final String role;
  final String telephone;
  final String? photo;
  final bool actif;

  Profil({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.role,
    required this.telephone,
    this.photo,
    required this.actif,
  });

  String get nomComplet {
    String complet = '$prenom $nom'.trim();
    if (complet.isEmpty) {
      return 'Utilisateur sans nom';
    }
    return complet;
  }

  factory Profil.fromMap(Map<String, dynamic> map) {
    return Profil(
      id: map['id']?.toString() ?? '',
      nom: map['nom']?.toString() ?? '',
      prenom: map['prenom']?.toString() ?? '',
      role: map['role']?.toString().toUpperCase() ?? 'ATHLETE',
      telephone: map['telephone']?.toString() ?? '',
      photo: map['photo']?.toString(),
      // Si la colonne actif est nulle ou absente, le compte est actif par défaut
      actif: map['actif'] == null ? true : (map['actif'] as bool),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'role': role,
      'telephone': telephone,
      'photo': photo,
      'actif': actif,
    };
  }
}
