import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
import '../widgets/recaptcha_widget.dart';

class InscriptionFormScreen extends StatefulWidget {
  final Inscription? inscription;
  final Evenement? evenementInitial;

  const InscriptionFormScreen({
    super.key,
    this.inscription,
    this.evenementInitial,
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

  // MÉTIER 1 : informations de l'athlète à vérifier.
  String ageTexte = '';
  NiveauCategorie niveauAthlete = NiveauCategorie.debutant;

  // MÉTIER 1 : places encore disponibles (-1 = pas encore calculé).
  int placesRestantes = -1;

  StatutInscription statut = StatutInscription.enAttente;

  // 📌 SÉCURITÉ ANTI-BOT GOOGLE reCAPTCHA
  bool captchaValide = false;

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
      // En modification, pas besoin de redemander le captcha
      captchaValide = true;
    } else if (widget.evenementInitial != null) {
      idEvenement = widget.evenementInitial!.idEvenement;
      idCategorie = widget.evenementInitial!.idCategorie;
    }

    chargerEvenements();
  }

  Future<void> chargerEvenements() async {
    try {
      List<Evenement> resultat = await evenementRepository.getEvenements();

      if (!mounted) return;

      setState(() {
        evenements = resultat;
      });

      if (idEvenement.isNotEmpty) {
        for (Evenement e in evenements) {
          if (e.idEvenement == idEvenement) {
            chargerCategorieEvenement(e);
            compterPlaces(e);
          }
        }
      }
    } catch (erreur) {
      if (mounted) {
        afficherMessage(context, 'Erreur de chargement : $erreur');
      }
    }
  }

  Future<void> chargerCategorieEvenement(Evenement evenement) async {
    try {
      List<Categorie> toutes = await categorieRepository.getCategories();

      Categorie? trouvee;
      for (Categorie c in toutes) {
        if (c.idCategorie == evenement.idCategorie) {
          trouvee = c;
        }
      }

      if (!mounted) return;

      setState(() {
        categories = [];
        if (trouvee != null) {
          categories.add(trouvee);
          idCategorie = trouvee.idCategorie;
        }
      });
    } catch (erreur) {
      if (mounted) {
        afficherMessage(context, 'Erreur de chargement : $erreur');
      }
    }
  }

  Future<void> compterPlaces(Evenement evenement) async {
    try {
      List<Inscription> liste = await inscriptionRepository.getInscriptionsByEvenement(
        evenement.idEvenement,
      );

      if (!mounted) return;

      setState(() {
        placesRestantes = evenement.capacite - compterPlacesPrises(liste);
      });
    } catch (erreur) {
      if (mounted) {
        afficherMessage(context, 'Erreur de chargement : $erreur');
      }
    }
  }

  Inscription? retrouverInscriptionCreee(List<Inscription> liste, Inscription cible) {
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
        'Cet événement n’a pas de catégorie : modifiez l’événement pour lui en affecter une.',
      );
      return;
    }

    // 📌 CONTRÔLE SÉCURITÉ GOOGLE reCAPTCHA (Nouvelle inscription)
    if (widget.inscription == null && !captchaValide) {
      afficherMessage(
        context,
        'Sécurité : Veuillez valider la case « Je ne suis pas un robot »',
      );
      return;
    }

    Evenement evenement = evenements.first;
    for (Evenement e in evenements) {
      if (e.idEvenement == idEvenement) {
        evenement = e;
      }
    }

    Categorie categorie = categories.first;

    // MÉTIER 1 : Vérifications 1 & 2
    if (widget.inscription == null) {
      if (!evenementOuvert(evenement)) {
        afficherMessage(
          context,
          'Inscriptions fermées : cet événement est ${evenement.statut.name.toUpperCase()}',
        );
        return;
      }

      try {
        List<Inscription> liste = await inscriptionRepository.getInscriptionsByEvenement(idEvenement);
        if (!placeDisponible(evenement, liste)) {
          afficherMessage(context, 'Événement complet : plus de place disponible');
          return;
        }
      } catch (erreur) {
        if (mounted) afficherMessage(context, 'Vérification impossible : $erreur');
        return;
      }
    }

    // MÉTIER 1 : Vérifications 3 & 4
    int age = int.parse(ageTexte);
    if (!ageEligible(categorie, age)) {
      afficherMessage(
        context,
        'Âge non éligible : la catégorie « ${categorie.nom} » accepte de ${categorie.ageMin} à ${categorie.ageMax} ans',
      );
      return;
    }

    if (!niveauEligible(categorie, niveauAthlete)) {
      afficherMessage(
        context,
        'Niveau requis pour « ${categorie.nom} » : ${categorie.niveau.name.toUpperCase()}',
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

        List<Inscription> liste = await inscriptionRepository.getInscriptionsByEvenement(idEvenement);

        // MÉTIER 4 : Capacité max atteinte => bascule automatique à COMPLET
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
              'La dernière place vient d’être prise : l’événement est désormais COMPLET.',
            );
          }
        }

        // MÉTIER 3 : si confirmée => redirection vers PAIEMENT
        if (statut == StatutInscription.confirmee) {
          Inscription? creee = retrouverInscriptionCreee(liste, inscription);
          if (creee != null && mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaiementFormScreen(inscriptionChoisie: creee),
              ),
            );
          }
        } else {
          if (mounted) {
            afficherMessage(
              context,
              'Inscription enregistrée EN ATTENTE. Retrouvez-la dans votre Panier !',
            );
          }
        }
      } else {
        await inscriptionRepository.modifier(inscription);
      }

      if (mounted) Navigator.pop(context);
    } catch (erreur) {
      if (mounted) afficherMessage(context, 'Enregistrement impossible : $erreur');
    }
  }

  Widget titreSection(String texte) {
    return Container(
        margin: const EdgeInsets.only(top: 20, bottom: 8),
          child: Text(
            texte,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        );
    }

  Widget evenementSelectionne() {
    Evenement? evt;
    for (Evenement e in evenements) {
      if (e.idEvenement == idEvenement) {
        evt = e;
        break;
      }
    }
    evt ??= widget.evenementInitial;

    String nom = evt?.nom ?? 'Événement sélectionné';
    String statutEvt = evt != null ? evt.statut.name.toUpperCase() : 'OUVERT';
    int capacite = evt?.capacite ?? 0;

    return Card(
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.blue.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nom.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Capacité : $capacite places',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statutEvt,
                style: TextStyle(
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  // MÉTIER 2 — Calcul d'éligibilité en direct à la frappe
  Widget choixCategorie() {
    if (idEvenement.isEmpty) {
      return const Text('Choisissez d’abord un événement.');
    }

    if (categories.isEmpty) {
      return const Text('Cet événement n’a pas de catégorie : modifiez l’événement.');
    }

    int? ageSaisi = int.tryParse(ageTexte);
    Categorie categorie = categories.first;
    bool choisie = idCategorie == categorie.idCategorie;

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
            Text('Âge : ${categorie.ageMin} - ${categorie.ageMax} ans'),
            Text('Niveau : ${categorie.niveau.name.toUpperCase()}'),
            if (ageSaisi != null)
              Text(
                eligible ? '✅ Éligible' : '❌ ${messageEligibilite(categorie, ageSaisi, niveauAthlete)}',
                style: TextStyle(
                  fontSize: 15,
                  color: eligible ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (ageSaisi == null)
              const Text('Saisissez votre âge pour voir l’éligibilité'),
          ],
        ),
      ),
    );
  }

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

  Widget choixStatut() {
    final List<StatutInscription> statutsDisponibles = [
      StatutInscription.confirmee,
      StatutInscription.enAttente,
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: statutsDisponibles.length,
      itemBuilder: (context, index) {
        StatutInscription valeur = statutsDisponibles[index];
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
          widget.inscription == null ? 'Nouvelle inscription' : 'Modifier inscription',
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: ListView(
            cacheExtent: 3000,
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              titreSection('Événement sélectionné'),
              evenementSelectionne(),
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
                decoration: const InputDecoration(labelText: 'Âge de l’athlète'),
                onChanged: (value) {
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

              // 📌 CONTRÔLE DE SÉCURITÉ GOOGLE reCAPTCHA (Nouvelle Inscription)
              if (widget.inscription == null) ...[
                titreSection('Contrôle de sécurité anti-bot'),
                RecaptchaWidget(
                  onVerifie: (valide) {
                    setState(() {
                      captchaValide = valide;
                    });
                  },
                ),
              ],

              Container(
                margin: const EdgeInsets.only(top: 35, bottom: 20),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: enregistrer,
                  child: const Text('Enregistrer', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}