import 'package:flutter/material.dart';

import 'core/utils/outils.dart';

import 'features/evenement/presentation/categories/categorie_list_screen.dart';
import 'features/evenement/presentation/evenements/evenement_list_screen.dart';
import 'features/evenement/presentation/inscription/inscription_list_screen.dart';
import 'features/evenement/presentation/paiements/paiement_list_screen.dart';

class NavigationOngletsScreen extends StatelessWidget {
  const NavigationOngletsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,

      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Navigation en haut',
          ),

          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Événements'),
              Tab(text: 'Catégories'),
              Tab(text: 'Inscriptions'),
              Tab(text: 'Paiements'),
            ],
          ),
        ),

        // IMPORTANT: displays the ☰ button
        drawer: construireDrawer(context),

        body: const TabBarView(
          children: [
            EvenementListScreen(integre: true),
            CategorieListScreen(integre: true),
            InscriptionListScreen(integre: true),
            PaiementListScreen(integre: true),
          ],
        ),
      ),
    );
  }
}
