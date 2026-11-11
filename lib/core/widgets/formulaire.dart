import 'package:flutter/material.dart';

import 'package:coach_app/core/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Composants de formulaire partagés (écrans Programme et Séance).
// Fichier à placer dans : lib/core/widgets/formulaire.dart
// ---------------------------------------------------------------------------

// Style commun de tous les champs : fond gris très clair, coins arrondis,
// bordure violette/bleue au focus, bordure rouge en cas d'erreur.
InputDecoration decorationChamp(
    String libelle, {
      IconData? icone,
      String? aide,
      String? suffixe,
      Widget? action,
    }) {
  OutlineInputBorder bordure(Color couleur, double epaisseur) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: couleur, width: epaisseur),
    );
  }

  return InputDecoration(
    labelText: libelle,
    helperText: aide,
    suffixText: suffixe,
    prefixIcon:
    icone == null ? null : Icon(icone, color: AppCouleurs.principale),
    suffixIcon: action,
    filled: true,
    fillColor: const Color(0xFFF7F7FA),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    border: bordure(const Color(0xFFE0E0E8), 1),
    enabledBorder: bordure(const Color(0xFFE0E0E8), 1),
    focusedBorder: bordure(AppCouleurs.principale, 2),
    errorBorder: bordure(Colors.red.shade400, 1),
    focusedErrorBorder: bordure(Colors.red.shade400, 2),
  );
}

// Carte blanche avec une icône + un titre, qui regroupe un bloc de champs.
class CarteSection extends StatelessWidget {
  final String titre;
  final IconData icone;
  final List<Widget> enfants;

  const CarteSection({
    super.key,
    required this.titre,
    required this.icone,
    required this.enfants,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6E6EE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppCouleurs.principale.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icone, size: 20, color: AppCouleurs.principale),
              ),
              const SizedBox(width: 12),
              Text(
                titre,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppCouleurs.texte,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Column(
            spacing: 16,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: enfants,
          ),
        ],
      ),
    );
  }
}

// Choix unique présenté sous forme de puces (ChoiceChip) qui passent à la
// ligne automatiquement (Wrap) : remplace les gros boutons d'une GridView.
class ChoixPuces<T> extends StatelessWidget {
  final List<T> items;
  final bool Function(T) estChoisi;
  final String Function(T) libelle;
  final void Function(T) onChoisi;

  const ChoixPuces({
    super.key,
    required this.items,
    required this.estChoisi,
    required this.libelle,
    required this.onChoisi,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        bool choisi = estChoisi(item);

        return ChoiceChip(
          label: Text(libelle(item)),
          selected: choisi,
          onSelected: (_) => onChoisi(item),
          selectedColor: AppCouleurs.principale,
          backgroundColor: Colors.white,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            color: choisi ? Colors.white : AppCouleurs.texte,
          ),
          side: BorderSide(
            color: choisi ? AppCouleurs.principale : const Color(0xFFD5D5DF),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        );
      }).toList(),
    );
  }
}

// Petit encadré d'information (fond teinté + icône).
class NoteInfo extends StatelessWidget {
  final String texte;

  const NoteInfo({super.key, required this.texte});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppCouleurs.principale.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: AppCouleurs.principale),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texte,
              style: const TextStyle(
                fontSize: 13,
                color: AppCouleurs.texteSecondaire,
              ),
            ),
          ),
        ],
      ),
    );
  }
}