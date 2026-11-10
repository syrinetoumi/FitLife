import 'package:flutter/material.dart';
import 'package:coach_app/core/utils/outils.dart';
import '../data/repositories/dossier_repository.dart';
import 'consultations/consultation_list_screen.dart';
import 'programmes/programme_nutri_list_screen.dart';
import 'suivi/suivi_dashboard_screen.dart';

/// Écran principal de navigation pour le module Nutrition & Suivi.
/// Regroupe :
/// 1. Programmes Nutritionnels & Repas
/// 2. Suivi & Coordination
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
  Key _suiviKey = UniqueKey();
  Key _programmesKey = UniqueKey();
  String _idDossier = 'demo-dossier-001';

  final List<String> _titres = [
    'Programmes Nutritionnels',
    'Suivi & Coordination',
    'Consultations',
  ];

  @override
  void initState() {
    super.initState();
    _recupererIdDossier();
  }

  Future<void> _recupererIdDossier() async {
    final dossier = await DossierRepository().getDossier(widget.idAthlete);
    if (mounted) {
      setState(() {
        _idDossier = dossier.idDossier;
      });
    }
  }

  void _rafraichirSuivi() {
    setState(() {
      _suiviKey = UniqueKey();
    });
  }

  void _rafraichirProgrammes() {
    setState(() {
      _programmesKey = UniqueKey();
    });
  }

  Widget _pageCourante() {
    switch (_indexCourant) {
      case 0:
        return ProgrammeNutriListScreen(
          key: _programmesKey,
          integre: true,
          idDossier: _idDossier,
          onProgrammeModifie: _rafraichirSuivi,
        );
      case 1:
        return SuiviDashboardScreen(
          key: _suiviKey,
          integre: true,
          idAthlete: widget.idAthlete,
          onObjectifModifie: _rafraichirProgrammes,
        );
      case 2:
        return ConsultationListScreen(
          integre: true,
          idAthlete: widget.idAthlete,
        );
      default:
        return const SizedBox.shrink();
    }
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
      body: _pageCourante(),
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
            // Force le rechargement des données fraîches à chaque changement d'onglet
            if (index == 1) {
              _suiviKey = UniqueKey();
            } else if (index == 0) {
              _programmesKey = UniqueKey();
            }
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            activeIcon: Icon(Icons.restaurant_menu, color: primaryBlue),
            label: 'Programmes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            activeIcon: Icon(Icons.show_chart, color: primaryBlue),
            label: 'Suivi',
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
