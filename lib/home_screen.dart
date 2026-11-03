import 'package:flutter/material.dart';

import 'package:coach_app/core/utils/outils.dart';
import 'package:coach_app/features/auth/presentation/utilisateur_list_screen.dart';
import 'package:coach_app/navigation_bas_screen.dart';

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
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icone, size: 14, color: Colors.white),
                          const SizedBox(width: 6),
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

            // 2. TEXTE ET ACTION (Fond blanc / clair)
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
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Bouton rond avec flèche
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: couleurTheme.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 15,
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

  // Carte pour la gestion des utilisateurs (Visible uniquement par l'admin)
  Widget carteUtilisateursAdmin() {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.deepPurple.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UtilisateurListScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Colors.deepPurple,
                      Color(0xFF7E57C2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.people_alt,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Gestion des Utilisateurs',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'ADMIN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Activer ou désactiver les comptes des athlètes et coachs',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 15,
                color: Colors.grey.shade400,
              ),
            ],
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
          'FitLife',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
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

          // Bouton switch pour basculer Admin / Athlète en 1 clic
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  basculerModeAdmin();
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
                    // Badge du profil actuel
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: Text(
                        admin ? '👑 ADMIN' : '🏃 ATHLÈTE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
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

          // GESTION 3 : NOS ESPACES SPORTIFS (photo espaces sportif.jpg)
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
