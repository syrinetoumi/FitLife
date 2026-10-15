import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient client = Supabase.instance.client;

  Future<void> connecter(String email, String motDePasse) async {
    await client.auth.signInWithPassword(
      email: email.trim(),
      password: motDePasse,
    );
  }

  // true : l'utilisateur est connecté tout de suite.
  // false : une confirmation par e-mail est demandée.
  Future<bool> inscrire({
    required String email,
    required String motDePasse,
    required Map<String, dynamic> donnees,
  }) async {
    final reponse = await client.auth.signUp(
      email: email.trim(),
      password: motDePasse,
      data: donnees,
    );

    return reponse.session != null;
  }

  Future<void> deconnecter() async {
    await client.auth.signOut();
  }

  // Envoie un code par e-mail.
  Future<void> demanderCode(String email) async {
    await client.auth.resetPasswordForEmail(email.trim());
  }

  // Vérifie le code (connecte l'utilisateur) puis change le mot de passe.
  Future<void> reinitialiser(
      String email,
      String code,
      String nouveauMotDePasse,
      ) async {
    await client.auth.verifyOTP(
      type: OtpType.recovery,
      email: email.trim(),
      token: code.trim(),
    );

    await client.auth.updateUser(UserAttributes(password: nouveauMotDePasse));
  }
}

// Messages d'erreur en français.
String messageErreurAuth(Object erreur) {
  String texte = erreur.toString().toLowerCase();

  if (erreur is AuthException) {
    texte = erreur.message.toLowerCase();
  }

  if (texte.contains('invalid login')) {
    return 'E-mail ou mot de passe incorrect.';
  }

  if (texte.contains('not confirmed')) {
    return 'Confirmez d’abord votre e-mail.';
  }

  if (texte.contains('already registered')) {
    return 'Cet e-mail possède déjà un compte.';
  }

  if (texte.contains('rate limit')) {
    return 'Trop de tentatives, réessayez plus tard.';
  }

  if (texte.contains('expired') || texte.contains('invalid')) {
    return 'Code invalide ou expiré.';
  }

  if (texte.contains('password')) {
    return 'Mot de passe refusé : choisissez-en un plus solide.';
  }

  if (texte.contains('socket') || texte.contains('network')) {
    return 'Pas de connexion internet.';
  }

  return 'Une erreur est survenue : $erreur';
}