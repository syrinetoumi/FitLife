import 'package:flutter/material.dart';

// Une ligne d'information : icône, petit libellé gris, valeur en gras.
Widget ligneInfo(IconData icone, String libelle, String valeur) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Icon(icone, color: Colors.deepPurple),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(left: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  libelle,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                Text(
                  valeur,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
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