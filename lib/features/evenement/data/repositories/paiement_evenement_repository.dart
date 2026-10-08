import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/paiement_evenement.dart';

class PaiementEvenementRepository {
  final SupabaseClient client = Supabase.instance.client;

  Future<void> ajouter(PaiementEvenement paiement) async {
    await client.from('paiements_evenement').insert(paiement.toMap());
  }

  Future<List<PaiementEvenement>> getPaiements() async {
    final lignes = await client
        .from('paiements_evenement')
        .select()
        .order('date_paiement', ascending: false);

    List<PaiementEvenement> paiements = [];

    for (var ligne in lignes) {
      paiements.add(PaiementEvenement.fromMap(ligne));
    }

    return paiements;
  }

  Future<void> modifier(PaiementEvenement paiement) async {
    await client
        .from('paiements_evenement')
        .update(paiement.toMap())
        .eq('id', paiement.idPaiement);
  }

  Future<void> supprimer(String id) async {
    await client.from('paiements_evenement').delete().eq('id', id);
  }

  // Une inscription ne peut avoir qu'un seul paiement (relation 1-1).
  Future<bool> inscriptionDejaPayee(String idInscription) async {
    final lignes = await client
        .from('paiements_evenement')
        .select('id')
        .eq('id_inscription', idInscription);

    return lignes.isNotEmpty;
  }
}
