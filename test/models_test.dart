import 'package:flutter_test/flutter_test.dart';
import 'package:coach_app/features/entrainement/data/models/enums.dart';
import 'package:coach_app/features/entrainement/data/models/programme.dart';
//import 'package:coach_app/features/entrainement/data/models/exercice.dart';
import 'package:coach_app/features/entrainement/data/models/seance.dart';
import 'package:coach_app/features/entrainement/data/models/programme_exercice.dart';

void main() {
  test('Programme fromJson / toJson', () {
    final p = Programme.fromJson({
      'id_programme': 1, 'nom': 'Test', 'description': null,
      'objectif': 'PRISE_MASSE', 'niveau': 'DEBUTANT',
      'duree_semaines': 8, 'date_debut': '2026-10-20',
      'date_fin': null, 'id_coach': 'abc',
    });
    expect(p.objectif, ObjectifProgramme.PRISE_MASSE);
    expect(p.toJson()['objectif'], 'PRISE_MASSE');
    expect(p.toJson()['date_debut'], '2026-10-20');
  });

  /*test('Exercice fromJson / toJson', () {
    final e = Exercice.fromJson({
      'id_exercice': 5, 'external_id': 'x1', 'nom': 'Pompes',
      'description': null, 'muscle': 'pectoraux', 'niveau': 'DEBUTANT',
      'equipement': null, 'image_url': null, 'gif_url': null,
      'instructions': null,
    });
    expect(e.niveau, Niveau.DEBUTANT);
    expect(e.toJson()['niveau'], 'DEBUTANT');
    expect(e.toJson()['muscle'], 'pectoraux');
  });*/

  test('ProgrammeExercice fromJson / toJson', () {
    final json = {
      'id_programme': 1,
      'external_id': '0001',
      'ordre': 1,
      'series': 3,
      'repetitions': 12,
      'temps_repos': 60,
      'charge': 20.5,
    };

    final exercice = ProgrammeExercice.fromJson(json);

    expect(exercice.idProgramme, 1);
    expect(exercice.externalId, '0001');
    expect(exercice.ordre, 1);
    expect(exercice.series, 3);
    expect(exercice.repetitions, 12);
    expect(exercice.tempsRepos, 60);
    expect(exercice.charge, 20.5);
    expect(exercice.toJson(), json);
  });

  test('Seance fromJson / toJson', () {
    final s = Seance.fromJson({
      'id_seance': 1, 'titre': 'S1', 'description': null,
      'date': '2026-10-20', 'heure_debut': '16:00:00',
      'heure_fin': '18:00:00', 'type': 'COLLECTIVE', 'capacite': 10,
      'prix': 15, 'statut': 'PLANIFIEE', 'id_coach': 'abc',
      'id_programme': null, 'id_espace_sportif': null,
    });
    expect(s.type, TypeSeance.COLLECTIVE);
    expect(s.statut, StatutSeance.PLANIFIEE);
    expect(s.prix, 15.0);
    expect(s.toJson()['date'], '2026-10-20');
    expect(s.toJson()['type'], 'COLLECTIVE');
  });
}