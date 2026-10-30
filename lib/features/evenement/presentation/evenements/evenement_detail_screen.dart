import 'package:flutter/material.dart';

import 'package:coach_app/core/utils/alertes.dart';
import 'package:coach_app/core/utils/outils.dart';
import 'package:coach_app/features/entrainement/presentation/widgets/carte_image.dart';
import 'package:coach_app/features/entrainement/presentation/widgets/ligne_info.dart';
import 'package:coach_app/features/evenement/data/models/categorie.dart';
import 'package:coach_app/features/evenement/data/models/evenement.dart';
import 'package:coach_app/features/evenement/data/models/inscription.dart';
import 'package:coach_app/features/evenement/data/repositories/categorie_repository.dart';
import 'package:coach_app/features/evenement/data/repositories/evenement_repository.dart';
import 'package:coach_app/features/evenement/data/repositories/inscription_repository.dart';
import 'package:coach_app/features/evenement/presentation/inscription/inscription_form_screen.dart';
import 'package:coach_app/features/evenement/presentation/widgets/apparence_evenement.dart';
import 'evenement_form_screen.dart';

class EvenementDetailScreen extends StatefulWidget {
  final Evenement evenement;
  final bool? estAdmin;

  const EvenementDetailScreen({
    super.key,
    required this.evenement,
    this.estAdmin,
  });

  @override
  State<EvenementDetailScreen> createState() => _EvenementDetailScreenState();
}

class _EvenementDetailScreenState extends State<EvenementDetailScreen> {
  EvenementRepository evenementRepository = EvenementRepository();
  CategorieRepository categorieRepository = CategorieRepository();
  InscriptionRepository inscriptionRepository = InscriptionRepository();

  Categorie? categorie;
  int? placesPrises;
  bool chargement = true;

  Evenement get evenement => widget.evenement;

  bool get estAdmin => widget.estAdmin ?? estUtilisateurAdmin();

  @override
  void initState() {
    super.initState();
    charger();
  }

  // Charge la catégorie de l'événement et le nombre d'inscrits.
  Future<void> charger() async {
    try {
      List<Categorie> toutes = await categorieRepository.getCategories();

      List<Inscription> inscriptions = await inscriptionRepository
          .getInscriptionsByEvenement(evenement.idEvenement);

      Categorie? trouvee;
      for (Categorie c in toutes) {
        if (c.idCategorie == evenement.idCategorie) {
          trouvee = c;
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        categorie = trouvee;
        placesPrises = inscriptions.length;
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

  // --- ACTIONS ADMIN (CRUD) ---
  Future<void> modifier() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EvenementFormScreen(evenement: evenement),
      ),
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> supprimer() async {
    bool confirme = await confirmerAction(
      context,
      titre: 'Supprimer',
      message: 'Supprimer l’événement "${evenement.nom}" ?',
    );

    if (!confirme) {
      return;
    }

    try {
      await evenementRepository.supprimer(evenement.idEvenement);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (erreur) {
      if (mounted) {
        afficherAlerteErreur(
          context,
          titre: 'Suppression impossible',
          message: '$erreur',
        );
      }
    }
  }

  // --- ACTION ATHLÈTE (INSCRIPTION) ---
  void sInscrire() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InscriptionFormScreen(
          evenementInitial: evenement,
        ),
      ),
    );
  }

  Widget construireContenu() {
    String textePlaces = '${evenement.capacite} places';

    if (placesPrises != null) {
      textePlaces = '$placesPrises / ${evenement.capacite} inscrits';
    }

    String texteCategorie = 'Catégorie inconnue';

    if (categorie != null) {
      texteCategorie = '${categorie!.nom} '
          '(${categorie!.ageMin} - ${categorie!.ageMax} ans)';
    }

    bool peutSinscrire = evenement.statut == StatutEvenement.ouvert;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CarteImage(
          titre: evenement.nom,
          sousTitre: '${afficherDate(evenement.dateDebut)} · '
              '${evenement.heureDebut}',
          cheminImage: imageType(evenement.type),
          couleurs: couleursType(evenement.type),
          icone: iconeType(evenement.type),
          badge: pastilleStatut(evenement.statut.name.toUpperCase()),
          hauteur: 200,
        ),
        Card(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                ligneInfo(
                  Icons.event,
                  'Début',
                  afficherDate(evenement.dateDebut),
                ),
                const Divider(height: 1),
                ligneInfo(Icons.schedule, 'Heure', evenement.heureDebut),
                const Divider(height: 1),
                ligneInfo(
                  Icons.event_available,
                  'Fin',
                  afficherDate(evenement.dateFin),
                ),
                const Divider(height: 1),
                ligneInfo(Icons.place, 'Lieu', evenement.lieu),
                const Divider(height: 1),
                ligneInfo(
                  Icons.category,
                  'Type',
                  evenement.type.name.toUpperCase(),
                ),
                const Divider(height: 1),
                ligneInfo(Icons.groups, 'Catégorie', texteCategorie),
                const Divider(height: 1),
                ligneInfo(Icons.event_seat, 'Places', textePlaces),
                const Divider(height: 1),
                ligneInfo(
                  Icons.payments,
                  'Prix',
                  '${evenement.prix.toStringAsFixed(2)} DT',
                ),
              ],
            ),
          ),
        ),
        if (evenement.description.isNotEmpty)
          Card(
            margin: const EdgeInsets.only(top: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Text(
                evenement.description,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ),
          ),

        // Actions selon le rôle
        if (estAdmin) ...[
          Container(
            margin: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: modifier,
                    child: const Text('Modifier'),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 10),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: supprimer,
                      child: const Text('Supprimer'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            margin: const EdgeInsets.only(top: 20),
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: peutSinscrire ? Colors.deepPurple : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: peutSinscrire ? sInscrire : null,
              child: Text(
                peutSinscrire
                    ? 'S\'INSCRIRE À CET ÉVÉNEMENT'
                    : 'INSCRIPTIONS FERMÉES',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Événement')),
      body: chargement
          ? const Center(child: CircularProgressIndicator())
          : construireContenu(),
    );
  }
}
