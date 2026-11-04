import '../models/modeles_espaces.dart';
import 'offres_metier.dart';
import 'valeurs_metier.dart';

// L’annulation est définitive ; une suspension ne décale pas la date de fin.
extension ReglesAbonnement on AbonnementApercu {
  String get statutEffectif =>
      statut != 'ANNULE' && jourLocal().isAfter(fin) ? 'EXPIRE' : statut;
}

// Un abonnement actif ou suspendu du compte courant empêche une seconde souscription à la même offre.
bool abonnementPersonnelExistant(
  Iterable<AbonnementApercu> abonnements,
  int offre,
) => abonnements.any(
  (a) =>
      a.estPersonnel &&
      a.offre == offre &&
      ['ACTIF', 'SUSPENDU'].contains(a.statutEffectif),
);

bool souscriptionPossible(
  OffreApercu offre,
  EspaceApercu espace,
  Iterable<AbonnementApercu> abonnements,
) =>
    offre.disponible &&
    espace.statut == 'ACTIF' &&
    !abonnementPersonnelExistant(abonnements, offre.id);

// Les deux dates sont incluses : un accès d’un jour se termine le jour où il commence.
DateTime dateFinAbonnement(DateTime debut, int duree) =>
    debut.add(Duration(days: duree - 1));

// Ce calcul sert à l’aperçu. En production, le serveur crée le montant et les dates.
AbonnementApercu creerAbonnementDemonstration(OffreApercu offre, int id) {
  final debut = jourLocal();
  return AbonnementApercu(
    id: id,
    offre: offre.id,
    athlete: 'Votre compte',
    estPersonnel: true,
    debut: debut,
    fin: dateFinAbonnement(debut, offre.duree),
    millimes: offre.millimes,
  );
}
