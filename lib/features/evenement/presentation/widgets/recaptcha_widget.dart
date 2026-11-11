import 'package:flutter/material.dart';
import '../../data/services/recaptcha_service.dart';

// ============================================================================
// 📌 QUESTION PROF : WIDGET DE SÉCURITÉ GOOGLE reCAPTCHA (IHM)
// Reproduit fidèlement la boîte officielle Google reCAPTCHA v2 ("Je ne suis pas un robot")
// Déclenche un appel réseau HTTP POST en temps réel vers les serveurs de Google.
// ============================================================================

class RecaptchaWidget extends StatefulWidget {
  final Function(bool estValide) onVerifie;

  const RecaptchaWidget({
    super.key,
    required this.onVerifie,
  });

  @override
  State<RecaptchaWidget> createState() => _RecaptchaWidgetState();
}

class _RecaptchaWidgetState extends State<RecaptchaWidget> {
  final RecaptchaService recaptchaService = RecaptchaService();

  bool estVerifie = false;
  bool verificationEnCours = false;
  String? messageErreur;

  Future<void> lancerVerification() async {
    if (estVerifie || verificationEnCours) return;

    setState(() {
      verificationEnCours = true;
      messageErreur = null;
    });

    try {
      // 📌 Appel réseau HTTP POST vers les serveurs de Google
      final resultat = await recaptchaService.verifierCaptcha();

      if (!mounted) return;

      if (resultat.succes) {
        setState(() {
          estVerifie = true;
          verificationEnCours = false;
        });
        widget.onVerifie(true);
      } else {
        setState(() {
          verificationEnCours = false;
          messageErreur = resultat.message;
        });
        widget.onVerifie(false);
      }
    } catch (erreur) {
      if (!mounted) return;
      setState(() {
        verificationEnCours = false;
        messageErreur = 'Erreur réseau : $erreur';
      });
      widget.onVerifie(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 2,
          color: Colors.grey.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(
              color: estVerifie ? Colors.green.shade400 : Colors.grey.shade300,
              width: estVerifie ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            onTap: estVerifie ? null : lancerVerification,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Partie gauche : Case à cocher + Texte
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: estVerifie ? Colors.green : Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: estVerifie ? Colors.green : Colors.grey.shade500,
                            width: 2,
                          ),
                        ),
                        child: verificationEnCours
                            ? const Padding(
                          padding: EdgeInsets.all(4),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.blue,
                          ),
                        )
                            : estVerifie
                            ? const Icon(
                          Icons.check,
                          size: 20,
                          color: Colors.white,
                        )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Text(
                        estVerifie
                            ? 'Humain vérifié'
                            : verificationEnCours
                            ? 'Vérification Google...'
                            : 'Je ne suis pas un robot',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: estVerifie ? Colors.green.shade800 : Colors.black87,
                        ),
                      ),
                    ],
                  ),

                  // Partie droite : Logo et marque Google reCAPTCHA
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.network(
                        'https://www.gstatic.com/recaptcha/api2/logo_48.png',
                        width: 30,
                        height: 30,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.security,
                          color: Colors.blue,
                          size: 26,
                        ),
                      ),
                      const Text(
                        'reCAPTCHA',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const Text(
                        'Confidentialité - Conditions',
                        style: TextStyle(
                          fontSize: 7,
                          color: Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (messageErreur != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 6),
            child: Text(
              messageErreur!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}