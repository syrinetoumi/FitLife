import 'enums.dart';
class Exercice {
  final int? id;
  final String? externalId;
  final String nom;
  final String? description;
  final String? muscle;
  final Niveau? niveau;
  final String? equipement;
  final String? imageUrl;
  final String? gifUrl;
  final String? instructions;

  Exercice({
    this.id, this.externalId, required this.nom, this.description,
    this.muscle, this.niveau, this.equipement, this.imageUrl,
    this.gifUrl, this.instructions,
  });

  factory Exercice.fromJson(Map<String, dynamic> j) => Exercice(
    id: j['id_exercice'],
    externalId: j['external_id'],
    nom: j['nom'],
    description: j['description'],
    muscle: j['muscle'],
    niveau: j['niveau'] != null ? Niveau.values.byName(j['niveau']) : null,
    equipement: j['equipement'],
    imageUrl: j['image_url'],
    gifUrl: j['gif_url'],
    instructions: j['instructions'],
  );

  Map<String, dynamic> toJson() => {
    'external_id': externalId,
    'nom': nom,
    'description': description,
    'muscle': muscle,
    'niveau': niveau?.name,
    'equipement': equipement,
    'image_url': imageUrl,
    'gif_url': gifUrl,
    'instructions': instructions,
  };
}