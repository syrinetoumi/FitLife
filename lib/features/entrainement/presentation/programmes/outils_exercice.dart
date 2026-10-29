// ExerciseDB renvoie des noms en minuscules : on met la première lettre en majuscule.
String nomPropre(String texte) {
  if (texte.isEmpty) {
    return texte;
  }
  return texte[0].toUpperCase() + texte.substring(1);
}