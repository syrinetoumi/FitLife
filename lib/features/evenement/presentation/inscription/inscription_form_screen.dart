import 'package:flutter/material.dart';

// Votre fichier est dans features/evenement/presentation/inscription/
// ../../          = remonte jusqu'à evenement/
// ../../data/...  = les modèles et repositories sont sous data/
import '../../data/models/categorie.dart';
import '../../data/models/evenement.dart';
import '../../data/models/inscription.dart';
import '../../data/repositories/categorie_repository.dart';
import '../../data/repositories/evenement_repository.dart';
import '../../data/repositories/inscription_repository.dart';
import '../../domain/eligibilite_checker.dart';
import '../../domain/capacite_checker.dart';
import '../../../../core/utils/outils.dart';
import '../paiements/paiement_form_screen.dart';

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
  // La catégorie de l'événement choisi (UNE seule, car chaque
  // événement possède sa catégorie via evenements.id_categorie).
  List<Categorie> categories = [];

  String idAthlete = '';
  String idEvenement = '';
  String idCategorie = '';

  // MÉTIER 1 : informations de l'athlète à vérifier.
  String ageTexte = '';
  NiveauCategorie niveauAthlete = NiveauCategorie.debutant;

  // MÉTIER 1 : places encore disponibles pour l'événement choisi
  // (-1 = pas encore calculé).
  int placesRestantes = -1;

  StatutInscription statut = StatutInscription.enAttente;

  @override
  void initState() {
    super.initState();

    if (widget.inscription != null) {
      Inscription inscription = widget.inscription!;

      idAthlete = inscription.idAthlete;
      idEvenement = inscription.idEvenement;
      idCategorie = inscription.idCategorie;
      ageTexte = inscription.ageAthlete.toString();
      niveauAthlete = inscription.niveauAthlete;
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

      // En modification : charger la catégorie de l'événement choisi.
      if (idEvenement.isNotEmpty) {
        for (Evenement e in evenements) {
          if (e.idEvenement == idEvenement) {
            chargerCategorieEvenement(e);
          }
        }
      }
    } catch (erreur) {
      if (mounted) {
        afficherMessage(context, 'Erreur de chargement : $erreur');
      }
    }
  }

  // La catégorie de l'événement est unique : on la retrouve dans le
  // catalogue et on la présélectionne automatiquement.
  Future<void> chargerCategorieEvenement(Evenement evenement) async {
    try {
      List<Categorie> toutes = await categorieRepository.getCategories();

      Categorie? trouvee;
      for (Categorie c in toutes) {
        if (c.idCategorie == evenement.idCategorie) {
          trouvee = c;
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        categories = [];
        if (trouvee != null) {
          categories.add(trouvee);
          // Présélection automatique (la seule possible).
          idCategorie = trouvee.idCategorie;
        }
      });
    } catch (erreur) {
      if (mounted) {
        afficherMessage(context, 'Erreur de chargement : $erreur');
      }
    }
  }

  // MÉTIER 1 : compter les places restantes de l'événement choisi.
  Future<void> compterPlaces(Evenement evenement) async {
    try {
      List<Inscription> liste =
      await inscriptionRepository.getInscriptionsByEvenement(
        evenement.idEvenement,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        // Règle métier du fichier domain/eligibilite_checker.dart
        placesRestantes = evenement.capacite - compterPlacesPrises(liste);
      });
    } catch (erreur) {
      if (mounted) {
        afficherMessage(context, 'Erreur de chargement : $erreur');
      }
    }
  }

  // MÉTIER 3 : retrouver l'inscription fraîchement créée dans une
  // liste, pour connaître son id généré par Supabase
  // (le paiement en a besoin : relation inscription → paiement).
  Inscription? retrouverInscriptionCreee(
      List<Inscription> liste,
      Inscription cible,
      ) {
    for (Inscription inscription in liste) {
      if (inscription.idAthlete == cible.idAthlete &&
          inscription.idCategorie == cible.idCategorie) {
        return inscription;
      }
    }

    return null;
  }

  String? validerAthlete(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Athlète obligatoire';
    }

    return null;
  }

  // Même principe que validerAge de CategorieFormScreen.
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

    if (idEvenement.isEmpty) {
      afficherMessage(context, 'Choisissez un événement');
      return;
    }

    if (idCategorie.isEmpty || categories.isEmpty) {
      afficherMessage(
        context,
        'Cet événement n’a pas de catégorie : modifiez l’événement '
            'pour lui en affecter une.',
      );
      return;
    }

    // ================================================================
    // MÉTIER 1 — INSCRIPTION INTELLIGENTE
    // Les règles viennent de domain/eligibilite_checker.dart.
    // ================================================================

    // Retrouver l'événement choisi et sa catégorie.
    Evenement evenement = evenements.first;
    for (Evenement e in evenements) {
      if (e.idEvenement == idEvenement) {
        evenement = e;
      }
    }

    // La catégorie de l'événement est unique : c'est la première.
    Categorie categorie = categories.first;

    // Vérifications 1 et 2 : UNIQUEMENT à la création.
    // (Une inscription existante garde sa place, même si l'événement
    // est devenu complet ou terminé entre-temps.)
    if (widget.inscription == null) {
      // Vérification 1 : statut de l'événement.
      if (!evenementOuvert(evenement)) {
        afficherMessage(
          context,
          'Inscriptions fermées : cet événement est '
              '${evenement.statut.name.toUpperCase()}',
        );
        return;
      }

      // Vérification 2 : nombre de places (recompté au moment du clic).
      try {
        List<Inscription> liste = await inscriptionRepository
            .getInscriptionsByEvenement(idEvenement);

        if (!placeDisponible(evenement, liste)) {
          afficherMessage(
            context,
            'Événement complet : plus de place disponible',
          );
          return;
        }
      } catch (erreur) {
        if (mounted) {
          afficherMessage(context, 'Vérification impossible : $erreur');
        }
        return;
      }
    }

    // Vérifications 3 et 4 : TOUJOURS (création ET modification),
    // car l'âge et le niveau restent modifiables dans le formulaire.

    // Vérification 3 : âge de l'athlète dans la catégorie.
    int age = int.parse(ageTexte);
    if (!ageEligible(categorie, age)) {
      afficherMessage(
        context,
        'Âge non éligible : la catégorie « ${categorie.nom} » '
            'accepte de ${categorie.ageMin} à ${categorie.ageMax} ans',
      );
      return;
    }

    // Vérification 4 : niveau de l'athlète = niveau de la catégorie.
    if (!niveauEligible(categorie, niveauAthlete)) {
      afficherMessage(
        context,
        'Niveau requis pour « ${categorie.nom} » : '
            '${categorie.niveau.name.toUpperCase()}',
      );
      return;
    }

    Inscription inscription = Inscription(
      idInscription: widget.inscription?.idInscription ?? '',
      idEvenement: idEvenement,
      idAthlete: idAthlete.trim(),
      idCategorie: idCategorie,
      ageAthlete: int.parse(ageTexte),
      niveauAthlete: niveauAthlete,
      dateInscription: widget.inscription?.dateInscription ?? DateTime.now(),
      statut: statut,
    );

    try {
      if (widget.inscription == null) {
        await inscriptionRepository.ajouter(inscription);

        // ========================================================
        // MÉTIERS 3 et 4 : on relit les inscriptions de
        // l'événement (les deux en ont besoin).
        // ========================================================
        List<Inscription> liste = await inscriptionRepository
            .getInscriptionsByEvenement(idEvenement);

        // --------------------------------------------------------
        // MÉTIER 4 — GESTION DE CAPACITÉ
        // Le nombre maximal de participants est atteint :
        // l'événement passe automatiquement à COMPLET et la
        // vérification 1 du Métier 1 bloquera les nouvelles
        // inscriptions.
        // --------------------------------------------------------
        if (capaciteAtteinte(evenement, liste)) {
          Evenement complet = Evenement(
            idEvenement: evenement.idEvenement,
            nom: evenement.nom,
            description: evenement.description,
            type: evenement.type,
            dateDebut: evenement.dateDebut,
            dateFin: evenement.dateFin,
            heureDebut: evenement.heureDebut,
            lieu: evenement.lieu,
            capacite: evenement.capacite,
            prix: evenement.prix,
            statut: StatutEvenement.complet,
            idCategorie: evenement.idCategorie,
          );

          await evenementRepository.modifier(complet);

          if (mounted) {
            afficherMessage(
              context,
              'La dernière place vient d’être prise : '
                  'l’événement est désormais COMPLET.',
            );
          }
        }

        // --------------------------------------------------------
        // MÉTIER 3 : le parcours continue automatiquement
        // vers le PAIEMENT (étape suivante du sujet).
        // --------------------------------------------------------
        Inscription? creee = retrouverInscriptionCreee(liste, inscription);

        if (creee != null && mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaiementFormScreen(
                inscriptionChoisie: creee,
              ),
            ),
          );
        }
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
                  placesRestantes = -1;
                });

                chargerCategorieEvenement(evenement);
                compterPlaces(evenement);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text(choisi ? '✓ ${evenement.nom}' : evenement.nom),
                    Text(
                      'Statut : ${evenement.statut.name.toUpperCase()} — '
                          'Capacité : ${evenement.capacite}',
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

  // MÉTIER 1 : affiche les places restantes de l'événement choisi.
  Widget cartePlaces() {
    if (idEvenement.isEmpty || placesRestantes < 0) {
      return Container();
    }

    if (placesRestantes == 0) {
      return const Card(
        color: Colors.red,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'Événement COMPLET : plus de place disponible',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      );
    }

    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'Places restantes : $placesRestantes',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  // ================================================================
  // MÉTIER 2 — VÉRIFICATION AUTOMATIQUE DE L'ÉLIGIBILITÉ
  // La catégorie de l'événement (unique) est présélectionnée et
  // affiche EN DIRECT "Éligible" (vert) ou la raison du refus
  // (rouge), grâce à domain/eligibilite_checker.dart.
  // ================================================================
  Widget choixCategorie() {
    if (idEvenement.isEmpty) {
      return const Text('Choisissez d’abord un événement.');
    }

    if (categories.isEmpty) {
      return const Text(
        'Cet événement n’a pas de catégorie : modifiez l’événement.',
      );
    }

    // Âge saisi (null tant que le champ est vide ou invalide).
    int? ageSaisi = int.tryParse(ageTexte);

    Categorie categorie = categories.first;
    bool choisie = idCategorie == categorie.idCategorie;

    // MÉTIER 2 : calcul automatique pour la catégorie de l'événement.
    bool eligible = false;
    if (ageSaisi != null) {
      eligible = categorieEligible(categorie, ageSaisi, niveauAthlete);
    }

    return Card(
      color: choisie ? Colors.blue.shade50 : null,
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

            // MÉTIER 2 : verdict automatique en direct.
            if (ageSaisi != null)
              Text(
                eligible ? '✅ Éligible'
                    : '❌ ${messageEligibilite(
                    categorie, ageSaisi, niveauAthlete)}',
                style: TextStyle(
                  fontSize: 15,
                  color: eligible ? Colors.green : Colors.red,
                ),
              ),

            if (ageSaisi == null)
              const Text(
                'Saisissez votre âge pour voir l’éligibilité',
              ),
          ],
        ),
      ),
    );
  }

  // MÉTIER 1 : choix du niveau de l'athlète.
  // Même GridView.builder que choixStatut() (Chapitre 4).
  Widget choixNiveauAthlete() {
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
              niveauAthlete = valeur;
            });
          },
          child: Text(niveauAthlete == valeur ? '✓ $libelle' : libelle),
        );
      },
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
              cartePlaces(),
              titreSection('Catégorie de l’événement'),
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
              TextFormField(
                initialValue: ageTexte,
                keyboardType: TextInputType.number,
                decoration:
                const InputDecoration(labelText: 'Âge de l’athlète'),
                onChanged: (value) {
                  // MÉTIER 2 : setState pour redessiner la carte
                  // catégorie à chaque touche (verdict en direct).
                  setState(() {
                    ageTexte = value;
                  });
                },
                validator: validerAge,
              ),
              titreSection('Niveau de l’athlète'),
              choixNiveauAthlete(),
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
