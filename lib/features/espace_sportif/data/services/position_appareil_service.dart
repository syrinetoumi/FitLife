import 'dart:async';

import 'package:geolocator/geolocator.dart';

enum ReglagePosition { application, localisation }

class ErreurPosition implements Exception {
  const ErreurPosition(this.message, {this.reglage});
  final String message;
  final ReglagePosition? reglage;
  @override
  String toString() => message;
}

class PositionAppareilService {
  // Une seule lecture à la demande, sans suivi ni stockage de la position.
  Future<Position> obtenir() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const ErreurPosition(
        'Activez la localisation du téléphone pour estimer le trajet.',
        reglage: ReglagePosition.localisation,
      );
    }
    // Une autorisation refusée définitivement se rétablit dans les réglages, pas par une nouvelle fenêtre de demande.
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const ErreurPosition(
        'Autorisez la localisation de FitLife dans les réglages de l’application.',
        reglage: ReglagePosition.application,
      );
    }
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      throw const ErreurPosition(
        'La localisation est nécessaire pour calculer le trajet depuis votre position.',
      );
    }
    // Le délai limite l’attente lorsque le téléphone ne reçoit pas de position GPS exploitable.
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } on TimeoutException {
      throw const ErreurPosition(
        'Position introuvable pour le moment. Vérifiez le GPS puis réessayez.',
      );
    } on LocationServiceDisabledException {
      throw const ErreurPosition(
        'La localisation est désactivée.',
        reglage: ReglagePosition.localisation,
      );
    }
  }

  Future<bool> ouvrirReglages(ReglagePosition reglage) =>
      reglage == ReglagePosition.application
      ? Geolocator.openAppSettings()
      : Geolocator.openLocationSettings();
}
