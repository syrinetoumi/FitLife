import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/services/localisation_service.dart';

import 'donnees_apercu.dart';
import '../data/metier/saisie_metier.dart';
export '../data/metier/saisie_metier.dart' show requis;
import '../data/metier/disponibilite_metier.dart';

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
  Key? cle,
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
        key: cle,
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

// Le formulaire attend l’enregistrement et conserve les valeurs saisies si la sauvegarde échoue.
Future<void> ouvrirFormulaire(
  BuildContext context,
  String titre,
  List<Widget> Function(StateSetter, BuildContext) champs,
  Future<void> Function() enregistrer,
) async {
  final cle = GlobalKey<FormState>();
  bool enCours = false;
  String? erreur;
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
                  if (erreur != null)
                    Text(
                      erreur!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  for (final widget in champs(modifier, context))
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
            onPressed: enCours ? null : () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: enCours
                ? null
                : () async {
                    if (!cle.currentState!.validate()) return;
                    modifier(() {
                      enCours = true;
                      erreur = null;
                    });
                    try {
                      await enregistrer();
                    } catch (_) {
                      if (dialogContext.mounted) {
                        modifier(() {
                          enCours = false;
                          erreur = 'Enregistrement impossible. Vérifiez la connexion, vos droits et les valeurs saisies.';
                        });
                      }
                      return;
                    }
                    if (!dialogContext.mounted || !context.mounted) return;
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Modifications enregistrées.'),
                      ),
                    );
                  },
            child: Text(enCours ? 'Enregistrement…' : 'Enregistrer'),
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

  await ouvrirFormulaire(
    context,
    espace == null ? 'Créer un espace' : 'Modifier l’espace',
    (modifier, formulaireContext) => [
      champ('Nom *', nom, (v) => nom = v, valider: requis),
      choix('Type *', type, {
        '': 'Choisir un type',
        ...typesEspace,
      }, (v) => modifier(() => type = v!)),
      champ('Adresse *', adresse, (v) => adresse = v, valider: requis),
      if (!donnees.demonstration)
        OutlinedButton.icon(
          icon: const Icon(Icons.search),
          label: const Text('Rechercher les coordonnées de cette adresse'),
          onPressed: () async {
            if (adresse.trim().length < 3) return;
            try {
              // La recherche reste volontaire ; le gestionnaire choisit le lieu avant de remplacer les coordonnées.
              final geocodage = await LocalisationService(
                Supabase.instance.client,
              ).geocoder(adresse);
              final resultats = geocodage.resultats;
              if (!formulaireContext.mounted) return;
              final resultat = await showDialog<Map<String, dynamic>>(
                context: formulaireContext,
                builder: (c) => SimpleDialog(
                  title: const Text('Choisir un lieu public'),
                  children: [
                    if (resultats.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Aucun résultat. Vous pouvez saisir les coordonnées manuellement.',
                        ),
                      ),
                    for (final r in resultats)
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(c, r),
                        child: Text(r['nom'] as String),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(geocodage.attribution),
                    ),
                  ],
                ),
              );
              if (resultat != null && formulaireContext.mounted) {
                modifier(() {
                  latitude = resultat['latitude'].toString();
                  longitude = resultat['longitude'].toString();
                });
              }
            } catch (erreur) {
              if (formulaireContext.mounted) {
                ScaffoldMessenger.of(formulaireContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      erreur is StateError
                          ? erreur.message.toString()
                          : 'Service indisponible. Réessayez plus tard.',
                    ),
                  ),
                );
              }
            }
          },
        ),
      if (!donnees.demonstration)
        const Text(
          'Recherche manuelle d’un établissement public via le service de géocodage. Ne saisissez pas une adresse privée ou confidentielle.',
        ),
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
        valider: validerEmailEspace,
      ),
      champ(
        'Site web',
        site,
        (v) => site = v,
        clavier: TextInputType.url,
        valider: validerSiteEspace,
      ),
      champ(
        'Latitude',
        latitude,
        (v) => latitude = v,
        cle: ValueKey('latitude:$latitude'),
        valider: (v) => validerCoordonneeEspace(v, 90, latitude, longitude),
        aide: 'Facultatif. Vous pouvez enregistrer sans coordonnées.',
      ),
      champ(
        'Longitude',
        longitude,
        (v) => longitude = v,
        cle: ValueKey('longitude:$longitude'),
        valider: (v) => validerCoordonneeEspace(v, 180, latitude, longitude),
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
    () async {
      final resultat = EspaceApercu(
        id: espace?.id ?? donnees.prochainId(),
        estGere: espace?.estGere ?? true,
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
      await donnees.enregistrerEspace(resultat, nouveau: espace == null);
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
    (modifier, formulaireContext) => [
      champ('Nom *', nom, (v) => nom = v, valider: requis),
      champ('Description', description, (v) => description = v, lignes: 2),
      champ(
        'Quantité *',
        quantite,
        (v) => quantite = v,
        clavier: TextInputType.number,
        aide: 'Une quantité de 0 retire l’équipement des disponibilités.',
        valider: validerQuantiteEquipement,
      ),
      choix('État *', etat, {
        '': 'Choisir un état',
        ...etatsEquipement,
      }, (v) => modifier(() => etat = v!)),
    ],
    () async {
      await donnees.enregistrerEquipement(
        EquipementApercu(
          equipement?.id ?? donnees.prochainId(),
          espace.id,
          nom.trim(),
          description.trim(),
          int.parse(quantite),
          etat,
        ),
        nouveau: equipement == null,
      );
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
    (modifier, formulaireContext) => [
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
        valider: (v) => validerFermeture(
          ouverture: debut,
          fermeture: v,
          horaires: donnees.horaires,
          espace: espace.id,
          jour: jour,
          ancien: horaire,
        ),
      ),
      const Text(
        'Plusieurs créneaux par jour sont possibles. Sans créneau, l’espace est fermé.',
      ),
    ],
    () async {
      await donnees.enregistrerHoraire(
        HoraireApercu(
          espace.id,
          jour,
          lireHeure(debut)!,
          lireHeure(fin)!,
          id: horaire?.id,
        ),
        ancien: horaire,
      );
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
  var statut = offre?.statut == 'EXPIREE'
      ? 'INACTIVE'
      : offre?.statut ?? 'INACTIVE';
  await ouvrirFormulaire(
    context,
    offre == null ? 'Créer une offre' : 'Modifier l’offre',
    (modifier, formulaireContext) => [
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
        valider: validerPrixOffre,
      ),
      champ(
        'Durée en jours *',
        duree,
        (v) => duree = v,
        clavier: TextInputType.number,
        valider: (v) => validerDureeOffre(v, type),
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
        valider: (v) => validerFinVentes(v, debut),
      ),
      choix('Statut', statut, {
        'INACTIVE': 'Inactive',
        'ACTIVE': 'Active',
      }, (v) => modifier(() => statut = v!)),
      const Text(
        'Les abonnements existants conservent leur prix et leurs dates. Un pack ne compte pas les visites.',
      ),
    ],
    () async {
      final resultat = OffreApercu(
        id: offre?.id ?? donnees.prochainId(),
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
      await donnees.enregistrerOffre(resultat, nouveau: offre == null);
    },
  );
}
