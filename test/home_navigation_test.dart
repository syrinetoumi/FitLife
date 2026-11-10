import 'package:coach_app/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('La carte espaces de l’accueil ouvre la route intégrée', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: const HomeScreen(),
        routes: {
          '/espaces': (_) =>
              const Scaffold(body: Text('Module espaces connecté')),
        },
      ),
    );
    await tester.pumpAndSettle();
    final carte = find.text('Nos Espaces Sportifs');
    await tester.ensureVisible(carte);
    await tester.tap(carte);
    await tester.pumpAndSettle();
    expect(find.text('Module espaces connecté'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
