import 'package:flutter/material.dart';

import 'package:coach_app/core/utils/outils.dart';
import 'package:coach_app/features/auth/presentation/utilisateur_list_screen.dart';
import 'package:coach_app/navigation_bas_screen.dart';
import 'features/espace_sportif/presentation/notifications_screen.dart';

// Écran d'accueil principal (HomeScreen)
// Page par défaut à l'ouverture de l'application
// Présente la bienvenue et les 4 grands modules avec leurs photos
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool get admin => estUtilisateurAdmin();

  // Navigation sécurisée vers les modules
  void ouvrirModule({
    required BuildContext context,
    required String route,
    Widget? ecranDirect,
    required String nomModule,
  }) async {
    if (ecranDirect != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ecranDirect),
      );
      return;
    }

    try {
      await Navigator.pushNamed(context, route);
    } catch (_) {
      if (context.mounted) {
        afficherMessage(
          context,
          'Le module "$nomModule" est en cours de développement.',
        );
      }
    }
  }

  // Widget d'affichage de la photo avec gestion des erreurs et fallbacks
  Widget imageAvecFallback({
    required String cheminPrincipal,
    String? cheminAlternatif,
    required Color couleurFallback,
    required IconData iconeFallback,
  }) {
    return Image.asset(
      cheminPrincipal,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        if (cheminAlternatif != null) {
          return Image.asset(
            cheminAlternatif,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return containerFallback(couleurFallback, iconeFallback);
            },
          );
        }
        return containerFallback(couleurFallback, iconeFallback);
      },
    );
  }

  Widget containerFallback(Color couleur, IconData icone) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            couleur,
            couleur.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          icone,
          size: 54,
          color: Colors.white.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  // Carte moderne avec photo panoramique en haut et description en bas
  Widget carteModulePhoto({
    required BuildContext context,
    required String titre,
    required String description,
    required String cheminPhoto,
    String? cheminPhotoAlternatif,
    required IconData icone,
    required Color couleurTheme,
    required VoidCallback onTap,
    String? badgeTexte,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. BANNIÈRE PHOTO (Hauteur 145px)
            SizedBox(
              height: 145,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Photo locale
                  imageAvecFallback(
                    cheminPrincipal: cheminPhoto,
                    cheminAlternatif: cheminPhotoAlternatif,
                    couleurFallback: couleurTheme,
                    iconeFallback: icone,
                  ),

                  // Dégradé pour faire ressortir le badge
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                  ),

                  // Badge thématique en haut à gauche
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: couleurTheme,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icone,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            badgeTexte ?? 'MODULE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. CORPS TEXTE
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titre,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: couleurTheme.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                      color: couleurTheme,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Carte d'administration dédiée pour les utilisateurs
  Widget carteUtilisateursAdmin() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade700,
            Colors.deepPurple.shade900,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const UtilisateurListScreen(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Gestion des Utilisateurs',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.verified_user,
                            color: Colors.amber,
                            size: 16,
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Activer, désactiver et contrôler les rôles des comptes',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FITLIFE',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          const ClocheNotifications(),
          // Raccourci vers les utilisateurs pour l'Admin
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

          // Raccourci vers Mon Profil
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.deepPurple, size: 28),
            tooltip: 'Mon Profil',
            onPressed: () {
              ouvrirModule(
                context: context,
                route: '/profil',
                nomModule: 'Profil',
              );
            },
          ),

          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(label: Text(libelleRoleUtilisateur())),
          ),
        ],
      ),
      drawer: construireDrawer(context),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. BANNIÈRE DE BIENVENUE
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF673AB7), // DeepPurple
                  Color(0xFF512DA8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.sports_soccer,
                          color: Colors.white,
                          size: 30,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Bienvenue !',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    // Badge du profil actuel (cliquable vers Mon Profil)
                    InkWell(
                      onTap: () {
                        ouvrirModule(
                          context: context,
                          route: '/profil',
                          nomModule: 'Profil',
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              admin ? '👑 ADMIN' : '🏃 ATHLÈTE',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 10,
                              color: Colors.white70,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Plateforme tout-en-un de coaching sportif, événements, espaces et nutrition.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 2. GESTION DES UTILISATEURS (Visible pour l'admin)
          if (admin) ...[
            carteUtilisateursAdmin(),
          ],

          // 3. TITRE DE LA SECTION NOS GESTIONS
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Nos Gestions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ),

          // GESTION 1 : NOS ÉVÉNEMENTS (photo evenements.jpg)
          carteModulePhoto(
            context: context,
            titre: 'Nos Événements',
            description: admin
                ? 'Gérer les événements, catégories et inscriptions'
                : 'Explorer les événements sportifs et accéder à mon panier',
            cheminPhoto: 'assets/images/Home/evenements.jpg',
            cheminPhotoAlternatif: 'assets/images/evenements.jpg',
            icone: Icons.event_available,
            couleurTheme: Colors.orange.shade800,
            badgeTexte: 'ÉVÉNEMENTS',
            onTap: () {
              ouvrirModule(
                context: context,
                route: '/bas',
                ecranDirect: const NavigationBasScreen(),
                nomModule: 'Événements',
              );
            },
          ),

          // GESTION 2 : NOS SÉANCES ET PROGRAMMES (photo entrainement.jpg)
          carteModulePhoto(
            context: context,
            titre: 'Nos Séances & Programmes Sportifs',
            description:
            'Planifier les séances, programmes d\'entraînement et exercices',
            cheminPhoto: 'assets/images/Home/entrainement.jpg',
            cheminPhotoAlternatif: 'assets/images/entrainement.jpg',
            icone: Icons.fitness_center,
            couleurTheme: Colors.blue.shade700,
            badgeTexte: 'ENTRAÎNEMENT',
            onTap: () {
              ouvrirModule(
                context: context,
                route: '/entrainement',
                nomModule: 'Entraînement',
              );
            },
          ),

          // GESTION 3 : espaces connectés aux données persistantes.
          carteModulePhoto(
            context: context,
            titre: 'Nos Espaces Sportifs',
            description:
            'Réserver terrains, salles de sport et équipements sportifs',
            cheminPhoto: 'assets/images/Home/espaces sportif.jpg',
            cheminPhotoAlternatif: 'assets/images/Home/espaces_sportif.jpg',
            icone: Icons.stadium,
            couleurTheme: Colors.teal.shade700,
            badgeTexte: 'ESPACES',
            onTap: () {
              ouvrirModule(
                context: context,
                route: '/espaces',
                nomModule: 'Espaces Sportifs',
              );
            },
          ),

          // GESTION 4 : CONTACTER VOTRE NUTRITIONNISTE (photo nutritionniste.jpg)
          carteModulePhoto(
            context: context,
            titre: 'Contacter votre Nutritionniste',
            description:
            'Prendre rendez-vous, suivi diététique et programmes repas',
            cheminPhoto: 'assets/images/Home/nutritionniste.jpg',
            cheminPhotoAlternatif: 'assets/images/nutritionniste.jpg',
            icone: Icons.restaurant,
            couleurTheme: Colors.green.shade700,
            badgeTexte: 'NUTRITION',
            onTap: () {
              ouvrirModule(
                context: context,
                route: '/nutrition',
                nomModule: 'Nutrition',
              );
            },
          ),
        ],
      ),
    );
  }
}
