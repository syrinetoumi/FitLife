import 'dart:convert';
import 'package:http/http.dart' as http;

// ============================================================================
// 📌 QUESTION PROF : LA COMMUNICATION HTTP (API REST EXTERNE - GOOGLE reCAPTCHA)
// FICHIER : lib/features/evenement/data/services/recaptcha_service.dart
// RÔLE : Vérification de sécurité anti-bot via l'API REST officielle Google reCAPTCHA.
//        Protège le système d'inscription aux événements contre les soumissions automatisées.
// CONCEPTS FLUTTER / DART :
//   - Package officiel 'package:http/http.dart'
//   - Requête HTTP POST sécurisée via Uri.https()
//   - Envoi de données en x-www-form-urlencoded (standard Google)
//   - Traitement du code de statut HTTP (statusCode == 200)
//   - Désérialisation du payload JSON retourné par Google (json.decode)
// ============================================================================

class RecaptchaResultat {
  final bool succes;
  final String challengeTs;
  final String hostname;
  final String message;

  RecaptchaResultat({
    required this.succes,
    required this.challengeTs,
    required this.hostname,
    required this.message,
  });
}

class RecaptchaService {
  // 🔑 Clé secrète officielle Google reCAPTCHA pour environnement de test / validation
  // (Fournie par Google Developers pour valider sans restriction)
  static const String cleSecreteGoogle = '6LeIxAcTAAAAAGG-vFI1TnRWxMZNFuojJ4WifJWe';

  // Point de terminaison REST officiel de vérification Google
  static const String hostGoogle = 'www.google.com';
  static const String endpointGoogle = '/recaptcha/api/siteverify';

  /// 📌 QUESTION PROF : COMMUNICATION HTTP - Requête REST POST vers Google
  /// Envoie le token de vérification à Google pour confirmer qu'il s'agit d'un humain.
  Future<RecaptchaResultat> verifierCaptcha({String tokenClient = 'token_fitlife_athlete'}) async {
    // 1. Construction de l'URL sécurisée HTTPS vers Google
    final Uri url = Uri.https(hostGoogle, endpointGoogle);

    // 2. Émission de la requête HTTP POST avec les paramètres de sécurité
    final http.Response reponse = await http.post(
      url,
      body: {
        'secret': cleSecreteGoogle,
        'response': tokenClient,
      },
    );

    // 3. Contrôle du code de statut HTTP (200 OK)
    if (reponse.statusCode != 200) {
      throw Exception(
        'Erreur de communication avec les serveurs Google reCAPTCHA (Code HTTP : ${reponse.statusCode})',
      );
    }

    // 4. Décodage du JSON renvoyé par l'API Google
    final Map<String, dynamic> donnees = json.decode(reponse.body);
    final bool estValide = donnees['success'] == true;

    if (!estValide) {
      return RecaptchaResultat(
        succes: false,
        challengeTs: '',
        hostname: '',
        message: 'Échec de la validation Google reCAPTCHA (Bot détecté)',
      );
    }

    return RecaptchaResultat(
      succes: true,
      challengeTs: donnees['challenge_ts']?.toString() ?? '',
      hostname: donnees['hostname']?.toString() ?? 'google.com',
      message: 'Humain authentifié avec succès par Google reCAPTCHA',
    );
  }
}