String? validerObligatoire(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Champ obligatoire';
  }

  return null;
}

String? validerEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'E-mail obligatoire';
  }

  RegExp modele = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  if (!modele.hasMatch(value.trim())) {
    return 'E-mail invalide';
  }

  return null;
}

String? validerMotDePasse(String? value) {
  if (value == null || value.length < 8) {
    return '8 caractères minimum';
  }

  return null;
}

String? validerTelephoneFacultatif(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }

  String chiffres = value.replaceAll(RegExp(r'[^0-9]'), '');

  if (chiffres.length < 8 || chiffres.length > 15) {
    return 'Numéro invalide';
  }

  return null;
}

// "10/11/2003" -> DateTime (années 1900 à aujourd'hui).
DateTime? lireDateNaissance(String texte) {
  List<String> parties = texte.trim().split('/');

  if (parties.length != 3) {
    return null;
  }

  int? jour = int.tryParse(parties[0]);
  int? mois = int.tryParse(parties[1]);
  int? annee = int.tryParse(parties[2]);

  if (jour == null || mois == null || annee == null) {
    return null;
  }

  if (annee < 1900) {
    return null;
  }

  DateTime date = DateTime(annee, mois, jour);

  if (date.day != jour || date.month != mois || date.year != annee) {
    return null;
  }

  if (date.isAfter(DateTime.now())) {
    return null;
  }

  return date;
}

String? validerDateNaissance(String? value) {
  if (lireDateNaissance(value ?? '') == null) {
    return 'Date invalide (jj/mm/aaaa)';
  }

  return null;
}