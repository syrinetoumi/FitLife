import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:coach_app/features/auth/models/profil.dart';

class ProfilRepository {
  final SupabaseClient client = Supabase.instance.client;

  // Récupère tous les profils pour l'écran admin
  Future<List<Profil>> getProfils() async {
    final lignes = await client
        .from('profiles')
        .select()
        .order('role', ascending: true);

    List<Profil> profils = [];
    for (var ligne in lignes) {
      profils.add(Profil.fromMap(ligne));
    }
    return profils;
  }

  // Active ou désactive un profil utilisateur
  // Utilise .select() pour vérifier que la base a réellement mis à jour la ligne
  Future<void> changerStatutActif(String id, bool actif) async {
    final resultat = await client
        .from('profiles')
        .update({'actif': actif})
        .eq('id', id)
        .select();

    if (resultat.isEmpty) {
      throw Exception(
        'Modification refusée. Vérifiez votre rôle administrateur et les politiques d’accès.',
      );
    }
  }

  // Vérifie si un compte utilisateur est actif (utilisé au Login)
  Future<bool> estCompteActif(String userId) async {
    final data = await client
        .from('profiles')
        .select('actif')
        .eq('id', userId)
        .maybeSingle();
    return data?['actif'] == true;
  }

  // Vérifie si un utilisateur possède le rôle ADMIN
  Future<bool> estAdmin(String userId) async {
    try {
      final data = await client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return false;
      return data['role']?.toString().toUpperCase() == 'ADMIN';
    } catch (_) {
      return false;
    }
  }
}
