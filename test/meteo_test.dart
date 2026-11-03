import 'package:flutter_test/flutter_test.dart';

import 'package:coach_app/features/entrainement/data/models/prevision_meteo.dart';
import 'package:coach_app/features/entrainement/data/services/analyse_meteo.dart';

void main() {
  test('Pluie modérée avec visibilité réduite : défavorable', () {
    final prevision = PrevisionMeteo.fromJson({
      'dt': 1793966400,
      'main': {'temp': 290.45, 'feels_like': 290.77, 'humidity': 97},
      'weather': [
        {'id': 501, 'icon': '10d'}
      ],
      'clouds': {'all': 100},
      'wind': {'speed': 2.37, 'gust': 4.49},
      'visibility': 3537,
      'pop': 1,
      'rain': {'3h': 6.18},
    });

    final avis = AnalyseMeteo.evaluer(prevision);

    expect(avis.niveau, NiveauMeteo.defavorable);
  });

  test('Ciel nuageux et doux : favorable', () {
    final prevision = PrevisionMeteo.fromJson({
      'dt': 1793620800,
      'main': {'temp': 281.52, 'feels_like': 281.12, 'humidity': 72},
      'weather': [
        {'id': 803, 'icon': '04d'}
      ],
      'clouds': {'all': 51},
      'wind': {'speed': 1.35, 'gust': 2.78},
      'visibility': 10000,
      'pop': 0,
    });

    final avis = AnalyseMeteo.evaluer(prevision);

    expect(avis.niveau, NiveauMeteo.favorable);
    expect(avis.raisons, isEmpty);
  });
}