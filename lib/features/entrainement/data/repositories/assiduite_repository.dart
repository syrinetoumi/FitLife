import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/assiduite.dart';
import '../models/suivi_objectif.dart';

class AssiduiteRepository {
  final SupabaseClient client = Supabase.instance.client;

  Exception _erreur(Object e) {
    if (e is PostgrestException) {
      return Exception(e.message);
    }
    return Exception('Erreur inattendue : $e');
  }

  // Réservations d'un athlète aux séances d'un programme, depuis une date.
  Future<List<LigneAssiduite>> getLignes({
    required String idAthlete,
    required int idProgramme,
    required DateTime depuis,
  }) async {
    try {
      final lignes = await client
          .from('reservation_seance')
          .select(
        'id_reservation, statut, presence, '
            'seance!inner(id_seance, titre, date, statut, id_programme)',
      )
          .eq('id_athlete', idAthlete)
          .eq('seance.id_programme', idProgramme)
          .gte('seance.date', dateSql(depuis));

      List<LigneAssiduite> liste = [];

      for (var ligne in lignes) {
        liste.add(LigneAssiduite.fromJson(ligne));
      }

      return liste;
    } catch (e) {
      throw _erreur(e);
    }
  }

  // Feuille de présence : participants confirmés d'une séance.
  Future<List<PresenceParticipant>> getFeuille(int idSeance) async {
    try {
      final lignes = await client
          .from('reservation_seance')
          .select('id_reservation, presence, profiles(nom, prenom)')
          .eq('id_seance', idSeance)
          .eq('statut', 'CONFIRMEE')
          .order('id_reservation');

      List<PresenceParticipant> liste = [];

      for (var ligne in lignes) {
        liste.add(PresenceParticipant.fromJson(ligne));
      }

      return liste;
    } catch (e) {
      throw _erreur(e);
    }
  }

  Future<void> marquerPresence(int idReservation, bool present) async {
    try {
      await client.rpc('marquer_presence', params: {
        'p_reservation': idReservation,
        'p_present': present,
      });
    } catch (e) {
      throw _erreur(e);
    }
  }
}