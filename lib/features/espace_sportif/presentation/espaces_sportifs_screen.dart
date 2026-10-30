import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'donnees_apercu.dart';
import 'formulaires_espaces.dart';
import 'localisation_espace.dart';

const _bleu = AppCouleurs.principale;
const _menthe = AppCouleurs.accent;

class EspacesSportifsScreen extends StatefulWidget {
  const EspacesSportifsScreen({super.key, this.donnees});
  final DonneesApercu? donnees;

  @override
  State<EspacesSportifsScreen> createState() => _EspacesSportifsScreenState();
}

class _EspacesSportifsScreenState extends State<EspacesSportifsScreen> {
  late final DonneesApercu donnees = widget.donnees ?? DonneesApercu();
  bool gestionnaire = true;
  int page = 0;
  String recherche = '', type = 'TOUS';
  bool avecOffres = false;
  final rechercheController = TextEditingController();

  @override
  void dispose() {
    rechercheController.dispose();
    if (widget.donnees == null) donnees.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: donnees,
    builder: (context, _) {
      final large = MediaQuery.sizeOf(context).width >= 900;
      final destinations = [
        const NavigationDestination(
          icon: Icon(Icons.explore_outlined),
          label: 'Explorer',
        ),
        if (gestionnaire)
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            label: 'Mes espaces',
          ),
        NavigationDestination(
          icon: const Icon(Icons.confirmation_number_outlined),
          label: gestionnaire ? 'Abonnés' : 'Abonnements',
        ),
        const NavigationDestination(
          icon: Icon(Icons.location_on_outlined),
          label: 'Localisation',
        ),
      ];
      final indexAbonnements = gestionnaire ? 2 : 1;
      final localisation = page == destinations.length - 1;
      return Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: Text(large ? 'FITLIFE / ESPACES' : 'FITLIFE', maxLines: 1),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<bool>(
                  value: gestionnaire,
                  items: const [
                    DropdownMenuItem(
                      value: true,
                      child: Text('Démo : gestionnaire'),
                    ),
                    DropdownMenuItem(
                      value: false,
                      child: Text('Démo : athlète'),
                    ),
                  ],
                  onChanged: (v) => setState(() {
                    gestionnaire = v!;
                    page = 0;
                  }),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFFE9ECFC),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
              child: const Text(
                'APERÇU INTERFACES · Données de démonstration · Modifications non enregistrées après redémarrage',
                style: TextStyle(fontSize: 12, color: _bleu),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  if (large)
                    NavigationRail(
                      selectedIndex: page,
                      extended: true,
                      onDestinationSelected: (v) => setState(() => page = v),
                      destinations: destinations
                          .map(
                            (d) => NavigationRailDestination(
                              icon: d.icon,
                              label: Text(d.label),
                            ),
                          )
                          .toList(),
                    ),
                  if (large) const VerticalDivider(width: 1),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: page == indexAbonnements
                            ? _abonnements()
                            : localisation
                            ? _localisations()
                            : _catalogue(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: large
            ? null
            : NavigationBar(
                selectedIndex: page,
                onDestinationSelected: (v) => setState(() => page = v),
                destinations: destinations,
              ),
      );
    },
  );

  Widget _catalogue() {
    final mesEspaces = gestionnaire && page == 1;
    final liste = donnees.espaces.where((e) {
      if (mesEspaces ? !e.estGere : e.statut != 'ACTIF') return false;
      if (type != 'TOUS' && e.type != type) return false;
      if (avecOffres &&
          !donnees.offres.any((o) => o.espace == e.id && o.disponible)) {
        return false;
      }
      return '${e.nom} ${e.adresse}'.toLowerCase().contains(
        recherche.toLowerCase(),
      );
    }).toList();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _hero(
          mesEspaces
              ? 'VOTRE ESPACE.\nLEUR PROGRESSION.'
              : 'TROUVEZ VOTRE\nPROCHAIN TERRAIN.',
          mesEspaces
              ? 'Pilotez vos lieux, vos équipements et vos offres depuis un même espace.'
              : 'Des lieux pour bouger, des équipements pour progresser. À vous de choisir.',
          mesEspaces ? Icons.storefront_outlined : Icons.sports_gymnastics,
        ),
        const SizedBox(height: 24),
        if (mesEspaces)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _indicateur(
                '${donnees.espaces.where((e) => e.estGere).length}',
                'espaces gérés',
                Icons.storefront_outlined,
              ),
              _indicateur(
                '${donnees.equipements.where((e) => donnees.espaces.any((s) => s.id == e.espace && s.estGere)).length}',
                'équipements',
                Icons.fitness_center,
              ),
              _indicateur(
                '${donnees.offres.where((o) => donnees.espaceDe(o).estGere && o.disponible).length}',
                'offres actives',
                Icons.local_offer_outlined,
              ),
            ],
          ),
        const SizedBox(height: 12),
        _titre(
          mesEspaces ? 'MES ESPACES' : 'EXPLORER LES ESPACES',
          action: mesEspaces
              ? FilledButton.icon(
                  onPressed: () => editerEspace(context, donnees),
                  icon: const Icon(Icons.add),
                  label: const Text('Créer un espace'),
                )
              : null,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: rechercheController,
          onChanged: (v) => setState(() => recherche = v),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            labelText: 'Rechercher un nom ou une adresse',
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entree in {'TOUS': 'Tous', ...typesEspace}.entries)
              ChoiceChip(
                label: Text(entree.value),
                selected: type == entree.key,
                onSelected: (_) => setState(() => type = entree.key),
              ),
            FilterChip(
              label: const Text('Avec une offre disponible'),
              selected: avecOffres,
              onSelected: (v) => setState(() => avecOffres = v),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Text(
            '${liste.length} espace${liste.length > 1 ? 's' : ''}',
            style: const TextStyle(color: AppCouleurs.texteSecondaire),
          ),
        ),
        if (liste.isEmpty)
          _vide(
            'Aucun espace trouvé',
            mesEspaces
                ? 'Créez votre premier espace ou modifiez les filtres.'
                : 'Essayez un autre nom, une autre adresse ou un autre type.',
          ),
        LayoutBuilder(
          builder: (context, contraintes) {
            final colonnes = contraintes.maxWidth >= 850
                ? 3
                : contraintes.maxWidth >= 550
                ? 2
                : 1;
            final largeur =
                (contraintes.maxWidth - (colonnes - 1) * 16) / colonnes;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final espace in liste)
                  SizedBox(width: largeur, child: _carteEspace(espace)),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _carteEspace(EspaceApercu espace) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => _ouvrirEspace(espace),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 128,
            color: const Color(0xFFE6EAF8),
            child: Stack(
              children: [
                Positioned(
                  right: 14,
                  bottom: -12,
                  child: Icon(
                    iconeEspace(espace.type),
                    size: 125,
                    color: _bleu.withValues(alpha: .12),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: _badge(espace.statut),
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: Text(
                    typesEspace[espace.type]!,
                    style: const TextStyle(
                      color: _bleu,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  espace.nom,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  espace.adresse,
                  style: const TextStyle(color: AppCouleurs.texteSecondaire),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Découvrir l’espace',
                        style: TextStyle(color: _bleu),
                      ),
                    ),
                    const Icon(Icons.arrow_forward, color: _bleu),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  void _ouvrirEspace(EspaceApercu espace) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: RouteSettings(name: '/espaces-sportifs/espace/${espace.id}'),
      builder: (_) => _DetailEspace(
        donnees: donnees,
        espace: espace,
        gestionnaire: gestionnaire && espace.estGere,
        athlete: !gestionnaire,
      ),
    ),
  );

  Widget _abonnements() {
    final liste = donnees.abonnements
        .where(
          (a) => gestionnaire
              ? donnees.espaceDe(donnees.offreDe(a)).estGere
              : a.estPersonnel,
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _hero(
          gestionnaire
              ? 'VOS OFFRES.\nLEUR ENGAGEMENT.'
              : 'VOTRE SPORT,\nAU QUOTIDIEN.',
          gestionnaire
              ? 'Suivez les adhésions aux offres de vos espaces.'
              : 'Retrouvez vos accès, leurs dates et leur statut.',
          Icons.confirmation_number_outlined,
        ),
        const SizedBox(height: 24),
        _titre(gestionnaire ? 'ABONNÉS DE MES ESPACES' : 'MES ABONNEMENTS'),
        const SizedBox(height: 16),
        if (liste.isEmpty)
          _vide(
            'Aucun abonnement',
            gestionnaire
                ? 'Les nouvelles souscriptions à vos offres apparaîtront ici.'
                : 'Explorez les espaces et choisissez une offre pour commencer.',
          ),
        for (final abonnement in liste)
          _carteAbonnement(context, donnees, abonnement, gestionnaire),
      ],
    );
  }

  Widget _localisations() => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      _hero(
        'LE SPORT,\nÀ VOTRE PORTÉE.',
        'Retrouvez les adresses des espaces et préparez votre prochaine visite.',
        Icons.near_me_outlined,
      ),
      const SizedBox(height: 24),
      const Text(
        'Choisissez un espace pour consulter sa carte ou préparer votre trajet.',
      ),
      const SizedBox(height: 24),
      for (final espace in donnees.espaces.where((e) => e.statut == 'ACTIF'))
        LocalisationEspace(espace: espace),
    ],
  );
}

class _DetailEspace extends StatefulWidget {
  const _DetailEspace({
    required this.donnees,
    required this.espace,
    required this.gestionnaire,
    required this.athlete,
  });
  final DonneesApercu donnees;
  final EspaceApercu espace;
  final bool gestionnaire;
  final bool athlete;
  @override
  State<_DetailEspace> createState() => _DetailEspaceState();
}

class _DetailEspaceState extends State<_DetailEspace> {
  int section = 0;
  DonneesApercu get donnees => widget.donnees;
  EspaceApercu get espace => widget.espace;
  bool get gerer => widget.gestionnaire;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: donnees,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: Text(espace.nom)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1050),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _hero(
                espace.nom.toUpperCase(),
                espace.adresse,
                iconeEspace(espace.type),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _badge(espace.statut),
                  Text(typesEspace[espace.type]!),
                  if (gerer)
                    OutlinedButton.icon(
                      onPressed: () =>
                          editerEspace(context, donnees, espace: espace),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Modifier l’espace'),
                    ),
                  if (gerer)
                    TextButton(
                      onPressed: () async {
                        final actif = espace.statut == 'ACTIF';
                        if (await _confirmer(
                          context,
                          actif
                              ? 'Désactiver cet espace ?'
                              : 'Activer cet espace ?',
                          actif
                              ? 'Les nouvelles souscriptions seront bloquées. Les abonnements existants seront conservés.'
                              : 'L’espace sera visible dans le catalogue de démonstration.',
                        )) {
                          espace.statut = actif ? 'INACTIF' : 'ACTIF';
                          donnees.actualiser();
                        }
                      },
                      child: Text(
                        espace.statut == 'ACTIF' ? 'Désactiver' : 'Activer',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entree in [
                    'Présentation',
                    'Équipements',
                    'Horaires',
                    'Offres',
                    if (gerer) 'Abonnés',
                  ].asMap().entries)
                    ChoiceChip(
                      label: Text(entree.value),
                      selected: section == entree.key,
                      onSelected: (_) => setState(() => section = entree.key),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              switch (section) {
                1 => _equipements(),
                2 => _horaires(),
                3 => _offres(),
                4 => _abonnes(),
                _ => _presentation(),
              },
            ],
          ),
        ),
      ),
    ),
  );

  Widget _presentation() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _titre('UN LIEU POUR VOS OBJECTIFS'),
      const SizedBox(height: 12),
      Text(
        espace.description.isEmpty
            ? 'Aucune description renseignée.'
            : espace.description,
        style: const TextStyle(fontSize: 16, height: 1.6),
      ),
      const SizedBox(height: 24),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _info(Icons.location_on_outlined, 'Adresse', espace.adresse),
              _info(
                Icons.phone_outlined,
                'Téléphone',
                espace.telephone.isEmpty ? 'Non renseigné' : espace.telephone,
              ),
              _info(
                Icons.mail_outline,
                'E-mail',
                espace.email.isEmpty ? 'Non renseigné' : espace.email,
              ),
              _info(
                Icons.language,
                'Site web',
                espace.siteWeb.isEmpty ? 'Non renseigné' : espace.siteWeb,
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      LocalisationEspace(espace: espace),
      const SizedBox(height: 8),
      Text(_coordonnees(espace)),
      const SizedBox(height: 24),
      if (gerer)
        OutlinedButton.icon(
          onPressed: () => _verifierDisponibilite(context, donnees, espace),
          icon: const Icon(Icons.event_available_outlined),
          label: const Text('Vérifier horaires et équipements'),
        ),
    ],
  );

  Widget _equipements() {
    final liste = donnees.equipements
        .where((e) => e.espace == espace.id)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _titre(
          'ÉQUIPEMENTS',
          action: gerer
              ? FilledButton.icon(
                  onPressed: () => editerEquipement(context, donnees, espace),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                )
              : null,
        ),
        const SizedBox(height: 12),
        const Text(
          'Seuls les équipements en bon état et en quantité suffisante sont utilisables.',
        ),
        const SizedBox(height: 12),
        if (liste.isEmpty)
          _vide(
            'Aucun équipement',
            'Les équipements renseignés apparaîtront ici.',
          ),
        for (final e in liste)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(Icons.fitness_center, color: _bleu),
                  SizedBox(
                    width: 190,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.nom,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                        ),
                        if (e.description.isNotEmpty) Text(e.description),
                      ],
                    ),
                  ),
                  Text('Quantité : ${e.quantite}'),
                  _badge(e.etat),
                  if (gerer)
                    IconButton(
                      tooltip: 'Modifier ${e.nom}',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => editerEquipement(
                        context,
                        donnees,
                        espace,
                        equipement: e,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _horaires() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _titre(
        'HORAIRES HEBDOMADAIRES',
        action: gerer
            ? FilledButton.icon(
                onPressed: () => editerHoraire(context, donnees, espace),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
              )
            : null,
      ),
      const SizedBox(height: 12),
      const Text(
        'Heure de Tunis · Les créneaux de nuit et fermetures exceptionnelles ne sont pas gérés.',
      ),
      const SizedBox(height: 16),
      for (var jour = 0; jour < 7; jour++) _ligneJour(jour),
      const SizedBox(height: 16),
      if (gerer)
        OutlinedButton.icon(
          onPressed: () => _verifierDisponibilite(context, donnees, espace),
          icon: const Icon(Icons.event_available_outlined),
          label: const Text('Vérifier horaires et équipements'),
        ),
    ],
  );

  Widget _ligneJour(int jour) {
    final liste =
        donnees.horaires
            .where((h) => h.espace == espace.id && h.jour == jour)
            .toList()
          ..sort((a, b) => a.debut.compareTo(b.debut));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              jours[jour],
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (liste.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Fermé'),
              ),
            for (final h in liste)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${heureTexte(h.debut)} — ${heureTexte(h.fin)}',
                    ),
                  ),
                  if (gerer) ...[
                    IconButton(
                      tooltip: 'Modifier le créneau du ${jours[jour]}',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () =>
                          editerHoraire(context, donnees, espace, horaire: h),
                    ),
                    IconButton(
                      tooltip: 'Supprimer le créneau du ${jours[jour]}',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        if (await _confirmer(
                          context,
                          'Supprimer ce créneau ?',
                          '${jours[jour]} : ${heureTexte(h.debut)} — ${heureTexte(h.fin)}',
                        )) {
                          donnees.horaires.remove(h);
                          donnees.actualiser();
                        }
                      },
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _offres() {
    final liste = donnees.offres
        .where((o) => o.espace == espace.id && (gerer || o.disponible))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _titre(
          'OFFRES ET ACCÈS',
          action: gerer
              ? FilledButton.icon(
                  onPressed: () => editerOffre(context, donnees, espace),
                  icon: const Icon(Icons.add),
                  label: const Text('Créer une offre'),
                )
              : null,
        ),
        const SizedBox(height: 12),
        if (liste.isEmpty)
          _vide(
            'Aucune offre disponible',
            gerer
                ? 'Créez une offre pour cet espace.'
                : 'Revenez consulter cet espace plus tard.',
          ),
        for (final offre in liste)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        typesOffre[offre.type]!,
                        style: const TextStyle(color: _bleu),
                      ),
                      _badge(offre.statutEffectif),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    offre.nom,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${montantTexte(offre.millimes)} TND',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: _bleu,
                          ),
                        ),
                        TextSpan(
                          text:
                              ' / ${offre.duree} jour${offre.duree > 1 ? 's' : ''}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    offre.description.isEmpty
                        ? 'Aucune description.'
                        : offre.description,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => _detailOffre(
                      context,
                      donnees,
                      offre,
                      gerer,
                      widget.athlete,
                    ),
                    child: const Text('Voir l’offre'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _abonnes() {
    final liste = donnees.abonnements
        .where((a) => donnees.offreDe(a).espace == espace.id)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _titre('ABONNÉS DE CET ESPACE'),
        const SizedBox(height: 16),
        if (liste.isEmpty)
          _vide(
            'Aucun abonné',
            'Les souscriptions à vos offres apparaîtront ici.',
          ),
        for (final a in liste) _carteAbonnement(context, donnees, a, true),
      ],
    );
  }
}

Widget _hero(String titre, String description, IconData icone) => Container(
  padding: const EdgeInsets.all(28),
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF232B78), _bleu],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  child: LayoutBuilder(
    builder: (context, contraintes) => Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ESPACES SPORTIFS',
                style: TextStyle(
                  color: _menthe,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                titre,
                style: styleTitre.copyWith(
                  color: Colors.white,
                  fontSize: contraintes.maxWidth < 400 ? 32 : 44,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: const TextStyle(color: Colors.white, height: 1.5),
              ),
            ],
          ),
        ),
        if (contraintes.maxWidth > 550)
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Icon(icone, size: 100, color: _menthe),
          ),
      ],
    ),
  ),
);

Widget _titre(String texte, {Widget? action}) => Wrap(
  spacing: 16,
  runSpacing: 12,
  crossAxisAlignment: WrapCrossAlignment.center,
  alignment: WrapAlignment.spaceBetween,
  children: [
    Text(texte, style: styleTitre.copyWith(fontSize: 27)),
    ?action,
  ],
);

Widget _indicateur(String valeur, String label, IconData icone) => Container(
  width: 215,
  padding: const EdgeInsets.all(18),
  color: Colors.white,
  child: Row(
    children: [
      Icon(icone, color: _bleu),
      const SizedBox(width: 16),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            valeur,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
          ),
          Text(label),
        ],
      ),
    ],
  ),
);

Widget _badge(String statut) {
  final positif = ['ACTIF', 'ACTIVE', 'BON'].contains(statut);
  final libelle =
      {
        'ACTIF': 'Actif',
        'ACTIVE': 'Active',
        'INACTIF': 'Inactif',
        'INACTIVE': 'Inactive',
        'EXPIRE': 'Expiré',
        'EXPIREE': 'Expirée',
        'SUSPENDU': 'Suspendu',
        'ANNULE': 'Annulé',
        ...etatsEquipement,
      }[statut] ??
      statut;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: positif ? const Color(0xFFDDF8E8) : const Color(0xFFF1EFE9),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      libelle,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 12,
        color: positif ? const Color(0xFF17603B) : const Color(0xFF62543D),
      ),
    ),
  );
}

Widget _vide(String titre, String message) => Container(
  padding: const EdgeInsets.all(28),
  color: Colors.white,
  child: Column(
    children: [
      const Icon(Icons.search_off_outlined, size: 40, color: _bleu),
      const SizedBox(height: 12),
      Text(
        titre,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      Text(message, textAlign: TextAlign.center),
    ],
  ),
);

Widget _info(IconData icone, String titre, String valeur) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 10),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icone, color: _bleu, size: 22),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titre,
              style: const TextStyle(
                color: AppCouleurs.texteSecondaire,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            SelectableText(valeur),
          ],
        ),
      ),
    ],
  ),
);

String _coordonnees(EspaceApercu espace) =>
    espace.latitude == null || espace.longitude == null
    ? 'Coordonnées non renseignées · Recherche par adresse disponible.'
    : 'Latitude ${espace.latitude!.toStringAsFixed(5)} · Longitude ${espace.longitude!.toStringAsFixed(5)}';

Future<bool> _confirmer(
  BuildContext context,
  String titre,
  String texte,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(titre),
        content: Text(texte),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Retour'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    ) ??
    false;

void _detailOffre(
  BuildContext context,
  DonneesApercu donnees,
  OffreApercu offre,
  bool gerer,
  bool athlete,
) {
  final parentContext = context;
  final espace = donnees.espaceDe(offre);
  showDialog<void>(
    context: context,
    builder: (c) => ListenableBuilder(
      listenable: donnees,
      builder: (context, _) => AlertDialog(
        title: Text(offre.nom),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(espace.nom),
                const SizedBox(height: 12),
                _badge(offre.statutEffectif),
                _info(
                  Icons.payments_outlined,
                  'Prix',
                  '${montantTexte(offre.millimes)} TND / ${offre.duree} jours',
                ),
                Text(offre.description),
                _info(
                  Icons.date_range,
                  'Période de vente',
                  'Du ${dateTexte(offre.debut)}${offre.fin == null ? ' · Sans date de fin' : ' au ${dateTexte(offre.fin!)}'}',
                ),
                if (athlete) ...[
                  const Divider(),
                  Text(
                    'Accès du ${dateTexte(jourLocal())} au ${dateTexte(jourLocal().add(Duration(days: offre.duree - 1)))} en souscrivant aujourd’hui.',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Démonstration locale : aucun paiement ni réservation de séance. Les dates et le prix seront confirmés par le serveur lors de l’intégration.',
                  ),
                  if (donnees.dejaAbonne(offre))
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        'Vous avez déjà un abonnement actif ou suspendu à cette offre.',
                      ),
                    ),
                  if (!offre.disponible || espace.statut != 'ACTIF')
                    const Text(
                      'Cette offre ne peut pas être souscrite actuellement.',
                    ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Fermer'),
          ),
          if (gerer)
            FilledButton(
              onPressed: () {
                Navigator.pop(c);
                editerOffre(parentContext, donnees, espace, offre: offre);
              },
              child: const Text('Modifier l’offre'),
            ),
          if (athlete)
            FilledButton(
              onPressed:
                  !offre.disponible ||
                      espace.statut != 'ACTIF' ||
                      donnees.dejaAbonne(offre)
                  ? null
                  : () async {
                      final confirmer = await _confirmer(
                        context,
                        'Confirmer la souscription ?',
                        '${offre.nom} · ${montantTexte(offre.millimes)} TND pour ${offre.duree} jours. Cette action utilise uniquement les données de démonstration.',
                      );
                      if (!confirmer || !c.mounted) return;
                      donnees.souscrire(offre);
                      Navigator.pop(c);
                    },
              child: const Text('Souscrire en démo'),
            ),
        ],
      ),
    ),
  );
}

Widget _carteAbonnement(
  BuildContext context,
  DonneesApercu donnees,
  AbonnementApercu abonnement,
  bool gerer,
) {
  final offre = donnees.offreDe(abonnement);
  final espace = donnees.espaceDe(offre);
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                offre.nom,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              _badge(abonnement.statutEffectif),
            ],
          ),
          const SizedBox(height: 8),
          Text(espace.nom),
          if (gerer) Text(abonnement.athlete),
          const SizedBox(height: 8),
          Text(
            '${dateTexte(abonnement.debut)} → ${dateTexte(abonnement.fin)} · ${montantTexte(abonnement.millimes)} TND',
          ),
          if (espace.statut != 'ACTIF')
            const Text(
              'Espace actuellement indisponible. Votre historique est conservé.',
            ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: () =>
                  _detailAbonnement(context, donnees, abonnement, gerer),
              child: const Text('Détails de l’abonnement'),
            ),
          ),
        ],
      ),
    ),
  );
}

void _detailAbonnement(
  BuildContext context,
  DonneesApercu donnees,
  AbonnementApercu a,
  bool gerer,
) {
  final offre = donnees.offreDe(a);
  showDialog<void>(
    context: context,
    builder: (c) => ListenableBuilder(
      listenable: donnees,
      builder: (context, _) {
        final modifiable = ['ACTIF', 'SUSPENDU'].contains(a.statutEffectif);
        Future<void> changer(String statut) async {
          if (await _confirmer(
            context,
            'Confirmer le changement ?',
            statut == 'ANNULE'
                ? 'L’annulation est définitive. Aucun remboursement n’est effectué dans cet aperçu.'
                : 'La date de fin reste le ${dateTexte(a.fin)}.',
          )) {
            if (!modifiable) return;
            a.statut = statut;
            donnees.actualiser();
          }
        }

        return AlertDialog(
          title: Text(offre.nom),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _badge(a.statutEffectif),
                  _info(
                    Icons.storefront_outlined,
                    'Espace',
                    donnees.espaceDe(offre).nom,
                  ),
                  _info(Icons.person_outline, 'Athlète', a.athlete),
                  _info(
                    Icons.date_range,
                    'Dates de l’abonnement',
                    '${dateTexte(a.debut)} au ${dateTexte(a.fin)} inclus',
                  ),
                  _info(
                    Icons.payments_outlined,
                    'Montant à la souscription',
                    '${montantTexte(a.millimes)} TND',
                  ),
                  const Text(
                    'La suspension ne prolonge pas l’abonnement. Les modifications de l’offre ne changent pas ce montant ni ces dates.',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Fermer'),
            ),
            if (modifiable && (gerer || a.estPersonnel))
              TextButton(
                onPressed: () => changer('ANNULE'),
                child: const Text('Annuler l’abonnement'),
              ),
            if (modifiable && gerer)
              FilledButton(
                onPressed: () =>
                    changer(a.statutEffectif == 'ACTIF' ? 'SUSPENDU' : 'ACTIF'),
                child: Text(
                  a.statutEffectif == 'ACTIF' ? 'Suspendre' : 'Réactiver',
                ),
              ),
          ],
        );
      },
    ),
  );
}

void _verifierDisponibilite(
  BuildContext context,
  DonneesApercu donnees,
  EspaceApercu espace,
) {
  var date = dateSaisie(jourLocal()), debut = '09:00', fin = '10:00';
  final exigences = <int, String>{};
  List<String>? raisons;
  final cle = GlobalKey<FormState>();
  showDialog<void>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (context, modifier) => AlertDialog(
        title: const Text('Horaires et équipements'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Form(
              key: cle,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Vérification indicative. Les séances existantes et la réservation du lieu ne sont pas connectées.',
                  ),
                  const SizedBox(height: 18),
                  champ(
                    'Date *',
                    date,
                    (v) {
                      date = v;
                      modifier(() => raisons = null);
                    },
                    calendrier: true,
                    aide: 'AAAA-MM-JJ · Heure de Tunis',
                    valider: (v) => lireDateApercu(v ?? '') == null
                        ? 'Date invalide.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  champ(
                    'Début *',
                    debut,
                    (v) {
                      debut = v;
                      modifier(() => raisons = null);
                    },
                    horloge: true,
                    aide: 'HH:mm',
                    valider: (v) =>
                        lireHeure(v ?? '') == null ? 'Heure invalide.' : null,
                  ),
                  const SizedBox(height: 16),
                  champ(
                    'Fin *',
                    fin,
                    (v) {
                      fin = v;
                      modifier(() => raisons = null);
                    },
                    horloge: true,
                    aide: 'HH:mm',
                    valider: (v) =>
                        lireHeure(v ?? '') == null ||
                            lireHeure(debut) == null ||
                            lireHeure(v!)! <= lireHeure(debut)!
                        ? 'La fin doit suivre le début le même jour.'
                        : null,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Équipements requis',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Text(
                    'Aucune sélection signifie explicitement : aucun équipement requis.',
                  ),
                  for (final e in donnees.equipements.where(
                    (e) => e.espace == espace.id,
                  )) ...[
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(e.nom),
                      subtitle: Text(
                        '${e.quantite} unités · ${etatsEquipement[e.etat]}',
                      ),
                      value: exigences.containsKey(e.id),
                      onChanged: (v) => modifier(() {
                        if (v!) {
                          exigences[e.id] = '1';
                        } else {
                          exigences.remove(e.id);
                        }
                        raisons = null;
                      }),
                    ),
                    if (exigences.containsKey(e.id))
                      TextFormField(
                        key: ValueKey(e.id),
                        initialValue: exigences[e.id],
                        decoration: const InputDecoration(
                          labelText: 'Quantité requise *',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          exigences[e.id] = v;
                          modifier(() => raisons = null);
                        },
                        validator: (v) =>
                            int.tryParse(v ?? '') == null || int.parse(v!) < 1
                            ? 'Saisissez un entier supérieur à 0.'
                            : null,
                      ),
                  ],
                  if (raisons != null)
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.all(16),
                      color: raisons!.isEmpty
                          ? const Color(0xFFDDF8E8)
                          : const Color(0xFFFFEAD8),
                      child: Text(
                        raisons!.isEmpty
                            ? 'Horaires et équipements compatibles. L’occupation par les séances reste à vérifier avant toute réservation.'
                            : raisons!.join('\n'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Fermer'),
          ),
          FilledButton(
            onPressed: () {
              if (!cle.currentState!.validate()) return;
              final jour = lireDateApercu(date)!.weekday - 1,
                  d = lireHeure(debut)!,
                  f = lireHeure(fin)!;
              final resultat = <String>[];
              if (espace.statut != 'ACTIF') {
                resultat.add('L’espace n’est pas actif.');
              }
              if (!donnees.horaires.any(
                (h) =>
                    h.espace == espace.id &&
                    h.jour == jour &&
                    d >= h.debut &&
                    f <= h.fin,
              )) {
                resultat.add(
                  'Le créneau ne tient pas entièrement dans une plage d’ouverture.',
                );
              }
              for (final exigence in exigences.entries) {
                final e = donnees.equipements.firstWhere(
                  (e) => e.id == exigence.key,
                );
                if (e.etat != 'BON' || e.quantite < int.parse(exigence.value)) {
                  resultat.add('${e.nom} : état ou quantité incompatible.');
                }
              }
              modifier(() => raisons = resultat);
            },
            child: const Text('Vérifier'),
          ),
        ],
      ),
    ),
  );
}
