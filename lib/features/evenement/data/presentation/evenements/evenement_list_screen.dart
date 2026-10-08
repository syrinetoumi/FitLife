import 'package:flutter/material.dart';

import '../../models/evenement.dart';
import '../../repositories/evenement_repository.dart';
import '../../../../../core/utils/outils.dart';
import 'evenement_form_screen.dart';

class EvenementListScreen extends StatefulWidget {
  // integre = true : l'écran est affiché dans un TabBarView ou sous un
  // BottomNavigationBar, donc sans son propre Scaffold/AppBar.
  final bool integre;

  const EvenementListScreen({
    super.key,
    this.integre = false,
  });

  @override
  State<EvenementListScreen> createState() => _EvenementListScreenState();
}

class _EvenementListScreenState extends State<EvenementListScreen> {
  EvenementRepository evenementRepository = EvenementRepository();

  List<Evenement> evenements = [];

  @override
  void initState() {
    super.initState();
    chargerEvenements();
  }

  Future<void> chargerEvenements() async {
    try {
      List<Evenement> resultat = await evenementRepository.getEvenements();

      if (!mounted) {
        return;
      }

      setState(() {
        evenements = resultat;
      });
    } catch (erreur) {
      if (mounted) {
        afficherMessage(context, 'Erreur de chargement : $erreur');
      }
    }
  }

  Future<void> supprimer(String id) async {
    try {
      await evenementRepository.supprimer(id);
      await chargerEvenements();
    } catch (erreur) {
      if (mounted) {
        afficherMessage(context, 'Suppression impossible : $erreur');
      }
    }
  }

  Future<void> ouvrirFormulaire(Evenement? evenement) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EvenementFormScreen(evenement: evenement),
      ),
    );

    chargerEvenements();
  }

  Widget construireListe() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      // +1 : la première ligne est le bouton "Ajouter".
      itemCount: evenements.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: ElevatedButton(
              onPressed: () {
                ouvrirFormulaire(null);
              },
              child: const Text('Ajouter un événement'),
            ),
          );
        }

        Evenement evenement = evenements[index - 1];

        return Card(
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    evenement.nom,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                Text(evenement.description),
                Text('Lieu : ${evenement.lieu}'),
                Text('Début : ${afficherDate(evenement.dateDebut)}'),
                Text('Heure : ${evenement.heureDebut}'),
                Text('Fin : ${afficherDate(evenement.dateFin)}'),
                Text('Capacité : ${evenement.capacite}'),
                Text('Prix : ${evenement.prix.toStringAsFixed(2)} DT'),
                Text('Type : ${evenement.type.name.toUpperCase()}'),
                Text('Statut : ${evenement.statut.name.toUpperCase()}'),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          ouvrirFormulaire(evenement);
                        },
                        child: const Text('Modifier'),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 10),
                        child: ElevatedButton(
                          onPressed: () {
                            supprimer(evenement.idEvenement);
                          },
                          child: const Text('Supprimer'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.integre) {
      return construireListe();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Événements'),
      ),
      drawer: construireDrawer(context),
      body: construireListe(),
    );
  }
}
