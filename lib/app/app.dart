import 'package:flutter/material.dart';

import '../screens/dashboard_screen.dart';
import 'app_theme.dart';

/// Raíz de la aplicación.
///
/// Mantiene la configuración global fuera de `main.dart`, de modo que el
/// punto de entrada sea pequeño y esta clase pueda usarse en las pruebas.
class LogiVerseApp extends StatelessWidget {
  const LogiVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LogiVerse Core',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const DashboardScreen(),
    );
  }
}
