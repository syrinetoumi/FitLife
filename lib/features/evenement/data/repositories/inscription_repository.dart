import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/inscription.dart';

class InscriptionRepository {
  final SupabaseClient client = Supabase.instance.client;

  Future<void> ajouter(Inscription inscription) async {
    await client.from('inscriptions').insert(inscription.toMap());
  }

  Future<List<Inscription>> getInscriptions() async {
    final lignes = await client
        .from('inscriptions')
        .select()
        .order('date_inscription', ascending: false);

    List<Inscription> inscriptions = [];

    for (var ligne in lignes) {
      inscriptions.add(Inscription.fromMap(ligne));
    }

    return inscriptions;
  }

  // Métier 1 : toutes les inscriptions d'un événement,
  // pour compter les places déjà prises.
  Future<List<Inscription>> getInscriptionsByEvenement(
      String idEvenement) async {
    final lignes = await client
        .from('inscriptions')
        .select()
        .eq('id_evenement', idEvenement)
        .order('date_inscription', ascending: false);

    List<Inscription> inscriptions = [];

    for (var ligne in lignes) {
      inscriptions.add(Inscription.fromMap(ligne));
    }

    return inscriptions;
  }

  Future<void> modifier(Inscription inscription) async {
    await client
        .from('inscriptions')
        .update(inscription.toMap())
        .eq('id', inscription.idInscription);
  }

  Future<void> supprimer(String id) async {
    await client.from('inscriptions').delete().eq('id', id);
  }
}
