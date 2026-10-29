import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/suivi_objectif.dart';

class SuiviObjectifRepository {
  final _client = Supabase.instance.client;

  static const _jointures = '*, programme(nom, objectif), profiles(nom, prenom)';

  Exception _erreur(Object e) {
    if (e is PostgrestException) {
      if (e.code == '23505') {
        return Exception(
            'Tu as déjà un objectif en cours pour ce programme.');
      }
      if (e.code == '23514') {
        return Exception(
            'Valeurs invalides : la date limite doit être après le début '
                'et la cible différente du départ.');
      }
      return Exception(e.message);
    }
    return Exception('Erreur inattendue : $e');
  }

  /// Athlète : ses propres objectifs.
  Future<List<SuiviObjectif>> getMesSuivis() async {
    final uid = _client.auth.currentUser!.id;
    try {
      final data = await _client
          .from('suivi_objectif')
          .select(_jointures)
          .eq('id_athlete', uid)
          .order('date_debut', ascending: false);
      return (data as List).map((j) => SuiviObjectif.fromJson(j)).toList();
    } catch (e) {
      throw _erreur(e);
    }
  }

  /// Coach : les objectifs des athlètes inscrits à ses programmes.
  Future<List<SuiviObjectif>> getSuivisDeMesAthletes() async {
    final uid = _client.auth.currentUser!.id;
    try {
      final data = await _client
          .from('suivi_objectif')
          .select(_jointures)
          .neq('id_athlete', uid)
          .order('date_limite');
      return (data as List).map((j) => SuiviObjectif.fromJson(j)).toList();
    } catch (e) {
      throw _erreur(e);
    }
  }

  Future<SuiviObjectif> getSuivi(int id) async {
    try {
      final data = await _client
          .from('suivi_objectif')
          .select(_jointures)
          .eq('id_suivi', id)
          .single();
      return SuiviObjectif.fromJson(data);
    } catch (e) {
      throw _erreur(e);
    }
  }

  Future<void> ajouter(SuiviObjectif suivi) async {
    try {
      await _client.from('suivi_objectif').insert(suivi.toJson());
    } catch (e) {
      throw _erreur(e);
    }
  }

  /// Modifie la cible, la date limite et/ou le statut.
  Future<void> modifier(int id,
      {double? valeurCible, DateTime? dateLimite, String? statut}) async {
    final champs = <String, dynamic>{
      'valeur_cible': ?valeurCible,
      'date_limite': ?(dateLimite == null ? null : dateSql(dateLimite)),
      'statut': ?statut,
    };
    if (champs.isEmpty) return;
    try {
      await _client.from('suivi_objectif').update(champs).eq('id_suivi', id);
    } catch (e) {
      throw _erreur(e);
    }
  }

  Future<void> supprimer(int id) async {
    try {
      await _client.from('suivi_objectif').delete().eq('id_suivi', id);
    } catch (e) {
      throw _erreur(e);
    }
  }
}