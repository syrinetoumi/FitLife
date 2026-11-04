import 'package:supabase_flutter/supabase_flutter.dart';

class LocalisationService {
  LocalisationService(this.client);
  final SupabaseClient client;

  // Le client appelle la fonction authentifiée ; les clés des fournisseurs restent sur le serveur.
  Future<Map<String, dynamic>> _appeler(Map<String, dynamic> body) async {
    try {
      final reponse = await client.functions.invoke(
        'espaces-localisation',
        body: body,
      );
      return Map<String, dynamic>.from(reponse.data as Map);
    } on FunctionException catch (erreur) {
      final details = erreur.details;
      throw StateError(
        details is Map && details['erreur'] is String
            ? details['erreur'] as String
            : 'Service non disponible. Vérifiez la configuration serveur.',
      );
    }
  }

  // L’attribution suit les résultats pour afficher les sources du fournisseur réellement utilisé.
  Future<({List<Map<String, dynamic>> resultats, String attribution})> geocoder(
    String recherche,
  ) async {
    final donnees = await _appeler({
      'action': 'geocoder',
      'recherche': recherche,
    });
    return (
      resultats: (donnees['resultats'] as List)
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList(),
      attribution: donnees['attribution'] as String? ?? 'OpenStreetMap',
    );
  }

  Future<Map<String, dynamic>> itineraire(
    int espace,
    double latitude,
    double longitude,
    String profil,
  ) => _appeler({
    'action': 'itineraire',
    'espace': espace,
    'depart': [longitude, latitude],
    'profil': profil,
  });
}
