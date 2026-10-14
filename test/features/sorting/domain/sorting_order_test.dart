import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:app_grafos/features/sorting/domain/sorting_algorithm.dart';
import 'package:app_grafos/features/sorting/domain/sorting_order.dart';
import 'package:app_grafos/features/sorting/domain/sorting_problem.dart';
import 'package:app_grafos/features/sorting/domain/sorting_solver.dart';
import 'package:app_grafos/features/sorting/presentation/providers/sorting_visualization_provider.dart';

void main() {
  const solver = SortingSolver();
  for (final algorithm in SortingAlgorithm.values) {
    for (final order in SortingOrder.values) {
      test(
        '${algorithm.displayName}: ${order.label}, duplicados y extremos',
        () {
          for (final input in <List<int>>[
            [8, 3, 8, 1, 5],
            [],
            [7],
            [1, 2, 3],
            [3, 2, 1],
            [4, 4, 4],
          ]) {
            final original = List<int>.of(input);
            final expected = List<int>.of(input)..sort();
            final result = solver.solve(
              SortingProblem(
                originalArray: input,
                algorithm: algorithm,
                order: order,
              ),
            );
            expect(
              result.finalArray,
              order == SortingOrder.ascending
                  ? expected
                  : expected.reversed.toList(),
            );
            expect(input, original);
            expect(result.steps.first.array, original);
            expect(
              result.steps.last.sortedIndices,
              Set<int>.from(List.generate(input.length, (i) => i)),
            );
            for (final step in result.steps) {
              for (final index in [
                step.comparingIndex1,
                step.comparingIndex2,
                step.movingIndex,
                ...step.sortedIndices,
              ]) {
                if (index != null) {
                  expect(index, inInclusiveRange(0, input.length - 1));
                }
              }
            }
          }
        },
      );
    }
  }

  test(
    'Selection cuenta todas las comparaciones y señala el candidato actual',
    () {
      final result = solver.solve(
        const SortingProblem(
          originalArray: [8, 3, 1],
          algorithm: SortingAlgorithm.selectionSort,
        ),
      );
      expect(result.totalComparisons, 3);
      final comparisons = result.steps
          .where((step) => step.comparingIndex1 != null)
          .toList();
      expect(comparisons[1].comparingIndex1, 1);
      expect(comparisons[1].comparingIndex2, 2);
    },
  );

  test('Insertion cuenta también las comparaciones que no desplazan', () {
    for (final order in SortingOrder.values) {
      final ordered = order == SortingOrder.ascending
          ? [1, 2, 3, 4]
          : [4, 3, 2, 1];
      final best = solver.solve(
        SortingProblem(
          originalArray: ordered,
          algorithm: SortingAlgorithm.insertionSort,
          order: order,
        ),
      );
      final worst = solver.solve(
        SortingProblem(
          originalArray: ordered.reversed.toList(),
          algorithm: SortingAlgorithm.insertionSort,
          order: order,
        ),
      );
      expect(best.totalComparisons, 3);
      expect(best.totalSwaps, 0);
      expect(worst.totalComparisons, 6);
      expect(worst.totalSwaps, 6);
    }
  });

  test(
    'Cambiar sentido conserva datos y velocidad, pausa y recalcula los pasos',
    () {
      final input = [3, 9, 1, 3];
      final provider = SortingVisualizationProvider(
        array: input,
        algorithm: SortingAlgorithm.insertionSort,
      );
      addTearDown(provider.dispose);
      input[0] = 100;
      provider.setSpeed(2);
      provider.play();
      provider.nextStep();
      provider.setOrder(SortingOrder.descending);
      expect(provider.currentStepIndex, 0);
      expect(provider.isPlaying, isFalse);
      expect(provider.speed, 2);
      expect(provider.currentArray, [3, 9, 1, 3]);
      expect(provider.finalArray, [9, 3, 3, 1]);
      provider.setOrder(SortingOrder.ascending);
      expect(provider.finalArray, [1, 3, 3, 9]);
    },
  );
  test('Merge y Shell coinciden con el orden nativo en entradas variadas', () {
    final random = Random(14);
    for (final algorithm in [
      SortingAlgorithm.mergeSort,
      SortingAlgorithm.shellSort,
    ]) {
      for (final order in SortingOrder.values) {
        for (var length = 0; length <= 20; length++) {
          final input = List.generate(length, (_) => random.nextInt(12));
          final expected = List<int>.of(input)..sort();
          final result = solver.solve(
            SortingProblem(
              originalArray: input,
              algorithm: algorithm,
              order: order,
            ),
          );
          expect(
            result.finalArray,
            order == SortingOrder.ascending
                ? expected
                : expected.reversed.toList(),
          );
          expect(
            result.totalComparisons,
            result.steps.where((s) => s.comparingIndex1 != null).length,
          );
        }
      }
    }
  });

  test(
    'Merge registra combinaciones y Shell registra saltos y estadísticas',
    () {
      final merge = solver.solve(
        const SortingProblem(
          originalArray: [4, 3, 2, 1],
          algorithm: SortingAlgorithm.mergeSort,
        ),
      );
      expect(merge.totalComparisons, 4);
      expect(merge.totalSwaps, 8);
      expect(
        merge.steps.any((s) => s.description.contains('Dividiendo')),
        isTrue,
      );
      final shell = solver.solve(
        const SortingProblem(
          originalArray: [1, 2, 3, 4],
          algorithm: SortingAlgorithm.shellSort,
        ),
      );
      expect(shell.totalComparisons, 5);
      expect(shell.totalSwaps, 0);
      expect(shell.steps.any((s) => s.description.contains('salto 2')), isTrue);
      expect(SortingAlgorithm.mergeSort.worstCase, 'O(n log n)');
      expect(SortingAlgorithm.shellSort.worstCase, 'O(n²)');
    },
  );
}
