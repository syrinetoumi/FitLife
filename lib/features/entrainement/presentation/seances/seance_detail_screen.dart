import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:coach_app/core/utils/alertes.dart';
import 'package:coach_app/core/utils/outils.dart';
import 'package:coach_app/features/entrainement/data/models/enums.dart';
import 'package:coach_app/features/entrainement/data/models/reservation_seance.dart';
import 'package:coach_app/features/entrainement/data/models/seance.dart';
import 'package:coach_app/features/entrainement/data/repositories/reservation_seance_repository.dart';
import 'package:coach_app/features/entrainement/data/repositories/seance_repository.dart';
import 'package:coach_app/features/entrainement/presentation/widgets/apparence_entrainement.dart';
import 'package:coach_app/features/entrainement/presentation/widgets/carte_image.dart';
import 'package:coach_app/features/entrainement/presentation/widgets/ligne_info.dart';
import 'libelles_seance.dart';
import 'seance_form_screen.dart';

class SeanceDetailScreen extends StatefulWidget {
  final Seance seance;

  const SeanceDetailScreen({super.key, required this.seance});

  @override
  State<SeanceDetailScreen> createState() => _SeanceDetailScreenState();
}

class _SeanceDetailScreenState extends State<SeanceDetailScreen> {
  SeanceRepository seanceRepository = SeanceRepository();
  ReservationSeanceRepository reservationRepository =
  ReservationSeanceRepository();

  late Seance seance;
  bool chargement = true;

  // Le coach propriétaire gère la séance, les autres la réservent.
  bool proprietaire = false;
  ReservationSeance? maReservation;
  int? nbReservations;
  List<String> participants = [];

  @override
  void initState() {
    super.initState();
    seance = widget.seance;
    charger();
  }

  // Recharge la séance (son statut change avec les réservations).
  Future<void> charger() async {
    try {
      User? utilisateur = Supabase.instance.client.auth.currentUser;

      Seance? fraiche = await seanceRepository.getSeance(seance.id!);

      if (fraiche != null) {
        seance = fraiche;
      }

      bool estProprietaire =
          utilisateur != null && seance.idCoach == utilisateur.id;

      ReservationSeance? reservation;
      List<String> noms = [];
      int? nombre;

      if (estProprietaire) {
        noms = await reservationRepository.getNomsParticipants(seance.id!);
        nombre = noms.length;
      } else {
        reservation = await reservationRepository.getMaReservation(seance.id!);
        nombre = await seanceRepository.nombreReservations(seance.id!);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        proprietaire = estProprietaire;
        maReservation = reservation;
        participants = noms;
        nbReservations = nombre;
        chargement = false;
      });
    } catch (erreur) {
      if (mounted) {
        setState(() {
          chargement = false;
        });

        afficherMessage(context, 'Erreur de chargement : $erreur');
      }
    }
  }

  // ---------- Athlète ----------

  Future<void> reserver() async {
    try {
      await reservationRepository.reserver(seance.id!);

      if (mounted) {
        afficherMessage(context, 'Réservation confirmée.');
      }
    } catch (erreur) {
      // Ex. "Séance complète" : message venant des règles de la base.
      if (mounted) {
        afficherAlerteErreur(
          context,
          titre: 'Réservation impossible',
          message: '$erreur',
        );
      }
    }

    await charger();
  }

  Future<void> annulerReservation() async {
    bool confirme = await confirmerAction(
      context,
      titre: 'Annuler la réservation',
      message: 'Annuler votre réservation pour "${seance.titre}" ?',
      libelleBouton: 'Annuler la réservation',
      libelleRefus: 'Retour',
    );

    if (!confirme || maReservation == null) {
      return;
    }

    try {
      await reservationRepository.annuler(maReservation!.id!);

      if (mounted) {
        afficherMessage(context, 'Réservation annulée.');
      }
    } catch (erreur) {
      if (mounted) {
        afficherAlerteErreur(
          context,
          titre: 'Annulation impossible',
          message: '$erreur',
        );
      }
    }

    await charger();
  }

  // ---------- Coach ----------

  Future<void> modifier() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeanceFormScreen(seance: seance),
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
      message: 'Supprimer la séance "${seance.titre}" ?',
    );

    if (!confirme) {
      return;
    }

    try {
      await seanceRepository.supprimer(seance.id!);

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

  // ---------- Affichage ----------

  Widget bandeau(IconData icone, String texte, Color couleur) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleur),
      ),
      child: Row(
        children: [
          Icon(icone, color: couleur),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 12),
              child: Text(
                texte,
                style: TextStyle(
                  color: couleur,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Ce que voit un athlète.
  Widget blocAthlete() {
    // Déjà réservé : bandeau vert et bouton d'annulation.
    if (maReservation != null) {
      return Column(
        spacing: 12,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          bandeau(
            Icons.check_circle,
            'Vous avez réservé cette séance',
            Colors.green,
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: annulerReservation,
            child: const Text('Annuler ma réservation'),
          ),
        ],
      );
    }

    if (seance.statut == StatutSeance.PLANIFIEE) {
      return ElevatedButton(
        onPressed: reserver,
        child: const Text('Réserver cette séance'),
      );
    }

    if (seance.statut == StatutSeance.COMPLETE) {
      return bandeau(Icons.event_busy, 'Séance complète', Colors.orange);
    }

    if (seance.statut == StatutSeance.ANNULEE) {
      return bandeau(Icons.cancel, 'Séance annulée', Colors.red);
    }

    return bandeau(Icons.history, 'Séance terminée', Colors.grey);
  }

  // Ce que voit le coach propriétaire.
  Widget blocCoach() {
    return Column(
      spacing: 12,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Participants (${participants.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (participants.isEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    child: const Text('Aucune réservation pour le moment.'),
                  )
                else
                  ...participants.map((nom) {
                    return Container(
                      margin: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: Colors.deepPurple),
                          Container(
                            margin: const EdgeInsets.only(left: 10),
                            child: Text(nom),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        Row(
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
      ],
    );
  }

  Widget construireContenu() {
    String textePlaces = '${seance.capacite} places';

    if (nbReservations != null && seance.capacite != null) {
      textePlaces = '$nbReservations / ${seance.capacite} réservées';
    }

    return ListView(
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
                  ligneInfo(Icons.event_seat, 'Places', textePlaces),
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
        // À venir : météo (Open-Meteo).
        Container(
          margin: const EdgeInsets.only(top: 12),
          child: proprietaire ? blocCoach() : blocAthlete(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Séance')),
      body: chargement
          ? const Center(child: CircularProgressIndicator())
          : construireContenu(),
    );
  }
}