import 'package:flutter/material.dart';

/// Las tarjetas ajustan su altura al texto y comparten columnas en cada fila.
class AlgorithmCardGrid extends StatelessWidget {
  const AlgorithmCardGrid({
    super.key,
    required this.children,
    this.maxColumns = 3,
  }) : assert(maxColumns > 0);

  final List<Widget> children;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableColumns = maxColumns >= 4 && constraints.maxWidth >= 1100
            ? 4
            : constraints.maxWidth >= 1000
            ? 3
            : constraints.maxWidth >= 600
            ? 2
            : 1;
        final columns = availableColumns.clamp(1, maxColumns);
        return Column(
          children: [
            for (var start = 0; start < children.length; start += columns) ...[
              if (start > 0) const SizedBox(height: 20),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var column = 0; column < columns; column++) ...[
                      if (column > 0) const SizedBox(width: 20),
                      Expanded(
                        child: start + column < children.length
                            ? children[start + column]
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
