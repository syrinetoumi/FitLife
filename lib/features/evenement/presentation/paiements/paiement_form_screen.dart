import 'package:flutter/material.dart';

import '../../data/models/categorie.dart';
import '../../data/models/evenement.dart';
import '../../data/models/inscription.dart';
import '../../data/models/paiement_evenement.dart';
import '../../data/repositories/categorie_repository.dart';
import '../../data/repositories/evenement_repository.dart';
import '../../data/repositories/inscription_repository.dart';
import '../../data/repositories/paiement_evenement_repository.dart';
import '../../data/services/paiement_api_service.dart';
import '../../../../core/utils/outils.dart';
import 'confirmation_paiement_screen.dart'; // <-- IMPORTANT IMPORT

class PaiementFormScreen extends StatefulWidget {
  final PaiementEvenement? paiement;
  final Inscription? inscriptionChoisie;

  const PaiementFormScreen({
    super.key,
    this.paiement,
    this.inscriptionChoisie,
  });

  @override
  State<PaiementFormScreen> createState() => _PaiementFormScreenState();
}

class _PaiementFormScreenState extends State<PaiementFormScreen> {
  final GlobalKey<FormState> _formPaiementKey = GlobalKey<FormState>();

  final PaiementEvenementRepository paiementRepository = PaiementEvenementRepository();
  final InscriptionRepository inscriptionRepository = InscriptionRepository();
  final EvenementRepository evenementRepository = EvenementRepository();
  final CategorieRepository categorieRepository = CategorieRepository();

  final PaiementApiService paiementApiService = PaiementApiService();

  List<Inscription> inscriptions = [];
  List<Evenement> evenements = [];
  List<Categorie> categories = [];

  String idInscription = '';
  double montant = 0;
  MethodePaiement methode = MethodePaiement.carte;

  final TextEditingController numeroCarteController = TextEditingController();
  final TextEditingController expirationController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();
  final TextEditingController titulaireController = TextEditingController();

  bool traitementEnCours = false;

  @override
  void initState() {
    super.initState();

    if (widget.paiement != null) {
      idInscription = widget.paiement!.idInscription;
      montant = widget.paiement!.montant;
      methode = widget.paiement!.methode;
    }

    if (widget.inscriptionChoisie != null) {
      idInscription = widget.inscriptionChoisie!.idInscription;
    }

    chargerDonnees();
  }

  @override
  void dispose() {
    numeroCarteController.dispose();
    expirationController.dispose();
    cvvController.dispose();
    titulaireController.dispose();
    super.dispose();
  }

  Future<void> chargerDonnees() async {
    try {
      List<Inscription> resultatInscriptions = await inscriptionRepository.getInscriptions();
      List<Evenement> resultatEvenements = await evenementRepository.getEvenements();
      List<Categorie> resultatCategories = await categorieRepository.getCategories();

      if (!mounted) return;

      double nouveauMontant = montant;
      if (widget.inscriptionChoisie != null) {
        for (Evenement e in resultatEvenements) {
          if (e.idEvenement == widget.inscriptionChoisie!.idEvenement) {
            nouveauMontant = e.prix;
          }
        }
      }

      setState(() {
        inscriptions = resultatInscriptions;
        evenements = resultatEvenements;
        categories = resultatCategories;
        montant = nouveauMontant;
      });
    } catch (erreur) {
      if (mounted) afficherMessage(context, 'Erreur de chargement : $erreur');
    }
  }

  String nomEvenement(String idEvenement) {
    for (Evenement e in evenements) {
      if (e.idEvenement == idEvenement) return e.nom;
    }
    return 'Événement Sportif';
  }

  String nomCategorie(String idCategorie) {
    for (Categorie c in categories) {
      if (c.idCategorie == idCategorie) return c.nom;
    }
    return 'Catégorie';
  }

  String genererReference() {
    return 'PAY-${DateTime.now().millisecondsSinceEpoch}';
  }

  String? validerTitulaire(String? value) {
    if (value == null || value.trim().isEmpty) return 'Veuillez renseigner votre nom complet';
    if (value.trim().length < 3) return 'Nom trop court (minimum 3 lettres)';
    return null;
  }

  String? validerNumeroCarte(String? value) {
    if (value == null || value.trim().isEmpty) return 'Numéro de carte obligatoire';
    String nettoye = value.replaceAll(RegExp(r'\s+'), '');
    if (nettoye.length != 16 || int.tryParse(nettoye) == null) {
      return 'Veuillez saisir les 16 chiffres de votre carte';
    }
    return null;
  }

  String? validerExpiration(String? value) {
    if (value == null || value.trim().isEmpty) return 'Date requise (MM/AA)';
    final regex = RegExp(r'^(0[1-9]|1[0-2])\/([0-9]{2})$');
    if (!regex.hasMatch(value.trim())) return 'Format invalide : MM/AA (ex: 12/28)';
    return null;
  }

  String? validerCvv(String? value) {
    if (value == null || value.trim().isEmpty) return 'Code CVV obligatoire';
    String nettoye = value.trim();
    if (nettoye.length != 3 || int.tryParse(nettoye) == null) {
      return '3 chiffres requis (au dos de la carte)';
    }
    return null;
  }

  Future<void> lancerPaiement() async {
    print("🔵 STEP 1: Starting payment process...");

    if (!_formPaiementKey.currentState!.validate()) {
      print("🔴 STEP 1 FAILED: Form validation failed.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Veuillez renseigner vos coordonnées bancaires avant de valider !',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    if (idInscription.isEmpty) {
      print("🔴 STEP 1 FAILED: idInscription is empty.");
      afficherMessage(context, 'Veuillez sélectionner une inscription.');
      return;
    }

    String idAthlete = widget.inscriptionChoisie?.idAthlete ?? titulaireController.text.trim();

    setState(() {
      traitementEnCours = true;
    });

    try {
      print("🔵 STEP 2: Generating reference and calling API...");
      String referencePaiement = genererReference();

      // Appel réseau HTTP POST
      final reponseApi = await paiementApiService.traiterPaiementCarte(
        reference: referencePaiement,
        montant: montant,
        idAthlete: idAthlete,
        idInscription: idInscription,
        numeroCarte: numeroCarteController.text,
        expiration: expirationController.text,
        cvv: cvvController.text,
      );

      print("🔵 STEP 3: API Response received: ${reponseApi.transactionId}");
      referencePaiement = reponseApi.transactionId;

      print("🔵 STEP 4: Creating payment object and saving to repository...");
      PaiementEvenement nouveauPaiement = PaiementEvenement(
        idPaiement: '', // Will be generated by repo or DB
        idInscription: idInscription,
        montant: montant,
        datePaiement: DateTime.now(),
        methode: MethodePaiement.carte,
        statut: StatutPaiement.paye,
        reference: referencePaiement,
      );

      await paiementRepository.ajouter(nouveauPaiement);
      print("🔵 STEP 5: Payment saved to repository successfully.");

      if (widget.inscriptionChoisie != null) {
        print("🔵 STEP 6: Updating inscription status to 'confirmee'...");
        Inscription maj = Inscription(
          idInscription: widget.inscriptionChoisie!.idInscription,
          idEvenement: widget.inscriptionChoisie!.idEvenement,
          idAthlete: widget.inscriptionChoisie!.idAthlete,
          idCategorie: widget.inscriptionChoisie!.idCategorie,
          ageAthlete: widget.inscriptionChoisie!.ageAthlete,
          niveauAthlete: widget.inscriptionChoisie!.niveauAthlete,
          dateInscription: widget.inscriptionChoisie!.dateInscription,
          statut: StatutInscription.confirmee,
        );
        await inscriptionRepository.modifier(maj);
      }

      if (!mounted) return;

      print("🟢 STEP 8: Navigating to ConfirmationPaiementScreen...");

      // USE PUSH HERE, NOT REPLACEMENT
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConfirmationPaiementScreen(
            paiement: nouveauPaiement,
            nomEvenement: nomEvenement(widget.inscriptionChoisie?.idEvenement ?? ''),
            nomCategorie: nomCategorie(widget.inscriptionChoisie?.idCategorie ?? ''),
            idAthlete: idAthlete,
          ),
        ),
      );

      print("🟢 STEP 9: Navigation complete.");

    } catch (erreur, stackTrace) {
      print("🔴 CRITICAL ERROR CAUGHT: $erreur");
      print("🔴 STACK TRACE: $stackTrace");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Échec de transaction : $erreur'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => traitementEnCours = false);
      }
    }
  }

  Widget logoMastercard({double taille = 22}) {
    return SizedBox(
      width: taille * 1.5,
      height: taille,
      child: Stack(
        children: [
          Container(
            width: taille,
            height: taille,
            decoration: const BoxDecoration(color: Color(0xFFEB001B), shape: BoxShape.circle),
          ),
          Positioned(
            left: taille * 0.5,
            child: Container(
              width: taille,
              height: taille,
              decoration: BoxDecoration(color: const Color(0xFFF79E1B).withOpacity(0.92), shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }

  Widget logoVisa({double taille = 18}) {
    return Text(
      'VISA',
      style: TextStyle(
        fontFamily: 'sans-serif',
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        fontSize: taille,
        color: const Color(0xFF1A1F71),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget boitePaiementMultiSafe() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formPaiementKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(color: Color(0xFF0072CE), shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                const Text('Credit card', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const Spacer(),
                logoMastercard(),
                const SizedBox(width: 8),
                logoVisa(),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Renseignez vos coordonnées de paiement', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const Text('Tous les champs sont obligatoires pour valider la transaction', style: TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 18),
            TextFormField(
              controller: titulaireController,
              validator: validerTitulaire,
              decoration: InputDecoration(
                labelText: 'Nom du titulaire *',
                hintText: 'Ex: Amine Ben Ali',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: numeroCarteController,
              validator: validerNumeroCarte,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Numéro de carte *',
                hintText: '4111 2222 3333 1234',
                prefixIcon: const Icon(Icons.credit_card),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: expirationController,
                    validator: validerExpiration,
                    keyboardType: TextInputType.datetime,
                    decoration: InputDecoration(
                      labelText: 'Expiration *',
                      hintText: 'MM/AA',
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: cvvController,
                    validator: validerCvv,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'CVV / CVC *',
                      hintText: '123',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0072CE),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 1,
                ),
                onPressed: traitementEnCours ? null : lancerPaiement,
                child: traitementEnCours
                    ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text('Vérification en cours...'),
                  ],
                )
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock, size: 18),
                    SizedBox(width: 8),
                    Text('Payer maintenant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget recapitulatifCommande() {
    String nom = 'Événement sportif';
    String athlete = 'Athlète';
    String categorie = 'Standard';

    if (widget.inscriptionChoisie != null) {
      nom = nomEvenement(widget.inscriptionChoisie!.idEvenement);
      athlete = widget.inscriptionChoisie!.idAthlete;
      categorie = nomCategorie(widget.inscriptionChoisie!.idCategorie);
    }

    return Card(
      elevation: 0,
      color: Colors.blue.shade50.withOpacity(0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nom.toUpperCase(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.indigo)),
                const SizedBox(height: 2),
                Text('Catégorie : $categorie · Athlète : $athlete', style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
            Text(
              '${montant.toStringAsFixed(2)} DT',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0072CE)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        title: const Text('Paiement Sécurisé'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Icon(Icons.lock, size: 16, color: Colors.green),
                SizedBox(width: 4),
                Text('SSL 256-bit', style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          recapitulatifCommande(),
          boitePaiementMultiSafe(),
          const SizedBox(height: 8),
          const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user, size: 14, color: Colors.black45),
                SizedBox(width: 6),
                Text('Paiement sécurisé et certifié', style: TextStyle(fontSize: 11, color: Colors.black45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}