import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/seance.dart';

// Stockage local (clé / valeur) de la dernière séance réservée.
class DerniereReservationLocale {
  // Une clé par utilisateur.
  static String? _cle() {
    String? uid = Supabase.instance.client.auth.currentUser?.id;

    if (uid == null) {
      return null;
    }

    return 'derniere_reservation_$uid';
  }

  static Future<void> enregistrer(Seance seance) async {
    String? cle = _cle();

    if (cle == null || seance.id == null) {
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      cle,
      jsonEncode({
        'id': seance.id,
        'titre': seance.titre,
        'date': seance.date.toIso8601String(),
        'heure': seance.debutCourt,
      }),
    );
  }

  static Future<Map<String, dynamic>?> lire() async {
    String? cle = _cle();

    if (cle == null) {
      return null;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? texte = prefs.getString(cle);

    if (texte == null) {
      return null;
    }

    try {
      return jsonDecode(texte) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> effacer() async {
    String? cle = _cle();

    if (cle == null) {
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(cle);
  }

  // N'efface que si c'est bien cette séance qui est mémorisée.
  static Future<void> effacerSi(int idSeance) async {
    Map<String, dynamic>? donnees = await lire();

    if (donnees != null && donnees['id'] == idSeance) {
      await effacer();
    }
  }
}