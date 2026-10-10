// ignore_for_file: constant_identifier_names

enum ObjectifProgramme {
  PERTE_POIDS,
  PRISE_MASSE,
  FORCE,
  ENDURANCE,
  REMISE_EN_FORME,
  PERFORMANCE,
}

enum Niveau { DEBUTANT, INTERMEDIAIRE, AVANCE }

enum TypeSeance { INDIVIDUELLE, COLLECTIVE }

enum StatutSeance { PLANIFIEE, COMPLETE, ANNULEE, TERMINEE }

enum StatutReservation { CONFIRMEE, ANNULEE }

// Affichage : PERTE_POIDS devient "PERTE POIDS".
String enTexte(Enum valeur) => valeur.name.replaceAll('_', ' ');