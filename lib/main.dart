import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/utils/outils.dart';
import 'features/espace_sportif/presentation/espaces_connectes_screen.dart';
import 'features/evenement/presentation/categories/categorie_list_screen.dart';
import 'features/evenement/presentation/evenements/evenement_list_screen.dart';
import 'home_screen.dart';
import 'features/evenement/presentation/inscription/inscription_list_screen.dart';
import 'navigation_bas_screen.dart';
import 'navigation_onglets_screen.dart';
import 'features/evenement/presentation/paiements/paiement_list_screen.dart';
import 'features/entrainement/presentation/entrainement_screen.dart';
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
  if (Supabase.instance.client.auth.currentSession != null) {
    try {
      if (!await actualiserRoleUtilisateur().timeout(
        const Duration(seconds: 10),
      )) {
        await Supabase.instance.client.auth.signOut();
      }
    } catch (_) {
      // La navigation reste disponible en cas de réseau absent ; les droits restent fermés.
    }
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
        '/espaces': (context) => const EspacesConnectesScreen(),
        '/espaces-sportifs': (context) => const EspacesConnectesScreen(),
        '/evenements': (context) => const EvenementListScreen(),
        '/categories': (context) => const CategorieListScreen(),
        '/inscriptions': (context) => const InscriptionListScreen(),
        '/paiements': (context) => const PaiementListScreen(),
        '/onglets': (context) => const NavigationOngletsScreen(),
        '/bas': (context) => const NavigationBasScreen(),
        '/connexion': (context) => const LoginScreen(),
        '/entrainement': (context) => const EntrainementScreen(),
        '/inscription': (context) => const RegisterScreen(),
        '/mot-de-passe-oublie': (context) => const ForgotPasswordScreen(),
      },
    );
  }
}
