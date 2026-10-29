import '../models/suivi_objectif.dart';
import 'calcul_progression.dart';

enum TypeProposition { prolongerDate, ajusterCible, conseil }

class Proposition {
  final TypeProposition type;
  final String titre;
  final String explication;
  final DateTime? nouvelleDate;
  final double? nouvelleCible;

  Proposition({
    required this.type,
    required this.titre,
    required this.explication,
    this.nouvelleDate,
    this.nouvelleCible,
  });
}

class AdaptationProgramme {
  static double _arrondi(double valeur) => (valeur * 10).round() / 10;

  static String _valeur(double v) {
    if (v == v.roundToDouble()) {
      return v.toStringAsFixed(0);
    }
    return v.toStringAsFixed(1);
  }

  static String _date(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  // Valeur prévue à la date limite si le rythme actuel continue.
  static double? _valeurProjetee(SuiviObjectif suivi, ResultatProgression r) {
    final rythme = r.rythmeParSemaine;

    if (rythme == null || rythme <= 0) {
      return null;
    }

    final sens = suivi.estUneBaisse ? -1 : 1;
    final semaines = r.joursRestants / 7;

    return r.valeurActuelle + sens * rythme * semaines;
  }

  static List<Proposition> proposer(
      SuiviObjectif suivi,
      ResultatProgression r,
      ) {
    final liste = <Proposition>[];
    final projetee = _valeurProjetee(suivi, r);

    switch (r.statut) {
      case StatutProgression.enRetard:
      // 1. Laisser plus de temps.
        DateTime nouvelleDate;
        String explication;

        if (r.dateEstimee != null && r.dateEstimee!.isAfter(suivi.dateLimite)) {
          nouvelleDate = r.dateEstimee!;
          explication = 'Au rythme actuel, l\'objectif sera atteint vers le '
              '${_date(nouvelleDate)}.';
        } else {
          nouvelleDate = suivi.dateLimite.add(const Duration(days: 14));
          explication = 'Laisse deux semaines de plus pour rattraper le retard.';
        }

        liste.add(Proposition(
          type: TypeProposition.prolongerDate,
          titre: 'Prolonger la date limite',
          explication: explication,
          nouvelleDate: nouvelleDate,
        ));

        // 2. Viser une cible réaliste.
        if (projetee != null && projetee > 0) {
          final cible = _arrondi(projetee);

          final avantCible = suivi.estUneBaisse
              ? cible > suivi.valeurCible
              : cible < suivi.valeurCible;
          final apresDepart = suivi.estUneBaisse
              ? cible < suivi.valeurDepart
              : cible > suivi.valeurDepart;

          if (avantCible && apresDepart) {
            liste.add(Proposition(
              type: TypeProposition.ajusterCible,
              titre: 'Viser une cible réaliste',
              explication: 'À la date limite, l\'athlète sera vers '
                  '${_valeur(cible)} ${suivi.unite} au rythme actuel.',
              nouvelleCible: cible,
            ));
          }
        }

        // 3. Conseil sur le programme.
        liste.add(Proposition(
          type: TypeProposition.conseil,
          titre: 'Renforcer le programme',
          explication: 'Ajoute une séance par semaine ou revois l\'intensité. '
              'Vérifie aussi l\'assiduité de l\'athlète.',
        ));
        break;

      case StatutProgression.enAvance:
        if (projetee != null && projetee > 0) {
          final cible = _arrondi(projetee);

          final plusAmbitieuse = suivi.estUneBaisse
              ? cible < suivi.valeurCible
              : cible > suivi.valeurCible;
          final apresDepart = suivi.estUneBaisse
              ? cible < suivi.valeurDepart
              : cible > suivi.valeurDepart;

          if (plusAmbitieuse && apresDepart) {
            liste.add(Proposition(
              type: TypeProposition.ajusterCible,
              titre: 'Relever la cible',
              explication: 'Au rythme actuel, l\'athlète atteindrait '
                  '${_valeur(cible)} ${suivi.unite} à la date limite.',
              nouvelleCible: cible,
            ));
          }
        }

        liste.add(Proposition(
          type: TypeProposition.conseil,
          titre: 'Passer au niveau supérieur',
          explication: 'L\'athlète progresse plus vite que prévu : augmente '
              'les charges ou le volume.',
        ));
        break;

      case StatutProgression.atteint:
        liste.add(Proposition(
          type: TypeProposition.conseil,
          titre: 'Objectif atteint',
          explication: 'Félicitations ! Propose un nouveau programme plus '
              'exigeant pour continuer.',
        ));
        break;

      case StatutProgression.dansLesTemps:
        liste.add(Proposition(
          type: TypeProposition.conseil,
          titre: 'Rythme conforme',
          explication: 'Aucun changement nécessaire, continue le programme.',
        ));
        break;

      case StatutProgression.sansMesure:
        liste.add(Proposition(
          type: TypeProposition.conseil,
          titre: 'Aucune mesure',
          explication: 'Une première mesure est nécessaire pour calculer '
              'la progression.',
        ));
        break;
    }

    return liste;
  }
}