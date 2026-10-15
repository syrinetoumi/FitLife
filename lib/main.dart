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
import 'features/entrainement/presentation/exploration_musculaire/body_screen.dart';
import 'features/entrainement/presentation/programmes/programme_list_screen.dart';
import 'features/entrainement/presentation/entrainement_navigation_bas_screen.dart';
import 'features/entrainement/presentation/entrainement_navigation_onglets_screen.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/auth/presentation/forgot_password_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.clePublishable,
  );
  // Connexion de test : active seulement si les valeurs sont fournies au lancement.
  const emailTest = String.fromEnvironment('DEV_EMAIL');
  const mdpTest = String.fromEnvironment('DEV_PASSWORD');

  if (emailTest.isNotEmpty && mdpTest.isNotEmpty) {
    await Supabase.instance.client.auth.signInWithPassword(
      email: emailTest,
      password: mdpTest,
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FitLife',
      theme: construireTheme(),
      initialRoute: Supabase.instance.client.auth.currentSession == null
          ? '/connexion'
          : '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/evenements': (context) => const EvenementListScreen(),
        '/categories': (context) => const CategorieListScreen(),
        '/inscriptions': (context) => const InscriptionListScreen(),
        '/paiements': (context) => const PaiementListScreen(),
        '/onglets': (context) => const NavigationOngletsScreen(),
        '/bas': (context) => const NavigationBasScreen(),
        '/corps': (context) => const BodyScreen(),
        '/programmes': (context) => const ProgrammeListScreen(),
        '/entrainement-bas': (context) => const EntrainementNavigationBasScreen(),
        '/entrainement-onglets': (context) =>
        const EntrainementNavigationOngletsScreen(),
        '/connexion': (context) => const LoginScreen(),
        '/inscription': (context) => const RegisterScreen(),
        '/mot-de-passe-oublie': (context) => const ForgotPasswordScreen(),
      },

    );
  }
}
