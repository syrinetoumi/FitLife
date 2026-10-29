import 'package:flutter/material.dart';

import 'package:coach_app/features/entrainement/data/models/enums.dart';

String libelleStatutSeance(StatutSeance statut) {
  switch (statut) {
    case StatutSeance.PLANIFIEE:
      return 'Planifiée';
    case StatutSeance.COMPLETE:
      return 'Complète';
    case StatutSeance.ANNULEE:
      return 'Annulée';
    case StatutSeance.TERMINEE:
      return 'Terminée';
  }
}

Color couleurStatutSeance(StatutSeance statut) {
  switch (statut) {
    case StatutSeance.PLANIFIEE:
      return Colors.green;
    case StatutSeance.COMPLETE:
      return Colors.orange;
    case StatutSeance.ANNULEE:
      return Colors.red;
    case StatutSeance.TERMINEE:
      return Colors.grey;
  }
}

String libelleTypeSeance(TypeSeance type) {
  if (type == TypeSeance.INDIVIDUELLE) {
    return 'Individuelle';
  }

  return 'Collective';
}

// Pastille colorée du statut.
Widget pastilleStatutSeance(StatutSeance statut) {
  Color couleur = couleurStatutSeance(statut);

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: couleur.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: couleur),
    ),
    child: Text(
      libelleStatutSeance(statut),
      style: TextStyle(color: couleur, fontWeight: FontWeight.bold),
    ),
  );
}