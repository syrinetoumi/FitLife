import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:coach_app/features/auth/presentation/utilisateur_list_screen.dart';

// Afficher un message en bas de l'écran.
void afficherMessage(BuildContext context, String texte) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(texte),
    ),
  );
}

// Convertir "26/09/2026" en DateTime.
DateTime? lireDate(String texte) {
  List<String> parties = texte.trim().split('/');

  if (parties.length != 3) {
    return null;
  }

  int? jour = int.tryParse(parties[0]);
  int? mois = int.tryParse(parties[1]);
  int? annee = int.tryParse(parties[2]);

  if (jour == null || mois == null || annee == null) {
    return null;
  }

  if (annee < 2000 || annee > 2100) {
    return null;
  }

  DateTime date = DateTime(annee, mois, jour);

  if (date.day != jour || date.month != mois || date.year != annee) {
    return null;
  }

  return date;
}

// Convertir DateTime en "26/09/2026".
String afficherDate(DateTime date) {
  String jour = date.day.toString().padLeft(2, '0');
  String mois = date.month.toString().padLeft(2, '0');

  return '$jour/$mois/${date.year}';
}

// Convertir "8:5" en "08:05".
String? lireHeure(String texte) {
  List<String> parties = texte.trim().split(':');

  if (parties.length != 2) {
    return null;
  }

  int? heure = int.tryParse(parties[0]);
  int? minute = int.tryParse(parties[1]);

  if (heure == null || minute == null) {
    return null;
  }

  if (heure < 0 || heure > 23 || minute < 0 || minute > 59) {
    return null;
  }

  return '${heure.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')}';
}

// ================================================================
// DÉTECTION DU RÔLE (ADMIN vs ATHLÈTE)
// ================================================================
// Variable globale permettant de basculer en mode Admin en 1 clic pour vos tests
bool modeAdminForce = false;

void basculerModeAdmin() {
  modeAdminForce = !modeAdminForce;
}

// Détecte si l'utilisateur est Admin (via le switch de test OU Supabase)
bool estUtilisateurAdmin() {
  // 1. Priorité au switch de test (pour tester sans compte admin)
  if (modeAdminForce) {
    return true;
  }

  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return false;
    }

    // 2. Métadonnées Supabase (ex: {"role": "admin"})
    final dynamic role = user.userMetadata?['role'];
    if (role != null && role.toString().toLowerCase() == 'admin') {
      return true;
    }

    // 3. Fallback pratique par e-mail
    final email = user.email?.toLowerCase() ?? '';
    if (email.contains('admin')) {
      return true;
    }

    return false;
  } catch (_) {
    return false;
  }
}

// Élément cliquable du Drawer.
Widget elementMenu(
    BuildContext context,
    String titre,
    IconData icone,
    String route,
    ) {
  return InkWell(
    onTap: () {
      Navigator.pop(context);

      // Si l'admin clique sur Utilisateurs, navigation directe sécurisée
      if (route == '/utilisateurs') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const UtilisateurListScreen(),
          ),
        );
        return;
      }

      Navigator.pushReplacementNamed(
        context,
        route,
      );
    },
    child: Container(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(
            icone,
            color: Colors.deepPurple,
          ),
          Container(
            margin: const EdgeInsets.only(left: 14),
            child: Text(
              titre,
              style: const TextStyle(
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// Drawer commun à tous les écrans.
Widget construireDrawer(BuildContext context) {
  return Drawer(
    child: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // HEADER
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.deepPurple,
          child: const Column(
            children: [
              Icon(
                Icons.sports_soccer,
                size: 48,
                color: Colors.white,
              ),
              Text(
                'FITLIFE',
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Coaching sportif',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),

        // ACCUEIL EN PREMIER
        Container(
          margin: const EdgeInsets.only(top: 15),
          child: Card(
            child: elementMenu(
              context,
              'Accueil',
              Icons.home,
              '/',
            ),
          ),
        ),

        // BLOC GESTION
        Container(
          margin: const EdgeInsets.only(
            top: 20,
            bottom: 8,
          ),
          child: const Text(
            'GESTION',
            style: TextStyle(
              fontSize: 14,
              color: Colors.deepPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        Card(
          child: Column(
            children: [
              elementMenu(
                context,
                'Événements',
                Icons.event,
                '/bas',
              ),
              // Gestion des comptes : visible UNIQUEMENT pour l'Admin
              if (estUtilisateurAdmin())
                elementMenu(
                  context,
                  'Utilisateurs',
                  Icons.people,
                  '/utilisateurs',
                ),
            ],
          ),
        ),

        // BLOC ENTRAÎNEMENT
        Container(
          margin: const EdgeInsets.only(
            top: 20,
            bottom: 8,
          ),
          child: const Text(
            'ENTRAÎNEMENT',
            style: TextStyle(
              fontSize: 14,
              color: Colors.deepPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        Card(
          child: Column(
            children: [
              elementMenu(
                context,
                'Entraînement',
                Icons.fitness_center,
                '/entrainement',
              ),
            ],
          ),
        ),

        // BLOC NAVIGATION
        Container(
          margin: const EdgeInsets.only(
            top: 20,
            bottom: 8,
          ),
          child: const Text(
            'NAVIGATION',
            style: TextStyle(
              fontSize: 14,
              color: Colors.deepPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        Card(
          child: Column(
            children: [
              elementMenu(
                context,
                'Navigation en haut',
                Icons.tab,
                '/onglets',
              ),
              elementMenu(
                context,
                'Navigation en bas',
                Icons.vertical_align_bottom,
                '/bas',
              ),
            ],
          ),
        ),

        // DÉCONNEXION
        Container(
          margin: const EdgeInsets.only(top: 15),
          child: Card(
            child: InkWell(
              onTap: () async {
                try {
                  await Supabase.instance.client.auth.signOut();
                } catch (_) {}
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/connexion');
                }
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                child: const Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 14),
                    Text(
                      'Se déconnecter',
                      style: TextStyle(fontSize: 15, color: Colors.red),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
