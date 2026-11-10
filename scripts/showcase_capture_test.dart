import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:coach_app/core/theme/app_theme.dart';
import 'package:coach_app/features/espace_sportif/presentation/donnees_apercu.dart';
import 'package:coach_app/features/espace_sportif/presentation/espaces_sportifs_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Capture du showcase des espaces sportifs', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const sdk = r'C:/Users/kuruttakao/Documents/SDK/flutter/bin/cache/artifacts/material_fonts';
    Future<void> police(String nom, String fichier) async {
      final chargeur = FontLoader(nom)..addFont(File(fichier).readAsBytes().then(ByteData.sublistView));
      await chargeur.load();
    }
    await tester.runAsync(() async {
      await police('Roboto', '$sdk/roboto-regular.ttf');
      await police('MaterialIcons', '$sdk/materialicons-regular.otf');
      await police('BarlowCondensed', 'assets/fonts/BarlowCondensed-BoldItalic.ttf');
    });
    final cle = GlobalKey();
    final scenes = <Map<String, dynamic>>[];
    final dossier = Directory('build/showcase/captures')..createSync(recursive: true);
    final donnees = DonneesApercu();
    addTearDown(donnees.dispose);
    Future<void> monter({bool gestionnaire = true}) async {
      final theme = construireTheme();
      await tester.pumpWidget(RepaintBoundary(key: cle, child: MaterialApp(
        key: UniqueKey(), debugShowCheckedModeBanner: false,
        theme: theme.copyWith(textTheme: theme.textTheme.apply(fontFamily: 'Roboto'), primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: 'Roboto')),
        home: EspacesSportifsScreen(donnees: donnees, gestionnaireInitial: gestionnaire),
      )));
      await tester.pumpAndSettle();
    }
    Future<void> photo(String chapitre, String titre, String texte, {double duree = 4}) async {
      await tester.pumpAndSettle();
      final nom = '${scenes.length.toString().padLeft(2, '0')}.png';
      await tester.runAsync(() async {
        final boundary = cle.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        File('${dossier.path}/$nom').writeAsBytesSync(png!.buffer.asUint8List());
        image.dispose();
      });
      scenes.add({'image': nom, 'chapitre': chapitre, 'titre': titre, 'texte': texte, 'duree': duree});
      expect(tester.takeException(), isNull);
    }
    Finder champ(String label) => find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText == label);
    Future<void> cliquer(Finder cible) async {
      if (cible.evaluate().isEmpty) {
        await tester.scrollUntilVisible(cible, -240, maxScrolls: 30, scrollable: find.byType(Scrollable).first);
      }
      await tester.ensureVisible(cible);
      await tester.pumpAndSettle();
      await tester.tap(cible);
      await tester.pumpAndSettle();
    }
    Future<void> saisir(String label, String valeur) async {
      await tester.ensureVisible(champ(label));
      await tester.enterText(champ(label), valeur);
      await tester.pumpAndSettle();
    }
    Future<void> atlas() async {
      await tester.scrollUntilVisible(find.text('Atlas Training Club'), 220, scrollable: find.byType(Scrollable).first);
      await cliquer(find.text('Atlas Training Club').first);
    }
    await monter();
    await photo('DÉCOUVERTE', 'Votre prochain terrain.', 'Explorer les espaces, comparer les offres et préparer sa visite.', duree: 5);
    await cliquer(find.text('Mes espaces'));
    await photo('GESTIONNAIRE', 'Tout piloter au même endroit.', 'Espaces gérés, équipements et offres actives : une vue claire du module.');
    await cliquer(find.text('Créer un espace'));
    await photo('ESPACES', 'Créer un nouveau lieu.', 'Nom, type, adresse et coordonnées facultatives dans un formulaire guidé.');
    await cliquer(find.text('Enregistrer'));
    await photo('VALIDATION', 'Des saisies contrôlées.', 'Les champs obligatoires sont signalés avant l’enregistrement.');
    await saisir('Nom *', 'FitLife Arena');
    await saisir('Adresse *', 'Sousse, Tunisie');
    await cliquer(find.byType(DropdownButtonFormField<String>).first);
    await cliquer(find.text('Salle de sport').last);
    await cliquer(find.text('Enregistrer'));
    expect(donnees.espaces.last.nom, 'FitLife Arena');
    expect(donnees.espaces.last.statut, 'INACTIF');
    await tester.scrollUntilVisible(find.text('FitLife Arena'), 240, scrollable: find.byType(Scrollable).first);
    await photo('ESPACES', 'Créer, puis activer.', 'Le nouvel espace démarre inactif. Le gestionnaire garde le contrôle de sa publication.');
    await monter();
    await atlas();
    await photo('FICHE ESPACE', 'Une fiche complète.', 'Présentation, contact, équipements, horaires, offres et abonnés.');
    await cliquer(find.text('Équipements'));
    await tester.ensureVisible(find.text('Haltères'));
    await photo('ÉQUIPEMENTS', 'Suivre le matériel.', 'Quantités et état du matériel : bon état, maintenance ou hors service.');
    await cliquer(find.byTooltip('Modifier Haltères'));
    await saisir('Quantité *', '14');
    await photo('ÉQUIPEMENTS', 'Modifier les quantités.', 'Une quantité de zéro permet de retirer un équipement des disponibilités.');
    await cliquer(find.text('Enregistrer'));
    expect(donnees.equipements.firstWhere((e) => e.nom == 'Haltères').quantite, 14);
    await cliquer(find.text('Horaires'));
    await tester.ensureVisible(find.text('Mercredi'));
    await photo('HORAIRES', 'Organiser la semaine.', 'Plusieurs créneaux par jour, avec contrôle des chevauchements.');
    await cliquer(find.text('Offres'));
    await tester.ensureVisible(find.text('Voir l’offre').first);
    await photo('OFFRES', 'Des offres lisibles.', 'Abonnement, pack ou accès à la journée. Prix en TND et durée en jours.');
    await cliquer(find.text('Voir l’offre').first);
    await photo('OFFRES', 'Afficher les conditions.', 'Prix, durée et période de vente sont réunis avant toute souscription.');
    await cliquer(find.text('Fermer'));
    await tester.pageBack(); await tester.pumpAndSettle();
    await cliquer(find.text('Abonnés'));
    await photo('ABONNÉS', 'Retrouver les abonnements.', 'Consulter les montants et les dates de chaque abonnement lié aux espaces gérés.');
    await cliquer(find.text('Détails de l’abonnement').first);
    await cliquer(find.text('Suspendre'));
    await photo('CYCLE DE VIE', 'Confirmer les actions.', 'La suspension demande une confirmation et conserve la date de fin.');
    await cliquer(find.text('Confirmer'));
    expect(donnees.abonnements.first.statut, 'SUSPENDU');
    await photo('CYCLE DE VIE', 'Suspendre et réactiver.', 'Le statut change. Le montant initial et les dates restent conservés.');
    await monter(gestionnaire: false);
    await atlas();
    await cliquer(find.text('Offres'));
    await tester.scrollUntilVisible(find.text('Voir l’offre').last, 200);
    await cliquer(find.text('Voir l’offre').last);
    await photo('ATHLÈTE', 'Choisir son offre.', 'L’athlète consulte le détail et les conditions de l’accès à la journée.');
    await cliquer(find.text('Souscrire'));
    await photo('SOUSCRIPTION', 'Valider son choix.', 'Une confirmation explicite précède la création de l’abonnement de démonstration.');
    await cliquer(find.text('Confirmer'));
    expect(donnees.abonnements.last.offre, 9);
    await tester.pageBack(); await tester.pumpAndSettle();
    await cliquer(find.text('Abonnements'));
    await cliquer(find.text('Détails de l’abonnement').last);
    await photo('MON ABONNEMENT', 'Garder une trace claire.', 'Montant à la souscription, dates inclusives et statut : les informations essentielles.');
    await cliquer(find.text('Fermer'));
    await cliquer(find.text('Localisation'));
    await photo('LOCALISATION', 'Préparer sa visite.', 'Consulter l’adresse, copier le lieu ou ouvrir son application de cartes.');
    File('build/showcase/scenes.json').writeAsStringSync(const JsonEncoder.withIndent('  ').convert(scenes));
  }, timeout: const Timeout(Duration(minutes: 5)));
}
