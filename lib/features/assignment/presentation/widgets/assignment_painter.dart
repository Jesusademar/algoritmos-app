import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/shared/graph_editor/geometry/offset_geometry.dart';
import 'package:app_grafos/shared/graph_editor/models/conexion.dart';
import 'package:app_grafos/shared/graph_editor/models/nodo.dart';

class AsignacionPainter extends CustomPainter {
  final List<Nodo> nodos;
  final List<Conexion> conexiones;
  final Nodo? nodoOrigen;
  final List<String> idsConexionesOptimas;

  AsignacionPainter(
    this.nodos,
    this.conexiones,
    this.nodoOrigen,
    this.idsConexionesOptimas,
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
        final isOptima =
            idsConexionesOptimas.contains(
              '${conexion.nodoA}-${conexion.nodoB}',
            ) ||
            idsConexionesOptimas.contains(
              '${conexion.nodoB}-${conexion.nodoA}',
            );

        if (isOptima) continue;

        paintConexion.color = conexion.color;
        final direccion = (nodoB.posicion - nodoA.posicion).normalize();
        final desdeAjustado = nodoA.posicion + direccion * 26;
        final hastaAjustado = nodoB.posicion - direccion * 26;

        canvas.drawLine(desdeAjustado, hastaAjustado, paintConexion);

        final centro = Offset(
          (desdeAjustado.dx + hastaAjustado.dx) / 2,
          (desdeAjustado.dy + hastaAjustado.dy) / 2,
        );

        // Contenedor limpio para evitar solapamientos visuales
        final textSpan = TextSpan(
          text: ' ${conexion.peso} ',
          style: const TextStyle(
            fontFamily: 'Roboto',
            color: AppColors.text,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

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
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );

        textPainter.paint(
          canvas,
          centro - Offset(textPainter.width / 2, textPainter.height / 2),
        );
      } catch (_) {}
    }

    for (var conexion in conexiones) {
      try {
        final nodoA = nodos.firstWhere((n) => n.id == conexion.nodoA);
        final nodoB = nodos.firstWhere((n) => n.id == conexion.nodoB);
        final isOptima =
            idsConexionesOptimas.contains(
              '${conexion.nodoA}-${conexion.nodoB}',
            ) ||
            idsConexionesOptimas.contains(
              '${conexion.nodoB}-${conexion.nodoA}',
            );

        if (!isOptima) continue;

        final direccion = (nodoB.posicion - nodoA.posicion).normalize();
        final desdeAjustado = nodoA.posicion + direccion * 26;
        final hastaAjustado = nodoB.posicion - direccion * 26;

        final paintGlow = Paint()
          ..color = const Color(0xFF34D399).withValues(alpha: 0.5)
          ..strokeWidth = 14.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(desdeAjustado, hastaAjustado, paintGlow);

        final paintGlowMid = Paint()
          ..color = AppColors.success.withValues(alpha: 0.8)
          ..strokeWidth = 8.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(desdeAjustado, hastaAjustado, paintGlowMid);

        final paintCore = Paint()
          ..color = AppColors.text
          ..strokeWidth = 3.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(desdeAjustado, hastaAjustado, paintCore);

        final centro = Offset(
          (desdeAjustado.dx + hastaAjustado.dx) / 2,
          (desdeAjustado.dy + hastaAjustado.dy) / 2,
        );

        final textSpan = TextSpan(
          text: ' ★ ${conexion.peso} ',
          style: const TextStyle(
            fontFamily: 'Roboto',
            color: AppColors.successText,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        final rectBg = Rect.fromCenter(
          center: centro,
          width: textPainter.width + 6,
          height: textPainter.height + 4,
        );

        canvas.drawRRect(
          RRect.fromRectAndRadius(rectBg, const Radius.circular(4)),
          Paint()..color = AppColors.successSoft,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rectBg, const Radius.circular(4)),
          Paint()
            ..color = AppColors.success
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );

        textPainter.paint(
          canvas,
          centro - Offset(textPainter.width / 2, textPainter.height / 2),
        );
      } catch (_) {}
    }

    final paintNodo = Paint()..style = PaintingStyle.fill;
    final paintBorde = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (var nodo in nodos) {
      final isOrigen = nodoOrigen?.id == nodo.id;
      paintNodo.color = isOrigen ? AppColors.primarySoft : AppColors.surface;
      paintBorde.color = isOrigen ? AppColors.primary : AppColors.textMuted;

      canvas.drawCircle(nodo.posicion, 24, paintNodo);
      canvas.drawCircle(nodo.posicion, 24, paintBorde);

      final textSpan = TextSpan(
        text: nodo.nombre,
        style: const TextStyle(
          fontFamily: 'Roboto',
          color: AppColors.text,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        nodo.posicion - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(AsignacionPainter oldDelegate) => true;
}
