import 'dart:math';

import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/shared/graph_editor/models/conexion.dart';
import 'package:app_grafos/shared/graph_editor/models/nodo.dart';

class RedActividadesPainter extends CustomPainter {
  final List<Nodo> nodos;
  final List<Conexion> conexiones;
  final Nodo? nodoOrigenParaConexion;
  final Map<String, int> tiemposTempranos;
  final Map<String, int> tiemposTardios;
  final Map<String, int> holguras;
  final Set<String> aristasCriticas;
  final bool mostrarProceso;

  RedActividadesPainter(
    this.nodos,
    this.conexiones,
    this.nodoOrigenParaConexion,
    this.tiemposTempranos,
    this.tiemposTardios,
    this.holguras,
    this.aristasCriticas,
    this.mostrarProceso,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paintNodo = Paint()..style = PaintingStyle.fill;
    final paintBorde = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (var c in conexiones) {
      final nA = nodos.firstWhere(
        (n) => n.id == c.nodoA,
        orElse: () => nodos.first,
      );
      final nB = nodos.firstWhere(
        (n) => n.id == c.nodoB,
        orElse: () => nodos.first,
      );
      if (nA.id.isNotEmpty && nB.id.isNotEmpty) {
        bool esCritica =
            mostrarProceso && aristasCriticas.contains('${c.nodoA}-${c.nodoB}');

        final paintArista = Paint()
          ..color = esCritica ? AppColors.success : c.color
          ..strokeWidth = esCritica ? 4.5 : 2.5
          ..style = PaintingStyle.stroke;

        _dibujarLineaConFlecha(canvas, nA.posicion, nB.posicion, paintArista);

        final mid = Offset(
          (nA.posicion.dx + nB.posicion.dx) / 2,
          (nA.posicion.dy + nB.posicion.dy) / 2,
        );

        final textSpan = TextSpan(
          text: ' ${c.peso} ',
          style: TextStyle(
            fontFamily: 'Roboto',
            color: esCritica ? AppColors.successText : AppColors.text,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        );
        final tp = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );
        tp.layout();

        final rectBg = Rect.fromCenter(
          center: mid,
          width: tp.width + 6,
          height: tp.height + 4,
        );

        canvas.drawRRect(
          RRect.fromRectAndRadius(rectBg, const Radius.circular(4)),
          Paint()
            ..color = esCritica ? AppColors.successSoft : AppColors.surface,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rectBg, const Radius.circular(4)),
          Paint()
            ..color = esCritica ? AppColors.success : AppColors.border
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );

        tp.paint(canvas, mid - Offset(tp.width / 2, tp.height / 2));

        if (mostrarProceso) {
          int hA = holguras[c.nodoA] ?? 0;
          final textHolgura = TextSpan(
            text: ' H=$hA ',
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          );
          final tpH = TextPainter(
            text: textHolgura,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
          );
          tpH.layout();

          final rectBgH = Rect.fromCenter(
            center: mid + const Offset(0, 16),
            width: tpH.width + 4,
            height: tpH.height + 2,
          );

          canvas.drawRRect(
            RRect.fromRectAndRadius(rectBgH, const Radius.circular(4)),
            Paint()..color = AppColors.surface,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(rectBgH, const Radius.circular(4)),
            Paint()
              ..color = AppColors.border
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1,
          );

          tpH.paint(
            canvas,
            mid + const Offset(0, 16) - Offset(tpH.width / 2, tpH.height / 2),
          );
        }
      }
    }

    for (var nodo in nodos) {
      final isOrigen = nodoOrigenParaConexion?.id == nodo.id;
      paintNodo.color = isOrigen ? AppColors.warningSoft : AppColors.surface;
      paintBorde.color = isOrigen ? AppColors.johnson : AppColors.textMuted;

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
        textAlign: TextAlign.center,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        nodo.posicion - Offset(textPainter.width / 2, textPainter.height / 2),
      );

      if (mostrarProceso) {
        int tTemp = tiemposTempranos[nodo.id] ?? 0;
        int tTard = tiemposTardios[nodo.id] ?? 0;

        final leftSpan = TextSpan(
          text: '$tTemp',
          style: const TextStyle(
            fontFamily: 'Roboto',
            color: AppColors.text,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        );
        final leftTP = TextPainter(
          text: leftSpan,
          textDirection: TextDirection.ltr,
        );
        leftTP.layout();
        leftTP.paint(canvas, nodo.posicion + const Offset(-40, -6));

        final rightSpan = TextSpan(
          text: '$tTard',
          style: const TextStyle(
            fontFamily: 'Roboto',
            color: AppColors.text,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        );
        final rightTP = TextPainter(
          text: rightSpan,
          textDirection: TextDirection.ltr,
        );
        rightTP.layout();
        rightTP.paint(canvas, nodo.posicion + const Offset(30, -6));
      }
    }
  }

  void _dibujarLineaConFlecha(
    Canvas canvas,
    Offset origen,
    Offset destino,
    Paint paint,
  ) {
    const double radioNodo = 24.0;
    final double angulo = atan2(destino.dy - origen.dy, destino.dx - origen.dx);

    final Offset puntoFinal = Offset(
      destino.dx - radioNodo * cos(angulo),
      destino.dy - radioNodo * sin(angulo),
    );

    final Offset puntoInicio = Offset(
      origen.dx + radioNodo * cos(angulo),
      origen.dy + radioNodo * sin(angulo),
    );

    canvas.drawLine(puntoInicio, puntoFinal, paint);

    const double tamFlecha = 12.0;
    final Path pathFlecha = Path();
    pathFlecha.moveTo(puntoFinal.dx, puntoFinal.dy);
    pathFlecha.lineTo(
      puntoFinal.dx - tamFlecha * cos(angulo - pi / 6),
      puntoFinal.dy - tamFlecha * sin(angulo - pi / 6),
    );
    pathFlecha.lineTo(
      puntoFinal.dx - tamFlecha * cos(angulo + pi / 6),
      puntoFinal.dy - tamFlecha * sin(angulo + pi / 6),
    );
    pathFlecha.close();

    final Paint paintFlecha = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;

    canvas.drawPath(pathFlecha, paintFlecha);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
