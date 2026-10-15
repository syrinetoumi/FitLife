import 'package:flutter/material.dart';

import 'package:coach_app/core/theme/app_theme.dart';
import 'package:coach_app/core/utils/outils.dart';
import 'package:coach_app/core/utils/validateurs.dart';
import 'package:coach_app/core/widgets/bouton_principal.dart';
import 'package:coach_app/core/widgets/en_tete_diagonal.dart';
import 'package:coach_app/core/widgets/titre_section.dart';
import 'package:coach_app/features/auth/data/auth_repository.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formKey = GlobalKey<FormState>();

  AuthRepository authRepository = AuthRepository();

  String nom = '';
  String prenom = '';
  String dateTexte = '';
  String telephone = '';
  String email = '';
  String motDePasse = '';
  String confirmation = '';

  String genre = ''; // FEMME ou HOMME
  String role = 'ATHLETE';

  bool masquer = true;
  bool enCours = false;

  // Valeur enregistrée en base : libellé affiché.
  final Map<String, String> roles = {
    'ATHLETE': 'Athlète',
    'COACH': 'Coach',
    'NUTRITIONNISTE': 'Nutritionniste',
    'GESTIONNAIRE_ESPACE': 'Gestionnaire d’espace',
  };

  Future<void> creerCompte() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (genre.isEmpty) {
      afficherMessage(context, 'Choisissez votre genre.');
      return;
    }

    DateTime? naissance = lireDateNaissance(dateTexte);

    if (naissance == null) {
      afficherMessage(context, 'Date de naissance invalide.');
      return;
    }

    setState(() {
      enCours = true;
    });

    try {
      bool connecte = await authRepository.inscrire(
        email: email,
        motDePasse: motDePasse,
        donnees: {
          'nom': nom.trim(),
          'prenom': prenom.trim(),
          'genre': genre,
          'date_naissance': naissance.toIso8601String().substring(0, 10),
          'telephone': telephone.trim(),
          'role': role,
        },
      );

      if (!mounted) {
        return;
      }

      if (connecte) {
        Navigator.pushReplacementNamed(context, '/');
      } else {
        afficherMessage(
          context,
          'Compte créé. Confirmez votre e-mail puis connectez-vous.',
        );
        Navigator.pushReplacementNamed(context, '/connexion');
      }
    } catch (erreur) {
      if (mounted) {
        setState(() {
          enCours = false;
        });

        afficherMessage(context, messageErreurAuth(erreur));
      }
    }
  }

  Widget boutonGenre(String valeur, String libelle) {
    bool choisi = genre == valeur;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            genre = valeur;
          });
        },
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: choisi ? AppCouleurs.principale : Colors.white,
            border: Border.all(color: Colors.grey),
          ),
          child: Text(
            libelle,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: choisi ? Colors.white : AppCouleurs.texte,
            ),
          ),
        ),
      ),
    );
  }

  Widget ligneRole(String valeur, String libelle) {
    bool choisi = role == valeur;

    return InkWell(
      onTap: () {
        setState(() {
          role = valeur;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: choisi ? AppCouleurs.principale : Colors.white,
          border: Border.all(color: Colors.grey),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                libelle,
                style: TextStyle(
                  fontSize: 16,
                  color: choisi ? Colors.white : AppCouleurs.texte,
                ),
              ),
            ),
            if (choisi) const Icon(Icons.check, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget champ(String libelle, void Function(String) surChangement,
      String? Function(String?)? validateur,
      {TextInputType type = TextInputType.text}) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: TextFormField(
        keyboardType: type,
        decoration: InputDecoration(labelText: libelle),
        onChanged: surChangement,
        validator: validateur,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: EdgeInsets.zero,
        // Garde tous les champs construits pour la validation.
        cacheExtent: 3000,
        children: [
          const EnTeteDiagonal(
            titre: 'Bienvenue',
            icone: Icons.waving_hand,
            retour: true,
            hauteur: 200,
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bienvenue dans la communauté FitLife ! Faisons rapidement connaissance.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppCouleurs.texteSecondaire,
                    ),
                  ),
                  champ('Nom', (v) => nom = v, validerObligatoire),
                  champ('Prénom', (v) => prenom = v, validerObligatoire),
                  const TitreSection(texte: 'Genre'),
                  Row(
                    children: [
                      boutonGenre('FEMME', 'FEMME'),
                      boutonGenre('HOMME', 'HOMME'),
                    ],
                  ),
                  champ(
                    'Date de naissance (jj/mm/aaaa)',
                        (v) => dateTexte = v,
                    validerDateNaissance,
                    type: TextInputType.datetime,
                  ),
                  champ(
                    'Téléphone (facultatif)',
                        (v) => telephone = v,
                    validerTelephoneFacultatif,
                    type: TextInputType.phone,
                  ),
                  const TitreSection(texte: 'Je suis'),
                  for (String cle in roles.keys) ligneRole(cle, roles[cle]!),
                  const TitreSection(texte: 'Compte'),
                  champ(
                    'E-mail',
                        (v) => email = v,
                    validerEmail,
                    type: TextInputType.emailAddress,
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    child: TextFormField(
                      obscureText: masquer,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe (8 caractères minimum)',
                        suffixIcon: IconButton(
                          icon: Icon(
                            masquer ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              masquer = !masquer;
                            });
                          },
                        ),
                      ),
                      onChanged: (value) {
                        motDePasse = value;
                      },
                      validator: validerMotDePasse,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    child: TextFormField(
                      obscureText: masquer,
                      decoration: const InputDecoration(
                        labelText: 'Confirmer le mot de passe',
                      ),
                      onChanged: (value) {
                        confirmation = value;
                      },
                      validator: (value) {
                        if (value != motDePasse) {
                          return 'Les mots de passe sont différents';
                        }

                        return null;
                      },
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 28),
                    child: BoutonPrincipal(
                      texte: 'Créer mon compte',
                      enChargement: enCours,
                      onPressed: creerCompte,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}