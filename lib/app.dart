import 'package:flutter/material.dart';

class CoachApp extends StatelessWidget {
  const CoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'COACH',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.deepOrange, useMaterial3: true),
      home: const Scaffold(
        body: Center(child: Text('COACH - connecté à Supabase')),
      ),
    );
  }
}