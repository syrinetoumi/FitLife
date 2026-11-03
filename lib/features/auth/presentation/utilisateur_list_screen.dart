import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:coach_app/core/utils/alertes.dart';
import 'package:coach_app/core/utils/outils.dart';
import '../models/profil.dart';
import '../repositories/profil_repository.dart';

// Écran d'administration : Gestion des comptes utilisateurs
// Permet à l'Admin d'activer ou désactiver les comptes des athlètes et coachs.
class UtilisateurListScreen extends StatefulWidget {
  const UtilisateurListScreen({super.key});

  @override
  State<UtilisateurListScreen> createState() => _UtilisateurListScreenState();
}

class _UtilisateurListScreenState extends State<UtilisateurListScreen> {
  final ProfilRepository profilRepository = ProfilRepository();
  final TextEditingController rechercheController = TextEditingController();

  List<Profil> profils = [];
  bool chargement = true;
  String recherche = '';

  @override
  void initState() {
    super.initState();
    chargerProfils();
  }

  @override
  void dispose() {
    rechercheController.dispose();
    super.dispose();
  }

  Future<void> chargerProfils() async {
    try {
      List<Profil> resultat = await profilRepository.getProfils();

      if (!mounted) return;

      setState(() {
        profils = resultat;
        chargement = false;
      });
    } catch (erreur) {
      if (mounted) {
        setState(() {
          chargement = false;
        });
        afficherMessage(context, 'Erreur de chargement : $erreur');
      }
    }
  }

  Future<void> basculerStatut(Profil profil) async {
    final bool nouveauStatut = !profil.actif;
    final String action = nouveauStatut ? 'Réactiver' : 'Désactiver';

    final String message = profil.actif
        ? 'Désactiver le compte de "${profil.nomComplet}" ? L\'utilisateur ne pourra plus se connecter.'
        : 'Réactiver le compte de "${profil.nomComplet}" ?';

    bool confirme = await confirmerAction(
      context,
      titre: '$action le compte',
      message: message,
      libelleBouton: action,
      libelleRefus: 'Annuler',
    );

    if (!confirme) return;

    // 1. Mise à jour immédiate visuelle (UI optimiste)
    setState(() {
      final index = profils.indexWhere((p) => p.id == profil.id);
      if (index != -1) {
        profils[index] = Profil(
          id: profil.id,
          nom: profil.nom,
          prenom: profil.prenom,
          role: profil.role,
          telephone: profil.telephone,
          photo: profil.photo,
          actif: nouveauStatut,
        );
      }
    });

    try {
      // 2. Envoi à la base Supabase
      await profilRepository.changerStatutActif(profil.id, nouveauStatut);

      if (mounted) {
        afficherMessage(
          context,
          'Compte de ${profil.nomComplet} ${nouveauStatut ? 'réactivé' : 'désactivé'}.',
        );
      }

      // 3. Rechargement des données fraîches depuis Supabase
      await chargerProfils();
    } catch (erreur) {
      // En cas d'échec, on remet l'affichage d'origine
      await chargerProfils();
      if (mounted) {
        afficherAlerteErreur(
          context,
          titre: 'Opération impossible',
          message: '$erreur',
        );
      }
    }
  }

  Color couleurRole(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return Colors.deepPurple;
      case 'COACH':
        return Colors.orange.shade800;
      case 'ATHLETE':
        return Colors.blue.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Widget carteProfil(Profil profil) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final bool estMonCompte =
    (currentUserId != null && currentUserId == profil.id);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: profil.actif ? Colors.green.shade200 : Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar avec initiale
            CircleAvatar(
              radius: 24,
              backgroundColor: couleurRole(profil.role).withValues(alpha: 0.15),
              child: Text(
                profil.nomComplet.isNotEmpty
                    ? profil.nomComplet[0].toUpperCase()
                    : 'U',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: couleurRole(profil.role),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Informations utilisateur
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profil.nomComplet,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Badge Rôle
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                          couleurRole(profil.role).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          profil.role,
                          style: TextStyle(
                            color: couleurRole(profil.role),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Badge Actif / Inactif
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: profil.actif
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          profil.actif ? 'ACTIF' : 'DÉSACTIVÉ',
                          style: TextStyle(
                            color: profil.actif
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (profil.telephone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '📞 ${profil.telephone}',
                      style:
                      const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ],
              ),
            ),

            // Interrupteur Switch (ou cadenas si c'est le compte de l'admin connecté)
            if (estMonCompte)
              Tooltip(
                message: 'Votre compte connecté (non modifiable)',
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, size: 14, color: Colors.grey),
                      SizedBox(width: 4),
                      Text('Moi',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else
              Switch(
                value: profil.actif,
                activeColor: Colors.green.shade700,
                inactiveThumbColor: Colors.red.shade700,
                inactiveTrackColor: Colors.red.shade100,
                onChanged: (_) => basculerStatut(profil),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String texte = recherche.trim().toLowerCase();

    final List<Profil> visibles = profils.where((p) {
      return p.nomComplet.toLowerCase().contains(texte) ||
          p.role.toLowerCase().contains(texte) ||
          p.telephone.contains(texte);
    }).toList();

    final int totalActifs = profils.where((p) => p.actif).length;
    final int totalDesactives = profils.where((p) => !p.actif).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Utilisateurs'),
      ),
      drawer: construireDrawer(context),
      body: chargement
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: chargerProfils,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Carte de résumé en haut
            Card(
              color: Colors.deepPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          '${profils.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Total',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                    Container(
                        width: 1, height: 30, color: Colors.white24),
                    Column(
                      children: [
                        Text(
                          '$totalActifs',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Actifs',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                    Container(
                        width: 1, height: 30, color: Colors.white24),
                    Column(
                      children: [
                        Text(
                          '$totalDesactives',
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Désactivés',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Barre de recherche
            TextField(
              controller: rechercheController,
              onChanged: (val) {
                setState(() {
                  recherche = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'Rechercher un utilisateur, rôle...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: recherche.isEmpty
                    ? null
                    : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    rechercheController.clear();
                    setState(() {
                      recherche = '';
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Liste des utilisateurs
            if (profils.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Aucun utilisateur dans la base.',
                  textAlign: TextAlign.center,
                ),
              )
            else if (visibles.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Aucun utilisateur ne correspond à "$recherche".',
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...visibles.map(carteProfil),
          ],
        ),
      ),
    );
  }
}
