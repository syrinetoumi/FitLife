import '../models/mesure_progression.dart';
import '../models/suivi_objectif.dart';

enum StatutProgression { atteint, enAvance, dansLesTemps, enRetard, sansMesure }

class ResultatProgression {
  final double valeurActuelle;
  final double pourcentage; // avancement réel (0 = départ, 100 = cible)
  final double pourcentageAttendu; // avancement prévu à la date du jour
  final double ecart; // pourcentage - pourcentageAttendu
  final double resteAFaire; // dans l'unité de l'objectif
  final int joursRestants;
  final double? rythmeParSemaine; // vitesse réelle de progression
  final DateTime? dateEstimee; // date d'arrivée si le rythme continue
  final StatutProgression statut;

  ResultatProgression({
    required this.valeurActuelle,
    required this.pourcentage,
    required this.pourcentageAttendu,
    required this.ecart,
    required this.resteAFaire,
    required this.joursRestants,
    required this.rythmeParSemaine,
    required this.dateEstimee,
    required this.statut,
  });
}

class CalculProgression {
  // Écart (en points de %) à partir duquel on est "en avance" / "en retard".
  static const double seuilAvance = 5;
  static const double seuilRetard = -10;

  static DateTime _jour(DateTime d) => DateTime(d.year, d.month, d.day);

  static ResultatProgression calculer(
      SuiviObjectif suivi,
      List<MesureProgression> mesures, {
        DateTime? aujourdhui,
      }) {
    final ajd = _jour(aujourdhui ?? DateTime.now());
    final debut = _jour(suivi.dateDebut);
    final limite = _jour(suivi.dateLimite);

    // Mesures triées de la plus ancienne à la plus récente.
    final triees = [...mesures]
      ..sort((a, b) => a.dateMesure.compareTo(b.dateMesure));

    final actuelle = triees.isEmpty ? suivi.valeurDepart : triees.last.valeur;

    // Distance à parcourir et distance déjà parcourue (selon le sens).
    final total = (suivi.valeurCible - suivi.valeurDepart).abs();
    final fait = suivi.estUneBaisse
        ? suivi.valeurDepart - actuelle
        : actuelle - suivi.valeurDepart;

    final pourcentage = fait / total * 100;

    // Avancement attendu : progression régulière entre le début et la limite.
    final dureeTotale = limite.difference(debut).inDays;
    final ecoule = ajd.difference(debut).inDays;
    final attendu = dureeTotale <= 0
        ? 100.0
        : (ecoule / dureeTotale * 100).clamp(0.0, 100.0).toDouble();

    final ecart = pourcentage - attendu;

    final reste = (total - fait).clamp(0.0, total).toDouble();
    final joursRestants = limite.difference(ajd).inDays;

    // Rythme réel (par semaine) et date estimée d'arrivée.
    double? rythme;
    DateTime? dateEstimee;
    if (triees.isNotEmpty) {
      final derniere = _jour(triees.last.dateMesure);
      final jours = derniere.difference(debut).inDays;
      if (jours > 0) {
        rythme = fait / jours * 7;
        if (rythme > 0 && reste > 0) {
          final joursNecessaires = (reste / (rythme / 7)).ceil();
          dateEstimee = derniere.add(Duration(days: joursNecessaires));
        }
      }
    }

    // Statut.
    StatutProgression statut;
    if (pourcentage >= 100) {
      statut = StatutProgression.atteint;
    } else if (triees.isEmpty) {
      statut = StatutProgression.sansMesure;
    } else if (ecart >= seuilAvance) {
      statut = StatutProgression.enAvance;
    } else if (ecart >= seuilRetard) {
      statut = StatutProgression.dansLesTemps;
    } else {
      statut = StatutProgression.enRetard;
    }

    return ResultatProgression(
      valeurActuelle: actuelle,
      pourcentage: pourcentage,
      pourcentageAttendu: attendu,
      ecart: ecart,
      resteAFaire: reste,
      joursRestants: joursRestants < 0 ? 0 : joursRestants,
      rythmeParSemaine: rythme,
      dateEstimee: dateEstimee,
      statut: statut,
    );
  }
}