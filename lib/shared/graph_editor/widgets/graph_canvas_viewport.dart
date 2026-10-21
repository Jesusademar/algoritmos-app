import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/shared/graph_editor/models/nodo.dart';

/// Navega por la pizarra sin cambiar las coordenadas ni los datos del grafo.
class GraphCanvasViewport extends StatefulWidget {
  const GraphCanvasViewport({
    super.key,
    required this.nodes,
    required this.painter,
    required this.onTap,
    required this.onEdit,
    required this.onNodeMoved,
  });
  final List<Nodo> nodes;
  final CustomPainter painter;
  final ValueChanged<Offset> onTap;
  final ValueChanged<Offset> onEdit;
  final void Function(Nodo node, Offset position) onNodeMoved;

  @override
  State<GraphCanvasViewport> createState() => GraphCanvasViewportState();
}

class GraphCanvasViewportState extends State<GraphCanvasViewport> {
  final transform = TransformationController();
  Size _view = Size.zero;
  Nodo? _dragging;
  Offset _anchor = Offset.zero;
  Offset _nodeStart = Offset.zero;
  Offset _pointerStart = Offset.zero;
  double _startScale = 1;
  double _gestureScale = 1;
  int _pointers = 0;
  Offset _doubleTap = Offset.zero;

  Offset toScene(Offset position) => transform.toScene(position);
  double get _scale => transform.value.getMaxScaleOnAxis();

  @override
  void dispose() {
    transform.dispose();
    super.dispose();
  }

  Nodo? _nodeAt(Offset point) {
    for (final node in widget.nodes.reversed) {
      if ((node.posicion - point).distance <= 30) return node;
    }
    return null;
  }

  void _setView(double scale, Offset offset) {
    transform.value = Matrix4.identity()
      ..translateByDouble(offset.dx, offset.dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  void _zoom(double factor, [Offset? focal]) {
    final point = focal ?? Offset(_view.width / 2, _view.height / 2);
    final anchor = toScene(point);
    final next = (_scale * factor).clamp(0.01, 5.0);
    _setView(next, point - anchor * next);
  }

  void fit() {
    if (widget.nodes.isEmpty) {
      transform.value = Matrix4.identity();
      return;
    }
    final positions = widget.nodes.map((node) => node.posicion);
    final left = positions.map((p) => p.dx).reduce(math.min) - 44;
    final right = positions.map((p) => p.dx).reduce(math.max) + 44;
    final top = positions.map((p) => p.dy).reduce(math.min) - 44;
    final bottom = positions.map((p) => p.dy).reduce(math.max) + 44;
    // Reservar espacio para el zoom superior y las acciones inferiores.
    final available = Size(
      math.max(1, _view.width - 32),
      math.max(1, _view.height - 150),
    );
    final scale = math.min(
      1.0,
      math.min(
        available.width / (right - left),
        available.height / (bottom - top),
      ),
    );
    _setView(
      scale,
      Offset(
        16 + (available.width - (right - left) * scale) / 2 - left * scale,
        52 + (available.height - (bottom - top) * scale) / 2 - top * scale,
      ),
    );
  }

  void _start(ScaleStartDetails details) {
    _anchor = toScene(details.localFocalPoint);
    // El punto de contacto original evita perder el nodo por el umbral de arrastre.
    _dragging = details.pointerCount == 1
        ? _nodeAt(toScene(_pointerStart))
        : null;
    _nodeStart = _dragging?.posicion ?? Offset.zero;
    if (_dragging != null) _anchor = toScene(_pointerStart);
    _startScale = _scale;
    _gestureScale = 1;
    _pointers = details.pointerCount;
  }

  void _update(ScaleUpdateDetails details) {
    if (_pointers != details.pointerCount) {
      _dragging = null;
      _pointers = details.pointerCount;
      _anchor = toScene(details.localFocalPoint);
      _startScale = _scale;
      _gestureScale = details.scale;
      return;
    }
    if (_dragging != null && details.pointerCount == 1) {
      widget.onNodeMoved(
        _dragging!,
        _nodeStart + toScene(details.localFocalPoint) - _anchor,
      );
    } else {
      final next = (_startScale * details.scale / _gestureScale).clamp(
        0.01,
        5.0,
      );
      _setView(next, details.localFocalPoint - _anchor * next);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final nextView = constraints.biggest;
      if (_view != nextView) {
        _view = nextView;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _view != nextView) return;
          final visible = Rect.fromLTRB(
            30,
            30,
            _view.width - 30,
            _view.height - 90,
          );
          if (widget.nodes.any(
            (node) => !visible.contains(
              MatrixUtils.transformPoint(transform.value, node.posicion),
            ),
          )) {
            fit();
          }
        });
      }
      return Stack(
        fit: StackFit.expand,
        children: [
          Listener(
            onPointerDown: (event) => _pointerStart = event.localPosition,
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                GestureBinding.instance.pointerSignalResolver.register(event, (
                  _,
                ) {
                  _zoom(
                    math.exp(-event.scrollDelta.dy * 0.0015),
                    event.localPosition,
                  );
                });
              }
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) =>
                  widget.onTap(toScene(details.localPosition)),
              onSecondaryTapUp: (details) =>
                  widget.onEdit(toScene(details.localPosition)),
              onDoubleTapDown: (details) => _doubleTap = details.localPosition,
              onDoubleTap: () => widget.onEdit(toScene(_doubleTap)),
              onLongPressStart: (details) =>
                  widget.onEdit(toScene(details.localPosition)),
              onScaleStart: _start,
              onScaleUpdate: _update,
              onScaleEnd: (_) => _dragging = null,
              child: ClipRect(
                child: CustomPaint(
                  painter: _ViewportPainter(widget.painter, transform),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Material(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Alejar pizarra',
                    onPressed: () => _zoom(1 / 1.25),
                    icon: const Icon(Icons.remove_rounded, size: 20),
                  ),
                  IconButton(
                    tooltip: 'Acercar pizarra',
                    onPressed: () => _zoom(1.25),
                    icon: const Icon(Icons.add_rounded, size: 20),
                  ),
                  IconButton(
                    tooltip: 'Ajustar nodos a la vista',
                    onPressed: fit,
                    icon: const Icon(
                      Icons.center_focus_strong_rounded,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _ViewportPainter extends CustomPainter {
  _ViewportPainter(this.content, this.transform) : super(repaint: transform);
  final CustomPainter content;
  final TransformationController transform;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.transform(transform.value.storage);
    content.paint(canvas, size);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ViewportPainter oldDelegate) => true;
}
