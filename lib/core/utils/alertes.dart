import 'package:flutter/material.dart';

// Boîte de dialogue pour afficher une erreur bloquante.
void afficherAlerteErreur(
    BuildContext context, {
      required String titre,
      required String message,
    }) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              color: Colors.red.shade700,
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 52,
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    child: Text(
                      titre,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, height: 1.4),
              ),
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Compris'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

// Demande de confirmation (suppression, etc.). Retourne true si confirmé.
Future<bool> confirmerAction(
    BuildContext context, {
      required String titre,
      required String message,
      String libelleBouton = 'Supprimer',
      String libelleRefus = 'Annuler',
    }) async {
  bool? reponse = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(titre),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: Text(libelleRefus),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: Text(
              libelleBouton,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      );
    },
  );

  return reponse == true;
}
