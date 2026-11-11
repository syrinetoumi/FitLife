import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../presentation/donnees_apercu.dart' show DonneesApercu;
import '../models/modeles_espaces.dart';
import '../metier/valeurs_metier.dart';
import '../services/notifications_service.dart';

const joursServeur = [
  'LUNDI',
  'MARDI',
  'MERCREDI',
  'JEUDI',
  'VENDREDI',
  'SAMEDI',
  'DIMANCHE',
];

// Les droits et les souscriptions restent contrôlés par les politiques et RPC du serveur.
class EspacesRepository extends DonneesApercu {
  EspacesRepository(this.client) : super(exemple: false);
  final SupabaseClient client;
  String _role = '';
  bool horsLigne = false;
  String? erreurActualisation;
  @override
  bool get demonstration => false;
  @override
  String get role => _role;
  String get _cache => 'espaces.catalogue.v1.${client.auth.currentUser!.id}';

  // La pagination évite de tronquer les listes quand le serveur limite le nombre de lignes par réponse.
  Future<List<Map<String, dynamic>>> _lireTable(
    String table,
    String cle,
  ) async {
    final lignes = <Map<String, dynamic>>[];
    var debut = 0;
    while (true) {
      final page = await client
          .from(table)
          .select()
          .order(cle)
          .range(debut, debut + 499);
      lignes.addAll(page);
      if (page.length < 500) return lignes;
      debut += 500;
    }
  }

  Future<void> charger() async {
    final utilisateur = client.auth.currentUser;
    if (utilisateur == null) throw StateError('Connexion requise.');
    final contexte = await client.rpc('contexte_espaces');
    _role = contexte['role'] as String? ?? '';
    if (_role.isEmpty) throw StateError('Un profil actif est requis.');
    final resultats = await Future.wait([
      _lireTable('espace_sportif', 'id_espace'),
      _lireTable('equipement', 'id_equipement'),
      _lireTable('disponibilite_espace', 'id_disponibilite'),
      _lireTable('offres_lecture', 'id_offre'),
      _lireTable('abonnements_lecture', 'id_abonnement'),
    ]);
    final donnees = <String, dynamic>{
      'espaces': resultats[0],
      'equipements': resultats[1],
      'horaires': resultats[2],
      'offres': resultats[3],
      'abonnements': resultats[4],
    };
    horsLigne = false;
    erreurActualisation = null;
    _remplir(donnees);
    actualiser();
    // Seul le catalogue public est conservé. Les abonnés et droits ne sont jamais mis en cache.
    try {
      final publics = <int>{};
      int? apres;
      while (true) {
        final page = await client.rpc(
          'rechercher_espaces',
          params: {'p_apres': apres, 'p_limite': 100},
        ) as List;
        publics.addAll(page.map((e) => e['id_espace'] as int));
        if (page.length < 100) break;
        apres = page.last['id_espace'] as int;
      }
      final cache = <String, dynamic>{
        'espaces': (resultats[0] as List)
            .where((e) => publics.contains(e['id_espace']))
            .toList(),
        'equipements': (resultats[1] as List)
            .where((e) => publics.contains(e['id_espace']))
            .toList(),
        'horaires': (resultats[2] as List)
            .where((e) => publics.contains(e['id_espace']))
            .toList(),
        'offres': (resultats[3] as List)
            .where(
              (e) =>
                  publics.contains(e['id_espace']) && e['statut'] == 'ACTIVE',
            )
            .toList(),
        'abonnements': <dynamic>[],
      };
      await (await SharedPreferences.getInstance()).setString(
        _cache,
        jsonEncode(cache),
      );
    } catch (_) {
      // Un échec du cache ne transforme pas une écriture confirmée en erreur réseau.
    }
  }

  Future<bool> chargerCache() async {
    if (client.auth.currentUser == null) return false;
    final texte = (await SharedPreferences.getInstance()).getString(_cache);
    if (texte == null) return false;
    _role = '';
    horsLigne = true;
    _remplir(jsonDecode(texte) as Map<String, dynamic>);
    actualiser();
    return true;
  }

  void _remplir(Map<String, dynamic> d) {
    final uid = client.auth.currentUser!.id;
    espaces
      ..clear()
      ..addAll(
        (d['espaces'] as List).map(
          (e) => EspaceApercu(
            id: e['id_espace'],
            nom: e['nom'],
            type: e['type'],
            adresse: e['adresse'],
            description: e['description'] ?? '',
            statut: e['statut'],
            telephone: e['telephone'] ?? '',
            email: e['email'] ?? '',
            siteWeb: e['site_web'] ?? '',
            latitude: (e['latitude'] as num?)?.toDouble(),
            longitude: (e['longitude'] as num?)?.toDouble(),
            estGere:
                !horsLigne && (_role == 'ADMIN' || e['id_gestionnaire'] == uid),
          ),
        ),
      );
    equipements
      ..clear()
      ..addAll(
        (d['equipements'] as List).map(
          (e) => EquipementApercu(
            e['id_equipement'],
            e['id_espace'],
            e['nom'],
            e['description'] ?? '',
            e['quantite'],
            e['etat'],
          ),
        ),
      );
    horaires
      ..clear()
      ..addAll(
        (d['horaires'] as List).map(
          (e) => HoraireApercu(
            e['id_espace'],
            joursServeur.indexOf(e['jour']),
            lireHeure((e['heure_ouverture'] as String).substring(0, 5))!,
            lireHeure((e['heure_fermeture'] as String).substring(0, 5))!,
            id: e['id_disponibilite'],
          ),
        ),
      );
    offres
      ..clear()
      ..addAll(
        (d['offres'] as List).map(
          (e) => OffreApercu(
            id: e['id_offre'],
            espace: e['id_espace'],
            nom: e['nom'],
            description: e['description'] ?? '',
            type: e['type'],
            statut: e['statut'],
            millimes: lireMillimes(e['prix'].toString())!,
            duree: e['duree'],
            debut: DateTime.parse(e['date_debut']),
            fin: e['date_fin'] == null ? null : DateTime.parse(e['date_fin']),
          ),
        ),
      );
    abonnements
      ..clear()
      ..addAll(
        (d['abonnements'] as List).map(
          (e) => AbonnementApercu(
            id: e['id_abonnement'],
            offre: e['id_offre'],
            athlete: 'Athlète ${e['id_athlete']}',
            estPersonnel: e['id_athlete'] == uid,
            debut: DateTime.parse(e['date_debut']),
            fin: DateTime.parse(e['date_fin']),
            millimes: lireMillimes(e['montant'].toString())!,
            statut: e['statut'],
          ),
        ),
      );
  }

  void _verifierConnexion() {
    if (horsLigne || _role.isEmpty) {
      throw StateError('Reconnectez-vous avant de modifier les données.');
    }
  }

  // Une écriture confirmée reste réussie même si le rechargement suivant échoue.
  Future<void> _rechargerApresEcriture() async {
    try {
      await charger();
    } catch (_) {
      erreurActualisation = 'Modification enregistrée sur le serveur. Actualisez pour afficher les nouvelles données.';
      actualiser();
    }
  }

  Future<void> _sauver(
    String table,
    String cle,
    int id,
    Map<String, dynamic> valeurs,
    bool nouveau,
  ) async {
    _verifierConnexion();
    if (nouveau) {
      await client.from(table).insert(valeurs).select(cle).single();
    } else {
      await client.from(table).update(valeurs).eq(cle, id).select(cle).single();
    }
    await _rechargerApresEcriture();
  }

  @override
  Future<void> enregistrerEspace(EspaceApercu valeur, {bool nouveau = false}) =>
      _sauver('espace_sportif', 'id_espace', valeur.id, {
        'nom': valeur.nom,
        'type': valeur.type,
        'adresse': valeur.adresse,
        'description': valeur.description,
        'telephone': valeur.telephone,
        'email': valeur.email,
        'site_web': valeur.siteWeb,
        'latitude': valeur.latitude,
        'longitude': valeur.longitude,
        'statut': valeur.statut,
      }, nouveau);
  @override
  Future<void> enregistrerEquipement(
    EquipementApercu valeur, {
    bool nouveau = false,
  }) => _sauver('equipement', 'id_equipement', valeur.id, {
    'nom': valeur.nom,
    'description': valeur.description,
    'quantite': valeur.quantite,
    'etat': valeur.etat,
    if (nouveau) 'id_espace': valeur.espace,
  }, nouveau);
  @override
  Future<void> enregistrerHoraire(
    HoraireApercu valeur, {
    HoraireApercu? ancien,
  }) => _sauver('disponibilite_espace', 'id_disponibilite', ancien?.id ?? 0, {
    'jour': joursServeur[valeur.jour],
    'heure_ouverture': heureTexte(valeur.debut),
    'heure_fermeture': heureTexte(valeur.fin),
    if (ancien == null) 'id_espace': valeur.espace,
  }, ancien == null);
  @override
  Future<void> supprimerHoraire(HoraireApercu valeur) async {
    _verifierConnexion();
    await client
        .from('disponibilite_espace')
        .delete()
        .eq('id_disponibilite', valeur.id!)
        .select()
        .single();
    await _rechargerApresEcriture();
  }

  @override
  Future<void> enregistrerOffre(OffreApercu valeur, {bool nouveau = false}) =>
      _sauver('offre', 'id_offre', valeur.id, {
        'nom': valeur.nom,
        'description': valeur.description,
        'type': valeur.type,
        'prix': montantTexte(valeur.millimes).replaceAll(',', '.'),
        'duree': valeur.duree,
        'date_debut': dateSaisie(valeur.debut),
        'date_fin': valeur.fin == null ? null : dateSaisie(valeur.fin!),
        'statut': valeur.statut == 'EXPIREE' ? 'INACTIVE' : valeur.statut,
        if (nouveau) 'id_espace': valeur.espace,
      }, nouveau);
  @override
  Future<void> changerStatutEspace(EspaceApercu valeur, String statut) =>
      _sauver('espace_sportif', 'id_espace', valeur.id, {
        'statut': statut,
      }, false);
  @override
  Future<void> souscrire(OffreApercu offre) async {
    _verifierConnexion();
    await client.rpc('souscrire_offre', params: {'p_offre': offre.id});
    try {
      await NotificationsService(client).synchroniser();
    } catch (_) {
      // La souscription est déjà validée. Le planificateur reprendra la notification.
    }
    await _rechargerApresEcriture();
  }

  @override
  Future<void> changerStatutAbonnement(
    AbonnementApercu valeur,
    String statut,
  ) async {
    _verifierConnexion();
    await client.rpc(
      'changer_statut_abonnement',
      params: {'p_abonnement': valeur.id, 'p_statut': statut},
    );
    await _rechargerApresEcriture();
  }
}
