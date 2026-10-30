import 'package:flutter/material.dart';

import 'package:coach_app/core/utils/outils.dart';
import 'package:coach_app/features/entrainement/presentation/widgets/carte_image.dart';
import '../../data/models/categorie.dart';
import '../../data/repositories/categorie_repository.dart';
import '../widgets/apparence_evenement.dart';
import 'categorie_detail_screen.dart';
import 'categorie_form_screen.dart';

class CategorieListScreen extends StatefulWidget {
  // integre = true : affiché sous la barre de navigation du bas
  // (ou dans un TabBarView), donc sans son propre Scaffold/AppBar.
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
  TextEditingController rechercheController = TextEditingController();

  List<Categorie> categories = [];
  bool chargement = true;
  String recherche = '';

  @override
  void initState() {
    super.initState();
    chargerCategories();
  }

  @override
  void dispose() {
    rechercheController.dispose();
    super.dispose();
  }

  Future<void> chargerCategories() async {
    try {
      List<Categorie> resultat = await categorieRepository.getCategories();

      if (!mounted) {
        return;
      }

      setState(() {
        categories = resultat;
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

  Future<void> ouvrirFormulaire() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CategorieFormScreen(),
      ),
    );

    chargerCategories();
  }

  Future<void> ouvrirDetail(Categorie categorie) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategorieDetailScreen(categorie: categorie),
      ),
    );

    chargerCategories();
  }

  // Barre de recherche arrondie.
  Widget barreRecherche() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: rechercheController,
        style: const TextStyle(color: Colors.white),
        cursorColor: Colors.white,
        onChanged: (valeur) {
          setState(() {
            recherche = valeur;
          });
        },
        decoration: InputDecoration(
          hintText: 'Rechercher une catégorie',
          hintStyle: const TextStyle(color: Colors.white70),
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          suffixIcon: recherche.isEmpty
              ? null
              : IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              rechercheController.clear();
              setState(() {
                recherche = '';
              });
            },
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.primary,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget boutonCreer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: ouvrirFormulaire,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('CRÉER UNE CATÉGORIE'),
            Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget carteCategorie(Categorie categorie) {
    return CarteImage(
      titre: categorie.nom,
      sousTitre: 'Âge : ${categorie.ageMin} - ${categorie.ageMax} · '
          '${categorie.niveau.name.toUpperCase()}',
      cheminImage: imageNiveau(categorie.niveau),
      couleurs: couleursNiveau(categorie.niveau),
      icone: iconeNiveau(categorie.niveau),
      onVoirPlus: () {
        ouvrirDetail(categorie);
      },
    );
  }

  Widget construireListe() {
    if (chargement) {
      return const Center(child: CircularProgressIndicator());
    }

    // Recherche par nom (sans tenir compte des majuscules).
    String texte = recherche.trim().toLowerCase();

    List<Categorie> visibles = categories.where((categorie) {
      return categorie.nom.toLowerCase().contains(texte);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        barreRecherche(),
        boutonCreer(),
        if (categories.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Aucune catégorie pour le moment.',
              textAlign: TextAlign.center,
            ),
          )
        else if (visibles.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Aucune catégorie ne correspond à "$recherche".',
              textAlign: TextAlign.center,
            ),
          ),
        ...visibles.map(carteCategorie),
      ],
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