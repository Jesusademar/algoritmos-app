import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';

/// Identidad de cada módulo, con una superficie luminosa y el símbolo legible.
class NeonIcon extends StatelessWidget {
  const NeonIcon({
    super.key,
    required this.icon,
    this.accent = AppColors.primary,
    this.size = 24,
    this.padding = 12,
  });

  final IconData icon;
  final Color accent;
  final double size;
  final double padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accent.withValues(alpha: 0.24),
          accent.withValues(alpha: 0.06),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: accent.withValues(alpha: 0.4)),
      boxShadow: [
        BoxShadow(color: accent.withValues(alpha: 0.10), blurRadius: 18),
      ],
    ),
    child: Icon(icon, color: accent, size: size),
  );
}
