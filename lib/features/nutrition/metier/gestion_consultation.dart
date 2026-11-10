import '../data/models/consultation.dart';
import '../data/models/enums_nutrition.dart';

/// Service Métier 1 : Logique métier et règles de gestion des consultations diététiques.
class GestionConsultation {
  /// Valide si le créneau proposé est valide (non passé, heure cohérente)
  static String? validerDateEtHeure(DateTime date, String heure) {
    final maintenant = DateTime.now();
    final dateDuJour = DateTime(maintenant.year, maintenant.month, maintenant.day);
    final dateCible = DateTime(date.year, date.month, date.day);

    if (dateCible.isBefore(dateDuJour)) {
      return 'La date de consultation ne peut pas être dans le passé.';
    }

    // Vérification basique du format HH:mm
    final parties = heure.split(':');
    if (parties.length != 2) {
      return 'Format d\'heure invalide (attendu HH:mm).';
    }

    final h = int.tryParse(parties[0]);
    final m = int.tryParse(parties[1]);
    if (h == null || m == null || h < 8 || h > 19 || m < 0 || m > 59) {
      return 'Les consultations se déroulent entre 08:00 et 20:00.';
    }

    return null;
  }

  /// Valide le motif de la demande
  static String? validerMotif(String? motif) {
    if (motif == null || motif.trim().isEmpty) {
      return 'Le motif de la consultation est obligatoire.';
    }
    if (motif.trim().length < 5) {
      return 'Veuillez préciser le motif (au moins 5 caractères).';
    }
    return null;
  }

  /// Règle métier : une consultation peut-elle être confirmée par le praticien ?
  static bool peutConfirmer(Consultation consultation) {
    return consultation.statut == StatutConsultation.DEMANDEE;
  }

  /// Règle métier : une consultation peut-elle être annulée ?
  static bool peutAnnuler(Consultation consultation) {
    return consultation.statut == StatutConsultation.DEMANDEE ||
        consultation.statut == StatutConsultation.CONFIRMEE;
  }

  /// Règle métier : une consultation peut-elle être clôturée avec compte-rendu ?
  static bool peutCloturer(Consultation consultation) {
    return consultation.statut == StatutConsultation.CONFIRMEE;
  }

  /// Détermine le libellé d'action conseillé selon le statut
  static String actionConseillee(Consultation consultation) {
    switch (consultation.statut) {
      case StatutConsultation.DEMANDEE:
        return 'En attente de confirmation par le nutritionniste';
      case StatutConsultation.CONFIRMEE:
        return 'Rendez-vous planifié. Préparez vos questions nutritionnelles.';
      case StatutConsultation.TERMINEE:
        return 'Consultation terminée. Consultez le compte-rendu.';
      case StatutConsultation.ANNULEE:
        return 'Rendez-vous annulé.';
    }
  }
}
