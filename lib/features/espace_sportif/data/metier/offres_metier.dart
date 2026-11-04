import '../models/modeles_espaces.dart';
import 'valeurs_metier.dart';

// La période de vente est distincte de la durée de l’abonnement acheté.
extension ReglesOffre on OffreApercu {
  String get statutEffectif =>
      fin != null && jourLocal().isAfter(fin!) ? 'EXPIREE' : statut;
  bool get disponible =>
      statutEffectif == 'ACTIVE' && !jourLocal().isBefore(debut);
}

String? validerPrixOffre(String? valeur) => lireMillimes(valeur ?? '') == null
    ? 'Prix positif ou nul, avec 3 décimales maximum.'
    : null;

// Une offre SEANCE correspond à un accès d’un jour, pas à une réservation avec un coach.
String? validerDureeOffre(String? valeur, String type) {
  final jours = int.tryParse(valeur ?? '');
  if (jours == null || jours < 1 || jours > 36500) {
    return 'Durée attendue entre 1 et 36 500 jours.';
  }
  if (type == 'SEANCE' && jours != 1) {
    return 'Un accès à la journée dure exactement 1 jour.';
  }
  return null;
}

// La fin des ventes est facultative et inclut le dernier jour autorisé à souscrire.
String? validerFinVentes(String? valeur, String debut) {
  if (valeur == null || valeur.isEmpty) return null;
  final date = lireDateApercu(valeur), premiere = lireDateApercu(debut);
  return date == null || premiere == null || date.isBefore(premiere)
      ? 'La fin doit être une date valide après ou égale au début.'
      : null;
}
