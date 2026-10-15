import 'package:flutter/material.dart';

import 'package:coach_app/core/theme/app_theme.dart';
import 'package:coach_app/core/utils/outils.dart';
import 'package:coach_app/core/utils/validateurs.dart';
import 'package:coach_app/core/widgets/bouton_principal.dart';
import 'package:coach_app/core/widgets/en_tete_diagonal.dart';
import 'package:coach_app/features/auth/data/auth_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();

  AuthRepository authRepository = AuthRepository();

  String email = '';
  String motDePasse = '';
  bool masquer = true;
  bool enCours = false;

  Future<void> seConnecter() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      enCours = true;
    });

    try {
      await authRepository.connecter(email, motDePasse);

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const EnTeteDiagonal(
            titre: 'Connexion',
            icone: Icons.fitness_center,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Connectez-vous pour retrouver vos programmes et vos séances.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppCouleurs.texteSecondaire,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 24),
                    child: TextFormField(
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      onChanged: (value) {
                        email = value;
                      },
                      validator: validerEmail,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    child: TextFormField(
                      obscureText: masquer,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Mot de passe obligatoire';
                        }

                        return null;
                      },
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/mot-de-passe-oublie');
                      },
                      child: const Text('Mot de passe oublié ?'),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    child: BoutonPrincipal(
                      texte: 'Se connecter',
                      enChargement: enCours,
                      onPressed: seConnecter,
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/inscription');
                      },
                      child: const Text('Pas encore de compte ? Créer un compte'),
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