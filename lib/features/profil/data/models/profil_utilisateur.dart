/// Modèle représentant un utilisateur dans la table `profiles` de Supabase.
class ProfilUtilisateur {
  final String id;
  final String? nom;
  final String? prenom;
  final String role; // 'ATHLETE', 'COACH', 'NUTRITIONNISTE', 'GESTIONNAIRE_ESPACE'
  final String? telephone;
  final String? photo;
  final DateTime? dateNaissance;
  final DateTime? dateCreation;
  final bool actif;
  final String? genre; // 'HOMME', 'FEMME'
  final String? email; // Provient de auth.users

  const ProfilUtilisateur({
    required this.id,
    this.nom,
    this.prenom,
    this.role = 'ATHLETE',
    this.telephone,
    this.photo,
    this.dateNaissance,
    this.dateCreation,
    this.actif = true,
    this.genre,
    this.email,
  });

  /// Nom complet affichable
  String get nomComplet {
    final p = (prenom ?? '').trim();
    final n = (nom ?? '').trim();
    if (p.isEmpty && n.isEmpty) {
      return email ?? 'Utilisateur FitLife';
    }
    return '$p $n'.trim();
  }

  /// Initiales pour l'avatar (ex: "ST" pour "Syrine Toumi")
  String get initiales {
    final p = (prenom ?? '').trim();
    final n = (nom ?? '').trim();
    String res = '';
    if (p.isNotEmpty) res += p[0].toUpperCase();
    if (n.isNotEmpty) res += n[0].toUpperCase();
    if (res.isEmpty && email != null && email!.isNotEmpty) {
      res = email![0].toUpperCase();
    }
    return res.isEmpty ? 'U' : res;
  }

  /// Libellé lisible du rôle
  String get roleLibelle {
    switch (role.toUpperCase()) {
      case 'ATHLETE':
        return 'Athlète';
      case 'COACH':
        return 'Coach';
      case 'NUTRITIONNISTE':
        return 'Nutritionniste';
      case 'GESTIONNAIRE_ESPACE':
        return 'Gestionnaire d’espace';
      default:
        return role;
    }
  }

  /// Libellé lisible du genre
  String get genreLibelle {
    if (genre == null) return 'Non renseigné';
    switch (genre!.toUpperCase()) {
      case 'HOMME':
        return 'Homme';
      case 'FEMME':
        return 'Femme';
      default:
        return genre!;
    }
  }

  /// Calcul de l'âge
  int? get age {
    if (dateNaissance == null) return null;
    final now = DateTime.now();
    int age = now.year - dateNaissance!.year;
    if (now.month < dateNaissance!.month ||
        (now.month == dateNaissance!.month && now.day < dateNaissance!.day)) {
      age--;
    }
    return age;
  }

  /// Date de naissance formatée (JJ/MM/AAAA)
  String get dateNaissanceFormatee {
    if (dateNaissance == null) return 'Non renseignée';
    final j = dateNaissance!.day.toString().padLeft(2, '0');
    final m = dateNaissance!.month.toString().padLeft(2, '0');
    return '$j/$m/${dateNaissance!.year}';
  }

  /// Date de création formatée (JJ/MM/AAAA)
  String get dateCreationFormatee {
    if (dateCreation == null) return 'Non renseignée';
    final j = dateCreation!.day.toString().padLeft(2, '0');
    final m = dateCreation!.month.toString().padLeft(2, '0');
    return '$j/$m/${dateCreation!.year}';
  }

  /// Conversion Map Supabase -> Modèle
  factory ProfilUtilisateur.fromMap(Map<String, dynamic> map, {String? email}) {
    DateTime? parserDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    return ProfilUtilisateur(
      id: map['id']?.toString() ?? '',
      nom: map['nom'] as String?,
      prenom: map['prenom'] as String?,
      role: map['role'] as String? ?? 'ATHLETE',
      telephone: map['telephone'] as String?,
      photo: map['photo'] as String?,
      dateNaissance: parserDate(map['date_naissance']),
      dateCreation: parserDate(map['date_creation']),
      actif: map['actif'] as bool? ?? true,
      genre: map['genre'] as String?,
      email: email ?? map['email'] as String?,
    );
  }

  /// Conversion Modèle -> Map Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'role': role,
      'telephone': telephone,
      'photo': photo,
      'date_naissance': dateNaissance != null
          ? '${dateNaissance!.year}-${dateNaissance!.month.toString().padLeft(2, '0')}-${dateNaissance!.day.toString().padLeft(2, '0')}'
          : null,
      'actif': actif,
      'genre': genre,
    };
  }

  /// Copie avec modification
  ProfilUtilisateur copyWith({
    String? id,
    String? nom,
    String? prenom,
    String? role,
    String? telephone,
    String? photo,
    DateTime? dateNaissance,
    DateTime? dateCreation,
    bool? actif,
    String? genre,
    String? email,
  }) {
    return ProfilUtilisateur(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      role: role ?? this.role,
      telephone: telephone ?? this.telephone,
      photo: photo ?? this.photo,
      dateNaissance: dateNaissance ?? this.dateNaissance,
      dateCreation: dateCreation ?? this.dateCreation,
      actif: actif ?? this.actif,
      genre: genre ?? this.genre,
      email: email ?? this.email,
    );
  }
}
