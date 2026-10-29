import 'package:flutter/material.dart';
import '../../data/models/enums_nutrition.dart';
import '../../data/models/programme_nutritionnel.dart';
import '../../data/models/repas.dart';
import '../../data/repositories/programme_nutri_repository.dart';
import '../../data/services/frankfurter_service.dart';
import 'programme_nutri_form_screen.dart';

class ProgrammeNutriListScreen extends StatefulWidget {
  final bool integre;
  final String idDossier;

  const ProgrammeNutriListScreen({
    super.key,
    this.integre = false,
    this.idDossier = 'demo-dossier-001',
  });

  @override
  State<ProgrammeNutriListScreen> createState() => _ProgrammeNutriListScreenState();
}

class _ProgrammeNutriListScreenState extends State<ProgrammeNutriListScreen> {
  static const Color primaryBlue = Color(0xFF3843B8);
  static const Color dangerRed = Color(0xFFD32F2F);

  final ProgrammeNutriRepository _repository = ProgrammeNutriRepository();
  final FrankfurterService _frankfurter = FrankfurterService();

  List<ProgrammeNutritionnel> _programmes = [];
  Map<String, List<Repas>> _repasParProgramme = {};
  Map<String, double> _budgetEnTnd = {};
  bool _chargement = true;
  String _filtreRecherche = '';
  final Set<String> _programmesDeplies = {};

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    final liste = await _repository.getProgrammesDuDossier(widget.idDossier);

    Map<String, List<Repas>> mapRepas = {};
    Map<String, double> mapTnd = {};

    for (final p in liste) {
      final repas = await _repository.getRepasDuProgramme(p.idProgramme);
      mapRepas[p.idProgramme] = repas;

      if (p.budgetMontant != null && p.budgetMontant! > 0) {
        final conv = await _frankfurter.convertir(p.budgetMontant!, de: p.budgetDevise, vers: 'TND');
        mapTnd[p.idProgramme] = conv;
      }
    }

    if (mounted) {
      setState(() {
        _programmes = liste;
        _repasParProgramme = mapRepas;
        _budgetEnTnd = mapTnd;
        _chargement = false;
        if (liste.isNotEmpty && _programmesDeplies.isEmpty) {
          _programmesDeplies.add(liste.first.idProgramme);
        }
      });
    }
  }

  Future<void> _confirmerSuppression(ProgrammeNutritionnel p) async {
    final conf = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer le programme "${p.titre}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: dangerRed, foregroundColor: Colors.white),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (conf == true) {
      await _repository.supprimerProgramme(p.idProgramme);
      _charger();
    }
  }

  Widget _construireCorps() {
    if (_chargement) {
      return const Center(child: CircularProgressIndicator(color: primaryBlue));
    }

    final programmesFiltres = _programmes.where((p) {
      if (_filtreRecherche.isEmpty) return true;
      return p.titre.toLowerCase().contains(_filtreRecherche.toLowerCase()) ||
          formatEnumNutrition(p.objectif).toLowerCase().contains(_filtreRecherche.toLowerCase());
    }).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // ==========================================
        // BARRE DE RECHERCHE PILL (Style Screenshot 1 & 4)
        // ==========================================
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: primaryBlue,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.white70, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Rechercher un programme',
                    hintStyle: TextStyle(color: Colors.white70, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (val) => setState(() => _filtreRecherche = val.trim()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ==========================================
        // BOUTON CRÉER UN PROGRAMME (Style Screenshot 1 & 4)
        // ==========================================
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProgrammeNutriFormScreen(idDossier: widget.idDossier),
                ),
              );
              if (res == true) _charger();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CRÉER UN PROGRAMME',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8),
                ),
                Icon(Icons.chevron_right, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (programmesFiltres.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                _filtreRecherche.isEmpty ? 'Aucun programme disponible.' : 'Aucun programme correspondant.',
                style: const TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ),
          ),

        // ==========================================
        // LISTE DES PROGRAMMES (Style Screenshot 1, 4 & 5)
        // ==========================================
        ...programmesFiltres.map((p) {
          final estDeplie = _programmesDeplies.contains(p.idProgramme);
          final repasDuProg = _repasParProgramme[p.idProgramme] ?? [];
          final budgetTnd = _budgetEnTnd[p.idProgramme];

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Column(
              children: [
                // 1. CARTE HERO GRADIENT AVEC TITRE EN ITALIQUE ET WATERMARK
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF8D4408),
                        Color(0xFF4A1F02),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        right: 10,
                        child: Icon(
                          Icons.restaurant_menu,
                          size: 90,
                          color: Colors.white.withAlpha(20),
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            p.titre.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${formatEnumNutrition(p.objectif).toUpperCase()} · ${p.caloriesCible} kcal',
                            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () {
                              setState(() {
                                if (estDeplie) {
                                  _programmesDeplies.remove(p.idProgramme);
                                } else {
                                  _programmesDeplies.add(p.idProgramme);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    estDeplie ? 'Masquer' : 'Voir plus',
                                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    estDeplie ? Icons.keyboard_arrow_up : Icons.chevron_right,
                                    size: 16,
                                    color: Colors.black87,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 2. DÉTAIL DÉPLIÉ (Style Screenshot 2 & 5)
                if (estDeplie) ...[
                  const SizedBox(height: 12),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ligneDetail(Icons.flag_outlined, 'Objectif', formatEnumNutrition(p.objectif)),
                          const Divider(height: 20),
                          _ligneDetail(Icons.local_fire_department_outlined, 'Calories journalières', '${p.caloriesCible} kcal/j'),
                          const Divider(height: 20),
                          _ligneDetail(
                            Icons.pie_chart_outline,
                            'Macronutriments prescrits',
                            'P: ${p.proteinesCibleG}g (${p.pourcentageProteines.round()}%) · G: ${p.glucidesCibleG}g (${p.pourcentageGlucides.round()}%) · L: ${p.lipidesCibleG}g (${p.pourcentageLipides.round()}%)',
                          ),
                          const Divider(height: 20),
                          _ligneDetail(
                            Icons.calendar_today_outlined,
                            'Période',
                            'Début : ${_dateEnTexte(p.dateDebut)}${p.dateFin != null ? ' · Fin : ${_dateEnTexte(p.dateFin!)}' : ''}',
                          ),
                          if (p.budgetMontant != null && p.budgetMontant! > 0) ...[
                            const Divider(height: 20),
                            _ligneDetail(
                              Icons.payments_outlined,
                              'Budget alimentaire estimé',
                              '${p.budgetMontant} ${p.budgetDevise}${budgetTnd != null ? ' ≈ ${budgetTnd.toStringAsFixed(2)} TND' : ''}',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Description
                  if (p.description != null && p.description!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        p.description!,
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ),
                  ],

                  // Repas planifiés
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(width: 4, height: 18, color: primaryBlue),
                      const SizedBox(width: 8),
                      Text(
                        'Repas du programme (${repasDuProg.length})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (repasDuProg.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        'Les repas configurés pour ce programme s\'afficheront ici.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),

                  ...repasDuProg.map((r) {
                    return Card(
                      elevation: 0.5,
                      margin: const EdgeInsets.only(bottom: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.restaurant_menu, color: primaryBlue, size: 20),
                        title: Text(r.nom, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(
                          '${formatEnumNutrition(r.type)}${r.heureRecommandee != null ? ' (${r.heureRecommandee})' : ''} · P: ${r.proteinesG}g · G: ${r.glucidesG}g · L: ${r.lipidesG}g',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Text(
                          '${r.calories} kcal',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: primaryBlue, fontSize: 14),
                        ),
                      ),
                    );
                  }),

                  // BOUTONS D'ACTION MODIFIER / SUPPRIMER (Style Screenshot 2 & 5)
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final res = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProgrammeNutriFormScreen(
                                  idDossier: widget.idDossier,
                                  programmeExistant: p,
                                ),
                              ),
                            );
                            if (res == true) _charger();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            elevation: 0,
                          ),
                          child: const Text('Modifier', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _confirmerSuppression(p),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: dangerRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            elevation: 0,
                          ),
                          child: const Text('Supprimer', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _ligneDetail(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: primaryBlue, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }

  String _dateEnTexte(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.integre) return _construireCorps();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text(
          'Programmes',
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
