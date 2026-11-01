import 'package:flutter/material.dart';

import 'package:coach_app/core/utils/alertes.dart';
import 'package:coach_app/features/entrainement/data/models/assiduite.dart';
import 'package:coach_app/features/entrainement/data/models/seance.dart';
import 'package:coach_app/features/entrainement/data/repositories/assiduite_repository.dart';

class PresenceSeanceScreen extends StatefulWidget {
  final Seance seance;

  const PresenceSeanceScreen({super.key, required this.seance});

  @override
  State<PresenceSeanceScreen> createState() => _PresenceSeanceScreenState();
}

class _PresenceSeanceScreenState extends State<PresenceSeanceScreen> {
  final AssiduiteRepository repository = AssiduiteRepository();

  List<PresenceParticipant> participants = [];
  bool chargement = true;

  @override
  void initState() {
    super.initState();
    charger();
  }

  Future<void> charger() async {
    try {
      List<PresenceParticipant> liste =
      await repository.getFeuille(widget.seance.id!);

      if (!mounted) {
        return;
      }

      setState(() {
        participants = liste;
        chargement = false;
      });
    } catch (erreur) {
      if (!mounted) {
        return;
      }

      setState(() {
        chargement = false;
      });

      afficherAlerteErreur(
        context,
        titre: 'Chargement impossible',
        message: erreur.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> marquer(PresenceParticipant participant, bool present) async {
    try {
      await repository.marquerPresence(participant.idReservation, present);
      await charger();
    } catch (erreur) {
      if (!mounted) {
        return;
      }

      afficherAlerteErreur(
        context,
        titre: 'Enregistrement impossible',
        message: erreur.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Widget resume() {
    int presents = participants.where((p) => p.presence == true).length;
    int absents = participants.where((p) => p.presence == false).length;
    int restants = participants.where((p) => p.presence == null).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          '$presents présent(s) · $absents absent(s) · $restants à renseigner',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget ligne(PresenceParticipant participant) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              participant.nom,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Présent'),
                  selected: participant.presence == true,
                  selectedColor: Colors.green.shade200,
                  onSelected: (_) {
                    marquer(participant, true);
                  },
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('Absent'),
                  selected: participant.presence == false,
                  selectedColor: Colors.red.shade200,
                  onSelected: (_) {
                    marquer(participant, false);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget corps() {
    if (chargement) {
      return const Center(child: CircularProgressIndicator());
    }

    if (participants.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aucun participant confirmé pour cette séance.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        resume(),
        ...participants.map(ligne),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Présence : ${widget.seance.titre}')),
      body: corps(),
    );
  }
}