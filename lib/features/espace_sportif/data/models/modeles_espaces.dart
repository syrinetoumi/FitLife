// Modèles partagés par les interfaces et le dépôt des espaces sportifs.
class EspaceApercu {
  EspaceApercu({
    required this.id,
    required this.nom,
    required this.type,
    required this.adresse,
    required this.description,
    this.statut = 'INACTIF',
    this.telephone = '',
    this.email = '',
    this.siteWeb = '',
    this.latitude,
    this.longitude,
    this.estGere = true,
  });

  final int id;
  String nom, type, adresse, description, statut, telephone, email, siteWeb;
  double? latitude, longitude;
  final bool estGere;
}

class EquipementApercu {
  EquipementApercu(
    this.id,
    this.espace,
    this.nom,
    this.description,
    this.quantite,
    this.etat,
  );
  final int id, espace;
  String nom, description, etat;
  int quantite;
}

class HoraireApercu {
  HoraireApercu(this.espace, this.jour, this.debut, this.fin, {this.id});
  final int? id;
  final int espace, jour;
  final int debut, fin;
}

// Les règles de disponibilité et d’expiration sont définies dans data/metier, séparément des données.
class OffreApercu {
  OffreApercu({
    required this.id,
    required this.espace,
    required this.nom,
    required this.description,
    required this.type,
    required this.millimes,
    required this.duree,
    required this.debut,
    this.fin,
    this.statut = 'INACTIVE',
  });
  final int id, espace;
  String nom, description, type, statut;
  int millimes, duree;
  DateTime debut;
  DateTime? fin;
}

// Le montant et les dates représentent l’état à la souscription ; modifier l’offre ne les recalcule pas.
class AbonnementApercu {
  AbonnementApercu({
    required this.id,
    required this.offre,
    required this.athlete,
    required this.estPersonnel,
    required this.debut,
    required this.fin,
    required this.millimes,
    this.statut = 'ACTIF',
  });
  final int id, offre, millimes;
  final String athlete;
  final bool estPersonnel;
  final DateTime debut, fin;
  String statut;
}
