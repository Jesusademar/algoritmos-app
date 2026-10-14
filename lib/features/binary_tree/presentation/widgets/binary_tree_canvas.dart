import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/features/binary_tree/domain/binary_tree.dart';

class BinaryTreeCanvas extends StatefulWidget {
  const BinaryTreeCanvas({
    super.key,
    required this.tree,
    this.positions = const {},
    this.onPositionsChanged,
  });
  final BinaryTree tree;
  final Map<int, Offset> positions;
  final ValueChanged<Map<int, Offset>>? onPositionsChanged;

  @override
  State<BinaryTreeCanvas> createState() => _BinaryTreeCanvasState();
}

class _BinaryTreeCanvasState extends State<BinaryTreeCanvas> {
  final _transform = TransformationController();
  Map<int, Offset> _positions = {};
  Size? _viewport;
  bool _needsFit = true;
  bool _needsLayout = true;
  int? _dragging;

  @override
  void didUpdateWidget(BinaryTreeCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tree != widget.tree) {
      _needsFit = true;
      _needsLayout = true;
      _dragging = null;
    } else if (!identical(oldWidget.positions, widget.positions)) {
      _positions.addAll(widget.positions);
    }
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  Map<int, Offset> _automaticPositions(Size view) {
    final values = widget.tree.traverse(TreeTraversal.inOrder);
    final ranks = {for (var i = 0; i < values.length; i++) values[i]: i};
    final horizontalOffset = math.max(
      0.0,
      (view.width - (values.length * 86 + 60)) / 2,
    );
    final result = <int, Offset>{};
    void place(BinaryTreeNode? node, int depth) {
      if (node == null) return;
      result[node.value] = Offset(
        horizontalOffset + 73 + ranks[node.value]! * 86,
        55 + depth * 100.0,
      );
      place(node.left, depth + 1);
      place(node.right, depth + 1);
    }

    place(widget.tree.root, 0);
    return result;
  }

  Size _contentSize(Size view) => Size(
    math.max(
      view.width,
      _positions.values.fold<double>(200, (max, p) => math.max(max, p.dx + 50)),
    ),
    math.max(
      view.height,
      _positions.values.fold<double>(150, (max, p) => math.max(max, p.dy + 50)),
    ),
  );

  void _fit(Size view, Size content) {
    final scale = math.min(
      1.0,
      math.min(
        (view.width - 24) / content.width,
        (view.height - 24) / content.height,
      ),
    );
    _transform.value = Matrix4.identity()
      ..translateByDouble(
        (view.width - content.width * scale) / 2,
        (view.height - content.height * scale) / 2,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
  }

  void _move(int value, Offset delta) {
    final scale = _transform.value.getMaxScaleOnAxis();
    final next = _positions[value]! + delta / scale;
    setState(
      () => _positions[value] = Offset(
        next.dx.clamp(36, 100000),
        next.dy.clamp(36, 100000),
      ),
    );
    widget.onPositionsChanged?.call(Map<int, Offset>.unmodifiable(_positions));
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final view = Size(constraints.maxWidth, constraints.maxHeight);
      if (_needsLayout) {
        _positions = _automaticPositions(view);
        for (final entry in widget.positions.entries) {
          if (_positions.containsKey(entry.key)) {
            _positions[entry.key] = entry.value;
          }
        }
        _needsLayout = false;
      }
      final content = _contentSize(view);
      if (_needsFit || _viewport != view) {
        _needsFit = false;
        _viewport = view;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _fit(view, content);
        });
      }
      return Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              transformationController: _transform,
              constrained: false,
              minScale: 0.02,
              maxScale: 3,
              boundaryMargin: const EdgeInsets.all(300),
              child: SizedBox(
                width: content.width,
                height: content.height,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _TreeEdgesPainter(
                          widget.tree,
                          Map.of(_positions),
                        ),
                      ),
                    ),
                    for (final entry in _positions.entries)
                      Positioned(
                        left: entry.value.dx - 29,
                        top: entry.value.dy - 29,
                        child: MouseRegion(
                          cursor: _dragging == entry.key
                              ? SystemMouseCursors.grabbing
                              : SystemMouseCursors.grab,
                          child: GestureDetector(
                            key: ValueKey('tree-node-${entry.key}'),
                            behavior: HitTestBehavior.opaque,
                            dragStartBehavior: DragStartBehavior.down,
                            onPanStart: (_) =>
                                setState(() => _dragging = entry.key),
                            onPanUpdate: (details) =>
                                _move(entry.key, details.delta),
                            onPanEnd: (_) => setState(() => _dragging = null),
                            onPanCancel: () => setState(() => _dragging = null),
                            child: Semantics(
                              label:
                                  'Nodo ${entry.key}. Arrastra para moverlo.',
                              child: Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.surface,
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.16,
                                      ),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(7),
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '${entry.key}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Ordenar nodos automáticamente',
                    icon: const Icon(Icons.auto_awesome_rounded),
                    onPressed: () {
                      setState(() => _positions = _automaticPositions(view));
                      widget.onPositionsChanged?.call(
                        Map<int, Offset>.unmodifiable(_positions),
                      );
                      _fit(view, _contentSize(view));
                    },
                  ),
                  IconButton(
                    tooltip: 'Ajustar árbol a la vista',
                    onPressed: () => _fit(view, content),
                    icon: const Icon(Icons.center_focus_strong_rounded),
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

class _TreeEdgesPainter extends CustomPainter {
  const _TreeEdgesPainter(this.tree, this.positions);
  final BinaryTree tree;
  final Map<int, Offset> positions;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.6)
      ..strokeWidth = 2;
    void draw(BinaryTreeNode? node) {
      if (node == null) return;
      for (final child in [node.left, node.right]) {
        if (child != null) {
          canvas.drawLine(
            positions[node.value]!,
            positions[child.value]!,
            paint,
          );
          draw(child);
        }
      }
    }

    draw(tree.root);
  }

  @override
  bool shouldRepaint(_TreeEdgesPainter oldDelegate) => true;
}
