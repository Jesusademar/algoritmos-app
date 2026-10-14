import 'package:flutter/material.dart';

import 'package:app_grafos/features/sorting/presentation/widgets/bowling_pin_painter.dart';

class BowlingPinWidget extends StatelessWidget {
  final int value;
  final int maxValue;
  final Color color;
  final Duration animationDuration;

  const BowlingPinWidget({
    super.key,
    required this.value,
    required this.maxValue,
    required this.color,
    this.animationDuration = const Duration(milliseconds: 400),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: animationDuration,
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        // Animación de desplazamiento lateral + elevación suave al intercambiarse
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0.0, 0.3), // Viene levemente desde abajo
          end: Offset.zero,
        ).animate(animation);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offsetAnimation, child: child),
        );
      },
      // Usamos el value como clave para que Flutter sepa exactamente cuándo una pieza cambia de lugar o valor
      child: CustomPaint(
        key: ValueKey<int>(value),
        painter: BowlingPinPainter(
          value: value,
          maxValue: maxValue,
          color: color,
          animationProgress: 1.0,
        ),
        size: const Size(55, 130),
      ),
    );
  }
}
