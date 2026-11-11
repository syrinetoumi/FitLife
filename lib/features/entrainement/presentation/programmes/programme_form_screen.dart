import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:coach_app/core/utils/alertes.dart';
import 'package:coach_app/core/utils/outils.dart';
import 'package:coach_app/core/widgets/bouton_principal.dart';
import 'package:coach_app/core/widgets/en_tete_diagonal.dart';
import 'package:coach_app/core/widgets/formulaire.dart';
import 'package:coach_app/features/entrainement/data/models/enums.dart';
import 'package:coach_app/features/entrainement/data/models/programme.dart';
import 'package:coach_app/features/entrainement/data/repositories/programme_repository.dart';

class ProgrammeFormScreen extends StatefulWidget {
  final Programme? programme;

  const ProgrammeFormScreen({
    super.key,
    this.programme,
  });

  @override
  State<ProgrammeFormScreen> createState() => _ProgrammeFormScreenState();
}

class _ProgrammeFormScreenState extends State<ProgrammeFormScreen> {
  final formKey = GlobalKey<FormState>();

  ProgrammeRepository programmeRepository = ProgrammeRepository();

  // Les dates utilisent un controller : le sélecteur de calendrier
  // doit pouvoir écrire dans le champ.
  final TextEditingController dateDebutController = TextEditingController();
  final TextEditingController dateFinController = TextEditingController();

  String nom = '';
  String description = '';
  String dureeTexte = '';

  ObjectifProgramme objectif = ObjectifProgramme.PERTE_POIDS;
  Niveau niveau = Niveau.DEBUTANT;

  bool enCours = false;

  @override
  void initState() {
    super.initState();

    if (widget.programme != null) {
      Programme programme = widget.programme!;

      nom = programme.nom;
      description = programme.description ?? '';
      dureeTexte = programme.dureeSemaines?.toString() ?? '';
      objectif = programme.objectif;
      niveau = programme.niveau;

      if (programme.dateDebut != null) {
        dateDebutController.text = afficherDate(programme.dateDebut!);
      }

      if (programme.dateFin != null) {
        dateFinController.text = afficherDate(programme.dateFin!);
      }
    }
  }

  @override
  void dispose() {
    dateDebutController.dispose();
    dateFinController.dispose();
    super.dispose();
  }

  String? validerNom(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nom obligatoire';
    }

    return null;
  }

  String? validerDuree(String? value) {
    int? duree = int.tryParse(value ?? '');

    if (duree == null || duree <= 0) {
      return 'Durée invalide';
    }

    return null;
  }

  // Les dates sont facultatives : vide = accepté.
  String? validerDateFacultative(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    if (lireDate(value) == null) {
      return 'Date invalide (jj/mm/aaaa)';
    }

    return null;
  }

  // Ouvre le calendrier et écrit la date choisie dans le champ.
  Future<void> choisirDate(TextEditingController controller) async {
    DateTime initiale = lireDate(controller.text) ?? DateTime.now();

    DateTime? choisie = await showDatePicker(
      context: context,
      initialDate: initiale,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (choisie != null) {
      controller.text = afficherDate(choisie);
    }
  }

  Widget boutonCalendrier(TextEditingController controller) {
    return IconButton(
      icon: const Icon(Icons.calendar_month),
      tooltip: 'Choisir une date',
      onPressed: () => choisirDate(controller),
    );
  }

  Future<void> enregistrer() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    // Le coach est l'utilisateur connecté, il ne se saisit pas.
    User? utilisateur = Supabase.instance.client.auth.currentUser;

    if (utilisateur == null) {
      afficherMessage(context, 'Connectez-vous d’abord.');
      return;
    }

    DateTime? dateDebut = lireDate(dateDebutController.text);
    DateTime? dateFin = lireDate(dateFinController.text);

    if (dateDebut != null && dateFin != null && dateFin.isBefore(dateDebut)) {
      afficherAlerteErreur(
        context,
        titre: 'Dates incorrectes',
        message: 'La date de fin doit être après la date de début.',
      );
      return;
    }

    Programme programme = Programme(
      id: widget.programme?.id,
      nom: nom.trim(),
      description: description.trim(),
      objectif: objectif,
      niveau: niveau,
      dureeSemaines: int.parse(dureeTexte),
      dateDebut: dateDebut,
      dateFin: dateFin,
      idCoach: widget.programme?.idCoach ?? utilisateur.id,
    );

    // Bouton en chargement : évite le double clic.
    setState(() {
      enCours = true;
    });

    try {
      if (widget.programme == null) {
        await programmeRepository.ajouter(programme);
      } else {
        await programmeRepository.modifier(programme);
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

  @override
  Widget build(BuildContext context) {
    bool ajout = widget.programme == null;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          EnTeteDiagonal(
            titre: ajout ? 'Nouveau programme' : 'Modifier le programme',
            icone: Icons.event_note,
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
                            initialValue: nom,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: decorationChamp(
                              'Nom du programme',
                              icone: Icons.title,
                            ),
                            onChanged: (value) {
                              nom = value;
                            },
                            validator: validerNom,
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
                          TextFormField(
                            initialValue: dureeTexte,
                            keyboardType: TextInputType.number,
                            decoration: decorationChamp(
                              'Durée',
                              icone: Icons.timer_outlined,
                              suffixe: 'semaines',
                            ),
                            onChanged: (value) {
                              dureeTexte = value;
                            },
                            validator: validerDuree,
                          ),
                        ],
                      ),
                      CarteSection(
                        titre: 'Objectif',
                        icone: Icons.flag_outlined,
                        enfants: [
                          ChoixPuces<ObjectifProgramme>(
                            items: ObjectifProgramme.values,
                            estChoisi: (valeur) => objectif == valeur,
                            libelle: (valeur) => enTexte(valeur),
                            onChoisi: (valeur) {
                              setState(() {
                                objectif = valeur;
                              });
                            },
                          ),
                        ],
                      ),
                      CarteSection(
                        titre: 'Niveau',
                        icone: Icons.bar_chart,
                        enfants: [
                          ChoixPuces<Niveau>(
                            items: Niveau.values,
                            estChoisi: (valeur) => niveau == valeur,
                            libelle: (valeur) => enTexte(valeur),
                            onChoisi: (valeur) {
                              setState(() {
                                niveau = valeur;
                              });
                            },
                          ),
                        ],
                      ),
                      CarteSection(
                        titre: 'Planning (facultatif)',
                        icone: Icons.calendar_month,
                        enfants: [
                          TextFormField(
                            controller: dateDebutController,
                            keyboardType: TextInputType.datetime,
                            decoration: decorationChamp(
                              'Date de début (jj/mm/aaaa)',
                              icone: Icons.play_circle_outline,
                              action: boutonCalendrier(dateDebutController),
                            ),
                            validator: validerDateFacultative,
                          ),
                          TextFormField(
                            controller: dateFinController,
                            keyboardType: TextInputType.datetime,
                            decoration: decorationChamp(
                              'Date de fin (jj/mm/aaaa)',
                              icone: Icons.stop_circle_outlined,
                              action: boutonCalendrier(dateFinController),
                            ),
                            validator: validerDateFacultative,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      BoutonPrincipal(
                        texte: ajout ? 'Créer le programme' : 'Enregistrer',
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