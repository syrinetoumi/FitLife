import 'package:flutter/material.dart';

import 'package:coach_app/features/entrainement/data/models/enums.dart';
import 'package:coach_app/features/entrainement/data/models/prevision_meteo.dart';
import 'package:coach_app/features/entrainement/data/models/seance.dart';
import 'package:coach_app/features/entrainement/data/services/analyse_meteo.dart';
import 'package:coach_app/features/entrainement/data/services/meteo_service.dart';

String libelleCondition(int id) {
  if (id >= 200 && id < 300) return 'Orage';
  if (id >= 300 && id < 400) return 'Bruine';
  if (id >= 500 && id < 600) return 'Pluie';
  if (id >= 600 && id < 700) return 'Neige';
  if (id >= 700 && id < 800) return 'Brume';
  if (id == 800) return 'Ciel dégagé';
  return 'Nuageux';
}

IconData iconeCondition(int id) {
  if (id >= 200 && id < 300) return Icons.thunderstorm;
  if (id >= 300 && id < 600) return Icons.water_drop;
  if (id >= 600 && id < 700) return Icons.ac_unit;
  if (id >= 700 && id < 800) return Icons.foggy;
  if (id == 800) return Icons.wb_sunny;
  return Icons.cloud;
}

class CarteMeteo extends StatefulWidget {
  final Seance seance;

  const CarteMeteo({super.key, required this.seance});

  @override
  State<CarteMeteo> createState() => _CarteMeteoState();
}

class _CarteMeteoState extends State<CarteMeteo> {
  final MeteoService service = MeteoService();

  PrevisionMeteo? prevision;
  AvisMeteo? avis;
  String? message;
  bool chargement = true;

  // Date et heure de début de la séance.
  DateTime get debutSeance {
    DateTime jour = widget.seance.date;
    List<String> morceaux = widget.seance.debutCourt.split(':');

    return DateTime(
      jour.year,
      jour.month,
      jour.day,
      int.parse(morceaux[0]),
      int.parse(morceaux[1]),
    );
  }

  // La météo n'a de sens que pour une séance à venir et maintenue.
  bool get concernee {
    StatutSeance statut = widget.seance.statut;

    if (statut == StatutSeance.ANNULEE || statut == StatutSeance.TERMINEE) {
      return false;
    }

    return debutSeance.isAfter(DateTime.now());
  }

  @override
  void initState() {
    super.initState();

    if (concernee) {
      charger();
    }
  }

  Future<void> charger() async {
    try {
      List<PrevisionMeteo> liste = await service.previsions();
      PrevisionMeteo? trouvee = MeteoService.plusProche(liste, debutSeance);

      if (!mounted) {
        return;
      }

      setState(() {
        prevision = trouvee;
        avis = trouvee == null ? null : AnalyseMeteo.evaluer(trouvee);
        message = trouvee == null
            ? 'Les prévisions couvrent seulement les 5 prochains jours.'
            : null;
        chargement = false;
      });
    } catch (erreur) {
      if (!mounted) {
        return;
      }

      setState(() {
        message = erreur.toString().replaceFirst('Exception: ', '');
        chargement = false;
      });
    }
  }

  Widget avisBandeau(AvisMeteo avisMeteo) {
    Color couleur;
    IconData icone;
    String titre;

    if (avisMeteo.niveau == NiveauMeteo.defavorable) {
      couleur = Colors.red;
      icone = Icons.warning_amber;
      titre = 'Conditions défavorables';
    } else if (avisMeteo.niveau == NiveauMeteo.attention) {
      couleur = Colors.orange;
      icone = Icons.info_outline;
      titre = 'À surveiller';
    } else {
      couleur = Colors.green;
      icone = Icons.check_circle_outline;
      titre = 'Conditions favorables';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleur),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: couleur),
              const SizedBox(width: 8),
              Text(
                titre,
                style: TextStyle(
                  color: couleur,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          ...avisMeteo.raisons.map((raison) {
            return Padding(
              padding: const EdgeInsets.only(top: 4, left: 32),
              child: Text(raison),
            );
          }),
        ],
      ),
    );
  }

  Widget petiteInfo(IconData icone, String texte) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 16),
        const SizedBox(width: 4),
        Text(texte, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Widget contenu() {
    if (chargement) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (prevision == null || avis == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message ?? 'Météo indisponible.'),
      );
    }

    PrevisionMeteo p = prevision!;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                iconeCondition(p.idCondition),
                size: 44,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${p.temperature.round()} °C',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(libelleCondition(p.idCondition)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              petiteInfo(Icons.air, '${(p.vent * 3.6).round()} km/h'),
              petiteInfo(Icons.water_drop,
                  '${(p.probabilitePluie * 100).round()} % de pluie'),
              petiteInfo(Icons.opacity, '${p.humidite} % d\'humidité'),
            ],
          ),
          const SizedBox(height: 12),
          avisBandeau(avis!),
          const SizedBox(height: 8),
          const Text(
            'À prendre en compte si la séance se déroule en extérieur.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!concernee) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              'Météo prévue · Tunis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          contenu(),
        ],
      ),
    );
  }
}