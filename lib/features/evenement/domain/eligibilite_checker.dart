import '../data/models/categorie.dart';
import '../data/models/evenement.dart';
import '../data/models/inscription.dart';

// ============================================================================
//  L'IMPLÉMENTATION DES FONCTIONNALITÉS MÉTIER
// FICHIER : lib/features/evenement/domain/eligibilite_checker.dart
// RÔLE : Contient la logique métier pure des MÉTIER 1 et MÉTIER 2.
// ARCHITECTURE : Aucun import Flutter / UI ici. Ce code est 100% testable
// unitairement et indépendant de la base de données.
// ============================================================================

// ============================================================================
//  MÉTIER 1 : INSCRIPTION INTELLIGENTE (Contrôle multi-critères avant CRUD)
// ============================================================================

///  MÉTIER 1 - Vérification 1
/// RÈGLE : Un athlète ne peut s'inscrire que si l'événement a le statut "OUVERT".
/// Si l'événement est BROUILLON, FERME ou TERMINE, l'inscription est refusée.
bool evenementOuvert(Evenement evenement) {
  return evenement.statut == StatutEvenement.ouvert;
}

///  MÉTIER 1 - Vérification 2 (a)
/// RÈGLE : Calculer le nombre réel de places occupées.
/// Une inscription n'occupe une place QUE si elle n'est ni ANNULEE ni REFUSEE.
int compterPlacesPrises(List<Inscription> inscriptions) {
  int prises = 0;

  for (Inscription inscription in inscriptions) {
    if (inscription.statut != StatutInscription.annulee &&
        inscription.statut != StatutInscription.refusee) {
      prises++;
    }
  }

  return prises;
}

///  MÉTIER 1 - Vérification 2 (b)
/// RÈGLE : Vérifier s'il reste au moins une place disponible avant d'inscrire.
bool placeDisponible(Evenement evenement, List<Inscription> inscriptions) {
  return compterPlacesPrises(inscriptions) < evenement.capacite;
}

///  MÉTIER 1 & 2 - Vérification 3
/// RÈGLE : L'âge de l'athlète doit être strictement compris entre ageMin et ageMax.
/// Exemple : Si la catégorie "Adultes" est 18-25 ans, un athlète de 30 ans est refusé.
bool ageEligible(Categorie categorie, int age) {
  return age >= categorie.ageMin && age <= categorie.ageMax;
}

///  MÉTIER 1 & 2 - Vérification 4
/// RÈGLE : Le niveau sportif de l'athlète doit correspondre au niveau de la catégorie.
/// Exemple : Si la catégorie exige INTERMEDIAIRE, un DEBUTANT est refusé.
bool niveauEligible(Categorie categorie, NiveauCategorie niveau) {
  return niveau == categorie.niveau;
}

// ============================================================================
//  MÉTIER 2 : VÉRIFICATION AUTOMATIQUE DE L'ÉLIGIBILITÉ EN TEMPS RÉEL
// ============================================================================

/// MÉTIER 2 - Test global d'éligibilité
/// RÈGLE : L'athlète est éligible SI ET SEULEMENT SI son âge ET son niveau sont valides.
bool categorieEligible(
    Categorie categorie,
    int age,
    NiveauCategorie niveau,
    ) {
  return ageEligible(categorie, age) && niveauEligible(categorie, niveau);
}

///  MÉTIER 2 - Message affiché en direct à la saisie
/// RÈGLE : Pendant que l'utilisateur tape son âge ou choisit son niveau (onChanged),
/// ce message s'actualise EN DIRECT sans qu'il ait besoin d'appuyer sur un bouton.
/// S'il est éligible ➔ "Éligible" (affiché en vert).
/// S'il n'est pas éligible ➔ la raison précise du refus (affichée en rouge).
String messageEligibilite(
    Categorie categorie,
    int age,
    NiveauCategorie niveau,
    ) {
  if (!ageEligible(categorie, age)) {
    return "Non éligible : l'âge doit être entre "
        "${categorie.ageMin} et ${categorie.ageMax} ans";
  }

  if (!niveauEligible(categorie, niveau)) {
    return 'Non éligible : niveau '
        '${categorie.niveau.name.toUpperCase()} requis';
  }

  return 'Éligible';
}
