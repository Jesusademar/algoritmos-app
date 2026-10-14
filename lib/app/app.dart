import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/features/dashboard/presentation/screens/dashboard_screen.dart';

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
