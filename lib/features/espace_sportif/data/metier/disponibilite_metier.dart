import '../models/modeles_espaces.dart';
import 'valeurs_metier.dart';

// Un créneau doit tenir entièrement dans une seule plage d’ouverture.
List<String> verifierDisponibilite({
  required EspaceApercu espace,
  required Iterable<HoraireApercu> horaires,
  required Iterable<EquipementApercu> equipements,
  required DateTime date,
  required int debut,
  required int fin,
  required Map<int, int> exigences,
}) {
  final resultat = <String>[];
  if (espace.statut != 'ACTIF') resultat.add('L’espace n’est pas actif.');
  if (!horaires.any(
    (h) =>
        h.espace == espace.id &&
        h.jour == date.weekday - 1 &&
        debut >= h.debut &&
        fin <= h.fin,
  )) {
    resultat.add(
      'Le créneau ne tient pas entièrement dans une plage d’ouverture.',
    );
  }
  // Un matériel en maintenance ne satisfait jamais une demande, même si sa quantité est suffisante.
  for (final exigence in exigences.entries) {
    final e = equipements.firstWhere((e) => e.id == exigence.key);
    if (e.etat != 'BON' || e.quantite < exigence.value) {
      resultat.add('${e.nom} : état ou quantité incompatible.');
    }
  }
  return resultat;
}

// Deux créneaux adjacents sont permis. Pendant une modification, le créneau lui-même est exclu du contrôle.
String? validerFermeture({
  required String ouverture,
  required String? fermeture,
  required Iterable<HoraireApercu> horaires,
  required int espace,
  required int jour,
  HoraireApercu? ancien,
}) {
  final d = lireHeure(ouverture), f = lireHeure(fermeture ?? '');
  if (f == null) return 'Heure invalide (HH:mm).';
  if (d == null || f <= d) {
    return 'La fermeture doit suivre l’ouverture le même jour.';
  }
  if (horaires.any(
    (h) =>
        h != ancien &&
        h.espace == espace &&
        h.jour == jour &&
        d < h.fin &&
        f > h.debut,
  )) {
    return 'Ce créneau chevauche un horaire existant.';
  }
  return null;
}
