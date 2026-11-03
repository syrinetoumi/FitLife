import 'package:flutter/material.dart';

import 'package:coach_app/core/utils/alertes.dart';
import 'package:coach_app/core/utils/outils.dart';
import 'package:coach_app/features/evenement/data/models/evenement.dart';
import 'package:coach_app/features/evenement/data/models/inscription.dart';
import 'package:coach_app/features/evenement/data/models/paiement_evenement.dart';
import 'package:coach_app/features/evenement/data/repositories/evenement_repository.dart';
import 'package:coach_app/features/evenement/data/repositories/inscription_repository.dart';
import 'package:coach_app/features/evenement/data/repositories/paiement_evenement_repository.dart';
import 'package:coach_app/features/evenement/presentation/widgets/apparence_evenement.dart';
import 'package:coach_app/features/evenement/presentation/paiements/paiement_form_screen.dart';

// Écran Panier & Transactions pour l'Athlète
// Affiche la liste des événements choisis, leur statut
// (en attente ou payé) et permet de finaliser le règlement ou d'annuler.
class PanierScreen extends StatefulWidget {
  final bool integre;

  const PanierScreen({
    super.key,
    this.integre = false,
  });

  @override
  State<PanierScreen> createState() => _PanierScreenState();
}

class _PanierScreenState extends State<PanierScreen> {
  InscriptionRepository inscriptionRepository = InscriptionRepository();
  EvenementRepository evenementRepository = EvenementRepository();
  PaiementEvenementRepository paiementRepository =
  PaiementEvenementRepository();

  List<Inscription> inscriptions = [];
  Map<String, Evenement> mapEvenements = {};
  Map<String, PaiementEvenement> mapPaiements = {};
  bool chargement = true;

  @override
  void initState() {
    super.initState();
    chargerPanier();
  }

  Future<void> chargerPanier() async {
    try {
      // 1. Récupérer toutes les données fraîches depuis Supabase
      List<Inscription> toutesInscriptions =
      await inscriptionRepository.getInscriptions();
      List<Evenement> tousEvenements =
      await evenementRepository.getEvenements();
      List<PaiementEvenement> tousPaiements =
      await paiementRepository.getPaiements();

      // 2. Indexer les événements par id
      Map<String, Evenement> indexEvt = {};
      for (Evenement evt in tousEvenements) {
        indexEvt[evt.idEvenement] = evt;
      }

      // 3. Indexer les paiements par id_inscription
      Map<String, PaiementEvenement> indexPay = {};
      for (PaiementEvenement p in tousPaiements) {
        indexPay[p.idInscription] = p;
      }

      if (!mounted) return;

      setState(() {
        // Affiche toutes les inscriptions récentes créées (pas de filtrage rigide)
        inscriptions = toutesInscriptions;
        mapEvenements = indexEvt;
        mapPaiements = indexPay;
        chargement = false;
      });
    } catch (erreur) {
      if (mounted) {
        setState(() {
          chargement = false;
        });
        afficherMessage(context, 'Erreur de chargement du panier : $erreur');
      }
    }
  }

  // Ouvre le formulaire de paiement pour une inscription en attente
  Future<void> payer(Inscription inscription, Evenement? evenement) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaiementFormScreen(
          inscriptionChoisie: inscription,
        ),
      ),
    );

    // Rechargement immédiat des paiements et inscriptions dès le retour
    await chargerPanier();
  }

  // Annule l'inscription sélectionnée dans le panier
  Future<void> annuler(Inscription inscription) async {
    bool confirme = await confirmerAction(
      context,
      titre: 'Annuler l\'inscription',
      message: 'Voulez-vous vraiment annuler votre inscription à cet événement ?',
      libelleBouton: 'Oui, annuler',
      libelleRefus: 'Retour',
    );

    if (!confirme) return;

    try {
      Inscription maj = Inscription(
        idInscription: inscription.idInscription,
        idAthlete: inscription.idAthlete,
        idEvenement: inscription.idEvenement,
        idCategorie: inscription.idCategorie,
        dateInscription: inscription.dateInscription,
        ageAthlete: inscription.ageAthlete,
        niveauAthlete: inscription.niveauAthlete,
        statut: StatutInscription.annulee,
      );

      await inscriptionRepository.modifier(maj);

      if (mounted) {
        afficherMessage(context, 'Inscription annulée.');
      }

      chargerPanier();
    } catch (erreur) {
      if (mounted) {
        afficherMessage(context, 'Erreur lors de l\'annulation : $erreur');
      }
    }
  }

  Widget carteArticlePanier(Inscription inscription) {
    Evenement? evenement = mapEvenements[inscription.idEvenement];
    PaiementEvenement? paiement = mapPaiements[inscription.idInscription];

    String nomEvt = evenement?.nom ?? 'Événement ${inscription.idEvenement}';
    double prix = evenement?.prix ?? 0.0;

    // Détermination précise de l'état
    bool paye = inscription.statut == StatutInscription.confirmee ||
        paiement != null;
    bool estAnnule = inscription.statut == StatutInscription.annulee;
    bool enAttente = !paye && !estAnnule;

    Color couleurFond = enAttente
        ? Colors.amber.shade50
        : (paye
        ? Colors.green.shade50
        : (estAnnule ? Colors.red.shade50 : Colors.grey.shade100));

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: enAttente
              ? Colors.orange.shade300
              : (paye
              ? Colors.green.shade300
              : (estAnnule ? Colors.red.shade300 : Colors.grey.shade300)),
          width: 1,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        color: couleurFond,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    nomEvt.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                pastilleStatut(
                  paye
                      ? 'PAYÉ'
                      : (enAttente ? 'EN ATTENTE' : (estAnnule ? 'ANNULÉ' : 'REFUSÉ')),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '👤 Athlète : ${inscription.idAthlete}',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (evenement != null) ...[
              Text(
                '📍 Lieu : ${evenement.lieu}',
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
              Text(
                '📅 Date : ${afficherDate(evenement.dateDebut)}',
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],
            Text(
              '🗓️ Inscrit le : ${afficherDate(inscription.dateInscription)}',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Prix : ${prix.toStringAsFixed(2)} DT',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),

                // 2 BOUTONS SI EN ATTENTE : ANNULER & PAYER
                if (enAttente)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Bouton Annuler
                      OutlinedButton.icon(
                        icon: const Icon(Icons.close, size: 16, color: Colors.red),
                        label: const Text('Annuler', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => annuler(inscription),
                      ),
                      const SizedBox(width: 8),
                      // Bouton Payer
                      ElevatedButton.icon(
                        icon: const Icon(Icons.payment, size: 16),
                        label: const Text('Payer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => payer(inscription, evenement),
                      ),
                    ],
                  )
                else if (estAnnule)
                  const Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Inscription annulée',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                else
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Règlement validé',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget construireContenu() {
    if (chargement) {
      return const Center(child: CircularProgressIndicator());
    }

    if (inscriptions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 80,
                color: Colors.deepPurple.shade200,
              ),
              const SizedBox(height: 16),
              const Text(
                'Votre panier est vide',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Consultez l\'onglet "Événements" pour découvrir les compétitions et vous inscrire !',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Actualiser'),
                onPressed: chargerPanier,
              ),
            ],
          ),
        ),
      );
    }

    // Calcul du total en attente
    double totalEnAttente = 0.0;
    int nombreEnAttente = 0;

    for (Inscription ins in inscriptions) {
      bool paye = ins.statut == StatutInscription.confirmee ||
          mapPaiements.containsKey(ins.idInscription);
      bool estAnnule = ins.statut == StatutInscription.annulee;

      if (!paye && !estAnnule) {
        Evenement? evt = mapEvenements[ins.idEvenement];
        totalEnAttente += evt?.prix ?? 0.0;
        nombreEnAttente++;
      }
    }

    return RefreshIndicator(
      onRefresh: chargerPanier,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Carte résumé en haut
          Card(
            color: Colors.deepPurple,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOTAL EN ATTENTE',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${totalEnAttente.toStringAsFixed(2)} DT',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$nombreEnAttente à régler',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Bouton d'actualisation rapide
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        tooltip: 'Actualiser le panier',
                        onPressed: chargerPanier,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...inscriptions.map(carteArticlePanier),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.integre) {
      return construireContenu();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Panier & Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: chargerPanier,
          ),
        ],
      ),
      drawer: construireDrawer(context),
      body: construireContenu(),
    );
  }
}
