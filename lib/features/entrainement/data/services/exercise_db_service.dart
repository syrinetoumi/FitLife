import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:coach_app/features/entrainement/data/models/exercice_api.dart';

// Clé donnée au lancement : --dart-define=EXERCISEDB_KEY=...
const String cleExerciseDb = String.fromEnvironment('EXERCISEDB_KEY');
const String hoteExerciseDb = 'exercisedb.p.rapidapi.com';

class ExerciseDbService {
  // Authentification par en-tête (recommandée par la doc).
  static Map<String, String> get entetes => {
    'X-RapidAPI-Key': cleExerciseDb,
    'X-RapidAPI-Host': hoteExerciseDb,
  };

  // Exercices ciblant un muscle (gratuit : 10 résultats maximum).
  Future<List<ExerciceApi>> exercicesParCible(String cible) async {
    if (cleExerciseDb.isEmpty) {
      throw Exception(
        'Clé ExerciseDB absente. Ajoute --dart-define=EXERCISEDB_KEY=... au lancement.',
      );
    }

    // Uri.https encode les espaces (ex. "levator scapulae").
    Uri url = Uri.https(
      hoteExerciseDb,
      '/exercises/target/$cible',
      {'limit': '10', 'rapidapi-key': cleExerciseDb},
    );

    http.Response reponse = await http.get(url);
    debugPrint('ExerciseDB ${reponse.statusCode} : ${reponse.body}');
    if (reponse.statusCode == 401 || reponse.statusCode == 403) {
      throw Exception(
        'Clé refusée ou abonnement ExerciseDB manquant (code ${reponse.statusCode}).',
      );
    }

    if (reponse.statusCode == 429) {
      throw Exception('Quota de requêtes atteint. Réessaie plus tard.');
    }

    if (reponse.statusCode != 200) {
      throw Exception('Erreur ExerciseDB (code ${reponse.statusCode}).');
    }

    // Chapitre 6 : json.decode, puis conversion de chaque élément.
    List<dynamic> liste = json.decode(reponse.body);

    return liste
        .map((element) => ExerciceApi.fromJson(element as Map<String, dynamic>))
        .toList();
  }

  // URL du GIF animé (180 px : seule résolution du plan gratuit).
  static String urlGif(String idExercice) {
    return Uri.https(
      hoteExerciseDb,
      '/image',
      {'exerciseId': idExercice, 'resolution': '180'},
    ).toString();
  }
}