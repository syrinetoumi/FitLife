import 'package:flutter/material.dart';

import '../../data/models/categorie.dart';
import '../../data/models/evenement.dart';
import '../../data/models/inscription.dart';
import '../../data/repositories/categorie_repository.dart';
import '../../data/repositories/evenement_repository.dart';
import '../../data/repositories/inscription_repository.dart';
import '../../../../core/utils/outils.dart';
import 'inscription_form_screen.dart';

class InscriptionListScreen extends StatefulWidget {
  // integre = true : affiché dans un TabBarView ou sous un
  // BottomNavigationBar, donc sans son propre Scaffold/AppBar.
  final bool integre;

  const InscriptionListScreen({
    super.key,
    this.integre = false,
  });

  @override
  State<InscriptionListScreen> createState() => _InscriptionListScreenState();
}

class _InscriptionListScreenState extends State<InscriptionListScreen> {
  InscriptionRepository inscriptionRepository = InscriptionRepository();
  EvenementRepository evenementRepository = EvenementRepository();
  CategorieRepository categorieRepository = CategorieRepository();

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

  String nomEvenement(String idEvenement) {
    for (Evenement evenement in evenements) {
      if (evenement.idEvenement == idEvenement) {
        return evenement.nom;
      }
    }

    return 'Événement inconnu';
  }

  String nomCategorie(String idCategorie) {
    for (Categorie categorie in categories) {
      if (categorie.idCategorie == idCategorie) {
        return categorie.nom;
      }
    }

    return 'Catégorie inconnue';
  }

  Future<void> supprimer(String id) async {
    try {
      await inscriptionRepository.supprimer(id);
      await chargerDonnees();
    } catch (erreur) {
      if (mounted) {
        afficherMessage(context, 'Suppression impossible : $erreur');
      }
    }
  }

  Future<void> ouvrirFormulaire(Inscription? inscription) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InscriptionFormScreen(inscription: inscription),
      ),
    );

    chargerDonnees();
  }

  Widget construireListe() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      // +1 : la première ligne est le bouton "Ajouter".
      itemCount: inscriptions.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: ElevatedButton(
              onPressed: () {
                ouvrirFormulaire(null);
              },
              child: const Text('Ajouter une inscription'),
            ),
          );
        }

        Inscription inscription = inscriptions[index - 1];

        return Card(
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    nomEvenement(inscription.idEvenement),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                Text('Catégorie : ${nomCategorie(inscription.idCategorie)}'),
                Text('Athlète : ${inscription.idAthlete}'),
                Text(
                  'Date inscription : '
                      '${afficherDate(inscription.dateInscription)}',
                ),
                Text('Statut : ${inscription.statutToString()}'),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          ouvrirFormulaire(inscription);
                        },
                        child: const Text('Modifier'),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 10),
                        child: ElevatedButton(
                          onPressed: () {
                            supprimer(inscription.idInscription);
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
        title: const Text('Inscriptions'),
      ),
      drawer: construireDrawer(context),
      body: construireListe(),
    );
  }
}
