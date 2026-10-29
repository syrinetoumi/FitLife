import 'package:flutter/material.dart';

import 'package:coach_app/core/utils/alertes.dart';
import 'package:coach_app/features/entrainement/presentation/widgets/carte_image.dart';
import 'package:coach_app/features/entrainement/presentation/widgets/ligne_info.dart';
import '../../data/models/categorie.dart';
import '../../data/repositories/categorie_repository.dart';
import '../widgets/apparence_evenement.dart';
import 'categorie_form_screen.dart';

class CategorieDetailScreen extends StatefulWidget {
  final Categorie categorie;

  const CategorieDetailScreen({super.key, required this.categorie});

  @override
  State<CategorieDetailScreen> createState() => _CategorieDetailScreenState();
}

class _CategorieDetailScreenState extends State<CategorieDetailScreen> {
  CategorieRepository categorieRepository = CategorieRepository();

  Categorie get categorie => widget.categorie;

  Future<void> modifier() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategorieFormScreen(categorie: categorie),
      ),
    );

    // On revient à la liste, qui se recharge.
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> supprimer() async {
    bool confirme = await confirmerAction(
      context,
      titre: 'Supprimer',
      message: 'Supprimer la catégorie "${categorie.nom}" ?',
    );

    if (!confirme) {
      return;
    }

    try {
      await categorieRepository.supprimer(categorie.idCategorie);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (erreur) {
      if (mounted) {
        afficherAlerteErreur(
          context,
          titre: 'Suppression impossible',
          message: '$erreur',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catégorie')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CarteImage(
            titre: categorie.nom,
            sousTitre: categorie.niveau.name.toUpperCase(),
            cheminImage: imageNiveau(categorie.niveau),
            couleurs: couleursNiveau(categorie.niveau),
            icone: iconeNiveau(categorie.niveau),
            hauteur: 200,
          ),
          Card(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                children: [
                  ligneInfo(
                    Icons.cake,
                    'Âge minimum',
                    '${categorie.ageMin} ans',
                  ),
                  const Divider(height: 1),
                  ligneInfo(
                    Icons.cake_outlined,
                    'Âge maximum',
                    '${categorie.ageMax} ans',
                  ),
                  const Divider(height: 1),
                  ligneInfo(
                    Icons.signal_cellular_alt,
                    'Niveau',
                    categorie.niveau.name.toUpperCase(),
                  ),
                ],
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: modifier,
                    child: const Text('Modifier'),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 10),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: supprimer,
                      child: const Text('Supprimer'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}