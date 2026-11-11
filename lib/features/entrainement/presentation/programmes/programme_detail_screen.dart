// ===========================================================================
// ÉCRAN : détail d'un programme.
// - Tout le monde : infos du programme + liste de ses exercices
//   (noms et GIF viennent de l'API ExerciseDB, jamais enregistrés en base).
// - Coach propriétaire : ajouter / modifier / retirer un exercice,
//   modifier / supprimer le programme.
// - Athlète : bouton "Choisir ce programme" (crée un suivi d'objectif).
// ===========================================================================

import 'package:flutter/material.dart';
// supabase_flutter : client de la base de données et de l'authentification.
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:coach_app/core/theme/app_theme.dart';
import 'package:coach_app/core/utils/alertes.dart';
import 'package:coach_app/core/utils/outils.dart';
import 'package:coach_app/core/widgets/formulaire.dart';
import 'package:coach_app/features/entrainement/data/models/enums.dart';
import 'package:coach_app/features/entrainement/data/models/exercice_api.dart';
import 'package:coach_app/features/entrainement/data/models/programme.dart';
import 'package:coach_app/features/entrainement/data/models/programme_exercice.dart';
import 'package:coach_app/features/entrainement/data/repositories/programme_exercice_repository.dart';
import 'package:coach_app/features/entrainement/data/repositories/programme_repository.dart';
import 'package:coach_app/features/entrainement/data/services/exercise_db_service.dart';
import 'package:coach_app/features/entrainement/presentation/suivi/libelles_suivi.dart';
import 'package:coach_app/features/entrainement/presentation/suivi/suivi_form_screen.dart';
import 'package:coach_app/features/entrainement/presentation/widgets/apparence_entrainement.dart';
import 'package:coach_app/features/entrainement/presentation/widgets/carte_image.dart';
import 'package:coach_app/features/entrainement/presentation/widgets/ligne_info.dart';
import 'choix_exercice_screen.dart';
import 'outils_exercice.dart';
import 'programme_exercice_form_screen.dart';
import 'programme_form_screen.dart';

class ProgrammeDetailScreen extends StatefulWidget {
  // Le programme à afficher, reçu de la liste.
  final Programme programme;

  // required : paramètre nommé obligatoire.
  const ProgrammeDetailScreen({super.key, required this.programme});

  @override
  State<ProgrammeDetailScreen> createState() => _ProgrammeDetailScreenState();
}

class _ProgrammeDetailScreenState extends State<ProgrammeDetailScreen> {
  // final : la variable ne peut plus être réaffectée (mais son contenu oui).
  final ProgrammeExerciceRepository exerciceRepository =
  ProgrammeExerciceRepository();
  final ExerciseDbService exerciseDbService = ExerciseDbService();

  List<ProgrammeExercice> exercices = [];

  // Infos venant de l'API (jamais enregistrées). Clé = id de l'exercice.
  // Valeur nulle = l'appel API a échoué pour cet exercice.
  final Map<String, ExerciceApi?> infos = {};
  bool chargementExercices = true;

  // Getter : se lit comme une variable mais calcule sa valeur à chaque fois.
  // Raccourci pour écrire "programme" au lieu de "widget.programme".
  Programme get programme => widget.programme;

  // Vrai si l'utilisateur connecté est le coach qui a créé ce programme.
  bool get proprietaire {
    // currentUser : utilisateur de la session locale (null si déconnecté).
    final utilisateur = Supabase.instance.client.auth.currentUser;
    return utilisateur != null && utilisateur.id == programme.idCoach;
  }

  // initState : appelée une seule fois à la création de l'écran.
  @override
  void initState() {
    super.initState();
    chargerExercices();
  }

  Future<void> chargerExercices() async {
    try {
      // "!" après programme.id : on affirme que l'id n'est pas null
      // (un programme déjà enregistré en possède un).
      List<ProgrammeExercice> liste =
      await exerciceRepository.getExercices(programme.id!);

      if (!mounted) {
        return;
      }

      setState(() {
        exercices = liste;
        chargementExercices = false;
        infos.clear(); // vide les infos API déjà chargées
      });

      // Noms et GIF : un appel API à la fois, sans bloquer l'affichage.
      // (le plan gratuit RapidAPI limite le nombre de requêtes)
      for (var element in liste) {
        try {
          ExerciceApi exercice =
          await exerciseDbService.exerciceParId(element.externalId);

          if (!mounted) {
            return;
          }

          setState(() {
            infos[element.externalId] = exercice;
          });
        } catch (_) {
          // "_" = on ignore l'erreur : ce n'est pas grave, on affichera
          // un nom de secours.
          if (!mounted) {
            return;
          }

          setState(() {
            infos[element.externalId] = null;
          });
        }
      }
    } catch (erreur) {
      if (mounted) {
        setState(() {
          chargementExercices = false;
        });

        afficherAlerteErreur(
          context,
          titre: 'Chargement impossible',
          message: messageErreur(erreur),
        );
      }
    }
  }

  Future<void> ajouterExercice() async {
    // Navigator.push<ExerciceApi> : l'écran suivant RENVOIE un ExerciceApi
    // (via Navigator.pop(context, valeur)). Null si l'utilisateur annule.
    ExerciceApi? choisi = await Navigator.push<ExerciceApi>(
      context,
      MaterialPageRoute(builder: (context) => const ChoixExerciceScreen()),
    );

    if (choisi == null || !mounted) {
      return;
    }

    try {
      int ordre = await exerciceRepository.prochainOrdre(programme.id!);

      if (!mounted) {
        return;
      }

      bool? ok = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => ProgrammeExerciceFormScreen(
            idProgramme: programme.id!,
            externalId: choisi.id,
            nomExercice: nomPropre(choisi.nom),
            ordre: ordre,
          ),
        ),
      );

      if (ok == true) {
        chargerExercices();
      }
    } catch (erreur) {
      if (mounted) {
        afficherAlerteErreur(
          context,
          titre: 'Ajout impossible',
          message: messageErreur(erreur),
        );
      }
    }
  }

  Future<void> modifierExercice(ProgrammeExercice element) async {
    ExerciceApi? info = infos[element.externalId];

    bool? ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ProgrammeExerciceFormScreen(
          idProgramme: programme.id!,
          externalId: element.externalId,
          nomExercice: info == null
              ? 'Exercice ${element.externalId}'
              : nomPropre(info.nom),
          ordre: element.ordre,
          existant: element,
        ),
      ),
    );

    if (ok == true) {
      chargerExercices();
    }
  }

  Future<void> supprimerExercice(ProgrammeExercice element) async {
    // confirmerAction : boîte de dialogue Oui/Non (core/utils/alertes.dart).
    bool confirme = await confirmerAction(
      context,
      titre: 'Retirer',
      message: 'Retirer cet exercice du programme ?',
      libelleBouton: 'Retirer',
    );

    if (!confirme) {
      return;
    }

    try {
      await exerciceRepository.supprimer(programme.id!, element.externalId);
      await chargerExercices();
    } catch (erreur) {
      if (mounted) {
        afficherAlerteErreur(
          context,
          titre: 'Suppression impossible',
          message: messageErreur(erreur),
        );
      }
    }
  }

  Future<void> modifier(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProgrammeFormScreen(programme: programme),
      ),
    );

    // On revient à la liste, qui se recharge.
    // context.mounted : équivalent de "mounted" pour un BuildContext reçu
    // en paramètre.
    if (context.mounted) {
      Navigator.pop(context); // pop = ferme l'écran courant
    }
  }

  Future<void> supprimer(BuildContext context) async {
    bool confirme = await confirmerAction(
      context,
      titre: 'Supprimer',
      message: 'Supprimer le programme "${programme.nom}" ?',
    );

    if (!confirme) {
      return;
    }

    try {
      await ProgrammeRepository().supprimer(programme.id!);

      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (erreur) {
      if (context.mounted) {
        afficherAlerteErreur(
          context,
          titre: 'Suppression impossible',
          message: '$erreur',
        );
      }
    }
  }

  // Athlète : choisit ce programme comme objectif (écran de suivi).
  Future<void> choisir(BuildContext context) async {
    bool? cree = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => SuiviFormScreen(programme: programme),
      ),
    );

    if (cree == true && context.mounted) {
      afficherMessage(
        context,
        'Objectif enregistré. Retrouve-le dans l\'onglet Suivi.',
      );
    }
  }

  // Ex. : "3 × 12 · repos 60 s · 20 kg"
  String resume(ProgrammeExercice element) {
    List<String> parties = [];

    if (element.series != null && element.repetitions != null) {
      parties.add('${element.series} × ${element.repetitions}');
    } else if (element.series != null) {
      parties.add('${element.series} séries');
    } else if (element.repetitions != null) {
      parties.add('${element.repetitions} répétitions');
    }

    if (element.tempsRepos != null) {
      parties.add('repos ${element.tempsRepos} s');
    }

    if (element.charge != null) {
      parties.add('${formaterValeur(element.charge!)} kg');
    }

    if (parties.isEmpty) {
      return 'Aucun détail';
    }

    // join : colle les éléments de la liste avec un séparateur.
    return parties.join(' · ');
  }

  // Une ligne d'exercice : GIF (API) + nom + résumé + boutons du coach.
  Widget ligneExercice(ProgrammeExercice element) {
    // containsKey : vrai si l'appel API est terminé (réussi ou échoué).
    bool connu = infos.containsKey(element.externalId);
    ExerciceApi? info = infos[element.externalId];

    String nom;
    if (info != null) {
      nom = nomPropre(info.nom);
    } else if (connu) {
      nom = 'Exercice ${element.externalId}';
    } else {
      nom = 'Chargement...';
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E6EE)),
      ),
      // ListTile : ligne standard (leading = gauche, title, subtitle, trailing = droite).
      child: ListTile(
        leading: ClipRRect(
          // ClipRRect : découpe l'enfant avec des coins arrondis.
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 56,
            height: 56,
            // Image.network : télécharge et affiche une image depuis une URL.
            // headers : clés RapidAPI nécessaires pour que le GIF soit autorisé.
            child: Image.network(
              ExerciseDbService.urlGif(element.externalId),
              headers: ExerciseDbService.entetes,
              fit: BoxFit.cover, // remplit le cadre en rognant si besoin
              // errorBuilder : widget affiché si le téléchargement échoue.
              errorBuilder: (context, erreur, trace) {
                return const Icon(Icons.fitness_center);
              },
            ),
          ),
        ),
        title: Text(
          '${element.ordre}. $nom',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(resume(element)),
        // Boutons modifier / retirer : seulement pour le coach propriétaire.
        trailing: proprietaire
            ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Modifier',
              onPressed: () {
                modifierExercice(element);
              },
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Colors.red.shade700,
              ),
              tooltip: 'Retirer',
              onPressed: () {
                supprimerExercice(element);
              },
            ),
          ],
        )
            : null,
      ),
    );
  }

  Widget sectionExercices() {
    if (chargementExercices) {
      return const Center(child: CircularProgressIndicator());
    }

    if (exercices.isEmpty) {
      return Text(
        proprietaire
            ? 'Aucun exercice pour le moment. Ajoute le premier.'
            : 'Ce programme ne contient pas encore d\'exercices.',
        style: const TextStyle(color: AppCouleurs.texteSecondaire),
      );
    }

    // map(...).toList() : transforme chaque exercice en widget.
    return Column(
      spacing: 10,
      children: exercices.map(ligneExercice).toList(),
    );
  }

  // Carte "Détails" : lignes icône + libellé + valeur séparées par des filets.
  Widget blocDetails() {
    return Column(
      children: [
        ligneInfo(Icons.flag, 'Objectif', enTexte(programme.objectif)),
        // Divider : trait horizontal fin.
        const Divider(height: 1),
        ligneInfo(
          Icons.signal_cellular_alt,
          'Niveau',
          enTexte(programme.niveau),
        ),
        if (programme.dureeSemaines != null) ...[
          const Divider(height: 1),
          ligneInfo(
            Icons.timelapse,
            'Durée',
            '${programme.dureeSemaines} semaines',
          ),
        ],
        if (programme.dateDebut != null) ...[
          const Divider(height: 1),
          ligneInfo(
            Icons.event,
            'Début',
            afficherDate(programme.dateDebut!),
          ),
        ],
        if (programme.dateFin != null) ...[
          const Divider(height: 1),
          ligneInfo(
            Icons.event_available,
            'Fin',
            afficherDate(programme.dateFin!),
          ),
        ],
      ],
    );
  }

  // Boutons du coach : modifier / supprimer le programme.
  Widget boutonsCoach() {
    return Row(
      spacing: 10,
      children: [
        // Expanded : chaque bouton prend la moitié de la largeur.
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              modifier(context);
            },
            icon: const Icon(Icons.edit),
            label: const Text('Modifier'),
          ),
        ),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              supprimer(context);
            },
            icon: const Icon(Icons.delete),
            label: const Text('Supprimer'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Programme')),
      body: Center(
        child: ConstrainedBox(
          // Largeur maximale : lisible sur grand écran.
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Grande carte photo en haut.
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                child: CarteImage(
                  titre: programme.nom,
                  sousTitre: enTexte(programme.objectif),
                  cheminImage: imageObjectif(programme.objectif),
                  couleurs: couleursObjectif(programme.objectif),
                  icone: iconeObjectif(programme.objectif),
                  hauteur: 200,
                ),
              ),
              CarteSection(
                titre: 'Détails',
                icone: Icons.info_outline,
                enfants: [blocDetails()],
              ),
              // Description : affichée seulement si elle existe.
              if (programme.description != null &&
                  programme.description!.isNotEmpty)
                CarteSection(
                  titre: 'Description',
                  icone: Icons.notes,
                  enfants: [
                    Text(
                      programme.description!,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ],
                ),
              CarteSection(
                titre: 'Exercices (${exercices.length})',
                icone: Icons.fitness_center,
                enfants: [
                  sectionExercices(),
                  if (proprietaire)
                    ElevatedButton.icon(
                      onPressed: ajouterExercice,
                      icon: const Icon(Icons.add),
                      label: const Text('AJOUTER UN EXERCICE'),
                    ),
                ],
              ),
              if (proprietaire) boutonsCoach(),
              if (!proprietaire)
                ElevatedButton.icon(
                  onPressed: () {
                    choisir(context);
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('CHOISIR CE PROGRAMME'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}