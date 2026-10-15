import 'package:flutter/material.dart';

import '../../data/models/categorie.dart';
import '../../data/models/evenement.dart';
import '../../data/repositories/categorie_repository.dart';
import '../../data/repositories/evenement_repository.dart';
import '../../../../core/utils/outils.dart';
import 'categorie_form_screen.dart';

class CategorieListScreen extends StatefulWidget {
  // integre = true : affiché dans un TabBarView ou sous un
  // BottomNavigationBar, donc sans son propre Scaffold/AppBar.
  final bool integre;

  const CategorieListScreen({
    super.key,
    this.integre = false,
  });

  @override
  State<CategorieListScreen> createState() => _CategorieListScreenState();
}

class _CategorieListScreenState extends State<CategorieListScreen> {
  CategorieRepository categorieRepository = CategorieRepository();
  EvenementRepository evenementRepository = EvenementRepository();

  List<Categorie> categories = [];
  List<Evenement> evenements = [];

  @override
  void initState() {
    super.initState();
    chargerDonnees();
  }

  Future<void> chargerDonnees() async {
    try {
      List<Categorie> resultatCategories =
      await categorieRepository.getCategories();

      List<Evenement> resultatEvenements =
      await evenementRepository.getEvenements();

      if (!mounted) {
        return;
      }

      setState(() {
        categories = resultatCategories;
        evenements = resultatEvenements;
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

  Future<void> supprimer(String id) async {
    try {
      await categorieRepository.supprimer(id);
      await chargerDonnees();
    } catch (erreur) {
      if (mounted) {
        afficherMessage(context, 'Suppression impossible : $erreur');
      }
    }
  }

  Future<void> ouvrirFormulaire(Categorie? categorie) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategorieFormScreen(categorie: categorie),
      ),
    );

    chargerDonnees();
  }

  Widget construireListe() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      // +1 : la première ligne est le bouton "Ajouter".
      itemCount: categories.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: ElevatedButton(
              onPressed: () {
                ouvrirFormulaire(null);
              },
              child: const Text('Ajouter une catégorie'),
            ),
          );
        }

        Categorie categorie = categories[index - 1];

        return Card(
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    categorie.nom,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                Text('Événement : ${nomEvenement(categorie.idEvenement)}'),
                Text('Âge : ${categorie.ageMin} - ${categorie.ageMax}'),
                Text('Niveau : ${categorie.niveau.name.toUpperCase()}'),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          ouvrirFormulaire(categorie);
                        },
                        child: const Text('Modifier'),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 10),
                        child: ElevatedButton(
                          onPressed: () {
                            supprimer(categorie.idCategorie);
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
        title: const Text('Catégories'),
      ),
      drawer: construireDrawer(context),
      body: construireListe(),
    );
  }
}
