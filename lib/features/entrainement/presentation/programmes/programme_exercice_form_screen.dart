import 'package:flutter/material.dart';

import 'package:coach_app/core/utils/alertes.dart';
import 'package:coach_app/features/entrainement/data/models/programme_exercice.dart';
import 'package:coach_app/features/entrainement/data/repositories/programme_exercice_repository.dart';

class ProgrammeExerciceFormScreen extends StatefulWidget {
  final int idProgramme;
  final String externalId;
  final String nomExercice;
  final int ordre;
  final ProgrammeExercice? existant; // non nul = modification

  const ProgrammeExerciceFormScreen({
    super.key,
    required this.idProgramme,
    required this.externalId,
    required this.nomExercice,
    required this.ordre,
    this.existant,
  });

  @override
  State<ProgrammeExerciceFormScreen> createState() =>
      _ProgrammeExerciceFormScreenState();
}

class _ProgrammeExerciceFormScreenState
    extends State<ProgrammeExerciceFormScreen> {
  final formKey = GlobalKey<FormState>();
  final ProgrammeExerciceRepository repository = ProgrammeExerciceRepository();

  late TextEditingController ordreController;
  late TextEditingController seriesController;
  late TextEditingController repetitionsController;
  late TextEditingController reposController;
  late TextEditingController chargeController;

  bool enregistrement = false;

  @override
  void initState() {
    super.initState();

    ProgrammeExercice? e = widget.existant;

    ordreController = TextEditingController(text: '${widget.ordre}');
    seriesController = TextEditingController(text: e?.series?.toString() ?? '');
    repetitionsController =
        TextEditingController(text: e?.repetitions?.toString() ?? '');
    reposController =
        TextEditingController(text: e?.tempsRepos?.toString() ?? '');
    chargeController = TextEditingController(text: e?.charge?.toString() ?? '');
  }

  @override
  void dispose() {
    ordreController.dispose();
    seriesController.dispose();
    repetitionsController.dispose();
    reposController.dispose();
    chargeController.dispose();
    super.dispose();
  }

  // Entier strictement positif obligatoire.
  String? validerEntierObligatoire(String? valeur) {
    if (valeur == null || valeur.trim().isEmpty) {
      return 'Champ obligatoire';
    }

    int? nombre = int.tryParse(valeur.trim());

    if (nombre == null || nombre <= 0) {
      return 'Saisis un entier supérieur à 0';
    }

    return null;
  }

  // Entier facultatif, 0 ou plus.
  String? validerEntierFacultatif(String? valeur) {
    if (valeur == null || valeur.trim().isEmpty) {
      return null;
    }

    int? nombre = int.tryParse(valeur.trim());

    if (nombre == null || nombre < 0) {
      return 'Saisis un entier positif';
    }

    return null;
  }

  String? validerCharge(String? valeur) {
    if (valeur == null || valeur.trim().isEmpty) {
      return null;
    }

    double? nombre = double.tryParse(valeur.trim().replaceAll(',', '.'));

    if (nombre == null || nombre < 0) {
      return 'Saisis un nombre positif';
    }

    return null;
  }

  Future<void> enregistrer() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    String repos = reposController.text.trim();
    String charge = chargeController.text.trim().replaceAll(',', '.');

    ProgrammeExercice exercice = ProgrammeExercice(
      idProgramme: widget.idProgramme,
      externalId: widget.externalId,
      ordre: int.parse(ordreController.text.trim()),
      series: int.parse(seriesController.text.trim()),
      repetitions: int.parse(repetitionsController.text.trim()),
      tempsRepos: repos.isEmpty ? null : int.parse(repos),
      charge: charge.isEmpty ? null : double.parse(charge),
    );

    setState(() {
      enregistrement = true;
    });

    try {
      if (widget.existant == null) {
        await repository.ajouter(exercice);
      } else {
        await repository.modifier(exercice);
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } catch (erreur) {
      if (!mounted) {
        return;
      }

      setState(() {
        enregistrement = false;
      });

      afficherAlerteErreur(
        context,
        titre: 'Enregistrement impossible',
        message: erreur.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Widget champ(
      TextEditingController controller,
      String libelle,
      String? Function(String?) validateur, {
        bool decimal = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: decimal),
        decoration: InputDecoration(
          labelText: libelle,
          border: const OutlineInputBorder(),
        ),
        validator: validateur,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool modification = widget.existant != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(modification ? 'Modifier l\'exercice' : 'Ajouter l\'exercice'),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.fitness_center),
                title: Text(widget.nomExercice),
              ),
            ),
            const SizedBox(height: 16),
            champ(ordreController, 'Ordre dans le programme',
                validerEntierObligatoire),
            champ(seriesController, 'Séries', validerEntierObligatoire),
            champ(repetitionsController, 'Répétitions',
                validerEntierObligatoire),
            champ(reposController, 'Repos (secondes, facultatif)',
                validerEntierFacultatif),
            champ(chargeController, 'Charge (kg, facultatif)', validerCharge,
                decimal: true),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: enregistrement ? null : enregistrer,
              child: Text(enregistrement ? 'ENREGISTREMENT...' : 'ENREGISTRER'),
            ),
          ],
        ),
      ),
    );
  }
}