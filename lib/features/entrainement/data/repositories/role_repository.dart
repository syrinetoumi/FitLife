import 'package:supabase_flutter/supabase_flutter.dart';

class RoleRepository {
  final SupabaseClient client = Supabase.instance.client;

  // Rôle de l'utilisateur connecté (ATHLETE par défaut).
  Future<String> getRole() async {
    final utilisateur = client.auth.currentUser;

    if (utilisateur == null) {
      return 'ATHLETE';
    }

    final ligne = await client
        .from('profiles')
        .select('role')
        .eq('id', utilisateur.id)
        .maybeSingle();

    if (ligne == null) {
      return 'ATHLETE';
    }

    return ligne['role'] as String;
  }

  Future<bool> estCoach() async {
    String role = await getRole();

    return role == 'COACH';
  }
}