import 'package:flutter/material.dart';

import '../data/models/modeles_espaces.dart';
import '../data/metier/valeurs_metier.dart';
import '../data/metier/abonnements_metier.dart';

export '../data/models/modeles_espaces.dart';
export '../data/metier/valeurs_metier.dart';
export '../data/metier/offres_metier.dart';
export '../data/metier/abonnements_metier.dart';

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

IconData iconeEspace(String type) => switch (type) {
  'PISCINE' => Icons.pool_outlined,
  'PARC' => Icons.park_outlined,
  'TERRAIN' || 'STADE' => Icons.sports_soccer_outlined,
  _ => Icons.fitness_center,
};

class DonneesApercu extends ChangeNotifier {
  DonneesApercu({bool exemple = true}) {
    if (!exemple) return;
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
        athlete: 'Votre compte',
        estPersonnel: true,
        debut: aujourdHui.subtract(const Duration(days: 5)),
        fin: aujourdHui.add(const Duration(days: 24)),
        millimes: 80000,
      ),
      AbonnementApercu(
        id: 12,
        offre: 8,
        athlete: 'Amine',
        estPersonnel: false,
        debut: aujourdHui.subtract(const Duration(days: 10)),
        fin: aujourdHui.add(const Duration(days: 19)),
        millimes: 80000,
        statut: 'SUSPENDU',
      ),
    ]);
  }

  bool get demonstration => true;
  String get role => 'GESTIONNAIRE_ESPACE';
  bool get peutSouscrire => demonstration || role == 'ATHLETE';
  bool get peutCreer => demonstration || role == 'GESTIONNAIRE_ESPACE';

  Future<void> enregistrerEspace(
    EspaceApercu valeur, {
    bool nouveau = false,
  }) async {
    espaces.removeWhere((e) => e.id == valeur.id);
    espaces.add(valeur);
    actualiser();
  }

  Future<void> enregistrerEquipement(
    EquipementApercu valeur, {
    bool nouveau = false,
  }) async {
    equipements.removeWhere((e) => e.id == valeur.id);
    equipements.add(valeur);
    actualiser();
  }

  Future<void> enregistrerHoraire(
    HoraireApercu valeur, {
    HoraireApercu? ancien,
  }) async {
    horaires.remove(ancien);
    horaires.add(valeur);
    actualiser();
  }

  Future<void> supprimerHoraire(HoraireApercu valeur) async {
    horaires.remove(valeur);
    actualiser();
  }

  Future<void> enregistrerOffre(
    OffreApercu valeur, {
    bool nouveau = false,
  }) async {
    offres.removeWhere((o) => o.id == valeur.id);
    offres.add(valeur);
    actualiser();
  }

  Future<void> changerStatutEspace(EspaceApercu valeur, String statut) async {
    valeur.statut = statut;
    actualiser();
  }

  Future<void> changerStatutAbonnement(
    AbonnementApercu valeur,
    String statut,
  ) async {
    valeur.statut = statut;
    actualiser();
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
  bool dejaAbonne(OffreApercu offre) =>
      abonnementPersonnelExistant(abonnements, offre.id);

  Future<void> souscrire(OffreApercu offre) async {
    if (!souscriptionPossible(offre, espaceDe(offre), abonnements)) return;
    abonnements.add(creerAbonnementDemonstration(offre, prochainId()));
    actualiser();
  }
}
