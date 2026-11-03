import 'package:flutter/material.dart';

import 'package:coach_app/core/utils/outils.dart';
import 'package:coach_app/features/entrainement/data/local/derniere_reservation_locale.dart';
import 'package:coach_app/features/entrainement/data/repositories/seance_repository.dart';
import 'seance_detail_screen.dart';

class CarteDerniereReservation extends StatefulWidget {
  const CarteDerniereReservation({super.key});

  @override
  State<CarteDerniereReservation> createState() =>
      _CarteDerniereReservationState();
}

class _CarteDerniereReservationState extends State<CarteDerniereReservation> {
  Map<String, dynamic>? donnees;

  @override
  void initState() {
    super.initState();
    charger();
  }

  Future<void> charger() async {
    Map<String, dynamic>? lues = await DerniereReservationLocale.lire();

    if (!mounted) {
      return;
    }

    setState(() {
      donnees = lues;
    });
  }

  Future<void> ouvrir() async {
    int id = donnees!['id'] as int;
    final seance = await SeanceRepository().getSeance(id);

    if (!mounted) {
      return;
    }

    // La séance a pu être supprimée depuis : on oublie la mémoire locale.
    if (seance == null) {
      await DerniereReservationLocale.effacer();
      await charger();

      if (mounted) {
        afficherMessage(context, 'Cette séance n\'existe plus.');
      }
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeanceDetailScreen(seance: seance),
      ),
    );

    // Au retour, la réservation a pu être annulée.
    await charger();
  }

  Future<void> oublier() async {
    await DerniereReservationLocale.effacer();
    await charger();
  }

  @override
  Widget build(BuildContext context) {
    if (donnees == null) {
      return const SizedBox.shrink();
    }

    DateTime date = DateTime.parse(donnees!['date'] as String);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        leading: Icon(
          Icons.history,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Dernière séance réservée'),
        subtitle: Text(
          '${donnees!['titre']} · ${afficherDate(date)} · ${donnees!['heure']}',
        ),
        onTap: ouvrir,
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: oublier,
        ),
      ),
    );
  }
}