import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/reservation_seance.dart';

class ReservationSeanceRepository {
  final SupabaseClient client = Supabase.instance.client;

  // Réserver : l'athlète est l'utilisateur connecté.
  // Les règles (séance pleine, doublon) sont vérifiées par la base.
  Future<void> reserver(int idSeance) async {
    final utilisateur = client.auth.currentUser;

    if (utilisateur == null) {
      throw 'Connectez-vous d’abord.';
    }

    try {
      await client.from('reservation_seance').insert({
        'id_seance': idSeance,
        'id_athlete': utilisateur.id,
        'statut': 'CONFIRMEE',
      });
    } on PostgrestException catch (erreur) {
      if (erreur.code == '23505') {
        throw 'Vous avez déjà réservé cette séance.';
      }

      // Messages de la base : "Séance complète", "Séance non disponible".
      throw erreur.message;
    }
  }

  Future<void> annuler(int idReservation) async {
    await client
        .from('reservation_seance')
        .update({'statut': 'ANNULEE'})
        .eq('id_reservation', idReservation);
  }

  // Réservations actives de l'athlète connecté.
  Future<List<ReservationSeance>> getMesReservations() async {
    final utilisateur = client.auth.currentUser;

    if (utilisateur == null) {
      return [];
    }

    final lignes = await client
        .from('reservation_seance')
        .select()
        .eq('id_athlete', utilisateur.id)
        .eq('statut', 'CONFIRMEE')
        .order('date_reservation', ascending: false);

    List<ReservationSeance> reservations = [];

    for (var ligne in lignes) {
      reservations.add(ReservationSeance.fromJson(ligne));
    }

    return reservations;
  }

  // Participants d'une séance (visible par le coach de la séance).
  Future<List<ReservationSeance>> getReservationsDeLaSeance(
      int idSeance,
      ) async {
    final lignes = await client
        .from('reservation_seance')
        .select()
        .eq('id_seance', idSeance)
        .eq('statut', 'CONFIRMEE');

    List<ReservationSeance> reservations = [];

    for (var ligne in lignes) {
      reservations.add(ReservationSeance.fromJson(ligne));
    }

    return reservations;
  }

  // Cette séance est-elle déjà réservée par l'athlète connecté ?
  Future<bool> dejaReservee(int idSeance) async {
    final utilisateur = client.auth.currentUser;

    if (utilisateur == null) {
      return false;
    }

    final lignes = await client
        .from('reservation_seance')
        .select('id_reservation')
        .eq('id_seance', idSeance)
        .eq('id_athlete', utilisateur.id)
        .eq('statut', 'CONFIRMEE');

    return lignes.isNotEmpty;
  }
}