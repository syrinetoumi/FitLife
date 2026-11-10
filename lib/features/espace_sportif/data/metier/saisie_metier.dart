String? requis(String? valeur) => valeur == null || valeur.trim().isEmpty
    ? 'Ce champ est obligatoire.'
    : null;

String? validerEmailEspace(String? valeur) =>
    valeur == null ||
        valeur.trim().isEmpty ||
        RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(valeur.trim())
    ? null
    : 'Adresse e-mail invalide.';

String? validerSiteEspace(String? valeur) {
  if (valeur == null || valeur.trim().isEmpty) return null;
  final uri = Uri.tryParse(valeur.trim());
  return uri != null &&
          ['http', 'https'].contains(uri.scheme) &&
          uri.host.isNotEmpty
      ? null
      : 'Utilisez une adresse http:// ou https:// valide.';
}

// Latitude et longitude sont facultatives, mais doivent être renseignées ensemble.
String? validerCoordonneeEspace(
  String? valeur,
  int limite,
  String latitude,
  String longitude,
) {
  if (latitude.trim().isEmpty != longitude.trim().isEmpty) {
    return 'Renseignez les deux coordonnées, ou aucune.';
  }
  if (valeur == null || valeur.trim().isEmpty) return null;
  final nombre = double.tryParse(valeur.replaceAll(',', '.'));
  return nombre == null || !nombre.isFinite || nombre.abs() > limite
      ? 'Valeur attendue entre -$limite et $limite.'
      : null;
}

String? validerCoordonneeDepart(String? texte, int maximum) {
  final n = double.tryParse((texte ?? '').trim().replaceAll(',', '.'));
  return n == null || !n.isFinite || n.abs() > maximum
      ? 'Valeur entre -$maximum et $maximum requise.'
      : null;
}

String? validerQuantiteEquipement(String? valeur) =>
    int.tryParse(valeur ?? '') == null || int.parse(valeur!) < 0
    ? 'Saisissez un entier positif ou nul.'
    : null;
