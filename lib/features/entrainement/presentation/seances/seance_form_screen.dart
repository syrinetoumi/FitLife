import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:coach_app/core/theme/app_theme.dart';
import 'package:coach_app/core/utils/alertes.dart';
import 'package:coach_app/core/utils/outils.dart';
import 'package:coach_app/core/widgets/bouton_principal.dart';
import 'package:coach_app/core/widgets/en_tete_diagonal.dart';
import 'package:coach_app/core/widgets/formulaire.dart';
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

  // Date et heures : controllers, car les sélecteurs écrivent dans le champ.
  final TextEditingController dateController = TextEditingController();
  final TextEditingController debutController = TextEditingController();
  final TextEditingController finController = TextEditingController();

  String titre = '';
  String description = '';
  String capaciteTexte = '';
  String prixTexte = '';

  TypeSeance type = TypeSeance.COLLECTIVE;
  StatutSeance statut = StatutSeance.PLANIFIEE;
  int? idProgramme;
  List<Programme> programmes = [];

  bool enCours = false;

  @override
  void initState() {
    super.initState();

    if (widget.seance != null) {
      Seance seance = widget.seance!;

      titre = seance.titre;
      description = seance.description ?? '';
      dateController.text = afficherDate(seance.date);
      debutController.text = seance.debutCourt;
      finController.text = seance.finCourt;
      capaciteTexte = seance.capacite?.toString() ?? '';
      prixTexte = seance.prix == 0 ? '' : seance.prix.toString();
      type = seance.type;
      statut = seance.statut;
      idProgramme = seance.idProgramme;
    }

    chargerProgrammes();
  }

  @override
  void dispose() {
    dateController.dispose();
    debutController.dispose();
    finController.dispose();
    super.dispose();
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

  // Calendrier : écrit la date choisie (jj/mm/aaaa) dans le champ.
  Future<void> choisirDate() async {
    DateTime maintenant = DateTime.now();
    DateTime aujourdhui =
    DateTime(maintenant.year, maintenant.month, maintenant.day);

    // Nouvelle séance : le calendrier commence à aujourd'hui.
    DateTime premiere = widget.seance == null ? aujourdhui : DateTime(2000);
    DateTime initiale = lireDate(dateController.text) ?? aujourdhui;

    if (initiale.isBefore(premiere)) {
      initiale = premiere;
    }

    DateTime? choisie = await showDatePicker(
      context: context,
      initialDate: initiale,
      firstDate: premiere,
      lastDate: DateTime(2100),
    );

    if (choisie != null) {
      dateController.text = afficherDate(choisie);
    }
  }

  // Horloge : écrit l'heure choisie (hh:mm) dans le champ.
  Future<void> choisirHeure(TextEditingController controller) async {
    TimeOfDay initiale = TimeOfDay.now();
    String? texte = lireHeure(controller.text);

    if (texte != null) {
      List<String> parties = texte.split(':');
      initiale = TimeOfDay(
        hour: int.parse(parties[0]),
        minute: int.parse(parties[1]),
      );
    }

    TimeOfDay? choisie = await showTimePicker(
      context: context,
      initialTime: initiale,
      // Format 24 h, comme dans le champ.
      builder: (contexte, enfant) {
        return MediaQuery(
          data: MediaQuery.of(contexte).copyWith(alwaysUse24HourFormat: true),
          child: enfant!,
        );
      },
    );

    if (choisie != null) {
      String heure = choisie.hour.toString().padLeft(2, '0');
      String minute = choisie.minute.toString().padLeft(2, '0');
      controller.text = '$heure:$minute';
    }
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

    DateTime date = lireDate(dateController.text)!;
    String heureDebut = lireHeure(debutController.text)!;
    String heureFin = lireHeure(finController.text)!;

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

    setState(() {
      enCours = true;
    });

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
            setState(() {
              enCours = false;
            });

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
        setState(() {
          enCours = false;
        });

        afficherAlerteErreur(
          context,
          titre: 'Enregistrement impossible',
          message: '$erreur',
        );
      }
    }
  }

  Widget boutonCalendrier() {
    return IconButton(
      icon: const Icon(Icons.calendar_month),
      tooltip: 'Choisir une date',
      onPressed: choisirDate,
    );
  }

  Widget boutonHorloge(TextEditingController controller) {
    return IconButton(
      icon: const Icon(Icons.schedule),
      tooltip: 'Choisir une heure',
      onPressed: () => choisirHeure(controller),
    );
  }

  // Individuelle / Collective : bouton segmenté (un seul choix).
  Widget choixType() {
    return SegmentedButton<TypeSeance>(
      segments: const [
        ButtonSegment(
          value: TypeSeance.INDIVIDUELLE,
          label: Text('Individuelle'),
          icon: Icon(Icons.person),
        ),
        ButtonSegment(
          value: TypeSeance.COLLECTIVE,
          label: Text('Collective'),
          icon: Icon(Icons.groups),
        ),
      ],
      selected: {type},
      showSelectedIcon: false,
      expandedInsets: EdgeInsets.zero,
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: AppCouleurs.principale,
        selectedForegroundColor: Colors.white,
      ),
      onSelectionChanged: (selection) {
        setState(() {
          type = selection.first;
        });
      },
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
      spacing: 12,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChoixPuces<StatutSeance>(
          items: options,
          estChoisi: (valeur) => statut == valeur,
          libelle: (valeur) => libelleStatutSeance(valeur),
          onChoisi: (valeur) {
            setState(() {
              statut = valeur;
            });
          },
        ),
        NoteInfo(texte: note),
      ],
    );
  }

  // Programme facultatif : on choisit parmi ceux du coach.
  Widget choixProgramme() {
    // null = "Aucun programme".
    List<Programme?> options = [null, ...programmes];

    return ChoixPuces<Programme?>(
      items: options,
      estChoisi: (programme) => idProgramme == programme?.id,
      libelle: (programme) => programme?.nom ?? 'Aucun',
      onChoisi: (programme) {
        setState(() {
          idProgramme = programme?.id;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool ajout = widget.seance == null;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          EnTeteDiagonal(
            titre: ajout ? 'Nouvelle séance' : 'Modifier la séance',
            icone: Icons.fitness_center,
            retour: true,
            hauteur: 160,
          ),
          // Largeur limitée : le formulaire reste lisible sur grand écran.
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CarteSection(
                        titre: 'Informations',
                        icone: Icons.info_outline,
                        enfants: [
                          TextFormField(
                            initialValue: titre,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: decorationChamp(
                              'Titre de la séance',
                              icone: Icons.title,
                            ),
                            onChanged: (value) {
                              titre = value;
                            },
                            validator: validerTitre,
                          ),
                          TextFormField(
                            initialValue: description,
                            minLines: 2,
                            maxLines: 4,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: decorationChamp(
                              'Description (facultatif)',
                              icone: Icons.notes,
                            ),
                            onChanged: (value) {
                              description = value;
                            },
                          ),
                        ],
                      ),
                      CarteSection(
                        titre: 'Date et horaire',
                        icone: Icons.event,
                        enfants: [
                          TextFormField(
                            controller: dateController,
                            keyboardType: TextInputType.datetime,
                            decoration: decorationChamp(
                              'Date (jj/mm/aaaa)',
                              icone: Icons.calendar_today,
                              action: boutonCalendrier(),
                            ),
                            validator: validerDate,
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 12,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: debutController,
                                  keyboardType: TextInputType.datetime,
                                  decoration: decorationChamp(
                                    'Début (hh:mm)',
                                    action: boutonHorloge(debutController),
                                  ),
                                  validator: validerHeure,
                                ),
                              ),
                              Expanded(
                                child: TextFormField(
                                  controller: finController,
                                  keyboardType: TextInputType.datetime,
                                  decoration: decorationChamp(
                                    'Fin (hh:mm)',
                                    action: boutonHorloge(finController),
                                  ),
                                  validator: validerHeure,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      CarteSection(
                        titre: 'Type et tarif',
                        icone: Icons.groups_outlined,
                        enfants: [
                          choixType(),
                          if (type == TypeSeance.COLLECTIVE)
                            TextFormField(
                              initialValue: capaciteTexte,
                              keyboardType: TextInputType.number,
                              decoration: decorationChamp(
                                'Capacité',
                                icone: Icons.event_seat_outlined,
                                suffixe: 'places',
                              ),
                              onChanged: (value) {
                                capaciteTexte = value;
                              },
                              validator: validerCapacite,
                            )
                          else
                            const NoteInfo(
                              texte: 'Séance individuelle : une seule place.',
                            ),
                          TextFormField(
                            initialValue: prixTexte,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: decorationChamp(
                              'Prix',
                              icone: Icons.payments_outlined,
                              suffixe: 'DT',
                              aide: 'Vide = gratuit',
                            ),
                            onChanged: (value) {
                              prixTexte = value;
                            },
                            validator: validerPrix,
                          ),
                        ],
                      ),
                      if (!ajout)
                        CarteSection(
                          titre: 'Statut',
                          icone: Icons.flag_outlined,
                          enfants: [choixStatut()],
                        ),
                      CarteSection(
                        titre: 'Programme (facultatif)',
                        icone: Icons.event_note,
                        enfants: [choixProgramme()],
                      ),
                      const SizedBox(height: 8),
                      BoutonPrincipal(
                        texte: ajout ? 'Créer la séance' : 'Enregistrer',
                        enChargement: enCours,
                        onPressed: enregistrer,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}