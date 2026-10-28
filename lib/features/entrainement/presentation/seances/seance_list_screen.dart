import 'package:flutter/material.dart';

import 'package:coach_app/core/utils/outils.dart';
import 'package:coach_app/features/entrainement/data/models/seance.dart';
import 'package:coach_app/features/entrainement/data/repositories/role_repository.dart';
import 'package:coach_app/features/entrainement/data/repositories/seance_repository.dart';
import 'package:coach_app/features/entrainement/presentation/widgets/apparence_entrainement.dart';
import 'package:coach_app/features/entrainement/presentation/widgets/carte_image.dart';
import 'libelles_seance.dart';
import 'seance_detail_screen.dart';
import 'seance_form_screen.dart';

class SeanceListScreen extends StatefulWidget {
  // integre = true : affiché sous la barre de navigation du bas.
  final bool integre;

  const SeanceListScreen({
    super.key,
    this.integre = false,
  });

  @override
  State<SeanceListScreen> createState() => _SeanceListScreenState();
}

class _SeanceListScreenState extends State<SeanceListScreen> {
  SeanceRepository seanceRepository = SeanceRepository();
  RoleRepository roleRepository = RoleRepository();
  TextEditingController rechercheController = TextEditingController();

  List<Seance> seances = [];
  bool chargement = true;
  bool coach = false;
  String recherche = '';

  @override
  void initState() {
    super.initState();
    chargerSeances();
  }

  @override
  void dispose() {
    rechercheController.dispose();
    super.dispose();
  }

  // Coach : ses séances. Athlète : les séances à venir de tous les coachs.
  Future<void> chargerSeances() async {
    try {
      bool estCoach = await roleRepository.estCoach();
      List<Seance> resultat;

      if (estCoach) {
        resultat = await seanceRepository.getSeancesDuCoach();
      } else {
        resultat = await seanceRepository.getSeancesDisponibles();
      }

      if (!mounted) {
        return;
      }

      setState(() {
        coach = estCoach;
        seances = resultat;
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
        builder: (context) => const SeanceFormScreen(),
      ),
    );

    chargerSeances();
  }

  Future<void> ouvrirDetail(Seance seance) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeanceDetailScreen(seance: seance),
      ),
    );

    chargerSeances();
  }

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
          hintText: 'Rechercher une séance',
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
            Text('CRÉER UNE SÉANCE'),
            Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget carteSeance(Seance seance) {
    return CarteImage(
      titre: seance.titre,
      sousTitre: '${afficherDate(seance.date)} · '
          '${seance.debutCourt} - ${seance.finCourt}',
      cheminImage: imageType(seance.type),
      couleurs: couleursType(seance.type),
      icone: iconeType(seance.type),
      badge: pastilleStatutSeance(seance.statut),
      onVoirPlus: () {
        ouvrirDetail(seance);
      },
    );
  }

  Widget construireListe() {
    if (chargement) {
      return const Center(child: CircularProgressIndicator());
    }

    String texte = recherche.trim().toLowerCase();

    List<Seance> visibles = seances.where((seance) {
      return seance.titre.toLowerCase().contains(texte);
    }).toList();

    String messageVide = coach
        ? 'Aucune séance pour le moment.'
        : 'Aucune séance disponible pour le moment.';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        barreRecherche(),
        // Seul le coach crée des séances.
        if (coach) boutonCreer(),
        if (seances.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              messageVide,
              textAlign: TextAlign.center,
            ),
          )
        else if (visibles.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Aucune séance ne correspond à "$recherche".',
              textAlign: TextAlign.center,
            ),
          ),
        ...visibles.map(carteSeance),
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
        title: const Text('Séances'),
      ),
      drawer: construireDrawer(context),
      body: construireListe(),
    );
  }
}