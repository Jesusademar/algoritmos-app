import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/shared/graph_editor/models/conexion.dart';
import 'package:app_grafos/shared/graph_editor/models/nodo.dart';

class NorOestePainter extends CustomPainter {
  final List<Nodo> nodos;
  final List<Conexion> conexiones;
  final Nodo? nodoOrigen;
  final Map<String, int> ofertas;
  final Map<String, int> demandas;

  NorOestePainter(
    this.nodos,
    this.conexiones,
    this.nodoOrigen,
    this.ofertas,
    this.demandas,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paintConexion = Paint()
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (var conexion in conexiones) {
      try {
        final nodoA = nodos.firstWhere((n) => n.id == conexion.nodoA);
        final nodoB = nodos.firstWhere((n) => n.id == conexion.nodoB);
        paintConexion.color = conexion.color;

        canvas.drawLine(nodoA.posicion, nodoB.posicion, paintConexion);

        final centro = Offset(
          (nodoA.posicion.dx + nodoB.posicion.dx) / 2,
          (nodoA.posicion.dy + nodoB.posicion.dy) / 2,
        );
        final textPainter = TextPainter(
          text: TextSpan(
            text: ' C: ${conexion.peso} ',
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: AppColors.text,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final rectBg = Rect.fromCenter(
          center: centro,
          width: textPainter.width + 6,
          height: textPainter.height + 4,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rectBg, const Radius.circular(4)),
          Paint()..color = AppColors.surface,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rectBg, const Radius.circular(4)),
          Paint()
            ..color = AppColors.border
            ..style = PaintingStyle.stroke,
        );
        textPainter.paint(
          canvas,
          centro - Offset(textPainter.width / 2, textPainter.height / 2),
        );
      } catch (_) {}
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
