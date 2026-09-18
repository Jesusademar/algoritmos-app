import 'package:flutter/material.dart';

/// Configuración visual compartida por toda la aplicación.
abstract final class AppTheme {
  static ThemeData get dark =>
      ThemeData(brightness: Brightness.dark, primarySwatch: Colors.indigo);
}
