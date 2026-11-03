import 'package:flutter/material.dart';

import '../../../../core/utils/outils.dart';
import '../../../entrainement/presentation/widgets/carte_image.dart';
import '../../data/models/evenement.dart';
import '../../data/repositories/evenement_repository.dart';
import '../widgets/apparence_evenement.dart';
import 'evenement_detail_screen.dart';
import 'evenement_form_screen.dart';

class EvenementListScreen extends StatefulWidget {
  final bool integre;
  final bool? estAdmin;

  const EvenementListScreen({
    super.key,
    this.integre = false,
    this.estAdmin,
  });

  @override
  State<EvenementListScreen> createState() => _EvenementListScreenState();
}

class _EvenementListScreenState extends State<EvenementListScreen> {
  EvenementRepository evenementRepository = EvenementRepository();
  TextEditingController rechercheController = TextEditingController();

  List<Evenement> evenements = [];
  bool chargement = true;
  String recherche = '';

  bool get estAdmin => widget.estAdmin ?? estUtilisateurAdmin();

  @override
  void initState() {
    super.initState();
    chargerEvenements();
  }

  @override
  void dispose() {
    rechercheController.dispose();
    super.dispose();
  }

  Future<void> chargerEvenements() async {
    try {
      List<Evenement> resultat = await evenementRepository.getEvenements();

      if (!mounted) {
        return;
      }

      setState(() {
        evenements = resultat;
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
        builder: (context) => const EvenementFormScreen(),
      ),
    );

    chargerEvenements();
  }

  Future<void> ouvrirDetail(Evenement evenement) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EvenementDetailScreen(
          evenement: evenement,
          estAdmin: estAdmin,
        ),
      ),
    );

    chargerEvenements();
  }

  // Barre de recherche arrondie (style bleu).
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
          hintText: 'Rechercher un événement',
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

  // Bouton "CRÉER UN ÉVÉNEMENT" (affiché UNIQUEMENT si Admin).
  Widget boutonCreer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: ouvrirFormulaire,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CRÉER UN ÉVÉNEMENT',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  // La boîte événement avec image, dégradé, titre, badge et bouton Voir plus.
  Widget carteEvenement(Evenement evenement) {
    return CarteImage(
      titre: evenement.nom,
      sousTitre: '${afficherDate(evenement.dateDebut)} · ${evenement.lieu}',
      cheminImage: imageType(evenement.type),
      couleurs: couleursType(evenement.type),
      icone: iconeType(evenement.type),
      badge: pastilleStatut(evenement.statut.name.toUpperCase()),
      onVoirPlus: () {
        ouvrirDetail(evenement);
      },
    );
  }

  Widget construireListe() {
    if (chargement) {
      return const Center(child: CircularProgressIndicator());
    }

    String texte = recherche.trim().toLowerCase();

    List<Evenement> visibles = evenements.where((evenement) {
      return evenement.nom.toLowerCase().contains(texte) ||
          evenement.lieu.toLowerCase().contains(texte);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        barreRecherche(),
        // 🔒 SEUL L'ADMIN PEUT CRÉER DES ÉVÉNEMENTS
        if (estAdmin) boutonCreer(),
        if (evenements.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Aucun événement pour le moment.',
              textAlign: TextAlign.center,
            ),
          )
        else if (visibles.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Aucun événement ne correspond à "$recherche".',
              textAlign: TextAlign.center,
            ),
          ),
        ...visibles.map(carteEvenement),
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
        title: const Text('Événements'),
      ),
      drawer: construireDrawer(context),
      body: construireListe(),
    );
  }
}
