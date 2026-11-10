import 'package:flutter_test/flutter_test.dart';
import 'package:coach_app/features/profil/data/models/profil_utilisateur.dart';

void main() {
  group('Tests ProfilUtilisateur', () {
    test('fromMap et toMap fonctionnent correctement', () {
      final map = {
        'id': 'user-123',
        'nom': 'Toumi',
        'prenom': 'Syrine',
        'role': 'ATHLETE',
        'telephone': '12345678',
        'photo': 'https://example.com/avatar.jpg',
        'date_naissance': '1998-05-14',
        'date_creation': '2026-01-10T10:00:00.000Z',
        'actif': true,
        'genre': 'FEMME',
      };

      final profil = ProfilUtilisateur.fromMap(map, email: 'syrine@fitlife.tn');

      expect(profil.id, 'user-123');
      expect(profil.nom, 'Toumi');
      expect(profil.prenom, 'Syrine');
      expect(profil.nomComplet, 'Syrine Toumi');
      expect(profil.initiales, 'ST');
      expect(profil.role, 'ATHLETE');
      expect(profil.roleLibelle, 'Athlète');
      expect(profil.telephone, '12345678');
      expect(profil.photo, 'https://example.com/avatar.jpg');
      expect(profil.genre, 'FEMME');
      expect(profil.genreLibelle, 'Femme');
      expect(profil.email, 'syrine@fitlife.tn');
      expect(profil.actif, isTrue);
      expect(profil.dateNaissance?.year, 1998);

      final converti = profil.toMap();
      expect(converti['id'], 'user-123');
      expect(converti['nom'], 'Toumi');
      expect(converti['prenom'], 'Syrine');
      expect(converti['date_naissance'], '1998-05-14');
    });

    test('Initiales et nomComplet par défaut en cas de données vides', () {
      final profil = ProfilUtilisateur(
        id: 'anon-1',
        email: 'athlete@fitlife.tn',
      );

      expect(profil.nomComplet, 'athlete@fitlife.tn');
      expect(profil.initiales, 'A');
      expect(profil.roleLibelle, 'Athlète');
      expect(profil.genreLibelle, 'Non renseigné');
      expect(profil.dateNaissanceFormatee, 'Non renseignée');
    });

    test('copyWith met à jour les champs correctement', () {
      final profil = ProfilUtilisateur(
        id: 'user-1',
        nom: 'Ben',
        prenom: 'Ali',
        role: 'COACH',
      );

      final modifie = profil.copyWith(nom: 'Salah', role: 'NUTRITIONNISTE');
      expect(modifie.nom, 'Salah');
      expect(modifie.prenom, 'Ali');
      expect(modifie.role, 'NUTRITIONNISTE');
      expect(modifie.roleLibelle, 'Nutritionniste');
    });
  });
}
