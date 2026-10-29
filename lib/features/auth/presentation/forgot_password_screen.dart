import 'package:flutter/material.dart';

import 'package:coach_app/core/theme/app_theme.dart';
import 'package:coach_app/core/utils/outils.dart';
import 'package:coach_app/core/utils/validateurs.dart';
import 'package:coach_app/core/widgets/bouton_principal.dart';
import 'package:coach_app/core/widgets/en_tete_diagonal.dart';
import 'package:coach_app/features/auth/data/auth_repository.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final formKey = GlobalKey<FormState>();

  AuthRepository authRepository = AuthRepository();

  String email = '';
  String code = '';
  String motDePasse = '';
  String confirmation = '';

  bool codeEnvoye = false;
  bool enCours = false;

  Future<void> valider() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      enCours = true;
    });

    try {
      if (!codeEnvoye) {
        await authRepository.demanderCode(email);

        if (mounted) {
          setState(() {
            codeEnvoye = true;
            enCours = false;
          });

          afficherMessage(context, 'Code envoyé. Consultez votre e-mail.');
        }
      } else {
        await authRepository.reinitialiser(email, code, motDePasse);

        if (mounted) {
          afficherMessage(context, 'Mot de passe modifié.');
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        }
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
            titre: 'Mot de passe oublié',
            icone: Icons.lock_reset,
            retour: true,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    codeEnvoye
                        ? 'Saisissez le code reçu par e-mail et choisissez un nouveau mot de passe.'
                        : 'Saisissez votre e-mail : nous vous enverrons un code.',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppCouleurs.texteSecondaire,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 24),
                    child: TextFormField(
                      enabled: !codeEnvoye,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      onChanged: (value) {
                        email = value;
                      },
                      validator: validerEmail,
                    ),
                  ),
                  if (codeEnvoye) ...[
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Code reçu par e-mail',
                        ),
                        onChanged: (value) {
                          code = value;
                        },
                        validator: validerObligatoire,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      child: TextFormField(
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Nouveau mot de passe',
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
                        obscureText: true,
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
                  ],
                  Container(
                    margin: const EdgeInsets.only(top: 28),
                    child: BoutonPrincipal(
                      texte: codeEnvoye ? 'Valider' : 'Envoyer le code',
                      enChargement: enCours,
                      onPressed: valider,
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