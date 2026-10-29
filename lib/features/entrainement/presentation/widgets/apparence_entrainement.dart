import 'package:flutter/material.dart';

import 'package:coach_app/features/entrainement/data/models/enums.dart';

// ---------- Programmes (selon l'objectif) ----------

// Ex. assets/images/programmes/perte_poids.jpg
String imageObjectif(ObjectifProgramme objectif) {
  return 'assets/images/programmes/${objectif.name.toLowerCase()}.jpg';
}

List<Color> couleursObjectif(ObjectifProgramme objectif) {
  switch (objectif) {
    case ObjectifProgramme.PERTE_POIDS:
      return const [Color(0xFF0F766E), Color(0xFF14B8A6)];
    case ObjectifProgramme.PRISE_MASSE:
      return const [Color(0xFF9A3412), Color(0xFFF97316)];
    case ObjectifProgramme.FORCE:
      return const [Color(0xFF7F1D1D), Color(0xFFEF4444)];
    case ObjectifProgramme.ENDURANCE:
      return const [Color(0xFF1D4ED8), Color(0xFF60A5FA)];
    case ObjectifProgramme.REMISE_EN_FORME:
      return const [Color(0xFF166534), Color(0xFF4ADE80)];
    case ObjectifProgramme.PERFORMANCE:
      return const [Color(0xFF581C87), Color(0xFFA855F7)];
  }
}

IconData iconeObjectif(ObjectifProgramme objectif) {
  switch (objectif) {
    case ObjectifProgramme.PERTE_POIDS:
      return Icons.monitor_weight;
    case ObjectifProgramme.PRISE_MASSE:
      return Icons.fitness_center;
    case ObjectifProgramme.FORCE:
      return Icons.bolt;
    case ObjectifProgramme.ENDURANCE:
      return Icons.directions_run;
    case ObjectifProgramme.REMISE_EN_FORME:
      return Icons.self_improvement;
    case ObjectifProgramme.PERFORMANCE:
      return Icons.emoji_events;
  }
}

// ---------- Séances (selon le type) ----------

// Ex. assets/images/seances/individuelle.jpg
String imageType(TypeSeance type) {
  return 'assets/images/seances/${type.name.toLowerCase()}.jpg';
}

List<Color> couleursType(TypeSeance type) {
  if (type == TypeSeance.INDIVIDUELLE) {
    return const [Color(0xFF1E3A8A), Color(0xFF3B82F6)];
  }

  return const [Color(0xFF4C1D95), Color(0xFF8B5CF6)];
}

IconData iconeType(TypeSeance type) {
  if (type == TypeSeance.INDIVIDUELLE) {
    return Icons.person;
  }

  return Icons.groups;
}