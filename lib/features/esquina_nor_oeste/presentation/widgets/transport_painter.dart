import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/shared/graph_editor/geometry/offset_geometry.dart';
import 'package:app_grafos/shared/domain/mathematical_procedure.dart';
import 'package:app_grafos/shared/graph_editor/models/conexion.dart';
import 'package:app_grafos/shared/graph_editor/models/nodo.dart';

class NorOestePainter extends CustomPainter {
  final List<Nodo> nodos;
  final List<Conexion> conexiones;
  final Nodo? nodoOrigen;
  final Map<String, int> ofertas;
  final Map<String, int> demandas;
  final Map<(String, String), num> optimalRoutes;

  NorOestePainter(
    this.nodos,
    this.conexiones,
    this.nodoOrigen,
    this.ofertas,
    this.demandas, {
    this.optimalRoutes = const {},
  });

  @override
  void paint(Canvas canvas, Size size) {
    final nodesById = {for (final node in nodos) node.id: node};
    // Las rutas óptimas se pintan al final para conservar el brillo en cruces.
    for (final optimalPass in [false, true]) {
      for (final conexion in conexiones) {
        final quantity = optimalRoutes[(conexion.nodoA, conexion.nodoB)];
        final isOptimal = quantity != null && quantity > 0;
        if (isOptimal != optimalPass) continue;
        final from = nodesById[conexion.nodoA];
        final to = nodesById[conexion.nodoB];
        if (from == null || to == null) continue;
        final direction = (to.posicion - from.posicion).normalize();
        final start = from.posicion + direction * 26;
        final end = to.posicion - direction * 26;
        if (isOptimal) {
          for (final layer in <(Color, double)>[
            (AppColors.success.withValues(alpha: 0.35), 14),
            (AppColors.success.withValues(alpha: 0.8), 8),
            (AppColors.text, 3.5),
          ]) {
            canvas.drawLine(
              start,
              end,
              Paint()
                ..color = layer.$1
                ..strokeWidth = layer.$2
                ..style = PaintingStyle.stroke
                ..strokeCap = StrokeCap.round,
            );
          }
        } else {
          canvas.drawLine(
            start,
            end,
            Paint()
              ..color = optimalRoutes.isEmpty
                  ? conexion.color
                  : conexion.color.withValues(alpha: 0.3)
              ..strokeWidth = 2.5
              ..style = PaintingStyle.stroke,
          );
        }
        final center = (start + end) / 2;
        final label = TextPainter(
          text: TextSpan(
            text: isOptimal
                ? ' C: ${conexion.peso} · Q: ${mathNumber(quantity)} '
                : ' C: ${conexion.peso} ',
            style: TextStyle(
              fontFamily: 'Roboto',
              color: isOptimal ? AppColors.successText : AppColors.text,
              fontSize: isOptimal ? 12 : 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final background = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center,
            width: label.width + 6,
            height: label.height + 4,
          ),
          const Radius.circular(4),
        );
        canvas.drawRRect(
          background,
          Paint()
            ..color = isOptimal ? AppColors.successSoft : AppColors.surface,
        );
        canvas.drawRRect(
          background,
          Paint()
            ..color = isOptimal ? AppColors.success : AppColors.border
            ..style = PaintingStyle.stroke,
        );
        label.paint(canvas, center - Offset(label.width / 2, label.height / 2));
      }
    }

    for (var nodo in nodos) {
      final isOrigen = nodoOrigen?.id == nodo.id;
      final isO =
          nodos.isNotEmpty &&
          nodo.posicion.dx <=
              (nodos.map((n) => n.posicion.dx).reduce((a, b) => a + b) /
                  nodos.length);
      final etiquetaVal = isO
          ? 'O:${ofertas[nodo.id] ?? 10}'
          : 'D:${demandas[nodo.id] ?? 10}';

      final paintNodo = Paint()
        ..color = isOrigen ? AppColors.successSoft : AppColors.surface
        ..style = PaintingStyle.fill;
      final paintBorde = Paint()
        ..color = isOrigen ? AppColors.success : AppColors.textMuted
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawCircle(nodo.posicion, 24, paintNodo);
      canvas.drawCircle(nodo.posicion, 24, paintBorde);

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${nodo.nombre}\n($etiquetaVal)',
          style: const TextStyle(
            fontFamily: 'Roboto',
            color: AppColors.text,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();

      textPainter.paint(
        canvas,
        nodo.posicion - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(NorOestePainter oldDelegate) => true;
}
