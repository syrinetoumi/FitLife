import '../data/models/dossier_nutritionnel.dart';

/// Service Métier 3 : Analyse de l'évolution du poids et estimation du temps restant.
class AnalyseEvolutionPoids {
  /// Analyse l'évolution du poids par rapport à l'objectif et estime les semaines restantes
  static Map<String, dynamic> analyser(DossierNutritionnel dossier) {
    final prog = dossier.progressionPourcentage;
    final restant = dossier.poidsRestantKg;

    // Estimation théorique du temps restant (sur une base saine de 0.5 kg de perte/gain par semaine)
    final semainesRestantes = restant > 0 ? (restant / 0.5).ceil() : 0;

    String appreciation;
    if (prog >= 100.0) {
      appreciation = 'Objectif atteint ! Félicitations !';
    } else if (prog >= 75.0) {
      appreciation = 'Dernière ligne droite, vous y êtes presque !';
    } else if (prog >= 40.0) {
      appreciation = 'Bonne dynamique en cours, poursuivez les efforts.';
    } else {
      appreciation = 'Phase initiale : régularité et patience.';
    }

    return {
      'progressionPourcentage': prog,
      'poidsRestantKg': restant,
      'semainesEstimees': semainesRestantes,
      'appreciation': appreciation,
    };
  }
}
