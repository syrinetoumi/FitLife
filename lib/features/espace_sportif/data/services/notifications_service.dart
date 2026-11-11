import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Invalide les cloches visibles après une souscription ou une lecture.
final notificationsChangees = ValueNotifier<int>(0);

class NotificationsService {
  NotificationsService(this.client);
  final SupabaseClient client;

  Future<Map<String, dynamic>> _appeler(Map<String, dynamic> body) async {
    try {
      final resultat = await client.functions.invoke(
        'espaces-notifications',
        body: body,
      );
      return Map<String, dynamic>.from(resultat.data as Map);
    } on FunctionException catch (erreur) {
      final details = erreur.details;
      throw StateError(
        details is Map && details['erreur'] is String
            ? details['erreur'] as String
            : 'Notifications indisponibles. Réessayez dans un instant.',
      );
    }
  }

  Future<Map<String, dynamic>> lister() => _appeler({'action': 'lister'});

  Future<void> synchroniser() async {
    await _appeler({'action': 'synchroniser'});
    notificationsChangees.value++;
  }

  Future<void> lire(String id) async {
    await _appeler({'action': 'lire', 'id': id});
    notificationsChangees.value++;
  }
}
