import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:coach_app/core/utils/alertes.dart';
import 'package:coach_app/core/utils/outils.dart';
import 'package:coach_app/features/entrainement/data/models/enums.dart';
import 'package:coach_app/features/entrainement/data/models/programme.dart';
import 'package:coach_app/features/entrainement/data/models/suivi_objectif.dart';
import 'package:coach_app/features/entrainement/data/repositories/suivi_objectif_repository.dart';
import 'libelles_suivi.dart';

class SuiviFormScreen extends StatefulWidget {
  final Programme programme;

  const SuiviFormScreen({super.key, required this.programme});

  @override
  State<SuiviFormScreen> createState() => _SuiviFormScreenState();
}

class _SuiviFormScreenState extends State<SuiviFormScreen> {
  final formKey = GlobalKey<FormState>();
  final departController = TextEditingController();
  final cibleController = TextEditingController();
  final SuiviObjectifRepository repository = SuiviObjectifRepository();

  DateTime? dateLimite;
  bool enregistrement = false;

  @override
  void initState() {
    super.initState();

    DateTime aujourdhui = DateTime.now();
    DateTime demain = DateTime(aujourdhui.year, aujourdhui.month, aujourdhui.day)
        .add(const Duration(days: 1));

    // Date proposée : la fin du programme, sinon 12 semaines.
    DateTime? fin = widget.programme.dateFin;

    if (fin != null && fin.isAfter(demain)) {
      dateLimite = fin;
    } else {
      dateLimite = demain.add(const Duration(days: 83));
    }
  }

  @override
  void dispose() {
    departController.dispose();
    cibleController.dispose();
    super.dispose();
  }

  String get nomValeur {
    if (widget.programme.objectif == ObjectifProgramme.FORCE) {
      return 'Charge';
    }
    return 'Poids';
  }

  double? lire(String texte) {
    return double.tryParse(texte.trim().replaceAll(',', '.'));
  }

  String? validerNombre(String? valeur) {
    if (valeur == null || valeur.trim().isEmpty) {
      return 'Champ obligatoire';
    }

    double? nombre = lire(valeur);

    if (nombre == null || nombre <= 0) {
      return 'Saisis un nombre supérieur à 0';
    }

    return null;
  }

  // La cible doit aller dans le sens du programme.
  String? verifierSens(double depart, double cible) {
    ObjectifProgramme objectif = widget.programme.objectif;

    if (objectif == ObjectifProgramme.PERTE_POIDS && cible >= depart) {
      return 'Pour une perte de poids, la cible doit être inférieure '
          'à la valeur de départ.';
    }

    if ((objectif == ObjectifProgramme.PRISE_MASSE ||
        objectif == ObjectifProgramme.FORCE) &&
        cible <= depart) {
      return 'Pour ce programme, la cible doit être supérieure '
          'à la valeur de départ.';
    }

    if (cible == depart) {
      return 'La cible doit être différente de la valeur de départ.';
    }

    return null;
  }

  Future<void> choisirDate() async {
    DateTime aujourdhui = DateTime.now();
    DateTime demain = DateTime(aujourdhui.year, aujourdhui.month, aujourdhui.day)
        .add(const Duration(days: 1));

    DateTime? choix = await showDatePicker(
      context: context,
      initialDate: dateLimite ?? demain,
      firstDate: demain,
      lastDate: demain.add(const Duration(days: 730)),
    );

    if (choix != null) {
      setState(() {
        dateLimite = choix;
      });
    }
  }

  Future<void> enregistrer() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (dateLimite == null) {
      afficherMessage(context, 'Choisis une date limite.');
      return;
    }

    double depart = lire(departController.text)!;
    double cible = lire(cibleController.text)!;

    String? probleme = verifierSens(depart, cible);

    if (probleme != null) {
      afficherAlerteErreur(
        context,
        titre: 'Objectif incohérent',
        message: probleme,
      );
      return;
    }

    setState(() {
      enregistrement = true;
    });

    try {
      String idAthlete = Supabase.instance.client.auth.currentUser!.id;

      await repository.ajouter(
        SuiviObjectif(
          idAthlete: idAthlete,
          idProgramme: widget.programme.id,
          valeurDepart: depart,
          valeurCible: cible,
          unite: 'kg',
          dateDebut: DateTime.now(),
          dateLimite: dateLimite!,
        ),
      );

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
        message: messageErreur(erreur),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon objectif')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.flag),
                title: Text(widget.programme.nom),
                subtitle: Text(enTexte(widget.programme.objectif)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: departController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: '$nomValeur de départ (kg)',
                border: const OutlineInputBorder(),
              ),
              validator: validerNombre,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: cibleController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: '$nomValeur à atteindre (kg)',
                border: const OutlineInputBorder(),
              ),
              validator: validerNombre,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: choisirDate,
              icon: const Icon(Icons.event),
              label: Text(
                dateLimite == null
                    ? 'Choisir la date limite'
                    : 'Date limite : ${afficherDate(dateLimite!)}',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: enregistrement ? null : enregistrer,
              child: Text(
                enregistrement ? 'ENREGISTREMENT...' : 'ENREGISTRER MON OBJECTIF',
              ),
            ),
          ],
        ),
      ),
    );
  }
}