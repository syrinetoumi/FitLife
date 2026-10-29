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
  // La réservation active de l'athlète connecté pour cette séance.
  Future<ReservationSeance?> getMaReservation(int idSeance) async {
    final utilisateur = client.auth.currentUser;

    if (utilisateur == null) {
      return null;
    }

    final ligne = await client
        .from('reservation_seance')
        .select()
        .eq('id_seance', idSeance)
        .eq('id_athlete', utilisateur.id)
        .eq('statut', 'CONFIRMEE')
        .maybeSingle();

    if (ligne == null) {
      return null;
    }

    return ReservationSeance.fromJson(ligne);
  }

  // Noms des participants confirmés (pour le coach de la séance).
  Future<List<String>> getNomsParticipants(int idSeance) async {
    final lignes = await client
        .from('reservation_seance')
        .select('date_reservation, profiles(nom, prenom)')
        .eq('id_seance', idSeance)
        .eq('statut', 'CONFIRMEE')
        .order('date_reservation', ascending: true);

    List<String> noms = [];

    for (var ligne in lignes) {
      final profil = ligne['profiles'];
      String nom = '';

      if (profil != null) {
        nom = '${profil['prenom'] ?? ''} ${profil['nom'] ?? ''}'.trim();
      }

      if (nom.isEmpty) {
        nom = 'Athlète';
      }

      noms.add(nom);
    }

    return noms;
  }
}