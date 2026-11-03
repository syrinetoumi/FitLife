import 'package:flutter/material.dart';

import 'donnees_apercu.dart';

String? requis(String? valeur) => valeur == null || valeur.trim().isEmpty
    ? 'Ce champ est obligatoire.'
    : null;

Widget champ(
  String label,
  String initial,
  ValueChanged<String> changer, {
  String? Function(String?)? valider,
  int lignes = 1,
  TextInputType? clavier,
  String? aide,
  bool calendrier = false,
  bool horloge = false,
}) => calendrier || horloge
    ? _ChampDateHeure(
        label: label,
        initial: initial,
        changer: changer,
        valider: valider,
        aide: aide,
        estDate: calendrier,
      )
    : TextFormField(
        initialValue: initial,
        onChanged: changer,
        validator: valider,
        maxLines: lignes,
        keyboardType: clavier,
        textInputAction: lignes == 1
            ? TextInputAction.next
            : TextInputAction.newline,
        decoration: InputDecoration(labelText: label, helperText: aide),
      );

class _ChampDateHeure extends StatefulWidget {
  const _ChampDateHeure({
    required this.label,
    required this.initial,
    required this.changer,
    required this.valider,
    required this.aide,
    required this.estDate,
  });
  final String label, initial;
  final ValueChanged<String> changer;
  final String? Function(String?)? valider;
  final String? aide;
  final bool estDate;
  @override
  State<_ChampDateHeure> createState() => _ChampDateHeureState();
}

class _ChampDateHeureState extends State<_ChampDateHeure> {
  late final controller = TextEditingController(text: widget.initial);
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> choisir() async {
    FocusScope.of(context).unfocus();
    String? texte;
    if (widget.estDate) {
      var initial = lireDateApercu(controller.text) ?? jourLocal();
      if (initial.year < 2000 || initial.year > 2200) initial = jourLocal();
      final valeur = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2000),
        lastDate: DateTime(2200, 12, 31),
        helpText: 'Choisir une date',
        cancelText: 'Annuler',
        confirmText: 'Choisir',
      );
      if (valeur != null) texte = dateSaisie(valeur);
    } else {
      final minutes = lireHeure(controller.text) ?? 8 * 60;
      final valeur = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
        helpText: 'Choisir une heure',
        cancelText: 'Annuler',
        confirmText: 'Choisir',
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
      );
      if (valeur != null) texte = heureTexte(valeur.hour * 60 + valeur.minute);
    }
    if (!mounted || texte == null) return;
    controller.text = texte;
    widget.changer(texte);
  }

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    onChanged: widget.changer,
    validator: widget.valider,
    keyboardType: TextInputType.datetime,
    textInputAction: TextInputAction.next,
    decoration: InputDecoration(
      labelText: widget.label,
      helperText: widget.aide,
      suffixIcon: IconButton(
        tooltip:
            '${widget.estDate ? 'Choisir la date' : 'Choisir l’heure'} : ${widget.label}',
        onPressed: choisir,
        icon: Icon(
          widget.estDate ? Icons.calendar_month_outlined : Icons.schedule,
        ),
      ),
    ),
  );
}

Widget choix(
  String label,
  String valeur,
  Map<String, String> options,
  ValueChanged<String?> changer,
) => DropdownButtonFormField<String>(
  initialValue: valeur,
  validator: (v) => v == null || v.isEmpty ? 'Choisissez une valeur.' : null,
  isExpanded: true,
  decoration: InputDecoration(labelText: label),
  items: options.entries
      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
      .toList(),
  onChanged: changer,
);

Future<void> ouvrirFormulaire(
  BuildContext context,
  String titre,
  List<Widget> Function(StateSetter) champs,
  VoidCallback enregistrer,
) async {
  final cle = GlobalKey<FormState>();
  await showDialog<void>(
    context: context,
    routeSettings: RouteSettings(name: '/espaces-sportifs/formulaire/$titre'),
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, modifier) => AlertDialog(
        title: Text(titre),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Form(
              key: cle,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Les champs marqués * sont obligatoires.'),
                  const SizedBox(height: 20),
                  for (final widget in champs(modifier))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: widget,
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (!cle.currentState!.validate()) return;
              enregistrer();
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Modifications enregistrées dans la démonstration.',
                  ),
                ),
              );
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    ),
  );
}

Future<void> editerEspace(
  BuildContext context,
  DonneesApercu donnees, {
  EspaceApercu? espace,
}) async {
  var nom = espace?.nom ?? '';
  var type = espace?.type ?? '';
  var adresse = espace?.adresse ?? '';
  var description = espace?.description ?? '';
  var telephone = espace?.telephone ?? '';
  var email = espace?.email ?? '';
  var site = espace?.siteWeb ?? '';
  var latitude = espace?.latitude?.toString() ?? '';
  var longitude = espace?.longitude?.toString() ?? '';
  var statut = espace?.statut ?? 'INACTIF';

  String? coordonnee(String? valeur, int limite) {
    if (latitude.trim().isEmpty != longitude.trim().isEmpty) {
      return 'Renseignez les deux coordonnées, ou aucune.';
    }
    if (valeur == null || valeur.trim().isEmpty) return null;
    final nombre = double.tryParse(valeur.replaceAll(',', '.'));
    return nombre == null || !nombre.isFinite || nombre.abs() > limite
        ? 'Valeur attendue entre -$limite et $limite.'
        : null;
  }

  await ouvrirFormulaire(
    context,
    espace == null ? 'Créer un espace' : 'Modifier l’espace',
    (modifier) => [
      champ('Nom *', nom, (v) => nom = v, valider: requis),
      choix('Type *', type, {
        '': 'Choisir un type',
        ...typesEspace,
      }, (v) => modifier(() => type = v!)),
      champ('Adresse *', adresse, (v) => adresse = v, valider: requis),
      champ('Description', description, (v) => description = v, lignes: 3),
      champ(
        'Téléphone',
        telephone,
        (v) => telephone = v,
        clavier: TextInputType.phone,
      ),
      champ(
        'E-mail',
        email,
        (v) => email = v,
        clavier: TextInputType.emailAddress,
        valider: (v) =>
            v!.trim().isEmpty ||
                RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())
            ? null
            : 'Adresse e-mail invalide.',
      ),
      champ(
        'Site web',
        site,
        (v) => site = v,
        clavier: TextInputType.url,
        valider: (v) {
          if (v!.trim().isEmpty) return null;
          final uri = Uri.tryParse(v.trim());
          return uri != null &&
                  ['http', 'https'].contains(uri.scheme) &&
                  uri.host.isNotEmpty
              ? null
              : 'Utilisez une adresse http:// ou https:// valide.';
        },
      ),
      champ(
        'Latitude',
        latitude,
        (v) => latitude = v,
        valider: (v) => coordonnee(v, 90),
        aide: 'Facultatif. Vous pouvez enregistrer sans coordonnées.',
      ),
      champ(
        'Longitude',
        longitude,
        (v) => longitude = v,
        valider: (v) => coordonnee(v, 180),
      ),
      if (espace != null)
        choix('Statut', statut, {
          'ACTIF': 'Actif',
          'INACTIF': 'Inactif',
          'EN_MAINTENANCE': 'En maintenance',
        }, (v) => modifier(() => statut = v!)),
      if (espace == null)
        const Text(
          'Votre espace sera créé inactif. Vous pourrez l’activer depuis sa fiche.',
        ),
    ],
    () {
      final resultat =
          espace ??
          EspaceApercu(
            id: donnees.prochainId(),
            nom: '',
            type: type,
            adresse: '',
            description: '',
          );
      resultat
        ..nom = nom.trim()
        ..type = type
        ..adresse = adresse.trim()
        ..description = description.trim()
        ..telephone = telephone.trim()
        ..email = email.trim()
        ..siteWeb = site.trim()
        ..statut = statut
        ..latitude = double.tryParse(latitude.replaceAll(',', '.'))
        ..longitude = double.tryParse(longitude.replaceAll(',', '.'));
      if (espace == null) donnees.espaces.add(resultat);
      donnees.actualiser();
    },
  );
}

Future<void> editerEquipement(
  BuildContext context,
  DonneesApercu donnees,
  EspaceApercu espace, {
  EquipementApercu? equipement,
}) async {
  var nom = equipement?.nom ?? '';
  var description = equipement?.description ?? '';
  var quantite = equipement?.quantite.toString() ?? '';
  var etat = equipement?.etat ?? '';
  await ouvrirFormulaire(
    context,
    equipement == null ? 'Ajouter un équipement' : 'Modifier l’équipement',
    (modifier) => [
      champ('Nom *', nom, (v) => nom = v, valider: requis),
      champ('Description', description, (v) => description = v, lignes: 2),
      champ(
        'Quantité *',
        quantite,
        (v) => quantite = v,
        clavier: TextInputType.number,
        aide: 'Une quantité de 0 retire l’équipement des disponibilités.',
        valider: (v) => int.tryParse(v ?? '') == null || int.parse(v!) < 0
            ? 'Saisissez un entier positif ou nul.'
            : null,
      ),
      choix('État *', etat, {
        '': 'Choisir un état',
        ...etatsEquipement,
      }, (v) => modifier(() => etat = v!)),
    ],
    () {
      if (equipement == null) {
        donnees.equipements.add(
          EquipementApercu(
            donnees.prochainId(),
            espace.id,
            nom.trim(),
            description.trim(),
            int.parse(quantite),
            etat,
          ),
        );
      } else {
        equipement
          ..nom = nom.trim()
          ..description = description.trim()
          ..quantite = int.parse(quantite)
          ..etat = etat;
      }
      donnees.actualiser();
    },
  );
}

Future<void> editerHoraire(
  BuildContext context,
  DonneesApercu donnees,
  EspaceApercu espace, {
  HoraireApercu? horaire,
}) async {
  var jour = horaire?.jour ?? 0;
  var debut = horaire == null ? '08:00' : heureTexte(horaire.debut);
  var fin = horaire == null ? '18:00' : heureTexte(horaire.fin);
  await ouvrirFormulaire(
    context,
    horaire == null ? 'Ajouter un créneau' : 'Modifier le créneau',
    (modifier) => [
      choix('Jour *', '$jour', {
        for (var i = 0; i < jours.length; i++) '$i': jours[i],
      }, (v) => modifier(() => jour = int.parse(v!))),
      champ(
        'Ouverture *',
        debut,
        (v) => debut = v,
        horloge: true,
        aide: 'Format 24 h : HH:mm',
        valider: (v) =>
            lireHeure(v ?? '') == null ? 'Heure invalide (HH:mm).' : null,
      ),
      champ(
        'Fermeture *',
        fin,
        (v) => fin = v,
        horloge: true,
        valider: (v) {
          final d = lireHeure(debut), f = lireHeure(v ?? '');
          if (f == null) return 'Heure invalide (HH:mm).';
          if (d == null || f <= d) {
            return 'La fermeture doit suivre l’ouverture le même jour.';
          }
          if (donnees.horaires.any(
            (h) =>
                h != horaire &&
                h.espace == espace.id &&
                h.jour == jour &&
                d < h.fin &&
                f > h.debut,
          )) {
            return 'Ce créneau chevauche un horaire existant.';
          }
          return null;
        },
      ),
      const Text(
        'Plusieurs créneaux par jour sont possibles. Sans créneau, l’espace est fermé.',
      ),
    ],
    () {
      if (horaire != null) donnees.horaires.remove(horaire);
      donnees.horaires.add(
        HoraireApercu(espace.id, jour, lireHeure(debut)!, lireHeure(fin)!),
      );
      donnees.actualiser();
    },
  );
}

Future<void> editerOffre(
  BuildContext context,
  DonneesApercu donnees,
  EspaceApercu espace, {
  OffreApercu? offre,
}) async {
  var nom = offre?.nom ?? '';
  var description = offre?.description ?? '';
  var type = offre?.type ?? 'ABONNEMENT';
  var prix = offre == null ? '' : montantTexte(offre.millimes);
  var duree = offre?.duree.toString() ?? '30';
  var debut = dateSaisie(offre?.debut ?? jourLocal());
  var fin = offre?.fin == null ? '' : dateSaisie(offre!.fin!);
  var statut = offre?.statut ?? 'INACTIVE';
  await ouvrirFormulaire(
    context,
    offre == null ? 'Créer une offre' : 'Modifier l’offre',
    (modifier) => [
      champ('Nom *', nom, (v) => nom = v, valider: requis),
      champ('Description', description, (v) => description = v, lignes: 3),
      choix(
        'Type *',
        type,
        typesOffre,
        (v) => modifier(() {
          type = v!;
        }),
      ),
      champ(
        'Prix en TND *',
        prix,
        (v) => prix = v,
        clavier: const TextInputType.numberWithOptions(decimal: true),
        aide: 'Jusqu’à 3 décimales. Exemple : 80,500',
        valider: (v) => lireMillimes(v ?? '') == null
            ? 'Prix positif ou nul, avec 3 décimales maximum.'
            : null,
      ),
      champ(
        'Durée en jours *',
        duree,
        (v) => duree = v,
        clavier: TextInputType.number,
        valider: (v) {
          final jours = int.tryParse(v ?? '');
          if (jours == null || jours < 1 || jours > 36500) {
            return 'Durée attendue entre 1 et 36 500 jours.';
          }
          if (type == 'SEANCE' && jours != 1) {
            return 'Un accès à la journée dure exactement 1 jour.';
          }
          return null;
        },
      ),
      champ(
        'Début des ventes *',
        debut,
        (v) => debut = v,
        calendrier: true,
        aide: 'Format AAAA-MM-JJ',
        valider: (v) => lireDateApercu(v ?? '') == null
            ? 'Date invalide (AAAA-MM-JJ).'
            : null,
      ),
      champ(
        'Fin des ventes',
        fin,
        (v) => fin = v,
        calendrier: true,
        aide: 'Facultatif. Format AAAA-MM-JJ',
        valider: (v) {
          if (v!.isEmpty) return null;
          final date = lireDateApercu(v), premiere = lireDateApercu(debut);
          return date == null || premiere == null || date.isBefore(premiere)
              ? 'La fin doit être une date valide après ou égale au début.'
              : null;
        },
      ),
      choix('Statut', statut, {
        'INACTIVE': 'Inactive',
        'ACTIVE': 'Active',
      }, (v) => modifier(() => statut = v!)),
      const Text(
        'Les abonnements existants conservent leur prix et leurs dates. Un pack ne compte pas les visites.',
      ),
    ],
    () {
      final resultat =
          offre ??
          OffreApercu(
            id: donnees.prochainId(),
            espace: espace.id,
            nom: '',
            description: '',
            type: type,
            millimes: 0,
            duree: 1,
            debut: jourLocal(),
          );
      resultat
        ..nom = nom.trim()
        ..description = description.trim()
        ..type = type
        ..millimes = lireMillimes(prix)!
        ..duree = int.parse(duree)
        ..debut = lireDateApercu(debut)!
        ..fin = fin.isEmpty ? null : lireDateApercu(fin)
        ..statut = statut;
      if (offre == null) donnees.offres.add(resultat);
      donnees.actualiser();
    },
  );
}
