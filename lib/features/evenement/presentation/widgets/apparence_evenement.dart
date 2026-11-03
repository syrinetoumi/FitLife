import 'package:flutter/material.dart';

import '../../data/models/categorie.dart';
import '../../data/models/evenement.dart';

// ---------- Palettes communes de dégradés ----------

const List<List<Color>> palettes = [
  [Color(0xFF1D4ED8), Color(0xFF60A5FA)], // Bleu
  [Color(0xFF9A3412), Color(0xFFF97316)], // Orange
  [Color(0xFF166534), Color(0xFF4ADE80)], // Vert
  [Color(0xFF581C87), Color(0xFFA855F7)], // Violet
  [Color(0xFF0F766E), Color(0xFF14B8A6)], // Cyan / Teal
  [Color(0xFF7F1D1D), Color(0xFFEF4444)], // Rouge foncé
];

List<Color> couleursIndex(int index) {
  return palettes[index % palettes.length];
}

// ================================================================
// IMAGES LOCALES DANS : assets/images/evenement/ (TOUTES EN .JPG)
// ================================================================
// - marathon.jpg
// - competition.jpg
// - match.jpg
// - tournoi.jpg
// - gala.jpg
// - challenge.jpg
String imageType(TypeEvenement type) {
  return 'assets/images/evenement/${type.name.toLowerCase()}.jpg';
}

List<Color> couleursType(TypeEvenement type) {
  return couleursIndex(type.index);
}

IconData iconeType(TypeEvenement type) {
  if (type == TypeEvenement.marathon) {
    return Icons.directions_run;
  }
  if (type == TypeEvenement.match) {
    return Icons.sports_soccer;
  }
  return Icons.emoji_events;
}

// ---------- Catégories (selon le niveau) ----------

String imageNiveau(NiveauCategorie niveau) {
  return 'assets/images/categories/${niveau.name.toLowerCase()}.jpg';
}

List<Color> couleursNiveau(NiveauCategorie niveau) {
  return couleursIndex(niveau.index);
}

IconData iconeNiveau(NiveauCategorie niveau) {
  return Icons.signal_cellular_alt;
}

// ---------- Inscriptions et paiements ----------

List<Color> couleursInscription() {
  return const [Color(0xFF1E3A8A), Color(0xFF3B82F6)];
}

List<Color> couleursPaiement() {
  return const [Color(0xFF166534), Color(0xFF4ADE80)];
}

// ---------- Statuts (événement, inscription, paiement) ----------

Color couleurStatut(String statut) {
  String texte = statut.toLowerCase();

  if (texte.contains('annul') ||
      texte.contains('refus') ||
      texte.contains('chou') ||
      texte.contains('rejet')) {
    return Colors.red;
  }

  if (texte.contains('attente') || texte.contains('complet')) {
    return Colors.orange;
  }

  if (texte.contains('brouillon') || texte.contains('termin')) {
    return Colors.grey;
  }

  return Colors.green;
}

// Pastille colorée du statut
Widget pastilleStatut(String libelle) {
  Color couleur = couleurStatut(libelle);

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: couleur.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: couleur, width: 1.5),
    ),
    child: Text(
      libelle,
      style: TextStyle(
        color: couleur,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    ),
  );
}
