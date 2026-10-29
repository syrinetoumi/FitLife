import '../data/models/categorie.dart';
import '../data/models/evenement.dart';
import '../data/models/inscription.dart';

// ================================================================
// MÉTIER 1 + MÉTIER 2 — Règles métier pures
// Aucun import Flutter / Supabase ici : ce fichier est réutilisable
// partout (formulaire, listes...) et testable sans l'application.
// ================================================================

// ---------- MÉTIER 1 : INSCRIPTION INTELLIGENTE ----------

// Vérification 1 : l'événement doit être OUVERT.
bool evenementOuvert(Evenement evenement) {
  return evenement.statut == StatutEvenement.ouvert;
}

// Vérification 2 (a) : compter les places déjà prises.
// Une place est prise par toute inscription qui n'est
// ni ANNULEE ni REFUSEE.
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

// Vérification 2 (b) : il reste au moins une place.
bool placeDisponible(Evenement evenement, List<Inscription> inscriptions) {
  return compterPlacesPrises(inscriptions) < evenement.capacite;
}

// ---------- MÉTIERS 1 ET 2 : ÂGE ET NIVEAU ----------

// L'âge de l'athlète doit être entre ageMin et ageMax de la catégorie.
bool ageEligible(Categorie categorie, int age) {
  return age >= categorie.ageMin && age <= categorie.ageMax;
}

// Le niveau de l'athlète doit correspondre au niveau de la catégorie.
bool niveauEligible(Categorie categorie, NiveauCategorie niveau) {
  return niveau == categorie.niveau;
}

// ---------- MÉTIER 2 : VÉRIFICATION AUTOMATIQUE DE L'ÉLIGIBILITÉ ----------

// Exemple du sujet : athlète 22 ans / INTERMEDIAIRE,
// catégorie 18-25 / INTERMEDIAIRE => éligible (les deux règles).
bool categorieEligible(
    Categorie categorie,
    int age,
    NiveauCategorie niveau,
    ) {
  return ageEligible(categorie, age) && niveauEligible(categorie, niveau);
}

// Message affiché EN DIRECT sous chaque catégorie :
// soit "Éligible", soit la raison exacte du refus.
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
