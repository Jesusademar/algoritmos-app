import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';

/// Pequeñas vistas de datos, decorativas y sin interacción.
class ModuleIllustration extends StatelessWidget {
  const ModuleIllustration({super.key, required this.id, required this.accent});
  final String id;
  final Color accent;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      height: 96,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.08),
            AppColors.background.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: CustomPaint(painter: _ModulePainter(id, accent)),
    ),
  );
}

class _ModulePainter extends CustomPainter {
  const _ModulePainter(this.id, this.accent);
  final String id;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final line = Paint()
      ..color = accent.withValues(alpha: 0.4)
      ..strokeWidth = 1.5;
    final fill = Paint()..color = accent.withValues(alpha: 0.85);
    void node(Offset point) {
      canvas.drawCircle(
        point,
        11,
        Paint()..color = accent.withValues(alpha: 0.09),
      );
      canvas.drawCircle(point, 7, Paint()..color = AppColors.surfaceMuted);
      canvas.drawCircle(
        point,
        7,
        Paint()
          ..color = accent
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
    }

    if (id == 'sorting') {
      const heights = [24.0, 50.0, 34.0, 64.0, 42.0, 56.0, 70.0];
      for (var i = 0; i < heights.length; i++) {
        final rect = Rect.fromLTWH(
          center.dx - 76 + i * 23,
          83 - heights[i],
          14,
          heights[i],
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                accent.withValues(alpha: 0.55 + i * 0.06),
                accent.withValues(alpha: 0.18),
              ],
            ).createShader(rect),
        );
      }
    } else if (id == 'assignment' || id == 'transport') {
      for (var row = 0; row < 3; row++) {
        for (var col = 0; col < 5; col++) {
          final rect = Rect.fromLTWH(
            center.dx - 77 + col * 32,
            15 + row * 23,
            26,
            17,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(3)),
            Paint()
              ..color = (col == row || (id == 'transport' && col == row + 1))
                  ? accent.withValues(alpha: 0.65)
                  : AppColors.surfaceMuted,
          );
        }
      }
    } else if (id == 'binary-tree') {
      final points = [
        Offset(center.dx, 18),
        Offset(center.dx - 45, 46),
        Offset(center.dx + 45, 46),
        Offset(center.dx - 70, 76),
        Offset(center.dx - 20, 76),
        Offset(center.dx + 70, 76),
      ];
      for (final pair in [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5)]) {
        canvas.drawLine(points[pair.$1], points[pair.$2], line);
      }
      for (final point in points) {
        node(point);
      }
    } else {
      final points = [
        Offset(center.dx - 76, 49),
        Offset(center.dx - 30, 22),
        Offset(center.dx - 25, 75),
        Offset(center.dx + 30, 22),
        Offset(center.dx + 75, 49),
      ];
      for (final pair in [(0, 1), (0, 2), (1, 3), (2, 3), (3, 4), (2, 4)]) {
        canvas.drawLine(points[pair.$1], points[pair.$2], line);
      }
      if (id == 'johnson') {
        canvas.drawLine(points[0], points[1], fill..strokeWidth = 2.5);
        canvas.drawLine(points[1], points[3], fill);
        canvas.drawLine(points[3], points[4], fill);
      }
      for (final point in points) {
        node(point);
      }
    }
  }

  @override
  bool shouldRepaint(_ModulePainter oldDelegate) =>
      id != oldDelegate.id || accent != oldDelegate.accent;
}
