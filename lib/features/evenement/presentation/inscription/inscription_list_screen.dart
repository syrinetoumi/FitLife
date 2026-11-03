import 'package:flutter/material.dart';

import 'package:coach_app/core/utils/outils.dart';
import 'package:coach_app/features/entrainement/presentation/widgets/carte_image.dart';
import '../../data/models/categorie.dart';
import '../../data/models/evenement.dart';
import '../../data/models/inscription.dart';
import '../../data/repositories/categorie_repository.dart';
import '../../data/repositories/evenement_repository.dart';
import '../../data/repositories/inscription_repository.dart';
import '../widgets/apparence_evenement.dart';
import 'inscription_detail_screen.dart';
import 'inscription_form_screen.dart';

class InscriptionListScreen extends StatefulWidget {
  // integre = true : affiché sous la barre de navigation du bas
  // (ou dans un TabBarView), donc sans son propre Scaffold/AppBar.
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
  TextEditingController rechercheController = TextEditingController();

  List<Inscription> inscriptions = [];
  List<Evenement> evenements = [];
  List<Categorie> categories = [];
  bool chargement = true;
  String recherche = '';

  @override
  void initState() {
    super.initState();
    chargerDonnees();
  }

  @override
  void dispose() {
    rechercheController.dispose();
    super.dispose();
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

  Future<void> ouvrirFormulaire() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InscriptionFormScreen(),
      ),
    );

    chargerDonnees();
  }

  Future<void> ouvrirDetail(Inscription inscription) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InscriptionDetailScreen(
          inscription: inscription,
          nomEvenement: nomEvenement(inscription.idEvenement),
          nomCategorie: nomCategorie(inscription.idCategorie),
        ),
      ),
    );

    chargerDonnees();
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
          hintText: 'Rechercher une inscription',
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
            Text('CRÉER UNE INSCRIPTION'),
            Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget carteInscription(Inscription inscription) {
    return CarteImage(
      titre: nomEvenement(inscription.idEvenement),
      sousTitre: 'Athlète : ${inscription.idAthlete} · '
          '${afficherDate(inscription.dateInscription)}',
      couleurs: couleursInscription(),
      icone: Icons.how_to_reg,
      badge: pastilleStatut(inscription.statutToString()),
      onVoirPlus: () {
        ouvrirDetail(inscription);
      },
    );
  }

  Widget construireListe() {
    if (chargement) {
      return const Center(child: CircularProgressIndicator());
    }

    // Recherche par événement ou par athlète.
    String texte = recherche.trim().toLowerCase();

    List<Inscription> visibles = inscriptions.where((inscription) {
      String evenement = nomEvenement(inscription.idEvenement).toLowerCase();
      String athlete = inscription.idAthlete.toLowerCase();

      return evenement.contains(texte) || athlete.contains(texte);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        barreRecherche(),
        boutonCreer(),
        if (inscriptions.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Aucune inscription pour le moment.',
              textAlign: TextAlign.center,
            ),
          )
        else if (visibles.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Aucune inscription ne correspond à "$recherche".',
              textAlign: TextAlign.center,
            ),
          ),
        ...visibles.map(carteInscription),
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
        title: const Text('Inscriptions'),
      ),
      drawer: construireDrawer(context),
      body: construireListe(),
    );
  }
}