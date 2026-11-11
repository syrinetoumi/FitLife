import 'package:flutter/material.dart';
import '../../data/models/paiement_evenement.dart';

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
      backgroundColor: Colors.white, // BRIGHT RED BACKGROUND
      appBar: AppBar(
        title: const Text('CONFIRMATION', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.black, size: 100),
            const SizedBox(height: 20),
            const Text(
              'PAYMENT CONFIRMED!',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 20),
            Text('Event: $nomEvenement', style: const TextStyle(fontSize: 20, color: Colors.black)),
            Text('Category: $nomCategorie', style: const TextStyle(fontSize: 20,color: Colors.black)),
            Text('Athlete: $idAthlete', style: const TextStyle(fontSize: 20,color: Colors.black)),
            const SizedBox(height: 10),
            Text('Amount: ${paiement.montant} DT', style: const TextStyle(fontSize: 20,color: Colors.black)),
            Text('Reference: ${paiement.reference}', style: const TextStyle(fontSize: 20,color: Colors.black)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Finish'),
            )
          ],
        ),
      ),
    );
  }
}