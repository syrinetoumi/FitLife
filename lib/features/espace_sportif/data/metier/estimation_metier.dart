import '../services/localisation_service.dart';
import '../services/position_appareil_service.dart';

// Ce métier relie la lecture du GPS au calcul de trajet sans demander de coordonnées à l’utilisateur.
class EstimationMetier {
  EstimationMetier(this.localisation, this.position);
  final LocalisationService localisation;
  final PositionAppareilService position;

  // Le départ provient du téléphone ; le serveur vérifie l’accès à la destination.
  Future<Map<String, dynamic>> estimer(int espace, String profil) async {
    final depart = await position.obtenir();
    return localisation.itineraire(
      espace,
      depart.latitude,
      depart.longitude,
      profil,
    );
  }
}
