import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:coach_app/core/utils/alertes.dart';
import 'package:coach_app/core/utils/outils.dart';
import 'package:coach_app/features/entrainement/data/models/enums.dart';
import 'package:coach_app/features/entrainement/data/models/programme.dart';
import 'package:coach_app/features/entrainement/data/models/seance.dart';
import 'package:coach_app/features/entrainement/data/repositories/programme_repository.dart';
import 'package:coach_app/features/entrainement/data/repositories/seance_repository.dart';
import 'libelles_seance.dart';

class SeanceFormScreen extends StatefulWidget {
  final Seance? seance;

  const SeanceFormScreen({
    super.key,
    this.seance,
  });

  @override
  State<SeanceFormScreen> createState() => _SeanceFormScreenState();
}

class _SeanceFormScreenState extends State<SeanceFormScreen> {
  final formKey = GlobalKey<FormState>();

  SeanceRepository seanceRepository = SeanceRepository();
  ProgrammeRepository programmeRepository = ProgrammeRepository();

  String titre = '';
  String description = '';
  String dateTexte = '';
  String heureDebutTexte = '';
  String heureFinTexte = '';
  String capaciteTexte = '';
  String prixTexte = '';

  TypeSeance type = TypeSeance.COLLECTIVE;
  StatutSeance statut = StatutSeance.PLANIFIEE;
  int? idProgramme;
  List<Programme> programmes = [];

  @override
  void initState() {
    super.initState();

    if (widget.seance != null) {
      Seance seance = widget.seance!;

      titre = seance.titre;
      description = seance.description ?? '';
      dateTexte = afficherDate(seance.date);
      heureDebutTexte = seance.debutCourt;
      heureFinTexte = seance.finCourt;
      capaciteTexte = seance.capacite?.toString() ?? '';
      prixTexte = seance.prix == 0 ? '' : seance.prix.toString();
      type = seance.type;
      statut = seance.statut;
      idProgramme = seance.idProgramme;
    }

    chargerProgrammes();
  }

  Future<void> chargerProgrammes() async {
    try {
      List<Programme> resultat =
      await programmeRepository.getProgrammesDuCoach();

      if (mounted) {
        setState(() {
          programmes = resultat;
        });
      }
    } catch (erreur) {
      // Le programme est facultatif : on continue sans la liste.
    }
  }

  String? validerTitre(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Titre obligatoire';
    }

    return null;
  }

  String? validerDate(String? value) {
    DateTime? date = lireDate(value ?? '');

    if (date == null) {
      return 'Date invalide (jj/mm/aaaa)';
    }

    // Une nouvelle séance ne peut pas être dans le passé.
    DateTime maintenant = DateTime.now();
    DateTime aujourdhui =
    DateTime(maintenant.year, maintenant.month, maintenant.day);

    if (widget.seance == null && date.isBefore(aujourdhui)) {
      return 'La date est déjà passée';
    }

    return null;
  }

  String? validerHeure(String? value) {
    if (lireHeure(value ?? '') == null) {
      return 'Heure invalide (hh:mm)';
    }

    return null;
  }

  String? validerCapacite(String? value) {
    int? capacite = int.tryParse((value ?? '').trim());

    if (capacite == null || capacite <= 0) {
      return 'Capacité invalide';
    }

    return null;
  }

  // Le prix est facultatif : vide = gratuit.
  String? validerPrix(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    double? prix = double.tryParse(value.trim().replaceAll(',', '.'));

    if (prix == null || prix < 0) {
      return 'Prix invalide';
    }

    return null;
  }

  Future<void> enregistrer() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    User? utilisateur = Supabase.instance.client.auth.currentUser;

    if (utilisateur == null) {
      afficherMessage(context, 'Connectez-vous d’abord.');
      return;
    }

    DateTime date = lireDate(dateTexte)!;
    String heureDebut = lireHeure(heureDebutTexte)!;
    String heureFin = lireHeure(heureFinTexte)!;

    if (heureFin.compareTo(heureDebut) <= 0) {
      afficherAlerteErreur(
        context,
        titre: 'Horaire incorrect',
        message: 'L’heure de fin doit être après l’heure de début.',
      );
      return;
    }

    // Séance individuelle : une seule place.
    int capacite = 1;

    if (type == TypeSeance.COLLECTIVE) {
      capacite = int.parse(capaciteTexte.trim());
    }

    double prix = 0;

    if (prixTexte.trim().isNotEmpty) {
      prix = double.parse(prixTexte.trim().replaceAll(',', '.'));
    }

    try {
      // Métier 4 : vérification des conflits avant l'enregistrement.
      // Une séance annulée libère son créneau : pas de vérification.
      if (statut != StatutSeance.ANNULEE) {
        Seance? conflit = await seanceRepository.trouverConflit(
          date: date,
          heureDebut: heureDebut,
          heureFin: heureFin,
          ignorerId: widget.seance?.id,
        );

        if (conflit != null) {
          if (mounted) {
            afficherAlerteErreur(
              context,
              titre: 'Créneau déjà occupé',
              message: 'Vous avez déjà la séance « ${conflit.titre} » '
                  'le ${afficherDate(conflit.date)} '
                  'de ${conflit.debutCourt} à ${conflit.finCourt}.\n\n'
                  'Choisissez un autre horaire.',
            );
          }
          return;
        }
      }

      Seance seance = Seance(
        id: widget.seance?.id,
        titre: titre.trim(),
        description: description.trim(),
        date: date,
        heureDebut: heureDebut,
        heureFin: heureFin,
        type: type,
        capacite: capacite,
        prix: prix,
        statut: statut,
        idCoach: widget.seance?.idCoach ?? utilisateur.id,
        idProgramme: idProgramme,
        idEspaceSportif: widget.seance?.idEspaceSportif,
      );

      if (widget.seance == null) {
        await seanceRepository.ajouter(seance);
      } else {
        await seanceRepository.modifier(
          seance,
          avecStatut: statut != widget.seance!.statut,
        );
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

  Widget choixType() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {
            setState(() {
              type = TypeSeance.INDIVIDUELLE;
            });
          },
          child: Text(
            type == TypeSeance.INDIVIDUELLE
                ? '✓ Individuelle'
                : 'Individuelle',
          ),
        ),
        Container(
          margin: const EdgeInsets.only(left: 10),
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                type = TypeSeance.COLLECTIVE;
              });
            },
            child: Text(
              type == TypeSeance.COLLECTIVE ? '✓ Collective' : 'Collective',
            ),
          ),
        ),
      ],
    );
  }

  // Statut : uniquement en modification.
  // Planifiée / Complète sont gérées par la base selon les réservations.
  Widget choixStatut() {
    StatutSeance actuel = widget.seance!.statut;

    List<StatutSeance> options = [
      StatutSeance.PLANIFIEE,
      StatutSeance.ANNULEE,
      StatutSeance.TERMINEE,
    ];

    // Séance complète : on ne la remet pas à la main en "Planifiée".
    if (actuel == StatutSeance.COMPLETE) {
      options = [StatutSeance.ANNULEE, StatutSeance.TERMINEE];
    }

    String note = 'Annulée libère le créneau. '
        'Une séance devient "Complète" toute seule quand toutes les '
        'places sont réservées.';

    if (actuel == StatutSeance.COMPLETE) {
      note = 'Cette séance est complète (statut automatique). '
          'Vous pouvez l’annuler ou la marquer comme terminée.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((valeur) {
            String libelle = libelleStatutSeance(valeur);

            return ElevatedButton(
              onPressed: () {
                setState(() {
                  statut = valeur;
                });
              },
              child: Text(statut == valeur ? '✓ $libelle' : libelle),
            );
          }).toList(),
        ),
        Container(
          margin: const EdgeInsets.only(top: 8),
          child: Text(
            note,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  // Programme facultatif : on choisit parmi ceux du coach.
  Widget choixProgramme() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ElevatedButton(
          onPressed: () {
            setState(() {
              idProgramme = null;
            });
          },
          child: Text(idProgramme == null ? '✓ Aucun' : 'Aucun'),
        ),
        ...programmes.map((programme) {
          bool choisi = idProgramme == programme.id;

          return ElevatedButton(
            onPressed: () {
              setState(() {
                idProgramme = programme.id;
              });
            },
            child: Text(choisi ? '✓ ${programme.nom}' : programme.nom),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.seance == null ? 'Ajouter séance' : 'Modifier séance',
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
                    initialValue: titre,
                    decoration: const InputDecoration(labelText: 'Titre'),
                    onChanged: (value) {
                      titre = value;
                    },
                    validator: validerTitre,
                  ),
                  TextFormField(
                    initialValue: description,
                    decoration:
                    const InputDecoration(labelText: 'Description'),
                    onChanged: (value) {
                      description = value;
                    },
                  ),
                  titreSection('Date et horaire'),
                  TextFormField(
                    initialValue: dateTexte,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(
                      labelText: 'Date (jj/mm/aaaa)',
                    ),
                    onChanged: (value) {
                      dateTexte = value;
                    },
                    validator: validerDate,
                  ),
                  TextFormField(
                    initialValue: heureDebutTexte,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(
                      labelText: 'Heure de début (hh:mm)',
                    ),
                    onChanged: (value) {
                      heureDebutTexte = value;
                    },
                    validator: validerHeure,
                  ),
                  TextFormField(
                    initialValue: heureFinTexte,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(
                      labelText: 'Heure de fin (hh:mm)',
                    ),
                    onChanged: (value) {
                      heureFinTexte = value;
                    },
                    validator: validerHeure,
                  ),
                  titreSection('Type'),
                  choixType(),
                  if (type == TypeSeance.COLLECTIVE)
                    TextFormField(
                      initialValue: capaciteTexte,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Capacité (nombre de places)',
                      ),
                      onChanged: (value) {
                        capaciteTexte = value;
                      },
                      validator: validerCapacite,
                    ),
                  TextFormField(
                    initialValue: prixTexte,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Prix en DT (vide = gratuit)',
                    ),
                    onChanged: (value) {
                      prixTexte = value;
                    },
                    validator: validerPrix,
                  ),
                  if (widget.seance != null) ...[
                    titreSection('Statut'),
                    choixStatut(),
                  ],
                  titreSection('Programme (facultatif)'),
                  choixProgramme(),
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