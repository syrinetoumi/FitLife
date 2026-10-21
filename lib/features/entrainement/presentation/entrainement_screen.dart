import 'package:flutter/material.dart';

import 'package:coach_app/core/utils/outils.dart';
import 'exploration_musculaire/body_screen.dart';
import 'programmes/programme_list_screen.dart';

class EntrainementScreen extends StatefulWidget {
  const EntrainementScreen({super.key});

  @override
  State<EntrainementScreen> createState() => _EntrainementScreenState();
}

class _EntrainementScreenState extends State<EntrainementScreen> {
  int indexCourant = 0;

  final List<String> titres = [
    'Exploration musculaire',
    'Programmes',
    // à ajouter : 'Séances'
  ];

  final List<Widget> pages = const [
    BodyScreen(integre: true),
    ProgrammeListScreen(integre: true),
    // à ajouter : SeanceListScreen(integre: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titres[indexCourant])),
      drawer: construireDrawer(context),
      body: pages[indexCourant],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: indexCourant,
        onTap: (index) {
          setState(() {
            indexCourant = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.accessibility_new),
            label: 'Corps',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Programmes',
          ),
          // à ajouter : BottomNavigationBarItem(icon: Icon(Icons.event_available), label: 'Séances'),
        ],
      ),
    );
  }
}