import 'package:flutter_test/flutter_test.dart';
import 'package:coach_app/features/espace_sportif/data/models/modeles_espaces.dart';
import 'package:coach_app/features/espace_sportif/data/metier/disponibilite_metier.dart';

void main() {
  final espace = EspaceApercu(
    id: 1,
    nom: 'Salle',
    type: 'SALLE',
    adresse: 'Tunis',
    description: '',
    statut: 'ACTIF',
  );
  final matin = HoraireApercu(1, 0, 8 * 60, 12 * 60);
  final apresMidi = HoraireApercu(1, 0, 12 * 60, 18 * 60);

  test('Disponibilité : une seule plage complète et uniquement du matériel utilisable', () {
    final equipement = EquipementApercu(7, 1, 'Haltères', '', 3, 'BON');
    List<String> verifier(int debut, int fin) => verifierDisponibilite(
      espace: espace,
      horaires: [matin, apresMidi],
      equipements: [equipement],
      date: DateTime(2026, 11, 2),
      debut: debut,
      fin: fin,
      exigences: {7: 3},
    );
    expect(verifier(8 * 60, 12 * 60), isEmpty);
    expect(
      verifier(11 * 60, 13 * 60),
      contains(
        'Le créneau ne tient pas entièrement dans une plage d’ouverture.',
      ),
    );
    equipement.etat = 'EN_MAINTENANCE';
    expect(
      verifier(8 * 60, 9 * 60),
      contains('Haltères : état ou quantité incompatible.'),
    );
    equipement.etat = 'BON';
    equipement.quantite = 2;
    expect(verifier(8 * 60, 9 * 60), isNotEmpty);
  });

  test('Horaires : l’adjacence est permise et la modification exclut son propre créneau', () {
    String? verifier(
      String ouverture,
      String fermeture, {
      HoraireApercu? ancien,
    }) => validerFermeture(
      ouverture: ouverture,
      fermeture: fermeture,
      horaires: [matin],
      espace: 1,
      jour: 0,
      ancien: ancien,
    );
    expect(verifier('12:00', '18:00'), isNull);
    expect(
      verifier('11:00', '13:00'),
      'Ce créneau chevauche un horaire existant.',
    );
    expect(verifier('08:00', '12:00', ancien: matin), isNull);
  });
}
