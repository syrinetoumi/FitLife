import 'package:flutter/material.dart';

// Carte avec une photo de fond, le titre écrit dessus et un bouton "Voir plus".
// Sans onVoirPlus, elle sert d'en-tête dans les écrans de détail.
class CarteImage extends StatelessWidget {
  final String titre;
  final String? sousTitre;
  final String? cheminImage; // photo dans assets/images/...
  final List<Color> couleurs; // dégradé si la photo n'existe pas
  final IconData icone;
  final Widget? badge;
  final double hauteur;
  final VoidCallback? onVoirPlus;

  const CarteImage({
    super.key,
    required this.titre,
    required this.couleurs,
    required this.icone,
    this.sousTitre,
    this.cheminImage,
    this.badge,
    this.hauteur = 190,
    this.onVoirPlus,
  });

  Widget fondDegrade() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: couleurs,
        ),
      ),
      child: Center(
        child: Icon(
          icone,
          size: 90,
          color: Colors.white.withValues(alpha: 0.25),
        ),
      ),
    );
  }

  Widget fond() {
    if (cheminImage == null) {
      return fondDegrade();
    }

    return Image.asset(
      cheminImage!,
      fit: BoxFit.cover,
      // Photo absente : on affiche le dégradé.
      errorBuilder: (context, erreur, trace) {
        return fondDegrade();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Même police que les titres de l'appli si le thème la définit.
    TextStyle styleTitre = (Theme.of(context).appBarTheme.titleTextStyle ??
        const TextStyle(
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.bold,
        ))
        .copyWith(color: Colors.white, fontSize: 28);

    return Container(
      height: hauteur,
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            fond(),

            // Voile sombre pour que le texte reste lisible.
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),

            if (badge != null)
              Positioned(
                top: 10,
                right: 10,
                child: badge!,
              ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    titre.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: styleTitre,
                  ),
                  if (sousTitre != null)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      child: Text(
                        sousTitre!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  if (onVoirPlus != null)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                        ),
                        onPressed: onVoirPlus,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Voir plus'),
                            Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}