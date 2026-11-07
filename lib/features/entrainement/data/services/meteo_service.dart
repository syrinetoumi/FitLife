import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/prevision_meteo.dart';

// Même clé RapidAPI que ExerciseDB : --dart-define=EXERCISEDB_KEY=...
const String cleMeteo = String.fromEnvironment('EXERCISEDB_KEY');
const String hoteMeteo = 'open-weather13.p.rapidapi.com';

class MeteoService {
  // Lieu par défaut : Tunis.
  static const double latitudeParDefaut = 36.8065;
  static const double longitudeParDefaut = 10.1815;

  // Petite mémoire de 30 minutes pour économiser le quota de l'API.
  static List<PrevisionMeteo>? _memoire;
  static DateTime? _memoireHeure;
  static String? _memoireLieu;

  Future<List<PrevisionMeteo>> previsions({
    double latitude = latitudeParDefaut,
    double longitude = longitudeParDefaut,
  }) async {
    if (cleMeteo.isEmpty) {
      throw Exception(
        'Clé RapidAPI absente. Ajoute --dart-define=EXERCISEDB_KEY=... au lancement.',
      );
    }

    String lieu = '$latitude,$longitude';

    if (_memoire != null &&
        _memoireLieu == lieu &&
        _memoireHeure != null &&
        DateTime.now().difference(_memoireHeure!).inMinutes < 30) {
      return _memoire!;
    }
    Uri url = Uri.https(hoteMeteo, '/fivedaysforcast', {
      'latitude': '$latitude',
      'longitude': '$longitude',
      'lang': 'EN',
    });

    // Même authentification que le playground RapidAPI : par en-têtes.
    http.Response reponse = await http.get(url, headers: {
      'x-rapidapi-key': cleMeteo,
      'x-rapidapi-host': hoteMeteo,
    });
    debugPrint('Météo : code ${reponse.statusCode}');

    if (reponse.statusCode != 200) {
      debugPrint('Météo : ${reponse.body}');
    }

    if (reponse.statusCode == 429) {
      throw Exception('Quota de requêtes atteint. Réessaie plus tard.');
    }

    if (reponse.statusCode != 200) {
      throw Exception('Erreur météo (code ${reponse.statusCode}).');
    }

    Map<String, dynamic> donnees =
    json.decode(reponse.body) as Map<String, dynamic>;

    List<PrevisionMeteo> liste = (donnees['list'] as List)
        .map((element) =>
        PrevisionMeteo.fromJson(element as Map<String, dynamic>))
        .toList();

    _memoire = liste;
    _memoireHeure = DateTime.now();
    _memoireLieu = lieu;

    return liste;
  }

  // Prévision la plus proche d'un instant, ou null si on sort des 5 jours.
  static PrevisionMeteo? plusProche(
      List<PrevisionMeteo> liste,
      DateTime instant,
      ) {
    PrevisionMeteo? meilleure;
    Duration? ecartMin;
    DateTime cible = instant.toUtc();

    for (var prevision in liste) {
      Duration ecart = prevision.instant.difference(cible).abs();

      if (ecartMin == null || ecart < ecartMin) {
        ecartMin = ecart;
        meilleure = prevision;
      }
    }

    // Les créneaux sont espacés de 3 h : au-delà de 2 h, on n'a rien.
    if (ecartMin == null || ecartMin > const Duration(hours: 2)) {
      return null;
    }

    return meilleure;
  }
}