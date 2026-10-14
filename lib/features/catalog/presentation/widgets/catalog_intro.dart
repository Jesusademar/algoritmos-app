import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';

class CatalogIntro extends StatelessWidget {
  const CatalogIntro({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TU ZONA DE EXPLORACIÓN',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Selecciona un Algoritmo',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Aprende haciendo. Crea tus datos, prueba ideas y descubre lo que pasa en cada paso.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.6),
              ),
            ],
          ),
        ),
        if (constraints.maxWidth >= 760) ...[
          const SizedBox(width: 28),
          const ExcludeSemantics(
            child: SizedBox(
              width: 180,
              height: 140,
              child: CustomPaint(
                painter: _OrbitPainter(),
                child: Center(
                  child: Icon(
                    Icons.rocket_launch_rounded,
                    color: AppColors.primary,
                    size: 42,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    canvas.drawCircle(
      center,
      44,
      Paint()..color = AppColors.primary.withValues(alpha: 0.10),
    );
    canvas.drawCircle(
      center,
      35,
      Paint()..color = AppColors.primary.withValues(alpha: 0.12),
    );
    final colors = [AppColors.primary, AppColors.sorting, AppColors.graph];
    for (var i = 0; i < 3; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i * math.pi / 3 - 0.4);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 152, height: 62),
        Paint()
          ..color = colors[i].withValues(alpha: 0.38)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      canvas.drawCircle(const Offset(76, 0), 4, Paint()..color = colors[i]);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter oldDelegate) => false;
}
