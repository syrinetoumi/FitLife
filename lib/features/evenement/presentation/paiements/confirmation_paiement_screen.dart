import 'package:flutter/material.dart';

import '../../data/models/paiement_evenement.dart';
import '../../../../core/utils/outils.dart';

// ================================================================
// MÉTIER 3 — Dernière étape du parcours : CONFIRMATION.
// Écran simple (StatelessWidget) : il ne fait qu'afficher
// le récapitulatif inscription + paiement + la référence.
// ================================================================
class ConfirmationPaiementScreen extends StatelessWidget {
  final PaiementEvenement paiement;
  final String nomEvenement;
  final String nomCategorie;
  final String idAthlete;

  const ConfirmationPaiementScreen({
    super.key,
    required this.paiement,
    required this.nomEvenement,
    required this.nomCategorie,
    required this.idAthlete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmation'),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // MESSAGE DE SUCCÈS
            Card(
              color: Colors.green,
              child: Container(
                padding: const EdgeInsets.all(24),
                child: const Column(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 50,
                    ),
                    Text(
                      'Inscription confirmée !',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    ),
                    Text(
                      'Votre paiement a bien été enregistré',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // RÉCAPITULATIF INSCRIPTION
            Card(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Votre inscription',
                      style: TextStyle(fontSize: 18),
                    ),
                    Text(nomEvenement),
                    Text('Catégorie : $nomCategorie'),
                    Text('Athlète : $idAthlete'),
                  ],
                ),
              ),
            ),

            // RÉCAPITULATIF PAIEMENT
            Card(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Votre paiement',
                      style: TextStyle(fontSize: 18),
                    ),
                    Text(
                      '${paiement.montant.toStringAsFixed(2)} DT',
                      style: const TextStyle(fontSize: 20),
                    ),
                    Text('Date : ${afficherDate(paiement.datePaiement)}'),
                    Text('Méthode : ${paiement.methodeToString()}'),
                    Text('Statut : ${paiement.statutToString()}'),
                    Text('Référence : ${paiement.reference}'),
                  ],
                ),
              ),
            ),

            const Text(
              'Conservez votre référence : elle vous sera '
                  'demandée le jour de l’événement.',
            ),

            // BOUTON TERMINER
            Container(
              margin: const EdgeInsets.only(top: 24, bottom: 20),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Terminer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
