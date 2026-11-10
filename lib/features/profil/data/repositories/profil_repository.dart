import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profil_utilisateur.dart';

/// Repository gérant la récupération et la mise à jour des données de profil
/// dans la table `profiles` de Supabase.
class ProfilRepository {
  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Profil de démonstration utilisé en l'absence de session active
  ProfilUtilisateur get _profilDemo => ProfilUtilisateur(
        id: 'demo-athlete-id',
        nom: 'Ben Ali',
        prenom: 'Syrine',
        role: 'ATHLETE',
        telephone: '+216 22 123 456',
        photo: null,
        dateNaissance: DateTime(1998, 5, 14),
        dateCreation: DateTime(2026, 1, 10, 11, 30),
        actif: true,
        genre: 'FEMME',
        email: 'syrine.toumi@fitlife.tn',
      );

  /// Récupère le profil de l'utilisateur actuellement connecté.
  /// Si aucun utilisateur n'est connecté ou en cas d'erreur, renvoie un profil de démonstration.
  Future<ProfilUtilisateur> getProfilActuel() async {
    final client = _client;
    if (client == null) {
      return _profilDemo;
    }

    final user = client.auth.currentUser;
    if (user == null) {
      return _profilDemo;
    }

    try {
      final data = await client
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        return ProfilUtilisateur.fromMap(data, email: user.email);
      }

      // Si le profil n'existe pas encore en base, on le pré-remplit avec les métadonnées d'inscription
      final meta = user.userMetadata ?? {};
      DateTime? parsedNaissance;
      if (meta['date_naissance'] != null) {
        parsedNaissance = DateTime.tryParse(meta['date_naissance'].toString());
      }

      final nouveauProfil = ProfilUtilisateur(
        id: user.id,
        nom: meta['nom'] as String?,
        prenom: meta['prenom'] as String?,
        role: (meta['role'] as String?) ?? 'ATHLETE',
        telephone: meta['telephone'] as String?,
        dateNaissance: parsedNaissance,
        dateCreation: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
        actif: true,
        genre: meta['genre'] as String?,
        email: user.email,
      );

      // On tente d'enregistrer la ligne initiale dans Supabase
      try {
        await client.from('profiles').upsert(nouveauProfil.toMap());
      } catch (e) {
        debugPrint('Impossible d\'insérer le profil initial : $e');
      }

      return nouveauProfil;
    } catch (e) {
      debugPrint('Erreur lors de la récupération du profil Supabase : $e');
      return ProfilUtilisateur(
        id: user.id,
        nom: (user.userMetadata?['nom'] as String?) ?? 'Utilisateur',
        prenom: (user.userMetadata?['prenom'] as String?) ?? '',
        role: (user.userMetadata?['role'] as String?) ?? 'ATHLETE',
        telephone: user.userMetadata?['telephone'] as String?,
        email: user.email,
        dateCreation: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
        actif: true,
      );
    }
  }

  /// Met à jour les informations du profil dans Supabase.
  Future<ProfilUtilisateur> mettreAJourProfil(ProfilUtilisateur profil) async {
    final client = _client;
    if (client == null) {
      return profil;
    }

    final user = client.auth.currentUser;
    final userId = user?.id ?? profil.id;

    final profilAEnvoyer = profil.copyWith(id: userId);

    try {
      await client.from('profiles').upsert(profilAEnvoyer.toMap());

      // Met également à jour les métadonnées auth
      if (user != null) {
        try {
          await client.auth.updateUser(
            UserAttributes(
              data: {
                if (profilAEnvoyer.nom != null) 'nom': profilAEnvoyer.nom,
                if (profilAEnvoyer.prenom != null) 'prenom': profilAEnvoyer.prenom,
                if (profilAEnvoyer.telephone != null) 'telephone': profilAEnvoyer.telephone,
                if (profilAEnvoyer.genre != null) 'genre': profilAEnvoyer.genre,
                if (profilAEnvoyer.role.isNotEmpty) 'role': profilAEnvoyer.role,
              },
            ),
          );
        } catch (_) {}
      }

      return profilAEnvoyer;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du profil : $e');
      rethrow;
    }
  }
}
