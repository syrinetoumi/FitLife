import '../models/assiduite.dart';

enum NiveauAssiduite { tresAssidu, moyen, faible, aucuneDonnee }

class ResultatAssiduite {
  final int presences;
  final int absences;
  final int nonRenseignees; // séances terminées sans présence saisie
  final int annulations; // réservations annulées par l'athlète
  final double? taux; // 0 à 100, null si aucune donnée
  final NiveauAssiduite niveau;

  ResultatAssiduite({
    required this.presences,
    required this.absences,
    required this.nonRenseignees,
    required this.annulations,
    required this.taux,
    required this.niveau,
  });
}

class CalculAssiduite {
  static const double seuilBon = 80;
  static const double seuilMoyen = 50;

  static ResultatAssiduite calculer(List<LigneAssiduite> lignes) {
    int presences = 0;
    int absences = 0;
    int nonRenseignees = 0;
    int annulations = 0;

    for (var ligne in lignes) {
      // Réservation annulée par l'athlète.
      if (ligne.statutReservation == 'ANNULEE') {
        annulations++;
        continue;
      }

      // Séance pas encore faite : on ne la compte pas.
      if (ligne.statutSeance != 'TERMINEE') {
        continue;
      }

      if (ligne.presence == true) {
        presences++;
      } else if (ligne.presence == false) {
        absences++;
      } else {
        nonRenseignees++;
      }
    }

    int comptees = presences + absences;
    double? taux = comptees == 0 ? null : presences / comptees * 100;

    NiveauAssiduite niveau;
    if (taux == null) {
      niveau = NiveauAssiduite.aucuneDonnee;
    } else if (taux >= seuilBon) {
      niveau = NiveauAssiduite.tresAssidu;
    } else if (taux >= seuilMoyen) {
      niveau = NiveauAssiduite.moyen;
    } else {
      niveau = NiveauAssiduite.faible;
    }

    return ResultatAssiduite(
      presences: presences,
      absences: absences,
      nonRenseignees: nonRenseignees,
      annulations: annulations,
      taux: taux,
      niveau: niveau,
    );
  }
}