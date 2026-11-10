import 'package:flutter/material.dart';
import 'package:coach_app/core/utils/outils.dart';
import 'consultations/consultation_list_screen.dart';
import 'programmes/programme_nutri_list_screen.dart';
import 'suivi/suivi_dashboard_screen.dart';

/// Écran principal de navigation pour le module Nutrition & Suivi.
/// Regroupe :
/// 1. Suivi & Coordination
/// 2. Programmes Nutritionnels & Repas
/// 3. Consultations
class NutritionNavigationScreen extends StatefulWidget {
  final String idAthlete;

  const NutritionNavigationScreen({
    super.key,
    this.idAthlete = 'demo-athlete-id',
  });

  @override
  State<NutritionNavigationScreen> createState() => _NutritionNavigationScreenState();
}

class _NutritionNavigationScreenState extends State<NutritionNavigationScreen> {
  static const Color primaryBlue = Color(0xFF3843B8);
  static const Color backgroundLight = Color(0xFFF7F8FC);

  int _indexCourant = 0;

  final List<String> _titres = [
    'Suivi & Coordination',
    'Programmes Nutritionnels',
    'Consultations',
  ];

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      SuiviDashboardScreen(integre: true, idAthlete: widget.idAthlete),
      const ProgrammeNutriListScreen(integre: true),
      ConsultationListScreen(integre: true, idAthlete: widget.idAthlete),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: Text(
          _titres[_indexCourant],
          style: const TextStyle(
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      drawer: construireDrawer(context),
      body: _pages[_indexCourant],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indexCourant,
        selectedItemColor: primaryBlue,
        unselectedItemColor: Colors.black54,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        onTap: (index) {
          setState(() {
            _indexCourant = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            activeIcon: Icon(Icons.show_chart, color: primaryBlue),
            label: 'Suivi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            activeIcon: Icon(Icons.restaurant_menu, color: primaryBlue),
            label: 'Programmes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            activeIcon: Icon(Icons.calendar_month, color: primaryBlue),
            label: 'Consultations',
          ),
        ],
      ),
    );
  }
}
