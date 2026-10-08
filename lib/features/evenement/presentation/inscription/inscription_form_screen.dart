import 'package:flutter/material.dart';

import '../../data/models/categorie.dart';
import '../../data/models/evenement.dart';
import '../../data/models/inscription.dart';
import '../../data/repositories/categorie_repository.dart';
import '../../data/repositories/evenement_repository.dart';
import '../../data/repositories/inscription_repository.dart';
import '../../../../core/utils/outils.dart';

class InscriptionFormScreen extends StatefulWidget {
  final Inscription? inscription;

  const InscriptionFormScreen({
    super.key,
    this.inscription,
  });

  @override
  State<InscriptionFormScreen> createState() => _InscriptionFormScreenState();
}

class _InscriptionFormScreenState extends State<InscriptionFormScreen> {
  final formKey = GlobalKey<FormState>();

  EvenementRepository evenementRepository = EvenementRepository();
  CategorieRepository categorieRepository = CategorieRepository();
  InscriptionRepository inscriptionRepository = InscriptionRepository();

  List<Evenement> evenements = [];
  List<Categorie> categories = [];

  String idAthlete = '';
  String idEvenement = '';
  String idCategorie = '';

  StatutInscription statut = StatutInscription.enAttente;

  @override
  void initState() {
    super.initState();

    if (widget.inscription != null) {
      Inscription inscription = widget.inscription!;

      idAthlete = inscription.idAthlete;
      idEvenement = inscription.idEvenement;
      idCategorie = inscription.idCategorie;
      statut = inscription.statut;
    }

    chargerEvenements();
  }

  Future<void> chargerEvenements() async {
    try {
      List<Evenement> resultat = await evenementRepository.getEvenements();

      if (!mounted) {
        return;
      }

      setState(() {
        evenements = resultat;
      });

      if (idEvenement.isNotEmpty) {
        chargerCategories(idEvenement);
      }
    } catch (erreur) {
      if (mounted) {
        afficherMessage(context, 'Erreur de chargement : $erreur');
      }
    }
  }

  Future<void> chargerCategories(String id) async {
    try {
      List<Categorie> resultat =
      await categorieRepository.getCategoriesByEvenement(id);

      if (!mounted) {
        return;
      }

      setState(() {
        categories = resultat;
      });
    } catch (erreur) {
      if (mounted) {
        afficherMessage(context, 'Erreur de chargement : $erreur');
      }
    }
  }

  String? validerAthlete(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Athlète obligatoire';
    }

    return null;
  }

  Future<void> enregistrer() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (idEvenement.isEmpty) {
      afficherMessage(context, 'Choisissez un événement');
      return;
    }

    if (idCategorie.isEmpty) {
      afficherMessage(context, 'Choisissez une catégorie');
      return;
    }

    Inscription inscription = Inscription(
      idInscription: widget.inscription?.idInscription ?? '',
      idEvenement: idEvenement,
      idAthlete: idAthlete.trim(),
      idCategorie: idCategorie,
      dateInscription: widget.inscription?.dateInscription ?? DateTime.now(),
      statut: statut,
    );

    try {
      if (widget.inscription == null) {
        await inscriptionRepository.ajouter(inscription);
      } else {
        await inscriptionRepository.modifier(inscription);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (erreur) {
      if (mounted) {
        afficherMessage(context, 'Enregistrement impossible : $erreur');
      }
    }
  }

  Widget titreSection(String texte) {
    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        texte,
        style: const TextStyle(fontSize: 18),
      ),
    );
  }

  Widget choixEvenement() {
    if (evenements.isEmpty) {
      return const Text('Aucun événement : créez-en un d’abord.');
    }

    return Container(
      height: 200,
      child: ListView.builder(
        itemCount: evenements.length,
        itemBuilder: (context, index) {
          Evenement evenement = evenements[index];
          bool choisi = idEvenement == evenement.idEvenement;

          return Card(
            color: choisi ? Colors.blue.shade50 : null,
            child: InkWell(
              onTap: () {
                setState(() {
                  idEvenement = evenement.idEvenement;
                  idCategorie = '';
                  categories = [];
                });

                chargerCategories(evenement.idEvenement);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Text(choisi ? '✓ ${evenement.nom}' : evenement.nom),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget choixCategorie() {
    if (idEvenement.isEmpty) {
      return const Text('Choisissez d’abord un événement.');
    }

    if (categories.isEmpty) {
      return const Text('Aucune catégorie pour cet événement.');
    }

    return Container(
      height: 200,
      child: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          Categorie categorie = categories[index];
          bool choisie = idCategorie == categorie.idCategorie;

          return Card(
            color: choisie ? Colors.blue.shade50 : null,
            child: InkWell(
              onTap: () {
                setState(() {
                  idCategorie = categorie.idCategorie;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text(
                      choisie ? '✓ ${categorie.nom}' : categorie.nom,
                      style: const TextStyle(fontSize: 17),
                    ),
                    Text('Âge : ${categorie.ageMin} - ${categorie.ageMax}'),
                    Text('Niveau : ${categorie.niveau.name.toUpperCase()}'),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Choix du statut : GridView.builder (Chapitre 4).
  Widget choixStatut() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: StatutInscription.values.length,
      itemBuilder: (context, index) {
        StatutInscription valeur = StatutInscription.values[index];
        String libelle = statutInscriptionEnTexte(valeur);

        return ElevatedButton(
          onPressed: () {
            setState(() {
              statut = valeur;
            });
          },
          child: Text(statut == valeur ? '✓ $libelle' : libelle),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.inscription == null
              ? 'Nouvelle inscription'
              : 'Modifier inscription',
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: ListView(
            // Garde tous les champs construits (voir evenement_form_screen).
            cacheExtent: 3000,
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              titreSection('Choisir un événement'),
              choixEvenement(),
              titreSection('Choisir une catégorie'),
              choixCategorie(),
              Container(
                margin: const EdgeInsets.only(top: 16),
                child: TextFormField(
                  initialValue: idAthlete,
                  decoration: const InputDecoration(labelText: 'ID Athlète'),
                  onChanged: (value) {
                    idAthlete = value;
                  },
                  validator: validerAthlete,
                ),
              ),
              titreSection('Statut de l’inscription'),
              choixStatut(),
              Container(
                margin: const EdgeInsets.only(top: 35, bottom: 20),
                child: ElevatedButton(
                  onPressed: enregistrer,
                  child: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
