import 'package:flutter/material.dart';

class AppCouleurs {
  static const Color principale = Color(0xFF3742B5); // bleu indigo
  static const Color accent = Color(0xFF6BF0A0); // vert menthe
  static const Color fond = Color(0xFFF5F5F5);
  static const Color texte = Color(0xFF1A1A1A);
  static const Color texteSecondaire = Color(0xFF666666);
  static const Color erreur = Color(0xFFD32F2F);
}

const String policeTitre = 'BarlowCondensed';

// Titres : condensé, gras, italique (mettre le texte en majuscules).
const TextStyle styleTitre = TextStyle(
  fontFamily: policeTitre,
  fontWeight: FontWeight.w700,
  fontStyle: FontStyle.italic,
  color: AppCouleurs.texte,
);

ThemeData construireTheme() {
  const carre = RoundedRectangleBorder(borderRadius: BorderRadius.zero);

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppCouleurs.principale,
      primary: AppCouleurs.principale,
      secondary: AppCouleurs.accent,
      error: AppCouleurs.erreur,
    ),
    scaffoldBackgroundColor: AppCouleurs.fond,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppCouleurs.texte,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: policeTitre,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        fontStyle: FontStyle.italic,
        color: AppCouleurs.texte,
      ),
    ),
    // Boutons rectangulaires, sans largeur forcée (ils restent utilisables
    // dans un Row, comme dans les écrans de ton collègue).
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppCouleurs.principale,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 48),
        shape: carre,
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppCouleurs.principale),
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 1,
      shape: carre,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.zero),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppCouleurs.principale, width: 2),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppCouleurs.principale,
      unselectedItemColor: AppCouleurs.texte,
      type: BottomNavigationBarType.fixed,
    ),
  );
}