import 'package:coach_app/core/theme/app_theme.dart';
import 'package:coach_app/features/espace_sportif/presentation/donnees_apercu.dart';
import 'package:coach_app/features/espace_sportif/presentation/espaces_sportifs_screen.dart';
import 'package:coach_app/features/espace_sportif/presentation/formulaires_espaces.dart';
import 'package:coach_app/features/espace_sportif/presentation/localisation_espace.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> monter(
  WidgetTester tester,
  DonneesApercu donnees, {
  Size taille = const Size(1200, 1000),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: construireTheme(),
      home: EspacesSportifsScreen(donnees: donnees),
    ),
  );
  await tester.pumpAndSettle();
}

Finder champLabel(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Future<void> ouvrirAtlas(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Atlas Training Club'),
    180,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Atlas Training Club'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Atlas Training Club').first);
  await tester.pumpAndSettle();
}

void main() {
  Future<void> formulaire(
    WidgetTester tester,
    VoidCallback Function(BuildContext) ouvrir,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: construireTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: ouvrir(context),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
  }

  Future<void> saisir(WidgetTester tester, String label, String texte) async {
    await tester.ensureVisible(champLabel(label));
    await tester.pumpAndSettle();
    await tester.enterText(champLabel(label), texte);
  }

  testWidgets(
    'Création d’espace : champs obligatoires, coordonnées et statut initial',
    (tester) async {
      final donnees = DonneesApercu();
      addTearDown(donnees.dispose);
      final nombre = donnees.espaces.length;
      await formulaire(
        tester,
        (context) =>
            () => editerEspace(context, donnees),
      );
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(donnees.espaces.length, nombre);
      expect(find.text('Ce champ est obligatoire.'), findsNWidgets(2));
      await saisir(tester, 'Nom *', 'Espace de validation');
      await saisir(tester, 'Adresse *', 'Tunis');
      await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salle de sport').last);
      await tester.pumpAndSettle();
      await saisir(tester, 'Latitude', '95');
      await saisir(tester, 'Longitude', '10.2');
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(donnees.espaces.length, nombre);
      expect(find.text('Valeur attendue entre -90 et 90.'), findsOneWidget);
      await saisir(tester, 'Latitude', '36.8');
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(donnees.espaces.last.nom, 'Espace de validation');
      expect(donnees.espaces.last.statut, 'INACTIF');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Une offre journée exige un jour et conserve trois décimales', (
    tester,
  ) async {
    final donnees = DonneesApercu();
    addTearDown(donnees.dispose);
    await formulaire(
      tester,
      (context) =>
          () => editerOffre(context, donnees, donnees.espaces.first),
    );
    await saisir(tester, 'Nom *', 'Pass validation');
    await tester.ensureVisible(
      find.byType(DropdownButtonFormField<String>).first,
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accès à la journée').last);
    await tester.pumpAndSettle();
    await saisir(tester, 'Prix en TND *', '12,005');
    await saisir(tester, 'Durée en jours *', '2');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(
      find.text('Un accès à la journée dure exactement 1 jour.'),
      findsOneWidget,
    );
    await saisir(tester, 'Durée en jours *', '1');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(donnees.offres.last.millimes, 12005);
    expect(donnees.offres.last.duree, 1);
    expect(donnees.offres.last.statut, 'INACTIVE');
  });

  testWidgets(
    'Le gestionnaire suspend puis réactive sans prolonger les dates',
    (tester) async {
      final donnees = DonneesApercu();
      addTearDown(donnees.dispose);
      final abonnement = donnees.abonnements.first;
      final fin = abonnement.fin;
      await monter(tester, donnees);
      await tester.tap(find.text('Abonnés'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Détails de l’abonnement').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Suspendre'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmer'));
      await tester.pumpAndSettle();
      expect(abonnement.statut, 'SUSPENDU');
      await tester.tap(find.text('Réactiver'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmer'));
      await tester.pumpAndSettle();
      expect(abonnement.statut, 'ACTIF');
      expect(abonnement.fin, fin);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Le sélecteur horaire est disponible sans perdre la saisie', (
    tester,
  ) async {
    final donnees = DonneesApercu();
    addTearDown(donnees.dispose);
    await formulaire(
      tester,
      (context) =>
          () => editerHoraire(context, donnees, donnees.espaces.first),
    );
    await tester.tap(find.byTooltip('Choisir l’heure : Ouverture *'));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(TimePickerDialog),
        matching: find.text('Annuler'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(champLabel('Ouverture *')).controller!.text,
      '08:00',
    );
  });

  test('Carte et trajet utilisent les coordonnées ou une adresse encodée', () {
    final donnees = DonneesApercu();
    addTearDown(donnees.dispose);
    expect(
      lienCarte(donnees.espaces.first).queryParameters['query'],
      '36.837,10.246',
    );
    final lien = lienItineraire(
      donnees.espaces.last,
      depart: 'Place de l’Indépendance, Tunis',
      mode: 'driving',
    );
    expect(lien.queryParameters['destination'], donnees.espaces.last.adresse);
    expect(lien.queryParameters['origin'], 'Place de l’Indépendance, Tunis');
    expect(lien.queryParameters['travelmode'], 'driving');
    expect(lien.queryParameters['api'], '1');
    expect(
      lienItineraire(donnees.espaces.first).queryParameters
          .containsKey('origin'),
      isFalse,
    );
  });

  testWidgets(
    'Une carte impossible à ouvrir propose une récupération du lien',
    (tester) async {
      final donnees = DonneesApercu();
      addTearDown(donnees.dispose);
      const channel = MethodChannel('plugins.flutter.io/url_launcher');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => false);
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: construireTheme(),
          home: Scaffold(
            body: LocalisationEspace(espace: donnees.espaces.first),
          ),
        ),
      );
      await tester.tap(find.text('Voir sur la carte'));
      await tester.pumpAndSettle();
      expect(
        find.text('Impossible d’ouvrir la carte. Vous pouvez copier le lien.'),
        findsOneWidget,
      );
      expect(find.text('Copier'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test('Les prix restent exacts et les dates impossibles sont refusées', () {
    expect(lireMillimes('80,005'), 80005);
    expect(lireMillimes('0.001'), 1);
    expect(lireMillimes('-1'), isNull);
    expect(lireMillimes('1.0001'), isNull);
    expect(lireDateApercu('2026-02-30'), isNull);
    expect(lireHeure('24:00'), isNull);
  });

  testWidgets('Catalogue et détails restent utilisables sur mobile', (
    tester,
  ) async {
    final donnees = DonneesApercu();
    addTearDown(donnees.dispose);
    await monter(tester, donnees, taille: const Size(390, 844));
    expect(tester.takeException(), isNull);
    await ouvrirAtlas(tester);
    await tester.scrollUntilVisible(
      find.text('Équipements'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Équipements'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Haltères'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Haltères'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Un formulaire refuse un équipement sans nom ou quantité valide',
    (tester) async {
      final donnees = DonneesApercu();
      addTearDown(donnees.dispose);
      await monter(tester, donnees);
      await ouvrirAtlas(tester);
      await tester.tap(find.text('Équipements'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ajouter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(find.text('Ce champ est obligatoire.'), findsOneWidget);
      expect(find.text('Saisissez un entier positif ou nul.'), findsOneWidget);
      await tester.enterText(champLabel('Nom *'), 'Vélo');
      await tester.enterText(champLabel('Quantité *'), '3');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bon état').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(donnees.equipements.last.nom, 'Vélo');
      expect(donnees.equipements.last.quantite, 3);
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Les horaires refusent un chevauchement et acceptent un créneau adjacent',
    (tester) async {
      final donnees = DonneesApercu();
      addTearDown(donnees.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: construireTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () =>
                    editerHoraire(context, donnees, donnees.espaces.first),
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(
        find.text('Ce créneau chevauche un horaire existant.'),
        findsOneWidget,
      );
      await tester.enterText(champLabel('Ouverture *'), '22:00');
      await tester.enterText(champLabel('Fermeture *'), '23:00');
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(donnees.horaires.last.debut, 22 * 60);
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets(
    'L’athlète souscrit puis annule sans modifier le prix historique',
    (tester) async {
      final donnees = DonneesApercu();
      addTearDown(donnees.dispose);
      await monter(tester, donnees);
      await tester.tap(find.byType(DropdownButton<bool>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Démo : athlète').last);
      await tester.pumpAndSettle();
      expect(find.text('Mes espaces'), findsNothing);
      await ouvrirAtlas(tester);
      expect(find.text('Modifier l’espace'), findsNothing);
      await tester.tap(find.text('Offres'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Voir l’offre').last, 180);
      await tester.tap(find.text('Voir l’offre').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Souscrire en démo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmer'));
      await tester.pumpAndSettle();
      final abonnement = donnees.abonnements.last;
      expect(abonnement.offre, 9);
      expect(abonnement.millimes, 15000);
      expect(abonnement.fin, abonnement.debut);
      donnees.offres.firstWhere((o) => o.id == 9).millimes = 20000;
      expect(abonnement.millimes, 15000);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abonnements'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Détails de l’abonnement').last);
      await tester.pumpAndSettle();
      expect(find.text('Suspendre'), findsNothing);
      await tester.tap(find.text('Annuler l’abonnement'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmer'));
      await tester.pumpAndSettle();
      expect(abonnement.statut, 'ANNULE');
      expect(find.text('Annuler l’abonnement'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'Une souscription en double est refusée et l’expiration est effective',
    () {
      final donnees = DonneesApercu();
      addTearDown(donnees.dispose);
      final offre = donnees.offres.first;
      final total = donnees.abonnements.length;
      donnees.souscrire(offre);
      expect(donnees.abonnements.length, total);
      offre.fin = jourLocal().subtract(const Duration(days: 1));
      expect(offre.statutEffectif, 'EXPIREE');
      expect(offre.disponible, isFalse);
    },
  );
}
