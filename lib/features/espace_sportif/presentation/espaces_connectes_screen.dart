import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repositories/espaces_repository.dart';
import 'espaces_sportifs_screen.dart';

class EspacesConnectesScreen extends StatefulWidget {
  const EspacesConnectesScreen({super.key});
  @override
  State<EspacesConnectesScreen> createState() => _EspacesConnectesScreenState();
}

class _EspacesConnectesScreenState extends State<EspacesConnectesScreen> {
  late final donnees = EspacesRepository(Supabase.instance.client);
  bool chargement = true;
  String? erreur;
  int version = 0;

  @override
  void initState() {
    super.initState();
    charger();
  }

  Future<void> charger() async {
    setState(() {
      chargement = true;
      erreur = null;
    });
    try {
      await donnees.charger();
    } catch (_) {
      bool cache = false;
      // Le catalogue local reste consultable en lecture seule lorsque le réseau est indisponible.
      try {
        cache = await donnees.chargerCache();
      } catch (_) {
        /* Cache absent ou illisible. */
      }
      erreur = cache ? null : 'Impossible de charger les espaces. Vérifiez votre connexion et que votre compte est actif.';
    }
    if (mounted) {
      setState(() {
        chargement = false;
        version++;
      });
    }
  }

  @override
  void dispose() {
    donnees.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (chargement || erreur != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Espaces sportifs')),
        body: Center(
          child: chargement
              ? const CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(erreur!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: charger,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
        ),
      );
    }
    return ListenableBuilder(
      listenable: donnees,
      builder: (context, _) => Column(
        children: [
          if (donnees.erreurActualisation != null)
            Material(
              color: Theme.of(context).colorScheme.errorContainer,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(donnees.erreurActualisation!),
                ),
              ),
            ),
          SafeArea(
            bottom: false,
            child: Material(
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      donnees.horsLigne
                          ? 'Catalogue hors ligne · lecture seule · données potentiellement anciennes'
                          : 'Données synchronisées · ${donnees.role}',
                    ),
                  ),
                  IconButton(
                    tooltip: 'Actualiser',
                    onPressed: charger,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: EspacesSportifsScreen(
              key: ValueKey(version),
              donnees: donnees,
              gestionnaireInitial: [
                'ADMIN',
                'GESTIONNAIRE_ESPACE',
              ].contains(donnees.role),
            ),
          ),
        ],
      ),
    );
  }
}
