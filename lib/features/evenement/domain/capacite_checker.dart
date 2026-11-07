import '../data/models/evenement.dart';
import '../data/models/inscription.dart';
import 'eligibilite_checker.dart';

// ================================================================
// MÉTIER 4 — GESTION DE CAPACITÉ
// Lorsque le nombre maximal de participants est atteint,
// l'événement est considéré COMPLET.
// (Le comptage réutilise compterPlacesPrises des Métiers 1-2 :
// les inscriptions ANNULEE et REFUSEE libèrent leur place.)
// RÔLE : Contient la règle métier pure du MÉTIER 4 (Gestion de capacité).
// ============================================================================

///  MÉTIER 4 - Règle de détection de quota plein
/// RÈGLE : Dès que le nombre d'inscriptions actives atteint ou dépasse la capacité
/// maximale fixée par l'administrateur, cette fonction renvoie TRUE.
/// Cela déclenchera la bascule automatique du statut de l'événement à COMPLET.
///
///
bool capaciteAtteinte(
    Evenement evenement,
    List<Inscription> inscriptions,
    ) {
  return compterPlacesPrises(inscriptions) >= evenement.capacite;
}