import 'package:flutter/material.dart';
import '../../data/models/consultation.dart';
import '../../data/models/enums_nutrition.dart';
import '../../data/repositories/consultation_repository.dart';
import 'consultation_form_screen.dart';

class ConsultationListScreen extends StatefulWidget {
  final bool integre;
  final String idAthlete;

  const ConsultationListScreen({
    super.key,
    this.integre = false,
    this.idAthlete = 'demo-athlete-id',
  });

  @override
  State<ConsultationListScreen> createState() => _ConsultationListScreenState();
}

class _ConsultationListScreenState extends State<ConsultationListScreen> {
  static const Color primaryBlue = Color(0xFF3843B8);
  static const Color dangerRed = Color(0xFFD32F2F);
  static const Color backgroundLight = Color(0xFFF7F8FC);

  final ConsultationRepository _repository = ConsultationRepository();
  List<Consultation> _consultations = [];
  bool _chargement = true;
  String _filtreRecherche = '';

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    final liste = await _repository.getConsultationsAthlete(widget.idAthlete);
    if (mounted) {
      setState(() {
        _consultations = liste;
        _chargement = false;
      });
    }
  }

  Color _couleurStatut(StatutConsultation statut) {
    switch (statut) {
      case StatutConsultation.DEMANDEE:
        return const Color(0xFFF57C00); // Orange
      case StatutConsultation.CONFIRMEE:
        return const Color(0xFF2E7D32); // Green
      case StatutConsultation.TERMINEE:
        return primaryBlue; // Royal Blue
      case StatutConsultation.ANNULEE:
        return dangerRed; // Red
    }
  }

  Future<void> _changerStatut(Consultation consultation, StatutConsultation nouveauStatut) async {
    String? compteRendu;

    if (nouveauStatut == StatutConsultation.TERMINEE) {
      final controller = TextEditingController(text: consultation.compteRendu ?? '');
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Compte-rendu de consultation',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Recommandations diététiques, plan nutritionnel validé...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: primaryBlue, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
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
      if (ok != true) return;
      compteRendu = controller.text.trim();
    }

    await _repository.changerStatut(
      consultation.idConsultation,
      nouveauStatut,
      compteRendu: compteRendu,
    );
    _charger();
  }

  Widget _ligneDetail({
    required IconData icon,
    required String label,
    required String valeur,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryBlue.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: primaryBlue, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      valeur,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(color: Colors.grey.shade200, height: 1),
      ],
    );
  }

  Widget _construireCorps() {
    if (_chargement) {
      return const Center(child: CircularProgressIndicator(color: primaryBlue));
    }

    final consultationsFiltrees = _consultations.where((c) {
      if (_filtreRecherche.isEmpty) return true;
      final q = _filtreRecherche.toLowerCase();
      return (c.nomNutritionniste ?? '').toLowerCase().contains(q) ||
          c.motif.toLowerCase().contains(q) ||
          c.statutTexte.toLowerCase().contains(q) ||
          c.heureConsultation.toLowerCase().contains(q);
    }).toList();

    return Container(
      color: backgroundLight,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ==========================================
          // BARRE DE RECHERCHE PILL (Style Thème FitLife)
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
                      hintText: 'Rechercher une consultation',
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
          // BOUTON PRENDRE RENDEZ-VOUS (Bannière FitLife)
          // ==========================================
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => ConsultationFormScreen(idAthlete: widget.idAthlete),
                  ),
                );
                if (res == true) _charger();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'PRENDRE RENDEZ-VOUS',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.8),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_ios, size: 14),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ==========================================
          // LISTE DES CONSULTATIONS OU EMPTY STATE
          // ==========================================
          if (consultationsFiltrees.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.event_busy, size: 56, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    _filtreRecherche.isEmpty
                        ? 'Aucune consultation enregistrée'
                        : 'Aucune consultation ne correspond à votre recherche',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Prenez rendez-vous avec votre nutritionniste pour concevoir ou ajuster votre programme.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...consultationsFiltrees.map((c) {
              final couleur = _couleurStatut(c.statut);
              final dateFormatee =
                  '${c.dateConsultation.day.toString().padLeft(2, '0')}/${c.dateConsultation.month.toString().padLeft(2, '0')}/${c.dateConsultation.year}';

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header de la carte: Praticien & Statut Pill
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: primaryBlue.withAlpha(25),
                                child: const Icon(Icons.person, color: primaryBlue, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.nomNutritionniste ?? 'Nutritionniste',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'Spécialiste nutrition',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: couleur.withAlpha(30),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: couleur, width: 1.2),
                            ),
                            child: Text(
                              c.statutTexte,
                              style: TextStyle(
                                color: couleur,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(color: Colors.grey.shade200, height: 1),

                      // Lignes de détails au style FitLife
                      _ligneDetail(
                        icon: Icons.calendar_today,
                        label: 'Date & Heure',
                        valeur: '$dateFormatee à ${c.heureConsultation}',
                      ),
                      _ligneDetail(
                        icon: Icons.chat_bubble_outline,
                        label: 'Motif',
                        valeur: c.motif,
                        isLast: c.compteRendu == null || c.compteRendu!.isEmpty,
                      ),
                      if (c.compteRendu != null && c.compteRendu!.isNotEmpty)
                        _ligneDetail(
                          icon: Icons.assignment_outlined,
                          label: 'Compte-rendu du nutritionniste',
                          valeur: c.compteRendu!,
                          isLast: true,
                        ),

                      const SizedBox(height: 14),

                      // Boutons d'action
                      if (c.estEnAttente)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _changerStatut(c, StatutConsultation.CONFIRMEE),
                                icon: const Icon(Icons.check, size: 16),
                                label: const Text('Confirmer'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E7D32),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _changerStatut(c, StatutConsultation.ANNULEE),
                                icon: const Icon(Icons.close, size: 16),
                                label: const Text('Refuser'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: dangerRed,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        )
                      else if (c.estConfirmee)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _changerStatut(c, StatutConsultation.TERMINEE),
                                icon: const Icon(Icons.done_all, size: 16),
                                label: const Text('Clôturer la séance'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: () => _changerStatut(c, StatutConsultation.ANNULEE),
                              icon: const Icon(Icons.cancel, size: 16),
                              label: const Text('Annuler'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: dangerRed,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.integre) {
      return _construireCorps();
    }

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Consultations',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _construireCorps(),
    );
  }
}
