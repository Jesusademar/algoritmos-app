import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Paints an ultra-realistic, professional bowling pin with studio gloss, depth,
/// and dynamic scaling based on its numerical value.
class BowlingPinPainter extends CustomPainter {
  final int value;
  final int maxValue;
  final Color color;
  final double animationProgress;

  const BowlingPinPainter({
    required this.value,
    required this.maxValue,
    required this.color,
    this.animationProgress = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Factor de escala dinámico según el valor (mínimo 0.75, máximo 1.15)
    final double valueScale = maxValue > 0
        ? 0.75 + (0.4 * (value / maxValue).clamp(0.0, 1.0))
        : 1.0;

    final double w = size.width * valueScale;
    final double h = size.height;
    final double centerX =
        size.width / 2; // Centrado respecto al espacio asignado
    final double maxHeight = (h * 0.85) * valueScale;

    // Trayectoria parabólica (efecto pieza de ajedrez flotante)
    final double liftOffset = math.sin(animationProgress * math.pi) * 35.0;

    // Sombra en el suelo de alta definición y difuminado realista
    final double shadowScale =
        (1.0 - (liftOffset / 50.0)).clamp(0.3, 1.0) * valueScale;
    final double shadowOpacity = (0.4 * (1.0 - (liftOffset / 60.0))).clamp(
      0.05,
      0.35,
    );

    final paintShadow = Paint()
      ..color = Colors.black.withValues(alpha: shadowOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, h - 4),
        width: w * 0.6 * shadowScale,
        height: 8 * shadowScale,
      ),
      paintShadow,
    );

    canvas.save();
    canvas.translate(centerX - (w / 2), h - maxHeight - liftOffset);

    // Trazado elegante y simétrico del pin de boliche
    final pinPath = Path();
    pinPath.moveTo(w * 0.28, maxHeight);
    pinPath.lineTo(w * 0.72, maxHeight);
    pinPath.quadraticBezierTo(
      w * 0.90,
      maxHeight * 0.58,
      w * 0.68,
      maxHeight * 0.35,
    );
    pinPath.quadraticBezierTo(
      w * 0.62,
      maxHeight * 0.2,
      w * 0.64,
      maxHeight * 0.1,
    );
    pinPath.arcToPoint(
      Offset(w * 0.36, maxHeight * 0.1),
      radius: Radius.circular(w * 0.14),
      largeArc: true,
      clockwise: false,
    );
    pinPath.quadraticBezierTo(
      w * 0.38,
      maxHeight * 0.2,
      w * 0.32,
      maxHeight * 0.35,
    );
    pinPath.quadraticBezierTo(w * 0.10, maxHeight * 0.58, w * 0.28, maxHeight);
    pinPath.close();

    // Gradiente de estudio tridimensional (efecto porcelana/cerámica brillante profesional)
    final paintBody = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,
          Colors.white.withValues(alpha: 0.95),
          Colors.grey.shade200,
          Colors.grey.shade400,
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, maxHeight));

    canvas.drawPath(
      pinPath,
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawPath(pinPath, paintBody);

    // Contorno dinámico de estado (con grosor estilizado)
    final paintOutline = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawPath(pinPath, paintOutline);

    // Franjas rojas superiores con brillo sutil
    final stripePaint = Paint()
      ..color = const Color(0xFFE53935)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(w / 2, maxHeight * 0.21),
        width: w * 0.26,
        height: maxHeight * 0.03,
      ),
      stripePaint,
    );

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(w / 2, maxHeight * 0.27),
        width: w * 0.24,
        height: maxHeight * 0.03,
      ),
      stripePaint,
    );

    // Número central perfectamente legible con tipografía moderna
    final textSpan = TextSpan(
      text: '$value',
      style: TextStyle(
        fontFamily: 'Roboto',
        color: const Color(0xFF0D47A1),
        fontSize: (w * 0.28).clamp(11.0, 18.0),
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final double bellyLocalY = maxHeight * 0.62;
    final double textX = (w / 2) - (textPainter.width / 2);
    final double textY = bellyLocalY - (textPainter.height / 2);

    textPainter.paint(canvas, Offset(textX, textY));

    canvas.restore();
  }

  @override
  bool shouldRepaint(BowlingPinPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.color != color ||
        oldDelegate.animationProgress != animationProgress;
  }
}
