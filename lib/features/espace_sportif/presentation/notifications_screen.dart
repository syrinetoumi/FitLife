import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/services/notifications_service.dart';

class ClocheNotifications extends StatefulWidget {
  const ClocheNotifications({super.key});

  @override
  State<ClocheNotifications> createState() => _ClocheNotificationsState();
}

class _ClocheNotificationsState extends State<ClocheNotifications>
    with WidgetsBindingObserver {
  late final service = NotificationsService(Supabase.instance.client);
  Timer? minuterie;
  int nonLues = 0;
  bool chargement = false;
  String? erreur;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    notificationsChangees.addListener(actualiser);
    minuterie = Timer.periodic(const Duration(seconds: 30), (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        actualiser();
      }
    });
    actualiser();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) actualiser();
  }

  Future<void> actualiser() async {
    if (chargement) return;
    chargement = true;
    try {
      final resultat = await service.lister();
      if (mounted) {
        setState(() {
          nonLues = (resultat['non_lues'] as num).toInt();
          erreur = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => erreur = 'Notifications indisponibles');
    } finally {
      chargement = false;
    }
  }

  @override
  void dispose() {
    minuterie?.cancel();
    notificationsChangees.removeListener(actualiser);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: erreur ?? 'Notifications ($nonLues non lues)',
    onPressed: () async {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
      );
      if (mounted) actualiser();
    },
    icon: Badge(
      isLabelVisible: nonLues > 0,
      label: Text(nonLues > 99 ? '99+' : '$nonLues'),
      child: Icon(
        erreur == null
            ? Icons.notifications_outlined
            : Icons.notifications_paused_outlined,
      ),
    ),
  );
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final service = NotificationsService(Supabase.instance.client);
  late Future<Map<String, dynamic>> resultat = service.lister();
  final lectures = <String>{};

  Future<void> actualiser() async {
    final prochain = service.lister();
    setState(() => resultat = prochain);
    await prochain;
  }

  Future<void> lire(Map notification) async {
    final id = notification['id'] as String;
    if (notification['lu'] == true || lectures.contains(id)) return;
    setState(() => lectures.add(id));
    try {
      await service.lire(id);
      if (mounted) await actualiser();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lecture non enregistrée. Réessayez.')),
        );
      }
    } finally {
      if (mounted) setState(() => lectures.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Notifications'),
      actions: [
        IconButton(
          tooltip: 'Actualiser',
          onPressed: () => actualiser().catchError((_) {}),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<Map<String, dynamic>>(
      future: resultat,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    snapshot.error is StateError
                        ? (snapshot.error as StateError).message.toString()
                        : 'Impossible de charger les notifications.',
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => actualiser().catchError((_) {}),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          );
        }
        final liste = snapshot.data!['notifications'] as List;
        if (liste.isEmpty) {
          return const Center(
            child: Text('Aucune notification pour le moment.'),
          );
        }
        return RefreshIndicator(
          onRefresh: () => actualiser().catchError((_) {}),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: liste.length,
            itemBuilder: (context, index) {
              final notification = liste[index] as Map;
              final lu = notification['lu'] == true;
              return Card(
                child: ListTile(
                  leading: Icon(
                    lu
                        ? Icons.mark_email_read_outlined
                        : Icons.notifications_active_outlined,
                  ),
                  title: Text(
                    notification['titre'] as String,
                    style: TextStyle(
                      fontWeight: lu ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(notification['texte'] as String),
                  trailing: lectures.contains(notification['id'])
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : lu
                      ? const Icon(Icons.done, semanticLabel: 'Lue')
                      : const Icon(
                          Icons.circle,
                          size: 10,
                          semanticLabel: 'Non lue',
                        ),
                  onTap: () => lire(notification),
                ),
              );
            },
          ),
        );
      },
    ),
  );
}
