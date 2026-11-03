import 'package:flutter/material.dart';

import 'package:coach_app/core/utils/alertes.dart';
import 'package:coach_app/core/utils/outils.dart';
import '../../data/models/categorie.dart';
import '../../data/models/evenement.dart';
import '../../data/repositories/categorie_repository.dart';
import '../../data/repositories/evenement_repository.dart';
import '../categories/categorie_form_screen.dart';

class EvenementFormScreen extends StatefulWidget {
  final Evenement? evenement;

  const EvenementFormScreen({
    super.key,
    this.evenement,
  });

  @override
  State<EvenementFormScreen> createState() => _EvenementFormScreenState();
}

class _EvenementFormScreenState extends State<EvenementFormScreen> {
  final formKey = GlobalKey<FormState>();

  EvenementRepository evenementRepository = EvenementRepository();
  CategorieRepository categorieRepository = CategorieRepository();

  // Valeurs du formulaire (mises à jour par onChanged).
  String nom = '';
  String description = '';
  String lieu = '';
  String capaciteTexte = '';
  String prixTexte = '';
  String dateDebutTexte = '';
  String dateFinTexte = '';
  String heureTexte = '';

  TypeEvenement type = TypeEvenement.marathon;
  StatutEvenement statut = StatutEvenement.brouillon;

  // La catégorie de l'événement : choisie dans le catalogue
  // (champ scrollable + bouton "+").
  List<Categorie> categories = [];
  String idCategorie = '';

  @override
  void initState() {
    super.initState();

    if (widget.evenement != null) {
      Evenement evenement = widget.evenement!;

      nom = evenement.nom;
      description = evenement.description;
      lieu = evenement.lieu;
      capaciteTexte = evenement.capacite.toString();
      prixTexte = evenement.prix.toString();
      dateDebutTexte = afficherDate(evenement.dateDebut);
      dateFinTexte = afficherDate(evenement.dateFin);
      heureTexte = evenement.heureDebut;
      type = evenement.type;
      statut = evenement.statut;
      // En modification : la catégorie actuelle est présélectionnée.
      idCategorie = evenement.idCategorie;
    }

    chargerCategories();
  }

  // Le catalogue des catégories (identique en création
  // et en modification : il ne dépend pas de l'événement).
  Future<void> chargerCategories() async {
    try {
      List<Categorie> resultat = await categorieRepository.getCategories();

      if (!mounted) {
        return;
      }

      setState(() {
        categories = resultat;
      });
    } catch (erreur) {
      if (mounted) {
        afficherAlerteErreur(
          context,
          titre: 'Chargement impossible',
          message: '$erreur',
        );
      }
    }
  }

  String? validerObligatoire(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Champ obligatoire';
    }

    return null;
  }

  String? validerCapacite(String? value) {
    int? capacite = int.tryParse(value ?? '');

    if (capacite == null || capacite <= 0) {
      return 'Capacité invalide';
    }

    return null;
  }

  String? validerPrix(String? value) {
    double? prix = double.tryParse((value ?? '').replaceAll(',', '.'));

    if (prix == null || prix < 0) {
      return 'Prix invalide';
    }

    return null;
  }

  String? validerDate(String? value) {
    if (lireDate(value ?? '') == null) {
      return 'Date invalide (jj/mm/aaaa)';
    }

    return null;
  }

  String? validerHeure(String? value) {
    if (lireHeure(value ?? '') == null) {
      return 'Heure invalide (hh:mm)';
    }

    return null;
  }

  Future<void> enregistrer() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    // La catégorie est obligatoire (création ET modification).
    if (idCategorie.isEmpty) {
      afficherAlerteErreur(
        context,
        titre: 'Catégorie manquante',
        message: 'Choisissez une catégorie pour l’événement.',
      );
      return;
    }

    DateTime? dateDebut = lireDate(dateDebutTexte);
    DateTime? dateFin = lireDate(dateFinTexte);
    String? heure = lireHeure(heureTexte);

    if (dateDebut == null || dateFin == null || heure == null) {
      afficherAlerteErreur(
        context,
        titre: 'Dates incorrectes',
        message: 'Dates ou heure invalides.',
      );
      return;
    }

    if (dateFin.isBefore(dateDebut)) {
      afficherAlerteErreur(
        context,
        titre: 'Dates incorrectes',
        message: 'La date de fin doit être après la date de début.',
      );
      return;
    }

    Evenement evenement = Evenement(
      idEvenement: widget.evenement?.idEvenement ?? '',
      nom: nom.trim(),
      description: description.trim(),
      type: type,
      dateDebut: dateDebut,
      dateFin: dateFin,
      heureDebut: heure,
      lieu: lieu.trim(),
      capacite: int.parse(capaciteTexte),
      prix: double.parse(prixTexte.replaceAll(',', '.')),
      statut: statut,
      idCategorie: idCategorie,
    );

    try {
      if (widget.evenement == null) {
        await evenementRepository.ajouter(evenement);
      } else {
        await evenementRepository.modifier(evenement);
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

  // Bouton "+" : ouvre le formulaire catégorie ; au retour, la zone
  // se recharge et la NOUVELLE catégorie est présélectionnée.
  Future<void> ouvrirFormulaireCategorie() async {
    // On mémorise le catalogue actuel pour repérer la nouveauté.
    List<String> anciensIds = [];
    for (Categorie c in categories) {
      anciensIds.add(c.idCategorie);
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CategorieFormScreen(),
      ),
    );

    await chargerCategories();

    if (!mounted) {
      return;
    }

    // La catégorie qui n'était pas là avant = la nouvelle.
    for (Categorie c in categories) {
      if (!anciensIds.contains(c.idCategorie)) {
        setState(() {
          idCategorie = c.idCategorie;
        });
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

  // Champ scrollable des catégories : ListView.builder (Chapitre 3)
  // dans une zone de hauteur fixe, chaque ligne est cliquable
  // (InkWell, Chapitre 5).
  Widget zoneCategorie() {
    if (categories.isEmpty) {
      return const Text(
        'Aucune catégorie : appuyez sur + pour en créer une.',
      );
    }

    return Container(
      height: 200,
      child: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          Categorie categorie = categories[index];
          bool choisie = idCategorie == categorie.idCategorie;

          return Card(
            color: choisie ? Colors.deepPurple.shade50 : null,
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
                    Text(
                      'Niveau : ${categorie.niveau.name.toUpperCase()}',
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Choix du type : GridView.builder (Chapitre 4).
  Widget choixType() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: TypeEvenement.values.length,
      itemBuilder: (context, index) {
        TypeEvenement valeur = TypeEvenement.values[index];
        String libelle = valeur.name.toUpperCase();

        return ElevatedButton(
          onPressed: () {
            setState(() {
              type = valeur;
            });
          },
          child: Text(type == valeur ? '✓ $libelle' : libelle),
        );
      },
    );
  }

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
      itemCount: StatutEvenement.values.length,
      itemBuilder: (context, index) {
        StatutEvenement valeur = StatutEvenement.values[index];
        String libelle = valeur.name.toUpperCase();

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
          widget.evenement == null ? 'Ajouter événement' : 'Modifier événement',
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              // Un seul Column : espacement régulier entre tous les champs
              // (et tous les champs restent construits, donc validés).
              Column(
                spacing: 16,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    initialValue: nom,
                    decoration: const InputDecoration(labelText: 'Nom'),
                    onChanged: (value) {
                      nom = value;
                    },
                    validator: validerObligatoire,
                  ),
                  TextFormField(
                    initialValue: description,
                    decoration:
                    const InputDecoration(labelText: 'Description'),
                    onChanged: (value) {
                      description = value;
                    },
                  ),
                  TextFormField(
                    initialValue: lieu,
                    decoration: const InputDecoration(labelText: 'Lieu'),
                    onChanged: (value) {
                      lieu = value;
                    },
                    validator: validerObligatoire,
                  ),
                  TextFormField(
                    initialValue: capaciteTexte,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Capacité'),
                    onChanged: (value) {
                      capaciteTexte = value;
                    },
                    validator: validerCapacite,
                  ),
                  TextFormField(
                    initialValue: prixTexte,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Prix (DT)'),
                    onChanged: (value) {
                      prixTexte = value;
                    },
                    validator: validerPrix,
                  ),
                  titreSection('Type de l’événement'),
                  choixType(),

                  // CATÉGORIE : titre + icône "+", puis champ scrollable.
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Catégorie de l’événement',
                          style: TextStyle(fontSize: 18),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: ouvrirFormulaireCategorie,
                        ),
                      ],
                    ),
                  ),
                  zoneCategorie(),

                  titreSection('Date et heure'),
                  TextFormField(
                    initialValue: dateDebutTexte,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(
                      labelText: 'Date de début (jj/mm/aaaa)',
                    ),
                    onChanged: (value) {
                      dateDebutTexte = value;
                    },
                    validator: validerDate,
                  ),
                  TextFormField(
                    initialValue: dateFinTexte,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(
                      labelText: 'Date de fin (jj/mm/aaaa)',
                    ),
                    onChanged: (value) {
                      dateFinTexte = value;
                    },
                    validator: validerDate,
                  ),
                  TextFormField(
                    initialValue: heureTexte,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(
                      labelText: 'Heure de début (hh:mm)',
                    ),
                    onChanged: (value) {
                      heureTexte = value;
                    },
                    validator: validerHeure,
                  ),
                  titreSection('Statut'),
                  choixStatut(),
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