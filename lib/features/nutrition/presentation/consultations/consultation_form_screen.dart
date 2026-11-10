import 'package:flutter/material.dart';
import '../../data/models/consultation.dart';
import '../../data/models/enums_nutrition.dart';
import '../../data/repositories/consultation_repository.dart';

class ConsultationFormScreen extends StatefulWidget {
  final String idAthlete;

  const ConsultationFormScreen({
    super.key,
    this.idAthlete = 'demo-athlete-id',
  });

  @override
  State<ConsultationFormScreen> createState() => _ConsultationFormScreenState();
}

class _ConsultationFormScreenState extends State<ConsultationFormScreen> {
  static const Color primaryBlue = Color(0xFF3843B8);
  static const Color backgroundLight = Color(0xFFF7F8FC);

  final _formKey = GlobalKey<FormState>();
  final ConsultationRepository _repository = ConsultationRepository();

  List<NutritionnisteItem> _nutritionnistes = [];
  NutritionnisteItem? _nutritionnisteSelectionne;
  DateTime _dateSelectionnee = DateTime.now().add(const Duration(days: 2));
  TimeOfDay _heureSelectionnee = const TimeOfDay(hour: 14, minute: 30);
  final TextEditingController _motifController = TextEditingController();
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _chargerPraticiens();
  }

  @override
  void dispose() {
    _motifController.dispose();
    super.dispose();
  }

  Future<void> _chargerPraticiens() async {
    try {
      final liste = await _repository.getNutritionnistes();
      if (mounted) {
        setState(() {
          _nutritionnistes = liste;
          if (liste.isNotEmpty) {
            _nutritionnisteSelectionne = liste.first;
          }
          _chargement = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _choisirDate() async {
    final DateTime? choix = await showDatePicker(
      context: context,
      initialDate: _dateSelectionnee,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryBlue,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (choix != null) {
      setState(() => _dateSelectionnee = choix);
    }
  }

  Future<void> _choisirHeure() async {
    final TimeOfDay? choix = await showTimePicker(
      context: context,
      initialTime: _heureSelectionnee,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryBlue,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (choix != null) {
      setState(() => _heureSelectionnee = choix);
    }
  }

  Future<void> _soumettre() async {
    if (!_formKey.currentState!.validate() || _nutritionnisteSelectionne == null) {
      return;
    }

    final heureFormattee =
        '${_heureSelectionnee.hour.toString().padLeft(2, '0')}:${_heureSelectionnee.minute.toString().padLeft(2, '0')}';

    final nouvelleConsultation = Consultation(
      idConsultation: '',
      idAthlete: widget.idAthlete,
      idNutritionniste: _nutritionnisteSelectionne!.id,
      nomNutritionniste: _nutritionnisteSelectionne!.nom,
      dateConsultation: _dateSelectionnee,
      heureConsultation: heureFormattee,
      motif: _motifController.text.trim(),
      statut: StatutConsultation.DEMANDEE,
    );

    try {
      await _repository.demanderConsultation(nouvelleConsultation);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande de consultation enregistrée avec succès !'),
            backgroundColor: primaryBlue,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la demande : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateTexte =
        '${_dateSelectionnee.day.toString().padLeft(2, '0')}/${_dateSelectionnee.month.toString().padLeft(2, '0')}/${_dateSelectionnee.year}';
    final heureTexte =
        '${_heureSelectionnee.hour.toString().padLeft(2, '0')}:${_heureSelectionnee.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Prendre un rendez-vous',
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
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(6),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primaryBlue.withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.calendar_month, color: primaryBlue, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Consultation Diététique',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Sélectionnez votre praticien, fixez le créneau et décrivez votre objectif.',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 1. Choix du nutritionniste
                    const Text(
                      '1. NUTRITIONNISTE *',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<NutritionnisteItem>(
                      initialValue: _nutritionnisteSelectionne,
                      items: _nutritionnistes.map((n) {
                        return DropdownMenuItem(
                          value: n,
                          child: Text('${n.nom} (${n.specialite})', style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _nutritionnisteSelectionne = val),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: primaryBlue, width: 2),
                        ),
                        prefixIcon: const Icon(Icons.person, color: primaryBlue),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 2. Choix de la date et heure
                    const Text(
                      '2. DATE & HEURE *',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _choisirDate,
                            icon: const Icon(Icons.calendar_today, size: 18, color: primaryBlue),
                            label: Text(
                              dateTexte,
                              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _choisirHeure,
                            icon: const Icon(Icons.access_time, size: 18, color: primaryBlue),
                            label: Text(
                              heureTexte,
                              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // 3. Motif
                    const Text(
                      '3. MOTIF DU RENDEZ-VOUS *',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _motifController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Ex : Établir un plan pour perte de 8 kg coordonné avec mes entraînements...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: primaryBlue, width: 2),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Veuillez préciser le motif de consultation';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // Bouton d'envoi
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _soumettre,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'ENVOYER LA DEMANDE',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.8),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_ios, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
