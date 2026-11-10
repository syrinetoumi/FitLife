import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/prevision_meteo.dart';

// ---------------------------------------------------------------------------
// Service météo : appelle l'API Open Weather (via RapidAPI) pour obtenir les
// prévisions à 5 jours, par créneaux de 3 heures.
//
// C'est un service externe : il ne parle pas à Supabase, il envoie une
// requête HTTP GET avec le paquet `http`.
// ---------------------------------------------------------------------------

// Clé RapidAPI de l'API météo. Elle est différente de celle d'ExerciseDB.
// Elle n'est jamais écrite dans le code (le dépôt GitHub est public) : on la
// donne au lancement avec  --dart-define=METEO_KEY=...
// `String.fromEnvironment` est lue à la compilation : il faut donc relancer
// l'application complètement (pas de rechargement à chaud) après un changement.
const String cleMeteo = String.fromEnvironment('METEO_KEY');

// Adresse du serveur de l'API. RapidAPI exige de la répéter dans un en-tête.
const String hoteMeteo = 'open-weather13.p.rapidapi.com';

class MeteoService {
  // Lieu par défaut : Tunis.
  static const double latitudeParDefaut = 36.8065;
  static const double longitudeParDefaut = 10.1815;

  // Petite mémoire de 30 minutes pour économiser le quota de l'API
  // (le plan gratuit n'autorise que 100 requêtes par mois).
  // Les variables sont `static` : elles sont partagées par toutes les
  // instances du service, mais perdues quand l'application redémarre.
  static List<PrevisionMeteo>? _memoire;
  static DateTime? _memoireHeure;
  static String? _memoireLieu;

  // Retourne les prévisions pour un lieu (Tunis si rien n'est précisé).
  Future<List<PrevisionMeteo>> previsions({
    double latitude = latitudeParDefaut,
    double longitude = longitudeParDefaut,
  }) async {
    // 1. Sans clé, inutile d'appeler l'API : on explique quoi faire.
    if (cleMeteo.isEmpty) {
      throw Exception(
        'Clé météo absente. Ajoute --dart-define=METEO_KEY=... au lancement.',
      );
    }

    // 2. Si on a déjà les prévisions de ce lieu depuis moins de 30 minutes,
    //    on les renvoie sans refaire de requête.
    String lieu = '$latitude,$longitude';

    if (_memoire != null &&
        _memoireLieu == lieu &&
        _memoireHeure != null &&
        DateTime.now().difference(_memoireHeure!).inMinutes < 30) {
      return _memoire!;
    }

    // 3. Construction de l'adresse :
    //    https://open-weather13.p.rapidapi.com/fivedaysforcast?latitude=...
    Uri url = Uri.https(hoteMeteo, '/fivedaysforcast', {
      'latitude': '$latitude',
      'longitude': '$longitude',
      'lang': 'EN',
    });

    // 4. Requête GET. L'authentification passe par deux en-têtes :
    //    la clé de l'utilisateur et le nom du serveur visé.
    http.Response reponse = await http.get(url, headers: {
      'x-rapidapi-key': cleMeteo,
      'x-rapidapi-host': hoteMeteo,
    });

    // Traces pour le débogage (visibles dans la console, jamais la clé).
    debugPrint('Météo : code ${reponse.statusCode}');

    if (reponse.statusCode != 200) {
      debugPrint('Météo : ${reponse.body}');
    }

    // 5. Codes d'erreur HTTP les plus courants avec RapidAPI.
    if (reponse.statusCode == 401) {
      throw Exception('Clé météo refusée (401). Vérifie METEO_KEY.');
    }

    if (reponse.statusCode == 403) {
      throw Exception(
        'Accès refusé (403) : clé invalide pour cette API ou abonnement '
            'manquant.',
      );
    }

    if (reponse.statusCode == 429) {
      throw Exception('Quota de requêtes atteint. Réessaie plus tard.');
    }

    if (reponse.statusCode != 200) {
      throw Exception('Erreur météo (code ${reponse.statusCode}).');
    }

    // 6. Lecture de la réponse : le texte JSON devient une Map, puis chaque
    //    élément de la liste `list` devient un objet PrevisionMeteo
    //    (la conversion Kelvin vers °C est faite dans le modèle).
    Map<String, dynamic> donnees =
    json.decode(reponse.body) as Map<String, dynamic>;

    List<PrevisionMeteo> liste = (donnees['list'] as List)
        .map((element) =>
        PrevisionMeteo.fromJson(element as Map<String, dynamic>))
        .toList();

    // 7. On garde le résultat en mémoire pour les 30 prochaines minutes.
    _memoire = liste;
    _memoireHeure = DateTime.now();
    _memoireLieu = lieu;

    return liste;
  }

  // Cherche la prévision la plus proche d'un instant donné (par exemple le
  // début d'une séance). Retourne null si l'instant sort des 5 jours.
  static PrevisionMeteo? plusProche(
      List<PrevisionMeteo> liste,
      DateTime instant,
      ) {
    PrevisionMeteo? meilleure;
    Duration? ecartMin;

    // Les prévisions de l'API sont en UTC : on compare dans le même fuseau.
    DateTime cible = instant.toUtc();

    for (var prevision in liste) {
      // `.abs()` : l'écart compte dans les deux sens (avant ou après).
      Duration ecart = prevision.instant.difference(cible).abs();

      if (ecartMin == null || ecart < ecartMin) {
        ecartMin = ecart;
        meilleure = prevision;
      }
    }

    // Les créneaux sont espacés de 3 h : au-delà de 2 h, on n'a rien de fiable.
    if (ecartMin == null || ecartMin > const Duration(hours: 2)) {
      return null;
    }

    return meilleure;
  }
}