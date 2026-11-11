import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:coach_app/features/espace_sportif/data/services/position_appareil_service.dart';

class PositionPlateforme extends GeolocatorPlatform {
  LocationPermission permission = LocationPermission.denied;
  LocationPermission reponse = LocationPermission.denied;
  bool active = false;
  int verifications = 0, demandes = 0, lectures = 0;

  @override
  Future<LocationPermission> checkPermission() async {
    verifications++;
    return permission;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    demandes++;
    return reponse;
  }

  @override
  Future<bool> isLocationServiceEnabled() async => active;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    lectures++;
    return Position(
      latitude: 36.84,
      longitude: 10.18,
      timestamp: DateTime(2026),
      accuracy: 1,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}

void main() {
  final service = PositionAppareilService();
  late GeolocatorPlatform initiale;
  late PositionPlateforme plateforme;
  setUp(() {
    initiale = GeolocatorPlatform.instance;
    plateforme = PositionPlateforme();
    GeolocatorPlatform.instance = plateforme;
  });
  tearDown(() => GeolocatorPlatform.instance = initiale);

  for (final permission in [
    LocationPermission.denied,
    LocationPermission.unableToDetermine,
  ]) {
    test(
      'Redemande $permission à chaque tentative, même GPS désactivé',
      () async {
        plateforme.permission = permission;
        for (var tentative = 0; tentative < 2; tentative++) {
          await expectLater(service.obtenir(), throwsA(isA<ErreurPosition>()));
        }
        expect(plateforme.verifications, 2);
        expect(plateforme.demandes, 2);
        expect(plateforme.lectures, 0);
      },
    );
  }

  test(
    'Permission accordée et GPS désactivé proposent les réglages GPS',
    () async {
      plateforme.reponse = LocationPermission.whileInUse;
      await expectLater(
        service.obtenir(),
        throwsA(
          isA<ErreurPosition>().having(
            (e) => e.reglage,
            'réglage',
            ReglagePosition.localisation,
          ),
        ),
      );
      expect(plateforme.demandes, 1);
      expect(plateforme.lectures, 0);
    },
  );

  test('Une autorisation révoquée est redemandée au prochain calcul', () async {
    plateforme.active = true;
    plateforme.permission = LocationPermission.whileInUse;
    await service.obtenir();
    expect(plateforme.demandes, 0);
    plateforme.permission = LocationPermission.denied;
    plateforme.reponse = LocationPermission.whileInUse;
    await service.obtenir();
    expect(plateforme.verifications, 2);
    expect(plateforme.demandes, 1);
    expect(plateforme.lectures, 2);
  });

  test(
    'Le refus définitif propose les réglages sans demande impossible',
    () async {
      plateforme.permission = LocationPermission.deniedForever;
      await expectLater(
        service.obtenir(),
        throwsA(
          isA<ErreurPosition>().having(
            (e) => e.reglage,
            'réglage',
            ReglagePosition.application,
          ),
        ),
      );
      expect(plateforme.demandes, 0);
      expect(plateforme.lectures, 0);
    },
  );
}
