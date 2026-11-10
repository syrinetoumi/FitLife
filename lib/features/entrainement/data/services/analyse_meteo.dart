import '../models/prevision_meteo.dart';

enum NiveauMeteo { favorable, attention, defavorable }

class AvisMeteo {
  final NiveauMeteo niveau;
  final List<String> raisons;

  AvisMeteo({required this.niveau, required this.raisons});
}

class AnalyseMeteo {
  static AvisMeteo evaluer(PrevisionMeteo p) {
    final raisons = <String>[];
    NiveauMeteo niveau = NiveauMeteo.favorable;

    // Garde le niveau le plus grave rencontré.
    void signaler(NiveauMeteo gravite, String raison) {
      raisons.add(raison);

      if (gravite.index > niveau.index) {
        niveau = gravite;
      }
    }

    int id = p.idCondition;

    // Orage (2xx) et neige (6xx).
    if (id >= 200 && id < 300) {
      signaler(NiveauMeteo.defavorable, 'Orage prévu');
    }

    if (id >= 600 && id < 700) {
      signaler(NiveauMeteo.defavorable, 'Neige prévue');
    }

    // Bruine (3xx) et pluie (5xx).
    if ((id >= 300 && id < 400) || (id >= 500 && id < 600)) {
      if (p.pluieMm >= 5) {
        signaler(
          NiveauMeteo.defavorable,
          //conv int-> 1chif   ,
          'Forte pluie (${p.pluieMm.toStringAsFixed(1)} mm)',
        );
      } else {
        signaler(
          NiveauMeteo.attention,
          'Pluie possible (${(p.probabilitePluie * 100).round()} %)',
        );
      }
    }

    // Vent (m/s -> km/h pour l'affichage).
    if (p.vent >= 14 || p.rafale >= 20) {
      signaler(
        NiveauMeteo.defavorable,
        'Vent fort (${(p.rafale * 3.6).round()} km/h en rafales)',
      );
    } else if (p.vent >= 8 || p.rafale >= 14) {
      signaler(
        NiveauMeteo.attention,
        'Vent soutenu (${(p.rafale * 3.6).round()} km/h en rafales)',
      );
    }

    // Température ressentie.
    if (p.ressenti >= 35) {
      signaler(
        NiveauMeteo.defavorable,
        'Chaleur extrême (${p.ressenti.round()} °C ressentis)',
      );
    } else if (p.ressenti >= 30) {
      signaler(
        NiveauMeteo.attention,
        'Forte chaleur (${p.ressenti.round()} °C ressentis)',
      );
    } else if (p.ressenti <= 0) {
      signaler(
        NiveauMeteo.defavorable,
        'Froid intense (${p.ressenti.round()} °C ressentis)',
      );
    } else if (p.ressenti <= 5) {
      signaler(
        NiveauMeteo.attention,
        'Temps froid (${p.ressenti.round()} °C ressentis)',
      );
    }

    // Visibilité.
    if (p.visibilite < 1000) {
      signaler(NiveauMeteo.defavorable, 'Visibilité très réduite');
    } else if (p.visibilite < 5000) {
      signaler(NiveauMeteo.attention, 'Visibilité réduite');
    }

    return AvisMeteo(niveau: niveau, raisons: raisons);
  }
}