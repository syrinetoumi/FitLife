import 'package:supabase_flutter/supabase_flutter.dart';

// Le dossier models/ est juste à côté : on remonte d'un cran (..)
import '../models/categorie.dart';

class CategorieRepository {
  final SupabaseClient client = Supabase.instance.client;

  Future<void> ajouter(Categorie categorie) async {
    await client.from('categories').insert(categorie.toMap());
  }

  Future<List<Categorie>> getCategories() async {
    final lignes = await client.from('categories').select().order('nom');

    List<Categorie> categories = [];

    for (var ligne in lignes) {
      categories.add(Categorie.fromMap(ligne));
    }

    return categories;
  }

  Future<List<Categorie>> getCategoriesByEvenement(String idEvenement) async {
    final lignes = await client
        .from('categories')
        .select()
        .eq('id_evenement', idEvenement)
        .order('nom');

    List<Categorie> categories = [];

    for (var ligne in lignes) {
      categories.add(Categorie.fromMap(ligne));
    }

    return categories;
  }

  Future<void> modifier(Categorie categorie) async {
    await client
        .from('categories')
        .update(categorie.toMap())
        .eq('id', categorie.idCategorie);
  }

  Future<void> supprimer(String id) async {
    await client.from('categories').delete().eq('id', id);
  }
}
