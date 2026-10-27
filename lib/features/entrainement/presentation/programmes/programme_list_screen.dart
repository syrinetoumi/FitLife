import 'package:flutter/material.dart';

import 'package:coach_app/core/utils/outils.dart';
import 'package:coach_app/features/entrainement/data/models/enums.dart';
import 'package:coach_app/features/entrainement/data/models/programme.dart';
import 'package:coach_app/features/entrainement/data/repositories/programme_repository.dart';
import 'package:coach_app/features/entrainement/presentation/widgets/apparence_entrainement.dart';
import 'package:coach_app/features/entrainement/presentation/widgets/carte_image.dart';
import 'programme_detail_screen.dart';
import 'programme_form_screen.dart';

class ProgrammeListScreen extends StatefulWidget {
  // integre = true : affiché sous la barre de navigation du bas.
  final bool integre;

  const ProgrammeListScreen({
    super.key,
    this.integre = false,
  });

  @override
  State<ProgrammeListScreen> createState() => _ProgrammeListScreenState();
}

class _ProgrammeListScreenState extends State<ProgrammeListScreen> {
  ProgrammeRepository programmeRepository = ProgrammeRepository();
  TextEditingController rechercheController = TextEditingController();

  List<Programme> programmes = [];
  bool chargement = true;
  String recherche = '';

  @override
  void initState() {
    super.initState();
    chargerProgrammes();
  }

  @override
  void dispose() {
    rechercheController.dispose();
    super.dispose();
  }

  Future<void> chargerProgrammes() async {
    try {
      List<Programme> resultat =
      await programmeRepository.getProgrammesDuCoach();

      if (!mounted) {
        return;
      }

      setState(() {
        programmes = resultat;
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
        builder: (context) => const ProgrammeFormScreen(),
      ),
    );

    chargerProgrammes();
  }

  Future<void> ouvrirDetail(Programme programme) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProgrammeDetailScreen(programme: programme),
      ),
    );

    chargerProgrammes();
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
          hintText: 'Rechercher un programme',
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
            Text('CRÉER UN PROGRAMME'),
            Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget carteProgramme(Programme programme) {
    String sousTitre = enTexte(programme.niveau);

    if (programme.dureeSemaines != null) {
      sousTitre = '$sousTitre · ${programme.dureeSemaines} semaines';
    }

    return CarteImage(
      titre: programme.nom,
      sousTitre: sousTitre,
      cheminImage: imageObjectif(programme.objectif),
      couleurs: couleursObjectif(programme.objectif),
      icone: iconeObjectif(programme.objectif),
      onVoirPlus: () {
        ouvrirDetail(programme);
      },
    );
  }

  Widget construireListe() {
    if (chargement) {
      return const Center(child: CircularProgressIndicator());
    }

    // Recherche par nom (sans tenir compte des majuscules).
    String texte = recherche.trim().toLowerCase();

    List<Programme> visibles = programmes.where((programme) {
      return programme.nom.toLowerCase().contains(texte);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        barreRecherche(),
        boutonCreer(),
        if (programmes.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Aucun programme pour le moment.',
              textAlign: TextAlign.center,
            ),
          )
        else if (visibles.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Aucun programme ne correspond à "$recherche".',
              textAlign: TextAlign.center,
            ),
          ),
        ...visibles.map(carteProgramme),
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
        title: const Text('Programmes'),
      ),
      drawer: construireDrawer(context),
      body: construireListe(),
    );
  }
}