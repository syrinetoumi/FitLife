import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Le paquet est déjà résolu dans le verrou existant. Ne pas modifier les dépendances partagées ici.
// ignore: depend_on_referenced_packages
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import 'donnees_apercu.dart';

String destinationEspace(EspaceApercu espace) =>
    espace.latitude != null && espace.longitude != null
    ? '${espace.latitude},${espace.longitude}'
    : espace.adresse;

Uri lienCarte(EspaceApercu espace) => Uri.https(
  'www.google.com',
  '/maps/search/',
  {'api': '1', 'query': destinationEspace(espace)},
);

Uri lienItineraire(
  EspaceApercu espace, {
  String depart = '',
  String mode = 'walking',
}) => Uri.https('www.google.com', '/maps/dir/', {
  'api': '1',
  'destination': destinationEspace(espace),
  if (depart.trim().isNotEmpty) 'origin': depart.trim(),
  'travelmode': mode,
});

Future<void> ouvrirLienLocalisation(BuildContext context, Uri lien) async {
  var ouvert = false;
  try {
    ouvert = await launchUrl(lien, mode: LaunchMode.externalApplication);
  } catch (_) {
    // Le message permet de récupérer le lien si aucune application ne répond.
  }
  if (!context.mounted || ouvert) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text(
        'Impossible d’ouvrir la carte. Vous pouvez copier le lien.',
      ),
      action: SnackBarAction(
        label: 'Copier',
        onPressed: () =>
            Clipboard.setData(ClipboardData(text: lien.toString())),
      ),
    ),
  );
}

class LocalisationEspace extends StatelessWidget {
  const LocalisationEspace({super.key, required this.espace});
  final EspaceApercu espace;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on_outlined, color: AppCouleurs.principale),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Préparer votre visite',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(espace.nom, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          SelectableText(espace.adresse),
          const SizedBox(height: 8),
          Text(
            espace.latitude == null
                ? 'Recherche sur la carte par adresse.'
                : 'Coordonnées : ${espace.latitude!.toStringAsFixed(5)}, ${espace.longitude!.toStringAsFixed(5)}',
            style: const TextStyle(color: AppCouleurs.texteSecondaire),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () =>
                    ouvrirLienLocalisation(context, lienCarte(espace)),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Voir sur la carte'),
              ),
              OutlinedButton.icon(
                onPressed: () => _itineraire(context, espace),
                icon: const Icon(Icons.directions_outlined),
                label: const Text('Itinéraire'),
              ),
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: espace.adresse));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Adresse copiée.')),
                  );
                },
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Copier l’adresse'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'La carte et le trajet s’ouvrent dans votre application de cartes ou navigateur. Les distances et durées sont fournies par ce service.',
            style: TextStyle(fontSize: 12, color: AppCouleurs.texteSecondaire),
          ),
        ],
      ),
    ),
  );
}

void _itineraire(BuildContext context, EspaceApercu espace) {
  final parentContext = context;
  var depart = '', mode = 'walking';
  final cle = GlobalKey<FormState>();
  showDialog<void>(
    context: context,
    routeSettings: const RouteSettings(name: '/espaces-sportifs/itineraire'),
    builder: (c) => StatefulBuilder(
      builder: (context, modifier) => AlertDialog(
        title: const Text('Préparer l’itinéraire'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Form(
              key: cle,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Destination : ${espace.nom}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(espace.adresse),
                  const SizedBox(height: 20),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Adresse de départ',
                      helperText: 'Facultatif : le service de cartes vous demandera le départ.',
                      helperMaxLines: 2,
                    ),
                    maxLength: 250,
                    onChanged: (v) => depart = v,
                    validator: (v) =>
                        v != null && v.isNotEmpty && v.trim().isEmpty
                        ? 'Renseignez une adresse ou laissez ce champ vide.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: mode,
                    decoration: const InputDecoration(
                      labelText: 'Mode de déplacement',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'walking', child: Text('À pied')),
                      DropdownMenuItem(
                        value: 'driving',
                        child: Text('En voiture'),
                      ),
                      DropdownMenuItem(
                        value: 'bicycling',
                        child: Text('À vélo'),
                      ),
                    ],
                    onChanged: (v) => modifier(() => mode = v!),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'L’adresse saisie sera transmise au service de cartes lors de l’ouverture. Aucun accès à votre position n’est demandé par FitLife.',
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Retour'),
          ),
          FilledButton(
            onPressed: () {
              if (!cle.currentState!.validate()) return;
              final lien = lienItineraire(espace, depart: depart, mode: mode);
              Navigator.pop(c);
              ouvrirLienLocalisation(parentContext, lien);
            },
            child: const Text('Ouvrir l’itinéraire'),
          ),
        ],
      ),
    ),
  );
}
