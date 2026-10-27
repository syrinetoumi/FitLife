import 'package:flutter/material.dart';

import 'package:coach_app/core/utils/alertes.dart';
import 'package:coach_app/core/utils/outils.dart';
import 'package:coach_app/features/entrainement/data/models/seance.dart';
import 'package:coach_app/features/entrainement/data/repositories/seance_repository.dart';
import 'package:coach_app/features/entrainement/presentation/widgets/apparence_entrainement.dart';
import 'package:coach_app/features/entrainement/presentation/widgets/carte_image.dart';
import 'package:coach_app/features/entrainement/presentation/widgets/ligne_info.dart';
import 'libelles_seance.dart';
import 'seance_form_screen.dart';

class SeanceDetailScreen extends StatelessWidget {
  final Seance seance;

  const SeanceDetailScreen({super.key, required this.seance});

  Future<void> modifier(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeanceFormScreen(seance: seance),
      ),
    );

    // On revient à la liste, qui se recharge.
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> supprimer(BuildContext context) async {
    bool confirme = await confirmerAction(
      context,
      titre: 'Supprimer',
      message: 'Supprimer la séance "${seance.titre}" ?',
    );

    if (!confirme) {
      return;
    }

    try {
      await SeanceRepository().supprimer(seance.id!);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Séance')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CarteImage(
            titre: seance.titre,
            sousTitre: '${afficherDate(seance.date)} · '
                '${seance.debutCourt} - ${seance.finCourt}',
            cheminImage: imageType(seance.type),
            couleurs: couleursType(seance.type),
            icone: iconeType(seance.type),
            badge: pastilleStatutSeance(seance.statut),
            hauteur: 200,
          ),
          Card(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                children: [
                  ligneInfo(Icons.event, 'Date', afficherDate(seance.date)),
                  const Divider(height: 1),
                  ligneInfo(
                    Icons.schedule,
                    'Horaire',
                    '${seance.debutCourt} - ${seance.finCourt}',
                  ),
                  const Divider(height: 1),
                  ligneInfo(
                    Icons.groups,
                    'Type',
                    libelleTypeSeance(seance.type),
                  ),
                  if (seance.capacite != null) ...[
                    const Divider(height: 1),
                    ligneInfo(
                      Icons.event_seat,
                      'Capacité',
                      '${seance.capacite} places',
                    ),
                  ],
                  const Divider(height: 1),
                  ligneInfo(
                    Icons.payments,
                    'Prix',
                    '${seance.prix.toStringAsFixed(2)} DT',
                  ),
                ],
              ),
            ),
          ),
          if (seance.description != null && seance.description!.isNotEmpty)
            Card(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Text(
                  seance.description!,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
              ),
            ),
          // À venir : météo, réservation (athlète), participants (coach).
          // Les boutons ci-dessous seront réservés au coach propriétaire.
          Container(
            margin: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      modifier(context);
                    },
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
                      onPressed: () {
                        supprimer(context);
                      },
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