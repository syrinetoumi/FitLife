/// Convertit une date en texte 'aaaa-mm-jj' pour Supabase.
String dateSql(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';

class SuiviObjectif {
  final int? id;
  final String idAthlete;
  final int? idProgramme;
  final double valeurDepart;
  final double valeurCible;
  final String unite;
  final DateTime dateDebut;
  final DateTime dateLimite;
  final String statut; // EN_COURS, ATTEINT, ABANDONNE

  // Données jointes (lecture seulement)
  final String? nomProgramme;
  final String? objectifProgramme;
  final String? nomAthlete;

  SuiviObjectif({
    this.id,
    required this.idAthlete,
    this.idProgramme,
    required this.valeurDepart,
    required this.valeurCible,
    this.unite = 'kg',
    required this.dateDebut,
    required this.dateLimite,
    this.statut = 'EN_COURS',
    this.nomProgramme,
    this.objectifProgramme,
    this.nomAthlete,
  });

  factory SuiviObjectif.fromJson(Map<String, dynamic> json) {
    final programme = json['programme'] as Map<String, dynamic>?;
    final profil = json['profiles'] as Map<String, dynamic>?;
    String? nomAthlete;
    if (profil != null) {
      nomAthlete = '${profil['prenom'] ?? ''} ${profil['nom'] ?? ''}'.trim();
    }
    return SuiviObjectif(
      id: json['id_suivi'] as int?,
      idAthlete: json['id_athlete'] as String,
      idProgramme: json['id_programme'] as int?,
      valeurDepart: (json['valeur_depart'] as num).toDouble(),
      valeurCible: (json['valeur_cible'] as num).toDouble(),
      unite: json['unite'] as String? ?? 'kg',
      dateDebut: DateTime.parse(json['date_debut'] as String),
      dateLimite: DateTime.parse(json['date_limite'] as String),
      statut: json['statut'] as String? ?? 'EN_COURS',
      nomProgramme: programme?['nom'] as String?,
      objectifProgramme: programme?['objectif'] as String?,
      nomAthlete: nomAthlete,
    );
  }

  /// Pour l'insertion (id et statut gérés par la base).
  Map<String, dynamic> toJson() => {
    'id_athlete': idAthlete,
    'id_programme': idProgramme,
    'valeur_depart': valeurDepart,
    'valeur_cible': valeurCible,
    'unite': unite,
    'date_debut': dateSql(dateDebut),
    'date_limite': dateSql(dateLimite),
  };

  /// Vrai si l'objectif est de perdre (cible plus basse que le départ).
  bool get estUneBaisse => valeurCible < valeurDepart;
}