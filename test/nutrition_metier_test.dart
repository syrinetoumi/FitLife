import 'package:flutter_test/flutter_test.dart';
import 'package:coach_app/features/nutrition/data/models/consultation.dart';
import 'package:coach_app/features/nutrition/data/models/dossier_nutritionnel.dart';
import 'package:coach_app/features/nutrition/data/models/enums_nutrition.dart';
import 'package:coach_app/features/nutrition/data/models/programme_nutritionnel.dart';
import 'package:coach_app/features/nutrition/metier/gestion_consultation.dart';
import 'package:coach_app/features/nutrition/metier/nutrition_calculator.dart';
import 'package:coach_app/features/nutrition/metier/analyse_evolution_poids.dart';
import 'package:coach_app/features/nutrition/metier/suivi_combine_sport_nutrition.dart';

void main() {
  group('Tests des 4 Métiers du Module Nutrition', () {
    // -------------------------------------------------------------
    // Métier 1 : Gestion des Consultations
    // -------------------------------------------------------------
    test('Métier 1 - GestionConsultation validation et machine à états', () {
      final consultationDemandee = Consultation(
        idConsultation: 'c1',
        idAthlete: 'ath-1',
        idNutritionniste: 'nut-1',
        dateConsultation: DateTime.now().add(const Duration(days: 2)),
        heureConsultation: '14:30',
        motif: 'Bilan nutritionnel complet pour sèche',
        statut: StatutConsultation.DEMANDEE,
      );

      // Transitions d'état
      expect(GestionConsultation.peutConfirmer(consultationDemandee), true);
      expect(GestionConsultation.peutAnnuler(consultationDemandee), true);
      expect(GestionConsultation.peutCloturer(consultationDemandee), false);

      // Validations
      expect(GestionConsultation.validerMotif('OK'), isNotNull); // Trop court
      expect(GestionConsultation.validerMotif('Suivi régulier perte de poids'), isNull);

      final datePassee = DateTime.now().subtract(const Duration(days: 5));
      expect(GestionConsultation.validerDateEtHeure(datePassee, '10:00'), isNotNull);

      final dateFutur = DateTime.now().add(const Duration(days: 5));
      expect(GestionConsultation.validerDateEtHeure(dateFutur, '10:00'), isNull);
    });

    // -------------------------------------------------------------
    // Métier 2 : Calculs Nutritionnels (BMR, calories, macros)
    // -------------------------------------------------------------
    test('Métier 2 - NutritionCalculator BMR et répartition des macronutriments', () {
      // Homme, 80kg, 180cm, 25 ans
      // BMR = (10 * 80) + (6.25 * 180) - (5 * 25) + 5 = 800 + 1125 - 125 + 5 = 1805
      final bmrHomme = NutritionCalculator.calculerBmr(
        poidsKg: 80,
        tailleCm: 180,
        age: 25,
        estHomme: true,
      );
      expect(bmrHomme, 1805.0);

      // TDEE = 1805 * 1.4 = 2527. En PERTE_POIDS : 2527 - 450 = 2077 kcal
      final caloriesPerte = NutritionCalculator.calculerCaloriesCible(
        bmr: bmrHomme,
        objectif: ObjectifNutrition.PERTE_POIDS,
      );
      expect(caloriesPerte, 2077);

      // Répartition macros pour 80kg en PERTE_POIDS
      final macros = NutritionCalculator.calculerRepartitionMacros(
        calories: 2000,
        poidsKg: 80,
        objectif: ObjectifNutrition.PERTE_POIDS,
      );
      // Protéines : 80 * 2.0 = 160g
      expect(macros['proteines'], 160.0);
      // Lipides : 80 * 0.8 = 64g
      expect(macros['lipides'], 64.0);
      expect(macros['glucides']!, greaterThan(0));
    });

    // -------------------------------------------------------------
    // Métier 3 : Analyse de l'évolution du poids
    // -------------------------------------------------------------
    test('Métier 3 - AnalyseEvolutionPoids progression et estimation', () {
      final dossier = DossierNutritionnel(
        idDossier: 'd1',
        idAthlete: 'ath-1',
        objectif: ObjectifNutrition.PERTE_POIDS,
        poidsInitial: 90.0,
        poidsActuel: 85.0,
        poidsCible: 80.0,
        tailleCm: 180.0,
        dateCreation: DateTime.now().subtract(const Duration(days: 30)),
        dateMiseAJour: DateTime.now(),
      );

      final analyse = AnalyseEvolutionPoids.analyser(dossier);
      expect(analyse['progressionPourcentage'], 50.0);
      expect(analyse['poidsRestantKg'], 5.0);
      // 5 kg restants à 0.5 kg/semaine = 10 semaines
      expect(analyse['semainesEstimees'], 10);
      expect(analyse['appreciation'], contains('Bonne dynamique'));
    });

    // -------------------------------------------------------------
    // Métier 4 : Suivi Combiné Sport + Nutrition
    // -------------------------------------------------------------
    test('Métier 4 - SuiviCombineSportNutrition bilan et synergie', () {
      final dossier = DossierNutritionnel(
        idDossier: 'd1',
        idAthlete: 'ath-1',
        objectif: ObjectifNutrition.PERTE_POIDS,
        poidsInitial: 85.0,
        poidsActuel: 82.0,
        poidsCible: 78.0,
        tailleCm: 175.0,
        dateCreation: DateTime.now().subtract(const Duration(days: 20)),
        dateMiseAJour: DateTime.now(),
      );

      final programme = ProgrammeNutritionnel(
        idProgramme: 'p1',
        idDossier: 'd1',
        titre: 'Sèche Été',
        objectif: ObjectifNutrition.PERTE_POIDS,
        caloriesCible: 2000,
        proteinesCibleG: 160.0,
        glucidesCibleG: 180.0,
        lipidesCibleG: 65.0,
        dateDebut: DateTime.now(),
      );

      final bilan = SuiviCombineSportNutrition.calculerBilan(
        dossier: dossier,
        programmeActif: programme,
      );

      expect(bilan.progressionPourcentage, closeTo(42.85, 0.1));
      expect(bilan.roleNutritionnisteApport, contains('2000 kcal/j'));
      expect(bilan.roleCoachApport, contains('Cardio HIIT'));
      expect(bilan.conseilSynthese, isNotEmpty);
    });
  });
}
