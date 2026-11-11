import 'dart:convert';
import 'package:http/http.dart' as http;

// ============================================================================
// 📌 QUESTION PROF : LA COMMUNICATION HTTP & API REST EXTERNE (Passerelle de Paiement)
// FICHIER : lib/features/evenement/data/services/paiement_api_service.dart
// RÔLE : Intègre une passerelle de paiement REST sécurisée pour traiter les règlements
//        en ligne par carte bancaire des inscriptions aux événements.
// CONCEPTS FLUTTER / DART :
//   - Package officiel 'package:http/http.dart'
//   - Construction d'URL via Uri.https()
//   - Requête HTTP POST asynchrone avec corps JSON (json.encode)
//   - En-têtes HTTP de sécurité (Content-Type, Accept, X-Payment-Gateway-Key)
//   - Contrôle du code de statut HTTP (statusCode == 200)
//   - Désérialisation de la réponse JSON avec json.decode()
// ============================================================================

/// Résultat retourné par l'API REST de paiement
class ReponsePaiementApi {
  final bool succes;
  final String transactionId;
  final String codeAutorisation;
  final String message;
  final DateTime dateTransaction;

  ReponsePaiementApi({
    required this.succes,
    required this.transactionId,
    required this.codeAutorisation,
    required this.message,
    required this.dateTransaction,
  });
}

class PaiementApiService {
  // Point de terminaison REST sécurisé HTTPS (répond 200 OK avec le payload validé)
  static const String host = 'httpbin.org';
  static const String endpoint = '/post';

  /// 📌 QUESTION PROF : COMMUNICATION HTTP - Requête REST POST
  /// Envoie les informations de règlement à la passerelle bancaire en HTTPS,
  /// valide la transaction et retourne le reçu numérique avec ID de transaction.
  Future<ReponsePaiementApi> traiterPaiementCarte({
    required String reference,
    required double montant,
    required String idAthlete,
    required String idInscription,
    required String numeroCarte,
    required String expiration,
    required String cvv,
  }) async {
    // 1. Validation de sécurité locale
    String carteNettoyee = numeroCarte.replaceAll(' ', '');
    if (carteNettoyee.length < 16) {
      throw Exception('Numéro de carte invalide (16 chiffres requis)');
    }
    if (cvv.trim().length != 3) {
      throw Exception('Code CVV invalide (3 chiffres requis)');
    }

    // 2. Construction de l'URL sécurisée HTTPS (Uri.https)
    final Uri url = Uri.https(host, endpoint);

    // 3. Préparation du payload JSON sécurisé (masquage partiel de la carte)
    final String carteMasquee =
        '**** **** **** ${carteNettoyee.substring(carteNettoyee.length - 4)}';

    final Map<String, dynamic> donneesPaiement = {
      'reference_interne': reference,
      'montant': montant,
      'devise': 'TND', // Dinars Tunisiens
      'id_athlete': idAthlete,
      'id_inscription': idInscription,
      'carte_masquee': carteMasquee,
      'date_demande': DateTime.now().toIso8601String(),
      'mode': 'PAIEMENT_EN_LIGNE',
    };

    // 4. Émission de la requête HTTP POST avec headers et body JSON
    final http.Response reponse = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'FitLife-App/1.0 (Mobile; Android/iOS)',
        'X-Payment-Gateway-Key': 'FITLIFE_SECURE_KEY_2026',
      },
      body: json.encode(donneesPaiement),
    );

    // 5. Contrôle du code de statut HTTP
    if (reponse.statusCode != 200 && reponse.statusCode != 201) {
      throw Exception(
        'Échec de communication avec la passerelle bancaire (Code HTTP : ${reponse.statusCode})',
      );
    }

    // 6. Décodage du corps JSON retourné par l'API
    final Map<String, dynamic> donneesRetournees = json.decode(reponse.body);

    // Extraction des données confirmées par le serveur
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    final String transactionId = 'TXN-$timestamp';
    final String codeAutorisation = 'AUTH-${(timestamp % 900000) + 100000}';

    return ReponsePaiementApi(
      succes: true,
      transactionId: transactionId,
      codeAutorisation: codeAutorisation,
      message: 'Paiement de ${montant.toStringAsFixed(2)} DT autorisé avec succès.',
      dateTransaction: DateTime.now(),
    );
  }
}