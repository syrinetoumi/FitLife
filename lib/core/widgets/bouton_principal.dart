import 'package:flutter/material.dart';

class BoutonPrincipal extends StatelessWidget {
  final String texte;
  final VoidCallback? onPressed;
  final bool enChargement;
  final bool avecFleche;

  const BoutonPrincipal({
    super.key,
    required this.texte,
    required this.onPressed,
    this.enChargement = false,
    this.avecFleche = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: enChargement ? null : onPressed,
        child: enChargement
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(texte, style: const TextStyle(fontSize: 17)),
            if (avecFleche)
              Container(
                margin: const EdgeInsets.only(left: 8),
                child: const Icon(Icons.arrow_forward, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}