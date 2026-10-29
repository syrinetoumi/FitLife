import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/programme_exercice.dart';

class ProgrammeExerciceRepository {
  final SupabaseClient client = Supabase.instance.client;

  Exception _erreur(Object e) {
    if (e is PostgrestException) {
      if (e.code == '23505') {
        return Exception('Cet exercice est déjà dans le programme.');
      }
      if (e.code == '23514') {
        return Exception(
            'Valeurs invalides : séries, répétitions et ordre doivent être '
                'supérieurs à 0.');
      }
      return Exception(e.message);
    }
    return Exception('Erreur inattendue : $e');
  }

  // Exercices d'un programme, dans l'ordre.
  Future<List<ProgrammeExercice>> getExercices(int idProgramme) async {
    try {
      final lignes = await client
          .from('programme_exercice')
          .select()
          .eq('id_programme', idProgramme)
          .order('ordre');

      List<ProgrammeExercice> liste = [];

      for (var ligne in lignes) {
        liste.add(ProgrammeExercice.fromJson(ligne));
      }

      return liste;
    } catch (e) {
      throw _erreur(e);
    }
  }

  // Prochain numéro d'ordre (dernier + 1).
  Future<int> prochainOrdre(int idProgramme) async {
    final lignes = await getExercices(idProgramme);

    if (lignes.isEmpty) {
      return 1;
    }

    return lignes.last.ordre + 1;
  }

  Future<void> ajouter(ProgrammeExercice exercice) async {
    try {
      await client.from('programme_exercice').insert(exercice.toJson());
    } catch (e) {
      throw _erreur(e);
    }
  }

  Future<void> modifier(ProgrammeExercice exercice) async {
    try {
      await client
          .from('programme_exercice')
          .update({
        'ordre': exercice.ordre,
        'series': exercice.series,
        'repetitions': exercice.repetitions,
        'temps_repos': exercice.tempsRepos,
        'charge': exercice.charge,
      })
          .eq('id_programme', exercice.idProgramme)
          .eq('external_id', exercice.externalId);
    } catch (e) {
      throw _erreur(e);
    }
  }

  Future<void> supprimer(int idProgramme, String externalId) async {
    try {
      await client
          .from('programme_exercice')
          .delete()
          .eq('id_programme', idProgramme)
          .eq('external_id', externalId);
    } catch (e) {
      throw _erreur(e);
    }
  }
}