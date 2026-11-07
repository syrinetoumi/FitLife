import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/evenement.dart';

// ============================================================================
//  LES OPÉRATIONS CRUD & LA COMMUNICATION HTTP (Supabase)
// FICHIER : lib/features/evenement/data/repositories/evenement_repository.dart
// RÔLE : Centralise toutes les opérations CRUD sur la table 'evenements'.
// COMMUNICATION HTTP SOUS-JACENTE :
//   Chaque méthode utilise le client PostgREST de Supabase qui émet des
//   requêtes HTTP sécurisées avec Token JWT (GET, POST, PATCH, DELETE).
// ============================================================================

class EvenementRepository {
  final SupabaseClient client = Supabase.instance.client;

  // --------------------------------------------------------------------------
  // CRUD - C (CREATE / Insertion)
  // Requête HTTP : POST https://xyz.supabase.co/rest/v1/evenements
  // Headers : Authorization: Bearer <JWT>, apikey: <clé>, Content-Type: application/json
  // Body : JSON sérialisé via evenement.toMap()
  // --------------------------------------------------------------------------
  Future<void> ajouter(Evenement evenement) async {
    await client.from('evenements').insert(evenement.toMap());
  }

  // --------------------------------------------------------------------------
  //  CRUD - R (READ / Lecture)
  // Requête HTTP : GET https://xyz.supabase.co/rest/v1/evenements?order=date_debut.asc
  // Désérialisation : Transforme chaque ligne JSON reçue en objet Dart Evenement
  // --------------------------------------------------------------------------
  Future<List<Evenement>> getEvenements() async {
    final lignes = await client
        .from('evenements')
        .select()
        .order('date_debut');

    List<Evenement> evenements = [];
    for (var ligne in lignes) {
      evenements.add(Evenement.fromMap(ligne));
    }
    return evenements;
  }

  // --------------------------------------------------------------------------
  //  CRUD - U (UPDATE / Mise à jour)
  // Requête HTTP : PATCH https://xyz.supabase.co/rest/v1/evenements?id=eq.<id>
  // Prédicat : .eq('id', evenement.idEvenement) cible uniquement la ligne concernée
  // Utilisé notamment par le MÉTIER 4 pour basculer le statut à 'COMPLET'.
  // --------------------------------------------------------------------------
  Future<void> modifier(Evenement evenement) async {
    await client
        .from('evenements')
        .update(evenement.toMap())
        .eq('id', evenement.idEvenement);
  }

  // --------------------------------------------------------------------------
  //  CRUD - D (DELETE / Suppression)
  // Requête HTTP : DELETE https://xyz.supabase.co/rest/v1/evenements?id=eq.<id>
  // Sécurisé dans l'UI par un dialogue de confirmation Material
  // --------------------------------------------------------------------------
  Future<void> supprimer(String id) async {
    await client.from('evenements').delete().eq('id', id);
  }

  // --------------------------------------------------------------------------
  // LECTURE PAR IDENTIFIANT UNIQUE (Read Single)
  // Requête HTTP : GET https://xyz.supabase.co/rest/v1/evenements?id=eq.<id>&limit=1
  // --------------------------------------------------------------------------
  Future<Evenement?> getEvenementById(String id) async {
    final ligne = await client
        .from('evenements')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (ligne == null) return null;
    return Evenement.fromMap(ligne);
  }
}
