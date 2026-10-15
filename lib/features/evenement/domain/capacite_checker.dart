import '../data/models/evenement.dart';
import '../data/models/inscription.dart';
import 'eligibilite_checker.dart';

// ================================================================
// MÉTIER 4 — GESTION DE CAPACITÉ
// Lorsque le nombre maximal de participants est atteint,
// l'événement est considéré COMPLET.
// (Le comptage réutilise compterPlacesPrises des Métiers 1-2 :
// les inscriptions ANNULEE et REFUSEE libèrent leur place.)
// ================================================================
bool capaciteAtteinte(
    Evenement evenement,
    List<Inscription> inscriptions,
    ) {
  return compterPlacesPrises(inscriptions) >= evenement.capacite;
}