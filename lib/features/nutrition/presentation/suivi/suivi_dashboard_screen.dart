import 'package:flutter/material.dart';
import '../../data/models/dossier_nutritionnel.dart';
import '../../data/models/enums_nutrition.dart';
import '../../data/models/programme_nutritionnel.dart';
import '../../data/repositories/dossier_repository.dart';
import '../../data/repositories/programme_nutri_repository.dart';
import '../../data/services/frankfurter_service.dart';
import '../../domain/suivi_progression_service.dart';

class SuiviDashboardScreen extends StatefulWidget {
  final bool integre;
  final String idAthlete;

  const SuiviDashboardScreen({
    super.key,
    this.integre = false,
    this.idAthlete = 'demo-athlete-id',
  });

  @override
  State<SuiviDashboardScreen> createState() => _SuiviDashboardScreenState();
}

class _SuiviDashboardScreenState extends State<SuiviDashboardScreen> {
  static const Color primaryBlue = Color(0xFF3843B8);

  final DossierRepository _dossierRepository = DossierRepository();
  final ProgrammeNutriRepository _programmeRepository = ProgrammeNutriRepository();
  final FrankfurterService _frankfurter = FrankfurterService();

  DossierNutritionnel? _dossier;
  ProgrammeNutritionnel? _programmeActif;
  bool _chargement = true;

  // Simulateur de conversion de devises
  final TextEditingController _budgetEurController = TextEditingController(text: '50');
  double _budgetConvertiTnd = 169.0;
  bool _enConversion = false;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
    _convertirBudget();
  }

  @override
  void dispose() {
    _budgetEurController.dispose();
    super.dispose();
  }

  Future<void> _chargerDonnees() async {
    setState(() => _chargement = true);
    final d = await _dossierRepository.getDossier(widget.idAthlete);
    final progs = await _programmeRepository.getProgrammesDuDossier(d.idDossier);
    final actif = progs.isNotEmpty ? progs.firstWhere((p) => p.estActif, orElse: () => progs.first) : null;

    if (mounted) {
      setState(() {
        _dossier = d;
        _programmeActif = actif;
        _chargement = false;
      });
    }
  }

  Future<void> _convertirBudget() async {
    final montant = double.tryParse(_budgetEurController.text) ?? 50.0;
    setState(() => _enConversion = true);
    final resultat = await _frankfurter.convertir(montant, de: 'EUR', vers: 'TND');
    if (mounted) {
      setState(() {
        _budgetConvertiTnd = resultat;
        _enConversion = false;
      });
    }
  }

  /// Dialogue permettant de modifier à la fois le poids initial, le poids actuel et l'objectif cible
  Future<void> _ouvrirDialogueModificationPoids() async {
    if (_dossier == null) return;

    final initialCtrl = TextEditingController(text: _dossier!.poidsInitial.toString());
    final actuelCtrl = TextEditingController(text: _dossier!.poidsActuel.toString());
    final cibleCtrl = TextEditingController(text: _dossier!.poidsCible.toString());
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.monitor_weight_outlined, color: primaryBlue),
            SizedBox(width: 8),
            Text(
              'Modifier le suivi du poids',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ajustez vos métriques de départ, de pesée actuelle et votre objectif cible.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: initialCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Poids initial (kg)',
                    prefixIcon: Icon(Icons.history, color: primaryBlue),
                    suffixText: 'kg',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => double.tryParse(v ?? '') == null ? 'Valeur invalide' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: actuelCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Poids actuel (kg)',
                    prefixIcon: Icon(Icons.scale, color: primaryBlue),
                    suffixText: 'kg',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => double.tryParse(v ?? '') == null ? 'Valeur invalide' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: cibleCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Objectif cible (kg)',
                    prefixIcon: Icon(Icons.flag_outlined, color: primaryBlue),
                    suffixText: 'kg',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => double.tryParse(v ?? '') == null ? 'Valeur invalide' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final pInit = double.tryParse(initialCtrl.text) ?? _dossier!.poidsInitial;
      final pActuel = double.tryParse(actuelCtrl.text) ?? _dossier!.poidsActuel;
      final pCible = double.tryParse(cibleCtrl.text) ?? _dossier!.poidsCible;

      final maj = await _dossierRepository.mettreAJourObjectifsPoids(
        widget.idAthlete,
        poidsInitial: pInit,
        poidsActuel: pActuel,
        poidsCible: pCible,
      );

      setState(() => _dossier = maj);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Objectifs et pesée mis à jour avec succès !')),
        );
      }
    }
  }

  Widget _construireCorps() {
    if (_chargement) {
      return const Center(child: CircularProgressIndicator(color: primaryBlue));
    }

    if (_dossier == null) {
      return const Center(child: Text('Aucun dossier trouvé.'));
    }

    final dossier = _dossier!;
    final bilan = SuiviProgressionService.calculerBilanCombine(
      dossier: dossier,
      programmeActif: _programmeActif,
    );
    final analyse = SuiviProgressionService.analyserEvolutionPoids(dossier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ==========================================
        // 1. CARTE SUIVI DU POIDS & PROGRESSION
        // ==========================================
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: primaryBlue,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Suivi du poids',
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    InkWell(
                      onTap: _ouvrirDialogueModificationPoids,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(45),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Modifier',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Objectif : ${formatEnumNutrition(dossier.objectif)}',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Évolution : Poids Initial -> Poids Actuel -> Objectif
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _blocPoids('Poids Initial', '${dossier.poidsInitial} kg', Icons.history),
                    const Icon(Icons.arrow_forward, color: Colors.white70, size: 20),
                    _blocPoids('Poids Actuel', '${dossier.poidsActuel} kg', Icons.scale, estActuel: true),
                    const Icon(Icons.arrow_forward, color: Colors.white70, size: 20),
                    _blocPoids('Objectif Cible', '${dossier.poidsCible} kg', Icons.flag_outlined),
                  ],
                ),
                const SizedBox(height: 20),

                // Barre de progression
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Progression globale', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Text(
                      '${dossier.progressionPourcentage.toStringAsFixed(1)} %',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (dossier.progressionPourcentage / 100.0).clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                  ),
                ),
                const SizedBox(height: 12),

                // Indicateurs restants
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reste : ${dossier.poidsRestantKg.toStringAsFixed(1)} kg',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    Text(
                      '~ ${analyse['semainesEstimees']} semaines estimées',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
                if (dossier.imc != null) ...[
                  const Divider(color: Colors.white24, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Taille : ${dossier.tailleCm?.round()} cm', style: const TextStyle(color: Colors.white70)),
                      Text('IMC : ${dossier.imc!.toStringAsFixed(1)} kg/m²',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ==========================================
        // 2. COORDINATION ENTRAÎNEMENT & NUTRITION
        // ==========================================
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryBlue.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.sync_alt, color: primaryBlue),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Coordination Entraînement & Nutrition',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Synergie : Athlète ↔ Coach ↔ Nutritionniste',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                _ligneCoordination(
                  'Coach (Entraînement)',
                  bilan.roleCoachApport,
                  Icons.fitness_center,
                  primaryBlue,
                ),
                const SizedBox(height: 10),
                _ligneCoordination(
                  'Nutritionniste (Alimentation)',
                  bilan.roleNutritionnisteApport,
                  Icons.restaurant,
                  Colors.teal,
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryBlue.withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, color: primaryBlue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${bilan.statutCoordination} : ${bilan.conseilSynthese}',
                          style: const TextStyle(fontSize: 13, color: primaryBlue, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ==========================================
        // 3. CONVERSION DE DEVISES
        // ==========================================
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.currency_exchange, color: Colors.teal),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Conversion de devises', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          Text('Gestion du budget alimentaire (EUR ↔ TND)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: _budgetEurController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Budget (EUR)',
                          suffixText: 'EUR',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _convertirBudget,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _enConversion
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Convertir'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: primaryBlue.withAlpha(12), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Équivalent estimé en TND :', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      Text(
                        '${_budgetConvertiTnd.toStringAsFixed(2)} DT',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryBlue),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _blocPoids(String titre, String valeur, IconData icone, {bool estActuel = false}) {
    return Column(
      children: [
        Icon(icone, color: estActuel ? Colors.greenAccent : Colors.white70, size: 24),
        const SizedBox(height: 4),
        Text(
          valeur,
          style: TextStyle(
            color: estActuel ? Colors.greenAccent : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: estActuel ? 18 : 15,
          ),
        ),
        Text(titre, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _ligneCoordination(String titre, String desc, IconData icone, Color couleur) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, color: couleur, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titre, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: couleur)),
              Text(desc, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.integre) return _construireCorps();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text(
          'Suivi Nutritionnel',
          style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _construireCorps(),
    );
  }
}
