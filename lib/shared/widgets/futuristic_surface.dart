import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';

/// Atmósfera de luz, estrellas y retícula; toda la decoración ignora los gestos.
class FuturisticBackground extends StatelessWidget {
  const FuturisticBackground({
    super.key,
    required this.child,
    this.accent = AppColors.primary,
    this.showGrid = true,
  });

  final Widget child;
  final Color accent;
  final bool showGrid;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      IgnorePointer(
        child: RepaintBoundary(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.background,
              gradient: RadialGradient(
                center: const Alignment(-0.85, -0.7),
                radius: 1.3,
                colors: [
                  Color.alphaBlend(
                    accent.withValues(alpha: 0.16),
                    AppColors.background,
                  ),
                  AppColors.background,
                ],
              ),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(1, 0.1),
                  radius: 0.9,
                  colors: [
                    AppColors.graph.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
              child: showGrid
                  ? CustomPaint(painter: _SpacePainter(accent))
                  : const SizedBox.expand(),
            ),
          ),
        ),
      ),
      child,
    ],
  );
}

class FuturisticPanel extends StatelessWidget {
  const FuturisticPanel({
    super.key,
    required this.child,
    this.accent = AppColors.primary,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final Color accent;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.alphaBlend(accent.withValues(alpha: 0.13), AppColors.surface),
          AppColors.surface.withValues(alpha: 0.97),
        ],
      ),
      borderRadius: BorderRadius.circular(AppLayout.radius),
      border: Border.all(color: accent.withValues(alpha: 0.28)),
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: 0.06),
          blurRadius: 28,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.14),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

class _SpacePainter extends CustomPainter {
  const _SpacePainter(this.accent);
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = accent.withValues(alpha: 0.045)
      ..strokeWidth = 0.6;
    for (double x = 0; x < size.width; x += 56) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 56) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    // Más estrellas, con halos y destellos que se distinguen del fondo.
    final count = (size.width * size.height / 8500).round().clamp(48, 150);
    for (var index = 0; index < count; index++) {
      final point = Offset(
        ((index * 173 + 53) % 997) / 997 * size.width,
        ((index * 113 + 37) % 541) / 541 * size.height,
      );
      final bright = index % 7 == 0;
      final color = index % 3 == 0 ? accent : AppColors.text;
      canvas.drawCircle(
        point,
        bright ? 5 : 2.5,
        Paint()..color = color.withValues(alpha: bright ? 0.10 : 0.04),
      );
      canvas.drawCircle(
        point,
        bright ? 1.9 : 1.1,
        Paint()..color = color.withValues(alpha: bright ? 0.85 : 0.45),
      );
      if (bright) {
        final sparkle = Paint()
          ..color = color.withValues(alpha: 0.55)
          ..strokeWidth = 0.8;
        canvas.drawLine(
          point - const Offset(4, 0),
          point + const Offset(4, 0),
          sparkle,
        );
        canvas.drawLine(
          point - const Offset(0, 4),
          point + const Offset(0, 4),
          sparkle,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_SpacePainter oldDelegate) => oldDelegate.accent != accent;
}
