import 'package:flutter/material.dart';

import 'core/utils/outils.dart';

import 'features/evenement/data/presentation/categories/categorie_list_screen.dart';
import 'features/evenement/data/presentation/evenements/evenement_list_screen.dart';
import 'features/evenement/data/presentation/inscription/inscription_list_screen.dart';
import 'features/evenement/data/presentation/paiements/paiement_list_screen.dart';

class NavigationBasScreen extends StatefulWidget {
  const NavigationBasScreen({super.key});

  @override
  State<NavigationBasScreen> createState() =>
      _NavigationBasScreenState();
}

class _NavigationBasScreenState
    extends State<NavigationBasScreen> {

  int indexCourant = 0;

  List<String> titres = [
    'Événements',
    'Catégories',
    'Inscriptions',
    'Paiements',
  ];

  List<Widget> pages = [
    const EvenementListScreen(integre: true),
    const CategorieListScreen(integre: true),
    const InscriptionListScreen(integre: true),
    const PaiementListScreen(integre: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: Text(
          titres[indexCourant],
        ),
      ),

      // IMPORTANT: adds the ☰ button
      drawer: construireDrawer(context),

      body: pages[indexCourant],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: indexCourant,
        type: BottomNavigationBarType.fixed,

        onTap: (index) {
          setState(() {
            indexCourant = index;
          });
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Événements',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Catégories',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.how_to_reg),
            label: 'Inscriptions',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.payment),
            label: 'Paiements',
          ),
        ],
      ),
    );
  }
}