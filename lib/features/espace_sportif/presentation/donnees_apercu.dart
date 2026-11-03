import 'package:flutter/material.dart';

// Données locales de présentation, indépendantes des modèles Supabase.
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
  HoraireApercu(this.espace, this.jour, this.debut, this.fin);
  final int espace, jour;
  final int debut, fin;
}

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

  String get statutEffectif =>
      fin != null && jourLocal().isAfter(fin!) ? 'EXPIREE' : statut;
  bool get disponible =>
      statutEffectif == 'ACTIVE' && !jourLocal().isBefore(debut);
}

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
  String get statutEffectif =>
      statut != 'ANNULE' && jourLocal().isAfter(fin) ? 'EXPIRE' : statut;
}

const typesEspace = {
  'SALLE': 'Salle de sport',
  'CLUB_SPORTIF': 'Club sportif',
  'STADE': 'Stade',
  'TERRAIN': 'Terrain',
  'PARC': 'Parc',
  'CENTRE_SPORTIF': 'Centre sportif',
  'PISCINE': 'Piscine',
  'AUTRE': 'Autre',
};
const etatsEquipement = {
  'BON': 'Bon état',
  'ENDOMMAGE': 'Endommagé',
  'EN_MAINTENANCE': 'En maintenance',
  'HORS_SERVICE': 'Hors service',
};
const typesOffre = {
  'ABONNEMENT': 'Abonnement',
  'PACK': 'Pack',
  'SEANCE': 'Accès à la journée',
};
const jours = [
  'Lundi',
  'Mardi',
  'Mercredi',
  'Jeudi',
  'Vendredi',
  'Samedi',
  'Dimanche',
];

DateTime jourLocal() {
  // L'aperçu utilise la date locale. Le serveur fournira la date métier.
  final date = DateTime.now();
  return DateTime(date.year, date.month, date.day);
}

String dateTexte(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
String dateSaisie(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
DateTime? lireDateApercu(String texte) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(texte)) return null;
  final date = DateTime.tryParse(texte);
  return date != null && dateSaisie(date) == texte ? date : null;
}

int? lireMillimes(String texte) {
  final normalise = texte.trim().replaceAll(',', '.');
  if (!RegExp(r'^\d{1,9}(\.\d{1,3})?$').hasMatch(normalise)) return null;
  final parties = normalise.split('.');
  return int.parse(parties.first) * 1000 +
      (parties.length == 2 ? int.parse(parties[1].padRight(3, '0')) : 0);
}

String montantTexte(int millimes) =>
    '${millimes ~/ 1000},${(millimes % 1000).toString().padLeft(3, '0')}';
String heureTexte(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
int? lireHeure(String texte) {
  if (!RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(texte)) return null;
  final parties = texte.split(':');
  return int.parse(parties[0]) * 60 + int.parse(parties[1]);
}

IconData iconeEspace(String type) => switch (type) {
  'PISCINE' => Icons.pool_outlined,
  'PARC' => Icons.park_outlined,
  'TERRAIN' || 'STADE' => Icons.sports_soccer_outlined,
  _ => Icons.fitness_center,
};

class DonneesApercu extends ChangeNotifier {
  DonneesApercu() {
    final aujourdHui = jourLocal();
    espaces.addAll([
      EspaceApercu(
        id: 1,
        nom: 'Atlas Training Club',
        type: 'SALLE',
        adresse: 'Les Berges du Lac, Tunis',
        statut: 'ACTIF',
        description: 'Un espace lumineux pour progresser à votre rythme. Musculation, cardio et entraînement fonctionnel.',
        telephone: '+216 71 000 100',
        email: 'contact@example.com',
        latitude: 36.837,
        longitude: 10.246,
      ),
      EspaceApercu(
        id: 2,
        nom: 'Bassin Azur',
        type: 'PISCINE',
        adresse: 'La Marsa, Tunis',
        statut: 'INACTIF',
        description: 'Natation et préparation physique dans un cadre calme. Ouverture prochaine.',
        latitude: 36.878,
        longitude: 10.325,
      ),
      EspaceApercu(
        id: 3,
        nom: 'Terrain Horizon',
        type: 'TERRAIN',
        adresse: 'El Menzah, Tunis',
        statut: 'ACTIF',
        estGere: false,
        description: 'Un terrain pour vos entraînements et vos rendez-vous sportifs en équipe.',
      ),
    ]);
    equipements.addAll([
      EquipementApercu(4, 1, 'Haltères', 'Paires de 2 à 30 kg', 12, 'BON'),
      EquipementApercu(5, 1, 'Tapis de course', 'Zone cardio', 4, 'BON'),
      EquipementApercu(
        6,
        1,
        'Rameur',
        'Révision en cours',
        1,
        'EN_MAINTENANCE',
      ),
      EquipementApercu(7, 3, 'Ballons', '', 6, 'BON'),
    ]);
    for (var jour = 0; jour < 6; jour++) {
      horaires.add(HoraireApercu(1, jour, 7 * 60, 22 * 60));
      horaires.add(HoraireApercu(3, jour, 8 * 60, 20 * 60));
    }
    offres.addAll([
      OffreApercu(
        id: 8,
        espace: 1,
        nom: 'Essentiel',
        description: 'Accès aux espaces cardio et musculation pendant les horaires d’ouverture.',
        type: 'ABONNEMENT',
        millimes: 80000,
        duree: 30,
        debut: aujourdHui.subtract(const Duration(days: 30)),
        statut: 'ACTIVE',
      ),
      OffreApercu(
        id: 9,
        espace: 1,
        nom: 'Pass découverte',
        description: 'Une journée pour découvrir le club. Sans réservation de séance coach.',
        type: 'SEANCE',
        millimes: 15000,
        duree: 1,
        debut: aujourdHui,
        statut: 'ACTIVE',
      ),
      OffreApercu(
        id: 10,
        espace: 1,
        nom: 'Pack performance',
        description: 'Accès aux équipements fonctionnels pendant 60 jours. Sans compteur de visites.',
        type: 'PACK',
        millimes: 140000,
        duree: 60,
        debut: aujourdHui,
        statut: 'INACTIVE',
      ),
    ]);
    abonnements.addAll([
      AbonnementApercu(
        id: 11,
        offre: 8,
        athlete: 'Votre compte démo',
        estPersonnel: true,
        debut: aujourdHui.subtract(const Duration(days: 5)),
        fin: aujourdHui.add(const Duration(days: 24)),
        millimes: 80000,
      ),
      AbonnementApercu(
        id: 12,
        offre: 8,
        athlete: 'Amine · Démonstration',
        estPersonnel: false,
        debut: aujourdHui.subtract(const Duration(days: 10)),
        fin: aujourdHui.add(const Duration(days: 19)),
        millimes: 80000,
        statut: 'SUSPENDU',
      ),
    ]);
  }

  final espaces = <EspaceApercu>[];
  final equipements = <EquipementApercu>[];
  final horaires = <HoraireApercu>[];
  final offres = <OffreApercu>[];
  final abonnements = <AbonnementApercu>[];
  int _id = 20;
  int prochainId() => _id++;
  void actualiser() => notifyListeners();
  EspaceApercu espaceDe(OffreApercu offre) =>
      espaces.firstWhere((e) => e.id == offre.espace);
  OffreApercu offreDe(AbonnementApercu abonnement) =>
      offres.firstWhere((o) => o.id == abonnement.offre);
  bool dejaAbonne(OffreApercu offre) => abonnements.any(
    (a) =>
        a.estPersonnel &&
        a.offre == offre.id &&
        ['ACTIF', 'SUSPENDU'].contains(a.statutEffectif),
  );

  void souscrire(OffreApercu offre) {
    if (!offre.disponible ||
        espaceDe(offre).statut != 'ACTIF' ||
        dejaAbonne(offre)) {
      return;
    }
    final debut = jourLocal();
    abonnements.add(
      AbonnementApercu(
        id: prochainId(),
        offre: offre.id,
        athlete: 'Votre compte démo',
        estPersonnel: true,
        debut: debut,
        fin: debut.add(Duration(days: offre.duree - 1)),
        millimes: offre.millimes,
      ),
    );
    actualiser();
  }
}
