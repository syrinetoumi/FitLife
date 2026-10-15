import 'package:flutter/material.dart';

import 'package:coach_app/core/theme/app_theme.dart';

class _DiagonaleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path chemin = Path();
    chemin.lineTo(size.width, 0);
    chemin.lineTo(size.width, size.height - 45);
    chemin.lineTo(0, size.height);
    chemin.close();
    return chemin;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class EnTeteDiagonal extends StatelessWidget {
  final String titre;
  final IconData? icone;
  final bool retour;
  final double hauteur;

  const EnTeteDiagonal({
    super.key,
    required this.titre,
    this.icone,
    this.retour = false,
    this.hauteur = 220,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _DiagonaleClipper(),
      child: Container(
        height: hauteur,
        width: double.infinity,
        color: AppCouleurs.principale,
        child: Stack(
          children: [
            if (icone != null)
              Positioned(
                right: 24,
                top: hauteur * 0.25,
                child: Icon(icone, size: 80, color: Colors.white),
              ),
            Positioned(
              left: 24,
              right: 120,
              bottom: 70,
              child: Transform.rotate(
                angle: -0.09,
                child: Text(
                  titre.toUpperCase(),
                  style: styleTitre.copyWith(fontSize: 38, color: Colors.white),
                ),
              ),
            ),
            if (retour)
              Positioned(
                left: 8,
                top: MediaQuery.of(context).padding.top + 4,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}