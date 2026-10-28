import 'package:flutter/material.dart';
import 'package:coach_app/features/entrainement/data/services/calcul_progression.dart';

String libelleStatutProgression(StatutProgression statut) {
  switch (statut) {
    case StatutProgression.atteint:
      return 'Objectif atteint';
    case StatutProgression.enAvance:
      return 'En avance';
    case StatutProgression.dansLesTemps:
      return 'Dans les temps';
    case StatutProgression.enRetard:
      return 'En retard';
    case StatutProgression.sansMesure:
      return 'Aucune mesure';
  }
}

Color couleurStatutProgression(StatutProgression statut) {
  switch (statut) {
    case StatutProgression.atteint:
      return Colors.teal;
    case StatutProgression.enAvance:
      return Colors.green;
    case StatutProgression.dansLesTemps:
      return Colors.orange;
    case StatutProgression.enRetard:
      return Colors.red;
    case StatutProgression.sansMesure:
      return Colors.grey;
  }
}
// Affiche 80 au lieu de 80.0, et 72.5 tel quel.
String formaterValeur(double valeur) {
  if (valeur == valeur.roundToDouble()) {
    return valeur.toStringAsFixed(0);
  }
  return valeur.toStringAsFixed(1);
}

// Enlève le mot "Exception:" devant un message d'erreur.
String messageErreur(Object erreur) {
  return erreur.toString().replaceFirst('Exception: ', '');
}

// Petite étiquette colorée du statut.
Widget pastilleProgression(StatutProgression statut) {
  final couleur = couleurStatutProgression(statut);

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: couleur.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      libelleStatutProgression(statut),
      style: TextStyle(
        color: couleur,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    ),
  );
}