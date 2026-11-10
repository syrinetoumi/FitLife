import '../data/models/dossier_nutritionnel.dart';
import '../data/models/enums_nutrition.dart';
import '../data/models/programme_nutritionnel.dart';

/// Résumé du suivi combiné entre l'entraînement et la nutrition (Métier 4)
class BilanSuiviCombine {
  final String objectifTitre;
  final double progressionPourcentage;
  final double poidsInitialKg;
  final double poidsActuelKg;
  final double poidsCibleKg;
  final double poidsEcartKg;
  final String roleCoachApport;
  final String roleNutritionnisteApport;
  final String statutCoordination;
  final String conseilSynthese;

  const BilanSuiviCombine({
    required this.objectifTitre,
    required this.progressionPourcentage,
    required this.poidsInitialKg,
    required this.poidsActuelKg,
    required this.poidsCibleKg,
    required this.poidsEcartKg,
    required this.roleCoachApport,
    required this.roleNutritionnisteApport,
    required this.statutCoordination,
    required this.conseilSynthese,
  });
}

/// Service Métier 4 : Suivi combiné entraînement + nutrition autour d'un objectif commun
class SuiviCombineSportNutrition {
  /// Calcule la synergie et le bilan de coordination sport & nutrition
  static BilanSuiviCombine calculerBilan({
    required DossierNutritionnel dossier,
    ProgrammeNutritionnel? programmeActif,
    String? entrainementResume,
  }) {
    // L'objectif effectif priorise celui du programme actif en cours s'il existe
    final objectifEffectif = programmeActif?.objectif ?? dossier.objectif;
    final progPct = dossier.progressionPourcentage;
    final deltaKg = dossier.poidsRestantKg;

    String coachAction;
    String nutriAction;
    String coordination;
    String conseil;

    switch (objectifEffectif) {
      case ObjectifNutrition.PERTE_POIDS:
        coachAction = entrainementResume ?? 'Programme Cardio HIIT + Musculation métabolique';
        nutriAction = programmeActif != null
            ? 'Plan alimentaire : ${programmeActif.caloriesCible} kcal/j (${programmeActif.proteinesCibleG}g protéines)'
            : 'Déficit calorique contrôlé & hydratation';
        coordination = progPct >= 50 ? 'Synergie optimale' : 'En phase d\'adaptation';
        conseil = 'Le cardio optimise le déficit calorique tandis que les protéines préservent votre masse musculaire.';
        break;

      case ObjectifNutrition.PRISE_MASSE:
        coachAction = entrainementResume ?? 'Musculation en surcharge progressive (Hypertrophie)';
        nutriAction = programmeActif != null
            ? 'Plan alimentaire : ${programmeActif.caloriesCible} kcal/j avec surplus calorique (${programmeActif.proteinesCibleG}g protéines)'
            : 'Surplus calorique & synthèse protéique';
        coordination = 'Synergie anabolique';
        conseil = 'L\'entraînement stimule la croissance musculaire et l\'apport nutritionnel fournit les briques de construction.';
        break;

      case ObjectifNutrition.PERFORMANCE:
        coachAction = entrainementResume ?? 'Séances d\'endurance et de puissance ciblées';
        nutriAction = programmeActif != null
            ? 'Plan glucidique ciblé : ${programmeActif.glucidesCibleG}g glucides pour recharger le glycogène'
            : 'Timing précis des glucides avant/après entraînement';
        coordination = 'Optimisation énergétique';
        conseil = 'Coordination directe entre les séances intenses du coach et les repas énergétiques du nutritionniste.';
        break;

      case ObjectifNutrition.MAINTIEN:
        coachAction = entrainementResume ?? 'Entretien musculaire et renforcement global';
        nutriAction = programmeActif != null
            ? 'Balance énergétique équilibrée (${programmeActif.caloriesCible} kcal/j)'
            : 'Régime normocalorique stabilisateur';
        coordination = 'Équilibre parfait';
        conseil = 'Maintien durable de la composition corporelle et de la vitalité.';
        break;
    }

    return BilanSuiviCombine(
      objectifTitre: 'Objectif : ${formatEnumNutrition(objectifEffectif)} (${deltaKg.toStringAsFixed(1)} kg)',
      progressionPourcentage: progPct,
      poidsInitialKg: dossier.poidsInitial,
      poidsActuelKg: dossier.poidsActuel,
      poidsCibleKg: dossier.poidsCible,
      poidsEcartKg: deltaKg,
      roleCoachApport: coachAction,
      roleNutritionnisteApport: nutriAction,
      statutCoordination: coordination,
      conseilSynthese: conseil,
    );
  }
}
