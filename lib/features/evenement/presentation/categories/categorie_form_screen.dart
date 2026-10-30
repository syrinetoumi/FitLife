import 'package:flutter/material.dart';

import 'package:coach_app/core/utils/alertes.dart';
import '../../data/models/categorie.dart';
import '../../data/repositories/categorie_repository.dart';

// Formulaire catégorie : gestion du CATALOGUE
// (nom, âges, niveau). Une catégorie n'est plus liée
// à un événement : l'affectation se fait dans le
// formulaire événement.
class CategorieFormScreen extends StatefulWidget {
  final Categorie? categorie;

  const CategorieFormScreen({
    super.key,
    this.categorie,
  });

  @override
  State<CategorieFormScreen> createState() => _CategorieFormScreenState();
}

class _CategorieFormScreenState extends State<CategorieFormScreen> {
  final formKey = GlobalKey<FormState>();

  CategorieRepository categorieRepository = CategorieRepository();

  String nom = '';
  String ageMinTexte = '';
  String ageMaxTexte = '';
  NiveauCategorie niveau = NiveauCategorie.debutant;

  @override
  void initState() {
    super.initState();

    if (widget.categorie != null) {
      Categorie categorie = widget.categorie!;

      nom = categorie.nom;
      ageMinTexte = categorie.ageMin.toString();
      ageMaxTexte = categorie.ageMax.toString();
      niveau = categorie.niveau;
    }
  }

  String? validerNom(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nom obligatoire';
    }

    return null;
  }

  String? validerAge(String? value) {
    int? age = int.tryParse(value ?? '');

    if (age == null || age < 0 || age > 120) {
      return 'Âge invalide';
    }

    return null;
  }

  Future<void> enregistrer() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    int ageMin = int.parse(ageMinTexte);
    int ageMax = int.parse(ageMaxTexte);

    if (ageMin > ageMax) {
      afficherAlerteErreur(
        context,
        titre: 'Âges incorrects',
        message: 'L’âge minimum dépasse l’âge maximum.',
      );
      return;
    }

    Categorie categorie = Categorie(
      idCategorie: widget.categorie?.idCategorie ?? '',
      nom: nom.trim(),
      ageMin: ageMin,
      ageMax: ageMax,
      niveau: niveau,
    );

    try {
      if (widget.categorie == null) {
        await categorieRepository.ajouter(categorie);
      } else {
        await categorieRepository.modifier(categorie);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (erreur) {
      if (mounted) {
        afficherAlerteErreur(
          context,
          titre: 'Enregistrement impossible',
          message: '$erreur',
        );
      }
    }
  }

  Widget titreSection(String texte) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Text(
        texte,
        style: const TextStyle(fontSize: 18),
      ),
    );
  }

  // Choix du niveau : GridView.builder (Chapitre 4).
  Widget choixNiveau() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: NiveauCategorie.values.length,
      itemBuilder: (context, index) {
        NiveauCategorie valeur = NiveauCategorie.values[index];
        String libelle = valeur.name.toUpperCase();

        return ElevatedButton(
          onPressed: () {
            setState(() {
              niveau = valeur;
            });
          },
          child: Text(niveau == valeur ? '✓ $libelle' : libelle),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.categorie == null ? 'Ajouter catégorie' : 'Modifier catégorie',
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              // Un seul Column : espacement régulier entre tous les champs.
              Column(
                spacing: 16,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    initialValue: nom,
                    decoration: const InputDecoration(
                      labelText: 'Nom de la catégorie',
                    ),
                    onChanged: (value) {
                      nom = value;
                    },
                    validator: validerNom,
                  ),
                  TextFormField(
                    initialValue: ageMinTexte,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Âge minimum',
                    ),
                    onChanged: (value) {
                      ageMinTexte = value;
                    },
                    validator: validerAge,
                  ),
                  TextFormField(
                    initialValue: ageMaxTexte,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Âge maximum',
                    ),
                    onChanged: (value) {
                      ageMaxTexte = value;
                    },
                    validator: validerAge,
                  ),
                  titreSection('Niveau'),
                  choixNiveau(),
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    child: ElevatedButton(
                      onPressed: enregistrer,
                      child: const Text('Enregistrer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}