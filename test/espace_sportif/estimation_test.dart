import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coach_app/features/espace_sportif/presentation/estimation_trajet_dialog.dart';
import 'package:coach_app/features/espace_sportif/data/services/position_appareil_service.dart';

void main() {
  testWidgets(
    'Le trajet est calculé automatiquement sans champs de coordonnées',
    (tester) async {
      final reponse = Completer<Map<String, dynamic>>();
      final profils = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: EstimationTrajetDialog(
            destination: 'Atlas',
            estimer: (profil) {
              profils.add(profil);
              return reponse.future;
            },
            ouvrirReglages: (_) async => true,
          ),
        ),
      );
      expect(profils, ['foot-walking']);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Localisation et calcul du trajet…'), findsOneWidget);
      reponse.complete({'distance': 8250, 'duree': 5940});
      await tester.pumpAndSettle();
      expect(find.text('8.3 km · 99 min environ'), findsOneWidget);
      await tester.tap(find.text('Actualiser ma position'));
      await tester.pumpAndSettle();
      expect(profils.length, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Une permission refusée propose les réglages et permet de réessayer',
    (tester) async {
      bool autorise = false;
      ReglagePosition? reglage;
      await tester.pumpWidget(
        MaterialApp(
          home: EstimationTrajetDialog(
            destination: 'Atlas',
            estimer: (_) async {
              if (!autorise) {
                throw const ErreurPosition(
                  'Autorisez la localisation.',
                  reglage: ReglagePosition.application,
                );
              }
              return {'distance': 1200, 'duree': 600};
            },
            ouvrirReglages: (r) async {
              reglage = r;
              return true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Autorisez la localisation.'), findsOneWidget);
      await tester.tap(find.text('Ouvrir les réglages'));
      await tester.pumpAndSettle();
      expect(reglage, ReglagePosition.application);
      autorise = true;
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();
      expect(find.text('1.2 km · 10 min environ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
