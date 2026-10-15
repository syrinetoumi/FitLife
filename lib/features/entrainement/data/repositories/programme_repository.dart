import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/programme.dart';

class ProgrammeRepository {
  final SupabaseClient client = Supabase.instance.client;

  Future<void> ajouter(Programme programme) async {
    await client.from('programme').insert(programme.toJson());
  }

  // Seulement les programmes du coach connecté.
  Future<List<Programme>> getProgrammesDuCoach() async {
    final utilisateur = client.auth.currentUser;

    if (utilisateur == null) {
      return [];
    }

    final lignes = await client
        .from('programme')
        .select()
        .eq('id_coach', utilisateur.id)
        .order('id_programme', ascending: false);

    List<Programme> programmes = [];

    for (var ligne in lignes) {
      programmes.add(Programme.fromJson(ligne));
    }

    return programmes;
  }

  Future<void> modifier(Programme programme) async {
    await client
        .from('programme')
        .update(programme.toJson())
        .eq('id_programme', programme.id!);
  }

  Future<void> supprimer(int id) async {
    await client.from('programme').delete().eq('id_programme', id);
  }
}