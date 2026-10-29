import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import 'presentation/nutrition_navigation_screen.dart';

/// Standalone test runner for the Nutrition & Suivi module.
/// Initializes Supabase gracefully with automatic fallback to offline demo mode.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.clePublishable,
    );
  } catch (e) {
    // If Supabase is offline or credentials not set, the app will still run with demo data!
    debugPrint('Note: Supabase non initialisé ou hors-ligne ($e). Mode démo actif.');
  }

  runApp(const NutritionAppPreview());
}

class NutritionAppPreview extends StatelessWidget {
  const NutritionAppPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FitLife - Nutrition & Suivi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        cardTheme: const CardThemeData(
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 6),
        ),
      ),
      home: const NutritionNavigationScreen(),
    );
  }
}
