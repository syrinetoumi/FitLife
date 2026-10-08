import 'package:flutter/material.dart';

import '../../models/categorie.dart';
import '../../models/evenement.dart';
import '../../models/inscription.dart';
import '../../models/paiement_evenement.dart';
import '../../repositories/categorie_repository.dart';
import '../../repositories/evenement_repository.dart';
import '../../repositories/inscription_repository.dart';
import '../../repositories/paiement_evenement_repository.dart';
import '../../../../../core/utils/outils.dart';
import 'paiement_form_screen.dart';

class PaiementListScreen extends StatefulWidget {
  // integre = true : affiché dans un TabBarView ou sous un
  // BottomNavigationBar, donc sans son propre Scaffold/AppBar.
  final bool integre;

  const PaiementListScreen({
    super.key,
    this.integre = false,
  });

  @override
  State<PaiementListScreen> createState() => _PaiementListScreenState();
}

class _PaiementListScreenState extends State<PaiementListScreen> {
  PaiementEvenementRepository paiementRepository =
  PaiementEvenementRepository();
  InscriptionRepository inscriptionRepository = InscriptionRepository();
  EvenementRepository evenementRepository = EvenementRepository();
  CategorieRepository categorieRepository = CategorieRepository();

  List<PaiementEvenement> paiements = [];
  List<Inscription> inscriptions = [];
  List<Evenement> evenements = [];
  List<Categorie> categories = [];

  @override
  void initState() {
    super.initState();
    chargerDonnees();
  }

  Future<void> chargerDonnees() async {
    try {
      List<PaiementEvenement> resultatPaiements =
      await paiementRepository.getPaiements();

      List<Inscription> resultatInscriptions =
      await inscriptionRepository.getInscriptions();

      List<Evenement> resultatEvenements =
      await evenementRepository.getEvenements();

      List<Categorie> resultatCategories =
      await categorieRepository.getCategories();

      if (!mounted) {
        return;
      }

      setState(() {
        paiements = resultatPaiements;
        inscriptions = resultatInscriptions;
        evenements = resultatEvenements;
        categories = resultatCategories;
      });
    } catch (erreur) {
      if (mounted) {
        afficherMessage(context, 'Erreur de chargement : $erreur');
      }
    }
  }

  Inscription? trouverInscription(String id) {
    for (Inscription inscription in inscriptions) {
      if (inscription.idInscription == id) {
        return inscription;
      }
    }

    return null;
  }

  String nomEvenement(String id) {
    for (Evenement evenement in evenements) {
      if (evenement.idEvenement == id) {
        return evenement.nom;
      }
    }

    return 'Événement inconnu';
  }

  String nomCategorie(String id) {
    for (Categorie categorie in categories) {
      if (categorie.idCategorie == id) {
        return categorie.nom;
      }
    }

    return 'Catégorie inconnue';
  }

  Future<void> supprimer(String id) async {
    try {
      await paiementRepository.supprimer(id);
      await chargerDonnees();
    } catch (erreur) {
      if (mounted) {
        afficherMessage(context, 'Suppression impossible : $erreur');
      }
    }
  }

  Future<void> ouvrirFormulaire(PaiementEvenement? paiement) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaiementFormScreen(paiement: paiement),
      ),
    );

    chargerDonnees();
  }

  Widget construireListe() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      // +1 : la première ligne est le bouton "Ajouter".
      itemCount: paiements.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: ElevatedButton(
              onPressed: () {
                ouvrirFormulaire(null);
              },
              child: const Text('Ajouter un paiement'),
            ),
          );
        }

        PaiementEvenement paiement = paiements[index - 1];

        Inscription? inscription = trouverInscription(paiement.idInscription);

        String evenement = 'Événement inconnu';
        String categorie = 'Catégorie inconnue';
        String athlete = 'Athlète inconnu';

        if (inscription != null) {
          evenement = nomEvenement(inscription.idEvenement);
          categorie = nomCategorie(inscription.idCategorie);
          athlete = inscription.idAthlete;
        }

        return Card(
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    evenement,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                Text('Catégorie : $categorie'),
                Text('Athlète : $athlete'),
                Text('Montant : ${paiement.montant.toStringAsFixed(2)} DT'),
                Text('Date : ${afficherDate(paiement.datePaiement)}'),
                Text('Méthode : ${paiement.methodeToString()}'),
                Text('Statut : ${paiement.statutToString()}'),
                Text('Référence : ${paiement.reference}'),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          ouvrirFormulaire(paiement);
                        },
                        child: const Text('Modifier'),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 10),
                        child: ElevatedButton(
                          onPressed: () {
                            supprimer(paiement.idPaiement);
                          },
                          child: const Text('Supprimer'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.integre) {
      return construireListe();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiements'),
      ),
      drawer: construireDrawer(context),
      body: construireListe(),
    );
  }
}
