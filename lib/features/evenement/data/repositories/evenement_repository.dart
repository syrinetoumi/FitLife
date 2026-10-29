import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/evenement.dart';

class EvenementRepository {
  final SupabaseClient client = Supabase.instance.client;

  Future<void> ajouter(Evenement evenement) async {
    await client.from('evenements').insert(evenement.toMap());
  }

  Future<List<Evenement>> getEvenements() async {
    final lignes = await client.from('evenements').select().order('date_debut');

    List<Evenement> evenements = [];

    for (var ligne in lignes) {
      evenements.add(Evenement.fromMap(ligne));
    }

    return evenements;
  }

  Future<void> modifier(Evenement evenement) async {
    await client
        .from('evenements')
        .update(evenement.toMap())
        .eq('id', evenement.idEvenement);
  }

  Future<void> supprimer(String id) async {
    await client.from('evenements').delete().eq('id', id);
  }
}
