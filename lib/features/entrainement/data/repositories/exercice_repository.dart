import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/exercice.dart';

class ExerciceRepository {
  final SupabaseClient _client;
  ExerciceRepository(this._client);

  Future<List<Exercice>> parMuscle(String muscle) async {
    final rows = await _client
        .from('exercice')
        .select()
        .ilike('muscle', muscle)
        .order('nom');
    return rows.map<Exercice>((j) => Exercice.fromJson(j)).toList();
  }

  Future<Exercice?> parId(int id) async {
    final row = await _client
        .from('exercice')
        .select()
        .eq('id_exercice', id)
        .maybeSingle();
    return row == null ? null : Exercice.fromJson(row);
  }

  /// Import en lot (une seule fois). Nécessite une contrainte unique sur external_id.
  Future<void> enregistrerLot(List<Exercice> exercices) async {
    await _client
        .from('exercice')
        .upsert(
      exercices.map((e) => e.toJson()).toList(),
      onConflict: 'external_id',
    );
  }
}