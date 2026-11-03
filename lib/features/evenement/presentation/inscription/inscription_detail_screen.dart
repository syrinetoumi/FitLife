import 'package:flutter/material.dart';

import 'package:coach_app/core/utils/alertes.dart';
import 'package:coach_app/core/utils/outils.dart';
import 'package:coach_app/features/entrainement/presentation/widgets/carte_image.dart';
import 'package:coach_app/features/entrainement/presentation/widgets/ligne_info.dart';
import '../../data/models/inscription.dart';
import '../../data/repositories/inscription_repository.dart';
import '../widgets/apparence_evenement.dart';
import 'inscription_form_screen.dart';

class InscriptionDetailScreen extends StatefulWidget {
  final Inscription inscription;
  final String nomEvenement;
  final String nomCategorie;

  const InscriptionDetailScreen({
    super.key,
    required this.inscription,
    required this.nomEvenement,
    required this.nomCategorie,
  });

  @override
  State<InscriptionDetailScreen> createState() =>
      _InscriptionDetailScreenState();
}

class _InscriptionDetailScreenState extends State<InscriptionDetailScreen> {
  InscriptionRepository inscriptionRepository = InscriptionRepository();

  Inscription get inscription => widget.inscription;

  Future<void> modifier() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InscriptionFormScreen(inscription: inscription),
      ),
    );

    // On revient à la liste, qui se recharge.
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> supprimer() async {
    bool confirme = await confirmerAction(
      context,
      titre: 'Supprimer',
      message: 'Supprimer l’inscription de "${inscription.idAthlete}" '
          'à "${widget.nomEvenement}" ?',
    );

    if (!confirme) {
      return;
    }

    try {
      await inscriptionRepository.supprimer(inscription.idInscription);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (erreur) {
      if (mounted) {
        afficherAlerteErreur(
          context,
          titre: 'Suppression impossible',
          message: '$erreur',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inscription')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CarteImage(
            titre: widget.nomEvenement,
            sousTitre: 'Athlète : ${inscription.idAthlete}',
            couleurs: couleursInscription(),
            icone: Icons.how_to_reg,
            badge: pastilleStatut(inscription.statutToString()),
            hauteur: 200,
          ),
          Card(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                children: [
                  ligneInfo(Icons.event, 'Événement', widget.nomEvenement),
                  const Divider(height: 1),
                  ligneInfo(Icons.groups, 'Catégorie', widget.nomCategorie),
                  const Divider(height: 1),
                  ligneInfo(Icons.person, 'Athlète', inscription.idAthlete),
                  const Divider(height: 1),
                  ligneInfo(
                    Icons.cake,
                    'Âge',
                    '${inscription.ageAthlete} ans',
                  ),
                  const Divider(height: 1),
                  ligneInfo(
                    Icons.signal_cellular_alt,
                    'Niveau',
                    inscription.niveauAthlete.name.toUpperCase(),
                  ),
                  const Divider(height: 1),
                  ligneInfo(
                    Icons.event_available,
                    'Inscrit le',
                    afficherDate(inscription.dateInscription),
                  ),
                ],
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: modifier,
                    child: const Text('Modifier'),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 10),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: supprimer,
                      child: const Text('Supprimer'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}