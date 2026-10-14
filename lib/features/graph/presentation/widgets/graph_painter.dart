import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/shared/graph_editor/geometry/offset_geometry.dart';
import 'package:app_grafos/shared/graph_editor/models/conexion.dart';
import 'package:app_grafos/shared/graph_editor/models/nodo.dart';

class GrafoPainter extends CustomPainter {
  final List<Nodo> nodos;
  final List<Conexion> conexiones;
  final Nodo? nodoOrigen;

  GrafoPainter(this.nodos, this.conexiones, this.nodoOrigen);

  void dibujarFlecha(Canvas canvas, Offset desde, Offset hasta, Color color) {
    final direccion = (hasta - desde).normalize();
    final desdeAjustado = desde + direccion * 28;
    final hastaAjustado = hasta - direccion * 28;
    canvas.drawLine(
      desdeAjustado,
      hastaAjustado,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    final base = hastaAjustado - direccion * 14;
    final perp = Offset(-direccion.dy, direccion.dx) * 8;
    canvas.drawPath(
      Path()
        ..moveTo(base.dx + perp.dx, base.dy + perp.dy)
        ..lineTo(hastaAjustado.dx, hastaAjustado.dy)
        ..lineTo(base.dx - perp.dx, base.dy - perp.dy)
        ..close(),
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  void dibujarFlechaCurva(
    Canvas canvas,
    Offset desde,
    Offset hasta,
    Color color,
  ) {
    final direccion = (hasta - desde).normalize();
    final desdeAjustado = desde + direccion * 28;
    final hastaAjustado = hasta - direccion * 28;
    final centro = Offset(
      (desdeAjustado.dx + hastaAjustado.dx) / 2,
      (desdeAjustado.dy + hastaAjustado.dy) / 2,
    );
    final distancia = (hastaAjustado - desdeAjustado).distance;
    final offset = Offset(
      (hastaAjustado.dy - desdeAjustado.dy) / distancia * 35,
      (desdeAjustado.dx - hastaAjustado.dx) / distancia * 35,
    );
    final path = Path();
    path.moveTo(desdeAjustado.dx, desdeAjustado.dy);
    path.quadraticBezierTo(
      centro.dx + offset.dx,
      centro.dy + offset.dy,
      hastaAjustado.dx,
      hastaAjustado.dy,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    final dirFinal =
        (hastaAjustado - Offset(centro.dx + offset.dx, centro.dy + offset.dy))
            .normalize();
    final base = hastaAjustado - dirFinal * 14;
    final perp = Offset(-dirFinal.dy, dirFinal.dx) * 8;
    canvas.drawPath(
      Path()
        ..moveTo(base.dx + perp.dx, base.dy + perp.dy)
        ..lineTo(hastaAjustado.dx, hastaAjustado.dy)
        ..lineTo(base.dx - perp.dx, base.dy - perp.dy)
        ..close(),
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  void dibujarBucle(Canvas canvas, Offset pos, Color color) {
    final start = pos + const Offset(-12, -24);
    final end = pos + const Offset(12, -24);
    final control1 = pos + const Offset(-40, -70);
    final control2 = pos + const Offset(40, -70);
    final path = Path();
    path.moveTo(start.dx, start.dy);
    path.cubicTo(
      control1.dx,
      control1.dy,
      control2.dx,
      control2.dy,
      end.dx,
      end.dy,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    final dirFinal = (end - control2).normalize();
    final base = end - dirFinal * 12;
    final perp = Offset(-dirFinal.dy, dirFinal.dx) * 7;
    canvas.drawPath(
      Path()
        ..moveTo(base.dx + perp.dx, base.dy + perp.dy)
        ..lineTo(end.dx, end.dy)
        ..lineTo(base.dx - perp.dx, base.dy - perp.dy)
        ..close(),
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (var conexion in conexiones) {
      final nodoA = nodos.firstWhere((n) => n.id == conexion.nodoA);
      final nodoB = nodos.firstWhere((n) => n.id == conexion.nodoB);
      Offset medio;
      final Color colorActual = conexion.color;
      if (conexion.nodoA == conexion.nodoB) {
        dibujarBucle(canvas, nodoA.posicion, colorActual);
        medio = nodoA.posicion + const Offset(0, -60);
      } else {
        final hayInversa = conexiones.any(
          (c) =>
              c.nodoA == conexion.nodoB &&
              c.nodoB == conexion.nodoA &&
              c.tipo == 'unidireccional',
        );
        if (conexion.tipo == 'sin_direccion') {
          canvas.drawLine(
            nodoA.posicion,
            nodoB.posicion,
            Paint()
              ..color = colorActual
              ..strokeWidth = 2.5
              ..strokeCap = StrokeCap.round,
          );
        } else {
          if (hayInversa) {
            dibujarFlechaCurva(
              canvas,
              nodoA.posicion,
              nodoB.posicion,
              colorActual,
            );
          } else {
            dibujarFlecha(canvas, nodoA.posicion, nodoB.posicion, colorActual);
          }
        }
        if (conexion.tipo == 'unidireccional' && hayInversa) {
          final direccion = (nodoB.posicion - nodoA.posicion).normalize();
          final desdeAjustado = nodoA.posicion + direccion * 28;
          final hastaAjustado = nodoB.posicion - direccion * 28;
          final centro = Offset(
            (desdeAjustado.dx + hastaAjustado.dx) / 2,
            (desdeAjustado.dy + hastaAjustado.dy) / 2,
          );
          final distancia = (hastaAjustado - desdeAjustado).distance;
          final offset = Offset(
            (hastaAjustado.dy - desdeAjustado.dy) / distancia * 35,
            (desdeAjustado.dx - hastaAjustado.dx) / distancia * 35,
          );
          final pControl = centro + offset;
          medio = desdeAjustado * 0.25 + pControl * 0.5 + hastaAjustado * 0.25;
        } else {
          medio = Offset(
            (nodoA.posicion.dx + nodoB.posicion.dx) / 2,
            (nodoA.posicion.dy + nodoB.posicion.dy) / 2,
          );
        }
      }
      final textPainter = TextPainter(
        text: TextSpan(
          text: ' ${conexion.peso} ',
          style: const TextStyle(
            fontFamily: 'Roboto',
            color: AppColors.text,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final bgRect = Rect.fromCenter(
        center: medio,
        width: textPainter.width + 10,
        height: textPainter.height + 6,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bgRect, const Radius.circular(8)),
        Paint()..color = AppColors.surface,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bgRect, const Radius.circular(8)),
        Paint()
          ..color = AppColors.border
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      textPainter.paint(
        canvas,
        medio - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
    for (var nodo in nodos) {
      final esOrigen = nodo.id == nodoOrigen?.id;
      canvas.drawCircle(
        nodo.posicion + const Offset(0, 4),
        26,
        Paint()..color = Colors.black.withValues(alpha: 0.08),
      );
      canvas.drawCircle(
        nodo.posicion,
        26,
        Paint()..color = esOrigen ? AppColors.graphSoft : AppColors.surface,
      );
      canvas.drawCircle(
        nodo.posicion,
        26,
        Paint()
          ..color = esOrigen
              ? AppColors.graph
              : AppColors.graph.withValues(alpha: 0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = esOrigen ? 3 : 1.5,
      );
      final textPainter = TextPainter(
        text: TextSpan(
          text: nodo.nombre,
          style: TextStyle(
            fontFamily: 'Roboto',
            color: esOrigen ? AppColors.graph : AppColors.text,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
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
  bool shouldRepaint(GrafoPainter oldDelegate) => true;
}
