import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/seance.dart';

class SeanceRepository {
  final SupabaseClient client = Supabase.instance.client;

  // Messages clairs pour les erreurs de la base.
  String traduireErreur(PostgrestException erreur) {
    // Métier 4 : contrainte anti-chevauchement.
    if (erreur.code == '23P01') {
      return 'Vous avez déjà une séance sur ce créneau horaire.';
    }

    if (erreur.code == '23514') {
      return 'Valeurs invalides : l’heure de fin doit suivre l’heure de début '
          'et la capacité doit être positive.';
    }

    if (erreur.code == '42501') {
      return 'Action non autorisée : seul le coach de la séance peut la modifier.';
    }

    if (erreur.code == '23503') {
      return 'Impossible de supprimer : cette séance a des réservations.';
    }

    return erreur.message;
  }

  Future<void> ajouter(Seance seance) async {
    try {
      await client.from('seance').insert(seance.toJson());
    } on PostgrestException catch (erreur) {
      throw traduireErreur(erreur);
    }
  }

  Future<void> modifier(Seance seance, {bool avecStatut = false}) async {
    Map<String, dynamic> donnees = seance.toJson();
    donnees.remove('id_coach');

    if (!avecStatut) {
      donnees.remove('statut');
    }

    try {
      await client
          .from('seance')
          .update(donnees)
          .eq('id_seance', seance.id!);
    } on PostgrestException catch (erreur) {
      throw traduireErreur(erreur);
    }
  }

  Future<void> supprimer(int id) async {
    try {
      await client.from('seance').delete().eq('id_seance', id);
    } on PostgrestException catch (erreur) {
      throw traduireErreur(erreur);
    }
  }

  // Seulement les séances du coach connecté, dans l'ordre chronologique.
  Future<List<Seance>> getSeancesDuCoach() async {
    final utilisateur = client.auth.currentUser;

    if (utilisateur == null) {
      return [];
    }

    final lignes = await client
        .from('seance')
        .select()
        .eq('id_coach', utilisateur.id)
        .order('date', ascending: true)
        .order('heure_debut', ascending: true);

    List<Seance> seances = [];

    for (var ligne in lignes) {
      seances.add(Seance.fromJson(ligne));
    }

    return seances;
  }

  // Métier 4 : cherche une séance du coach qui chevauche ce créneau.
  // Retourne la séance en conflit, ou null si le créneau est libre.
  // (La base garde le dernier mot grâce à sa contrainte.)
  Future<Seance?> trouverConflit({
    required DateTime date,
    required String heureDebut, // "HH:mm"
    required String heureFin, // "HH:mm"
    int? ignorerId, // la séance qu'on est en train de modifier
  }) async {
    final utilisateur = client.auth.currentUser;

    if (utilisateur == null) {
      return null;
    }

    String jour = date.toIso8601String().split('T').first;

    final lignes = await client
        .from('seance')
        .select()
        .eq('id_coach', utilisateur.id)
        .eq('date', jour)
        .neq('statut', 'ANNULEE');

    for (var ligne in lignes) {
      Seance autre = Seance.fromJson(ligne);

      if (ignorerId != null && autre.id == ignorerId) {
        continue;
      }

      // Deux créneaux se chevauchent si chacun commence avant la fin
      // de l'autre. 16:00-18:00 et 18:00-20:00 ne se chevauchent pas.
      if (heureDebut.compareTo(autre.finCourt) < 0 &&
          heureFin.compareTo(autre.debutCourt) > 0) {
        return autre;
      }
    }

    return null;
  }
  // Séances à venir visibles par les athlètes (planifiées ou complètes).
  Future<List<Seance>> getSeancesDisponibles() async {
    String aujourdhui = DateTime.now().toIso8601String().split('T').first;

    final lignes = await client
        .from('seance')
        .select()
        .inFilter('statut', ['PLANIFIEE', 'COMPLETE'])
        .gte('date', aujourdhui)
        .order('date', ascending: true)
        .order('heure_debut', ascending: true);

    List<Seance> seances = [];

    for (var ligne in lignes) {
      seances.add(Seance.fromJson(ligne));
    }

    return seances;
  }

  // Version à jour d'une séance (le statut change avec les réservations).
  Future<Seance?> getSeance(int id) async {
    final ligne = await client
        .from('seance')
        .select()
        .eq('id_seance', id)
        .maybeSingle();

    if (ligne == null) {
      return null;
    }

    return Seance.fromJson(ligne);
  }

  // Nombre de places réservées (fonction SQL nb_reservations).
  // Retourne null si la fonction n'existe pas encore.
  Future<int?> nombreReservations(int idSeance) async {
    try {
      final resultat = await client.rpc(
        'nb_reservations',
        params: {'p_seance': idSeance},
      );

      return (resultat as num).toInt();
    } catch (erreur) {
      return null;
    }
  }
}