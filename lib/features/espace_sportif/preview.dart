import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'presentation/espaces_sportifs_screen.dart';

void main() => runApp(const ApercuEspacesSportifs());

class ApercuEspacesSportifs extends StatelessWidget {
  const ApercuEspacesSportifs({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'FitLife · Espaces sportifs',
    debugShowCheckedModeBanner: false,
    theme: construireTheme(),
    routes: {'/': (context) => const EspacesSportifsScreen()},
  );
}
