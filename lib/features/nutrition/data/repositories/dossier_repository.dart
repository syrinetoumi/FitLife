import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/dossier_nutritionnel.dart';
import '../models/enums_nutrition.dart';

/// Repository pour la gestion du Dossier Nutritionnel de l'athlète (Entité 1).
/// Gère la persistance Supabase (table "dossier_nutritionnel") avec un mode de secours local
/// si Supabase n'est pas encore configuré ou inaccessible.
class DossierRepository {
  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // Données de secours en mémoire (permet de tester l'application avant la création des tables Supabase)
  static final Map<String, DossierNutritionnel> _dossiersLocaux = {
    'demo-athlete-id': DossierNutritionnel(
      idDossier: 'demo-dossier-001',
      idAthlete: 'demo-athlete-id',
      objectif: ObjectifNutrition.PERTE_POIDS,
      poidsInitial: 86.0,
      poidsActuel: 81.5,
      poidsCible: 78.0,
      tailleCm: 178.0,
      remarques: 'Objectif : perte de 8 kg coordonnée avec entraînement cardio/musculation.',
      dateCreation: DateTime.now().subtract(const Duration(days: 30)),
      dateMiseAJour: DateTime.now(),
    ),
  };

  /// Récupère ou initialise le dossier nutritionnel pour un athlète donné
  Future<DossierNutritionnel> getDossier(String idAthlete) async {
    final client = _client;
    if (client != null) {
      try {
        final response = await client
            .from('dossier_nutritionnel')
            .select()
            .eq('id_athlete', idAthlete)
            .maybeSingle();

        if (response != null) {
          return DossierNutritionnel.fromMap(response);
        }
      } catch (_) {
        // Supabase non configuré ou table non encore créée
      }
    }

    // Retour du dossier en mémoire ou création d'un dossier par défaut
    if (_dossiersLocaux.containsKey(idAthlete)) {
      return _dossiersLocaux[idAthlete]!;
    }

    final nouveauDossier = DossierNutritionnel(
      idDossier: 'local-${DateTime.now().millisecondsSinceEpoch}',
      idAthlete: idAthlete,
      objectif: ObjectifNutrition.PERTE_POIDS,
      poidsInitial: 80.0,
      poidsActuel: 80.0,
      poidsCible: 75.0,
      tailleCm: 175.0,
      remarques: 'Nouveau dossier créé',
      dateCreation: DateTime.now(),
      dateMiseAJour: DateTime.now(),
    );
    _dossiersLocaux[idAthlete] = nouveauDossier;
    return nouveauDossier;
  }

  /// Enregistre ou met à jour le dossier nutritionnel
  Future<void> enregistrerDossier(DossierNutritionnel dossier) async {
    _dossiersLocaux[dossier.idAthlete] = dossier;

    final client = _client;
    if (client != null) {
      try {
        await client.from('dossier_nutritionnel').upsert(
          dossier.toMap()..['id_athlete'] = dossier.idAthlete,
          onConflict: 'id_athlete',
        );
      } catch (_) {
        // Ignoré si Supabase n'est pas encore prêt
      }
    }
  }

  /// Met à jour rapidement le poids actuel de l'athlète
  Future<DossierNutritionnel> enregistrerPesee(String idAthlete, double nouveauPoids) async {
    final existant = await getDossier(idAthlete);
    final maj = existant.copyWith(
      poidsActuel: nouveauPoids,
      dateMiseAJour: DateTime.now(),
    );

    await enregistrerDossier(maj);
    return maj;
  }

  /// Met à jour les métriques de poids : initial, actuel et objectif cible
  Future<DossierNutritionnel> mettreAJourObjectifsPoids(
    String idAthlete, {
    required double poidsInitial,
    required double poidsActuel,
    required double poidsCible,
    ObjectifNutrition? objectif,
  }) async {
    final existant = await getDossier(idAthlete);
    final maj = existant.copyWith(
      poidsInitial: poidsInitial,
      poidsActuel: poidsActuel,
      poidsCible: poidsCible,
      objectif: objectif ?? existant.objectif,
      dateMiseAJour: DateTime.now(),
    );

    await enregistrerDossier(maj);
    return maj;
  }

  /// Met à jour l'objectif du dossier (et adapte le poids cible si nécessaire)
  Future<void> mettreAJourObjectifParDossier(
    String idDossier,
    ObjectifNutrition nouvelObjectif, {
    double? nouveauPoidsCible,
  }) async {
    final client = _client;
    if (client != null) {
      try {
        final data = <String, dynamic>{
          'objectif': nouvelObjectif.name,
          'date_mise_a_jour': DateTime.now().toUtc().toIso8601String(),
        };
        if (nouveauPoidsCible != null) {
          data['poids_cible'] = nouveauPoidsCible;
        }
        await client.from('dossier_nutritionnel').update(data).eq('id', idDossier);
      } catch (_) {}
    }

    for (final key in _dossiersLocaux.keys) {
      final dossier = _dossiersLocaux[key]!;
      if (dossier.idDossier == idDossier) {
        double cible = nouveauPoidsCible ?? dossier.poidsCible;
        if (nouveauPoidsCible == null) {
          if (nouvelObjectif == ObjectifNutrition.PRISE_MASSE && cible <= dossier.poidsActuel) {
            cible = dossier.poidsActuel + 4.0;
          } else if (nouvelObjectif == ObjectifNutrition.PERTE_POIDS && cible >= dossier.poidsActuel) {
            cible = (dossier.poidsActuel - 4.0).clamp(30.0, 300.0);
          }
        }

        _dossiersLocaux[key] = dossier.copyWith(
          objectif: nouvelObjectif,
          poidsCible: cible,
          dateMiseAJour: DateTime.now(),
        );
        break;
      }
    }
  }
}
