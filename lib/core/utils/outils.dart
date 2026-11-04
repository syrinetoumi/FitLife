import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:coach_app/features/auth/presentation/utilisateur_list_screen.dart';

// Afficher un message en bas de l'écran.
void afficherMessage(BuildContext context, String texte) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texte)));
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

// Le rôle provient du profil serveur, jamais d’un e-mail ou de métadonnées modifiables.
String? _utilisateurRole;
String? _roleVerifie;
Future<bool> actualiserRoleUtilisateur() async {
  _utilisateurRole = null;
  _roleVerifie = null;
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return false;
  final profil = await client
      .from('profiles')
      .select('role,actif')
      .eq('id', user.id)
      .maybeSingle();
  if (profil == null || profil['actif'] != true) return false;
  _utilisateurRole = user.id;
  _roleVerifie = profil['role'] as String?;
  return true;
}

bool estUtilisateurAdmin() {
  try {
    return _utilisateurRole == Supabase.instance.client.auth.currentUser?.id &&
        _roleVerifie == 'ADMIN';
  } catch (_) {
    return false;
  }
}

String libelleRoleUtilisateur() {
  try {
    if (_utilisateurRole != Supabase.instance.client.auth.currentUser?.id) {
      return 'Compte';
    }
    return switch (_roleVerifie) {
      'ADMIN' => 'Administrateur',
      'GESTIONNAIRE_ESPACE' => 'Gestionnaire',
      'COACH' => 'Coach',
      'NUTRITIONNISTE' => 'Nutritionniste',
      'ATHLETE' => 'Athlète',
      _ => 'Compte',
    };
  } catch (_) {
    return 'Compte';
  }
}

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

      Navigator.pushReplacementNamed(context, route);
    },
    child: Container(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icone, color: Colors.deepPurple),
          Container(
            margin: const EdgeInsets.only(left: 14),
            child: Text(titre, style: const TextStyle(fontSize: 15)),
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
              Icon(Icons.sports_soccer, size: 48, color: Colors.white),
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
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
        ),

        // ACCUEIL EN PREMIER
        Container(
          margin: const EdgeInsets.only(top: 15),
          child: Card(child: elementMenu(context, 'Accueil', Icons.home, '/')),
        ),

        // BLOC GESTION
        Container(
          margin: const EdgeInsets.only(top: 20, bottom: 8),
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
              elementMenu(context, 'Événements', Icons.event, '/bas'),
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
          margin: const EdgeInsets.only(top: 20, bottom: 8),
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
          margin: const EdgeInsets.only(top: 20, bottom: 8),
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
              elementMenu(context, 'Navigation en haut', Icons.tab, '/onglets'),
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
