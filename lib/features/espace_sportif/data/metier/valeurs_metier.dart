DateTime jourLocal() {
  // La Tunisie utilise UTC+1 toute l’année.
  final date = DateTime.now().toUtc().add(const Duration(hours: 1));
  return DateTime(date.year, date.month, date.day);
}

String dateTexte(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
String dateSaisie(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
// Le contrôle aller-retour refuse les dates normalisées automatiquement, comme le 31 février.
DateTime? lireDateApercu(String texte) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(texte)) return null;
  final date = DateTime.tryParse(texte);
  return date != null && dateSaisie(date) == texte ? date : null;
}

// Le prix est converti en millimes entiers pour éviter les arrondis des nombres décimaux binaires.
int? lireMillimes(String texte) {
  final normalise = texte.trim().replaceAll(',', '.');
  if (!RegExp(r'^\d{1,9}(\.\d{1,3})?$').hasMatch(normalise)) return null;
  final parties = normalise.split('.');
  return int.parse(parties.first) * 1000 +
      (parties.length == 2 ? int.parse(parties[1].padRight(3, '0')) : 0);
}

String montantTexte(int millimes) =>
    '${millimes ~/ 1000},${(millimes % 1000).toString().padLeft(3, '0')}';
String heureTexte(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
// Les horaires utilisent une précision à la minute et restent dans la même journée.
int? lireHeure(String texte) {
  if (!RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(texte)) return null;
  final parties = texte.split(':');
  return int.parse(parties[0]) * 60 + int.parse(parties[1]);
}
