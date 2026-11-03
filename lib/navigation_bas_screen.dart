import 'package:flutter/material.dart';

import 'package:coach_app/core/utils/outils.dart';
import 'package:coach_app/features/evenement/presentation/categories/categorie_list_screen.dart';
import 'package:coach_app/features/evenement/presentation/evenements/evenement_list_screen.dart';
import 'package:coach_app/features/evenement/presentation/panier/panier_screen.dart';
import 'package:coach_app/features/auth/presentation/utilisateur_list_screen.dart';

// Barre de navigation du bas (NavigationBasScreen)
// Détecte automatiquement le rôle de l'utilisateur connecté,
// avec bouton dans l'AppBar pour basculer facilement en test :
// - ADMIN   : 2 onglets ➔ Événements & Catégories (CRUD complet)
// - ATHLÈTE : 2 onglets ➔ Événements & Panier (inscriptions & paiements)
class NavigationBasScreen extends StatefulWidget {
  final bool? estAdmin;

  const NavigationBasScreen({
    super.key,
    this.estAdmin,
  });

  @override
  State<NavigationBasScreen> createState() => _NavigationBasScreenState();
}

class _NavigationBasScreenState extends State<NavigationBasScreen> {
  int indexCourant = 0;

  bool get admin => estUtilisateurAdmin();

  // Reconstruit la page à chaque changement d'onglet
  // pour que le panier recharge TOUJOURS les dernières données fraîches de Supabase !
  Widget pageCourante() {
    if (admin) {
      if (indexCourant == 0) {
        return EvenementListScreen(integre: true, estAdmin: true);
      }
      return const CategorieListScreen(integre: true);
    } else {
      if (indexCourant == 0) {
        return EvenementListScreen(integre: true, estAdmin: false);
      }
      return PanierScreen(
        key: UniqueKey(),
        integre: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> titres = admin
        ? ['Événements', 'Catégories']
        : ['Événements', 'Mon Panier'];

    final List<BottomNavigationBarItem> elementsBarre = admin
        ? const [
      BottomNavigationBarItem(
        icon: Icon(Icons.event),
        label: 'Événements',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.category),
        label: 'Catégories',
      ),
    ]
        : const [
      BottomNavigationBarItem(
        icon: Icon(Icons.event),
        label: 'Événements',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.shopping_cart),
        label: 'Panier',
      ),
    ];

    if (indexCourant >= titres.length) {
      indexCourant = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(titres[indexCourant]),
        actions: [
          // Raccourci vers la gestion des Utilisateurs quand on est Admin
          if (admin)
            IconButton(
              icon: const Icon(Icons.people, color: Colors.deepPurple),
              tooltip: 'Gérer les utilisateurs',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UtilisateurListScreen(),
                  ),
                );
              },
            ),

          // Bouton switch pour basculer en mode Admin / Athlète en 1 clic
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  basculerModeAdmin();
                  indexCourant = 0;
                });
                afficherMessage(
                  context,
                  estUtilisateurAdmin()
                      ? 'Mode Administrateur activé'
                      : 'Mode Athlète activé',
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: admin ? Colors.purple.shade100 : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: admin ? Colors.purple : Colors.blue,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      admin ? '👑 Admin' : '🏃 Athlète',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: admin
                            ? Colors.purple.shade900
                            : Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.swap_horiz,
                      size: 14,
                      color:
                      admin ? Colors.purple.shade900 : Colors.blue.shade900,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: construireDrawer(context),
      body: pageCourante(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: indexCourant,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        onTap: (index) {
          setState(() {
            indexCourant = index;
          });
        },
        items: elementsBarre,
      ),
    );
  }
}
