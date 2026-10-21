import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/shared/graph_editor/geometry/offset_geometry.dart';
import 'package:app_grafos/shared/graph_editor/models/conexion.dart';
import 'package:app_grafos/shared/graph_editor/models/nodo.dart';

class NetworkGraphPainter extends CustomPainter {
  NetworkGraphPainter({
    required this.nodes,
    required this.edges,
    required this.directed,
    required this.accent,
    this.selected,
    this.source,
    this.target,
    this.highlighted = const {},
    this.distances,
    this.maximizing = false,
  });
  final List<Nodo> nodes;
  final List<Conexion> edges;
  final bool directed;
  final Color accent;
  final String? selected;
  final String? source;
  final String? target;
  final Set<(String, String)> highlighted;
  final Map<String, int>? distances;
  final bool maximizing;

  static Offset edgeLabel(
    Conexion edge,
    List<Nodo> nodes,
    List<Conexion> edges,
    bool directed,
  ) {
    final from = nodes.firstWhere((n) => n.id == edge.nodoA).posicion;
    final to = nodes.firstWhere((n) => n.id == edge.nodoB).posicion;
    final direction = (to - from).normalize();
    final reciprocal =
        directed &&
        edges.any((e) => e.nodoA == edge.nodoB && e.nodoB == edge.nodoA);
    return (from + to) / 2 +
        (reciprocal ? Offset(-direction.dy, direction.dx) * 18 : Offset.zero);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final byId = {for (final node in nodes) node.id: node};
    for (final pass in [false, true]) {
      for (final edge in edges) {
        final optimal = highlighted.contains((edge.nodoA, edge.nodoB));
        if (optimal != pass) continue;
        final from = byId[edge.nodoA];
        final to = byId[edge.nodoB];
        if (from == null || to == null) continue;
        final direction = (to.posicion - from.posicion).normalize();
        final start = from.posicion + direction * 28;
        final end = to.posicion - direction * 28;
        final label = edgeLabel(edge, nodes, edges, directed);
        final middle = (from.posicion + to.posicion) / 2;
        final control = middle + (label - middle) * 2;
        final path = Path()
          ..moveTo(start.dx, start.dy)
          ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
        if (optimal) {
          canvas.drawPath(
            path,
            Paint()
              ..color = AppColors.success.withValues(alpha: 0.3)
              ..strokeWidth = 12
              ..style = PaintingStyle.stroke,
          );
        }
        final color = optimal
            ? AppColors.success
            : accent.withValues(alpha: highlighted.isEmpty ? 0.6 : 0.22);
        canvas.drawPath(
          path,
          Paint()
            ..color = color
            ..strokeWidth = optimal ? 4 : 2
            ..style = PaintingStyle.stroke,
        );
        if (directed) {
          final angle = math.atan2(end.dy - control.dy, end.dx - control.dx);
          final arrow = Path()
            ..moveTo(end.dx, end.dy)
            ..lineTo(
              end.dx - 10 * math.cos(angle - 0.45),
              end.dy - 10 * math.sin(angle - 0.45),
            )
            ..lineTo(
              end.dx - 10 * math.cos(angle + 0.45),
              end.dy - 10 * math.sin(angle + 0.45),
            )
            ..close();
          canvas.drawPath(arrow, Paint()..color = color);
        }
        _label(
          canvas,
          '${edge.peso}',
          label,
          optimal ? AppColors.successText : AppColors.text,
          optimal ? AppColors.successSoft : AppColors.surface,
          optimal ? AppColors.success : AppColors.border,
        );
      }
    }
    for (final node in nodes) {
      final color = selected == node.id
          ? AppColors.success
          : node.id == source
          ? accent
          : node.id == target
          ? AppColors.success
          : AppColors.textMuted;
      canvas.drawCircle(node.posicion, 26, Paint()..color = AppColors.surface);
      canvas.drawCircle(
        node.posicion,
        26,
        Paint()
          ..color = color
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke,
      );
      final text = TextPainter(
        text: TextSpan(
          text: node.nombre,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: 44);
      text.paint(
        canvas,
        node.posicion - Offset(text.width / 2, text.height / 2),
      );
      if (distances != null) {
        _label(
          canvas,
          'd: ${distances![node.id] ?? (maximizing ? '−∞' : '∞')}',
          node.posicion + const Offset(0, 40),
          AppColors.text,
          AppColors.surface,
          color,
        );
      }
    }
  }

  void _label(
    Canvas canvas,
    String value,
    Offset center,
    Color foreground,
    Color background,
    Color border,
  ) {
    final text = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: foreground,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final box = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: text.width + 12,
        height: text.height + 6,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(box, Paint()..color = background);
    canvas.drawRRect(
      box,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke,
    );
    text.paint(canvas, center - Offset(text.width / 2, text.height / 2));
  }

  @override
  bool shouldRepaint(NetworkGraphPainter oldDelegate) => true;
}
