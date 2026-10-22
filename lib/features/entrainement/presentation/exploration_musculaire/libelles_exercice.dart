import 'package:flutter/material.dart';

// Textes d'affichage en français pour les valeurs renvoyées par ExerciseDB.
// Si une valeur est inconnue, on affiche l'originale avec une majuscule.

String _majuscule(String texte) {
  if (texte.isEmpty) {
    return texte;
  }

  return texte[0].toUpperCase() + texte.substring(1);
}

String libelleMuscle(String valeur) {
  const Map<String, String> noms = {
    'abductors': 'Abducteurs',
    'abs': 'Abdominaux',
    'adductors': 'Adducteurs',
    'biceps': 'Biceps',
    'calves': 'Mollets',
    'cardiovascular system': 'Système cardiovasculaire',
    'delts': 'Épaules',
    'forearms': 'Avant-bras',
    'glutes': 'Fessiers',
    'hamstrings': 'Ischio-jambiers',
    'lats': 'Dorsaux',
    'levator scapulae': 'Cou',
    'pectorals': 'Pectoraux',
    'quads': 'Quadriceps',
    'serratus anterior': 'Dentelé antérieur',
    'spine': 'Bas du dos',
    'traps': 'Trapèzes',
    'triceps': 'Triceps',
    'upper back': 'Haut du dos',
    'shoulders': 'Épaules',
    'chest': 'Poitrine',
    'hip flexors': 'Fléchisseurs de hanche',
  };

  return noms[valeur] ?? _majuscule(valeur);
}

String libelleEquipement(String valeur) {
  const Map<String, String> noms = {
    'barbell': 'Barre',
    'dumbbell': 'Haltères',
    'body weight': 'Poids du corps',
    'cable': 'Poulie',
    'leverage machine': 'Machine',
    'smith machine': 'Machine Smith',
    'band': 'Bande élastique',
    'resistance band': 'Bande de résistance',
    'kettlebell': 'Kettlebell',
    'ez barbell': 'Barre EZ',
    'olympic barbell': 'Barre olympique',
    'trap bar': 'Barre hexagonale',
    'stability ball': 'Ballon de stabilité',
    'medicine ball': 'Médecine-ball',
    'bosu ball': 'Bosu',
    'roller': 'Rouleau',
    'rope': 'Corde',
    'assisted': 'Assisté',
    'weighted': 'Lesté',
    'wheel roller': 'Roue abdominale',
  };

  return noms[valeur] ?? _majuscule(valeur);
}

String libellePartieCorps(String valeur) {
  const Map<String, String> noms = {
    'upper arms': 'Bras',
    'lower arms': 'Avant-bras',
    'upper legs': 'Cuisses',
    'lower legs': 'Jambes',
    'waist': 'Taille',
    'chest': 'Poitrine',
    'back': 'Dos',
    'shoulders': 'Épaules',
    'neck': 'Cou',
    'cardio': 'Cardio',
  };

  return noms[valeur] ?? _majuscule(valeur);
}

String libelleDifficulte(String valeur) {
  const Map<String, String> noms = {
    'beginner': 'Débutant',
    'intermediate': 'Intermédiaire',
    'advanced': 'Avancé',
  };

  return noms[valeur] ?? _majuscule(valeur);
}

Color couleurDifficulte(String valeur) {
  if (valeur == 'beginner') {
    return Colors.green;
  }

  if (valeur == 'intermediate') {
    return Colors.orange;
  }

  if (valeur == 'advanced') {
    return Colors.red;
  }

  return Colors.grey;
}

String libelleCategorie(String valeur) {
  const Map<String, String> noms = {
    'strength': 'Force',
    'cardio': 'Cardio',
    'mobility': 'Mobilité',
    'balance': 'Équilibre',
    'stretching': 'Étirement',
    'plyometrics': 'Pliométrie',
    'rehabilitation': 'Rééducation',
  };

  return noms[valeur] ?? _majuscule(valeur);
}

// Met la première lettre du nom de l'exercice en majuscule.
String titreExercice(String nom) {
  return _majuscule(nom);
}