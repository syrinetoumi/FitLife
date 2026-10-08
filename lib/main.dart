import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'features/evenement/presentation/categories/categorie_list_screen.dart';
import 'features/evenement/presentation/evenements/evenement_list_screen.dart';
import 'home_screen.dart';
import 'features/evenement/presentation/inscription/inscription_list_screen.dart';
import 'navigation_bas_screen.dart';
import 'navigation_onglets_screen.dart';
import 'features/evenement/presentation/paiements/paiement_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.clePublishable,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Coach Sportif',
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/evenements': (context) => const EvenementListScreen(),
        '/categories': (context) => const CategorieListScreen(),
        '/inscriptions': (context) => const InscriptionListScreen(),
        '/paiements': (context) => const PaiementListScreen(),
        '/onglets': (context) => const NavigationOngletsScreen(),
        '/bas': (context) => const NavigationBasScreen(),
      },
    );
  }
}
