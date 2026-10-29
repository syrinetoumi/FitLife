import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mesure_progression.dart';
import '../models/suivi_objectif.dart';

class MesureProgressionRepository {
  final _client = Supabase.instance.client;

  Exception _erreur(Object e) {
    if (e is PostgrestException) {
      if (e.code == '23505') {
        return Exception('Une mesure existe déjà pour cette date.');
      }
      if (e.code == '23514') {
        return Exception('La valeur doit être supérieure à 0.');
      }
      return Exception(e.message);
    }
    return Exception('Erreur inattendue : $e');
  }

  /// Mesures d'un objectif, de la plus ancienne à la plus récente.
  Future<List<MesureProgression>> getMesures(int idSuivi) async {
    try {
      final data = await _client
          .from('mesure_progression')
          .select()
          .eq('id_suivi', idSuivi)
          .order('date_mesure');
      return (data as List).map((j) => MesureProgression.fromJson(j)).toList();
    } catch (e) {
      throw _erreur(e);
    }
  }

  Future<void> ajouter(MesureProgression mesure) async {
    try {
      await _client.from('mesure_progression').insert(mesure.toJson());
    } catch (e) {
      throw _erreur(e);
    }
  }

  Future<void> modifier(int id,
      {required double valeur, DateTime? date, String? note}) async {
    try {
      await _client.from('mesure_progression').update({
        'valeur': valeur,
        if (date != null) 'date_mesure': dateSql(date),
        'note': note,
      }).eq('id_mesure', id);
    } catch (e) {
      throw _erreur(e);
    }
  }

  Future<void> supprimer(int id) async {
    try {
      await _client.from('mesure_progression').delete().eq('id_mesure', id);
    } catch (e) {
      throw _erreur(e);
    }
  }
}