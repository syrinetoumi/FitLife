import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:coach_app/features/espace_sportif/data/repositories/espaces_repository.dart';
import 'package:coach_app/features/espace_sportif/presentation/donnees_apercu.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Enregistrement réel : identité serveur, prix exact et cache sans abonnés',
    () async {
      SharedPreferences.setMockInitialValues({});
      const uid = '11111111-1111-4111-8111-111111111111';
      final requetes = <http.Request>[];
      final espaces = <Map<String, dynamic>>[];
      final offres = <Map<String, dynamic>>[];
      bool panne = false;
      final client = SupabaseClient(
        'https://test.supabase.co',
        'public-test-key',
        httpClient: MockClient((req) async {
          requetes.add(req);
          final chemin = req.url.path;
          dynamic data;
          if (chemin == '/auth/v1/token') {
            final payload = base64Url
                .encode(
                  utf8.encode(jsonEncode({'sub': uid, 'exp': 4102444800})),
                )
                .replaceAll('=', '');
            data = {
              'access_token': 'e30.$payload.signature',
              'token_type': 'bearer',
              'expires_in': 86400,
              'refresh_token': 'test-refresh',
              'user': {
                'id': uid,
                'aud': 'authenticated',
                'role': 'authenticated',
                'email': 'manager@example.test',
                'app_metadata': {},
                'user_metadata': {},
                'created_at': '2026-01-01T00:00:00Z',
              },
            };
          } else if (panne) {
            return http.Response(
              '{"message":"offline"}',
              503,
              headers: {'content-type': 'application/json'},
              request: req,
            );
          } else if (chemin.endsWith('/rpc/rechercher_espaces')) {
            data = espaces.where((e) => e['statut'] == 'ACTIF').toList();
          } else if (chemin.endsWith('/rpc/contexte_espaces')) {
            data = {'role': 'GESTIONNAIRE_ESPACE'};
          } else if (chemin.endsWith('/espace_sportif')) {
            if (req.method == 'POST') {
              final valeurs = jsonDecode(req.body) as Map<String, dynamic>;
              expect(valeurs.containsKey('id_gestionnaire'), isFalse);
              expect(valeurs.containsKey('id_espace'), isFalse);
              espaces.add({
                ...valeurs,
                'id_espace': 101,
                'id_gestionnaire': uid,
              });
              data = {'id_espace': 101};
            } else {
              data = espaces;
            }
          } else if (chemin.endsWith('/offre')) {
            final valeurs = jsonDecode(req.body) as Map<String, dynamic>;
            expect(valeurs['prix'], '80.005');
            offres.add({...valeurs, 'id_offre': 202});
            data = {'id_offre': 202};
          } else if (chemin.endsWith('/offres_lecture')) {
            data = offres;
          } else {
            data = <dynamic>[];
          }
          return http.Response(
            jsonEncode(data),
            200,
            headers: {'content-type': 'application/json'},
            request: req,
          );
        }),
      );
      addTearDown(client.dispose);
      await client.auth.signInWithPassword(
        email: 'manager@example.test',
        password: 'local-mock-only',
      );
      final repo = EspacesRepository(client);
      addTearDown(repo.dispose);
      await repo.charger();
      await repo.enregistrerEspace(
        EspaceApercu(
          id: 20,
          nom: 'Salle',
          type: 'SALLE',
          adresse: 'Tunis',
          description: '',
          statut: 'ACTIF',
        ),
        nouveau: true,
      );
      expect(repo.espaces.single.id, 101);
      expect(repo.espaces.single.estGere, isTrue);
      await repo.enregistrerOffre(
        OffreApercu(
          id: 21,
          espace: 101,
          nom: 'Offre',
          description: '',
          type: 'ABONNEMENT',
          millimes: 80005,
          duree: 30,
          debut: DateTime(2026, 1, 1),
          statut: 'ACTIVE',
        ),
        nouveau: true,
      );
      expect(repo.offres.single.millimes, 80005);
      final prefs = await SharedPreferences.getInstance();
      final cache =
          jsonDecode(prefs.getString('espaces.catalogue.v1.$uid')!) as Map;
      expect(cache['abonnements'], isEmpty);
      expect(cache.containsKey('role'), isFalse);
      panne = true;
      expect(await repo.chargerCache(), isTrue);
      expect(repo.horsLigne, isTrue);
      expect(repo.role, isEmpty);
      expect(repo.espaces.single.estGere, isFalse);
      final avant = requetes.length;
      await expectLater(repo.souscrire(repo.offres.single), throwsStateError);
      expect(requetes.length, avant);
    },
  );
}
