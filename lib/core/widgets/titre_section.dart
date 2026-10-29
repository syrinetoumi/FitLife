import 'package:flutter/material.dart';

import 'package:coach_app/core/theme/app_theme.dart';

class TitreSection extends StatelessWidget {
  final String texte;
  final String? actionTexte;
  final VoidCallback? onAction;

  const TitreSection({
    super.key,
    required this.texte,
    this.actionTexte,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            texte.toUpperCase(),
            style: styleTitre.copyWith(fontSize: 26),
          ),
          if (actionTexte != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionTexte!),
            ),
        ],
      ),
    );
  }
}