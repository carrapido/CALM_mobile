import 'package:flutter/material.dart';

import 'screens/inicio_sesion_screen.dart';
import 'themes/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calm Mobil',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const InicioSesionScreen(),
    );
  }
}
