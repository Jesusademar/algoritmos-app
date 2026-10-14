import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/features/sorting/domain/sorting_algorithm.dart';

/// Informe de la ejecución, mostrado al terminar la visualización.
class SortingComplexityWidget extends StatelessWidget {
  const SortingComplexityWidget({
    super.key,
    required this.algorithm,
    required this.complexity,
    required this.elementCount,
    required this.comparisons,
    required this.movements,
    required this.calculationDuration,
  });

  final SortingAlgorithm algorithm;
  final String complexity;
  final int elementCount;
  final int comparisons;
  final int movements;
  final Duration calculationDuration;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          complexity,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.sorting,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          algorithm == SortingAlgorithm.insertionSort && movements == 0
              ? 'Entrada ya ordenada: comportamiento lineal.'
              : algorithm.complexityDescription,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 18,
          runSpacing: 10,
          children: [
            Text('Elementos (n): $elementCount'),
            Text('Comparaciones: $comparisons'),
            Text('${algorithm.movementLabel}: $movements'),
            Text(
              'Cálculo de los pasos: '
              '${(calculationDuration.inMicroseconds / 1000).toStringAsFixed(3)} ms',
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Big O describe cómo crece el trabajo del algoritmo. '
          'Las operaciones y el tiempo corresponden a esta ejecución; '
          'el tiempo excluye la reproducción de la animación.',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
