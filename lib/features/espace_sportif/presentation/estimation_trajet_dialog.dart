import 'package:flutter/material.dart';

import '../data/services/position_appareil_service.dart';

class EstimationTrajetDialog extends StatefulWidget {
  const EstimationTrajetDialog({
    super.key,
    required this.destination,
    required this.estimer,
    required this.ouvrirReglages,
  });
  final String destination;
  final Future<Map<String, dynamic>> Function(String profil) estimer;
  final Future<bool> Function(ReglagePosition reglage) ouvrirReglages;
  @override
  State<EstimationTrajetDialog> createState() => _EstimationTrajetDialogState();
}

class _EstimationTrajetDialogState extends State<EstimationTrajetDialog> {
  String profil = 'foot-walking';
  late Future<Map<String, dynamic>> resultat;
  @override
  void initState() {
    super.initState();
    // Le premier calcul démarre dès l’ouverture du dialogue, sans bouton de validation supplémentaire.
    resultat = widget.estimer(profil);
  }

  void actualiser() => setState(() {
    resultat = widget.estimer(profil);
  });

  @override
  // FutureBuilder affiche le résultat de la demande courante et ignore les réponses des anciennes demandes.
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: resultat,
    builder: (context, snapshot) {
      final enCours = snapshot.connectionState != ConnectionState.done;
      final erreur = snapshot.error;
      return AlertDialog(
        title: const Text('Estimation du trajet'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Destination : ${widget.destination}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                const Text('Départ : ma position actuelle'),
                const SizedBox(height: 8),
                const Text(
                  'Votre position est utilisée pour ce trajet et transmise au service de calcul d’itinéraire.',
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: profil,
                  decoration: const InputDecoration(
                    labelText: 'Mode de déplacement',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'foot-walking',
                      child: Text('À pied'),
                    ),
                    DropdownMenuItem(
                      value: 'cycling-regular',
                      child: Text('À vélo'),
                    ),
                    DropdownMenuItem(
                      value: 'driving-car',
                      child: Text('En voiture'),
                    ),
                  ],
                  onChanged: enCours
                      ? null
                      : (v) {
                          profil = v!;
                          actualiser();
                        },
                ),
                const SizedBox(height: 20),
                if (enCours)
                  const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Localisation et calcul du trajet…'),
                    ],
                  )
                else if (erreur != null) ...[
                  Text(
                    erreur is ErreurPosition
                        ? erreur.message
                        : erreur is StateError
                        ? erreur.message.toString()
                        : 'Estimation indisponible. Réessayez plus tard.',
                  ),
                  if (erreur is ErreurPosition && erreur.reglage != null)
                    TextButton.icon(
                      onPressed: () async {
                        try {
                          final ouvert = await widget.ouvrirReglages(
                            erreur.reglage!,
                          );
                          if (context.mounted && !ouvert) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Ouvrez les réglages du téléphone puis réessayez.',
                                ),
                              ),
                            );
                          }
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Ouvrez les réglages du téléphone puis réessayez.',
                                ),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.settings_outlined),
                      label: const Text('Ouvrir les réglages'),
                    ),
                ] else if (snapshot.hasData)
                  Text(
                    '${((snapshot.data!['distance'] as num) / 1000).toStringAsFixed(1)} km · ${((snapshot.data!['duree'] as num) / 60).ceil()} min environ',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                const SizedBox(height: 16),
                const Text(
                  'openrouteservice · © OpenStreetMap contributors',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          FilledButton.icon(
            onPressed: enCours ? null : actualiser,
            icon: const Icon(Icons.my_location),
            label: Text(
              erreur == null ? 'Actualiser ma position' : 'Réessayer',
            ),
          ),
        ],
      );
    },
  );
}
