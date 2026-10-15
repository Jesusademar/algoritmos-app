import 'package:app_grafos/features/sorting/domain/sorting_algorithm.dart';
import 'package:app_grafos/features/sorting/domain/sorting_problem.dart';
import 'package:app_grafos/features/sorting/domain/sorting_result.dart';
import 'package:app_grafos/features/sorting/domain/sorting_snapshot.dart';
import 'package:app_grafos/features/sorting/domain/sorting_step.dart';

/// Solves sorting problems using different algorithms.
/// Generates step-by-step visualization data without UI dependencies.
class SortingSolver {
  const SortingSolver();

  SortingResult solve(SortingProblem problem) {
    switch (problem.algorithm) {
      case SortingAlgorithm.selectionSort:
        return _solveSelectionSort(problem);
      case SortingAlgorithm.insertionSort:
        return _solveInsertionSort(problem);
      case SortingAlgorithm.mergeSort:
        return _solveMergeSort(problem);
      case SortingAlgorithm.shellSort:
        return _solveShellSort(problem);
    }
  }

  SortingResult _solveSelectionSort(SortingProblem problem) {
    final steps = <SortingStep>[];
    final array = SortingArray(problem.originalArray);
    var sortedCount = 0;
    int totalComparisons = 0;
    int totalSwaps = 0;

    // Initial state
    steps.add(
      SortingStep(
        array: array.snapshot,
        sortedIndices: {},
        description:
            'Selection Sort · ${problem.order.description}. ${array.length} elementos por ordenar.',
      ),
    );

    for (int i = 0; i < array.length - 1; i++) {
      int selectedIndex = i;

      // Select the next element according to the requested order
      for (int j = i + 1; j < array.length; j++) {
        totalComparisons++;

        // Step: comparing i and j
        steps.add(
          SortingStep(
            array: array.snapshot,
            comparingIndex1: selectedIndex,
            comparingIndex2: j,
            sortedIndices: SortedPrefix(sortedCount),
            description:
                'Comparando ${array[selectedIndex]} (posición $selectedIndex) con ${array[j]} (posición $j)',
          ),
        );

        if (problem.order.comesBefore(array[j], array[selectedIndex])) {
          selectedIndex = j;
        }
      }

      // Swap if necessary
      if (selectedIndex != i) {
        totalSwaps++;
        final temp = array[i];
        array[i] = array[selectedIndex];
        array[selectedIndex] = temp;

        steps.add(
          SortingStep(
            array: array.snapshot,
            movingIndex: i,
            sortedIndices: SortedPrefix(sortedCount),
            description:
                'Intercambiando elementos: ${array[i]} va a posición $i',
          ),
        );
      }

      // Mark as sorted
      sortedCount = i + 1;
      steps.add(
        SortingStep(
          array: array.snapshot,
          sortedIndices: SortedPrefix(sortedCount),
          description: 'Posición $i está en su lugar correcto: ${array[i]}',
        ),
      );
    }

    // Mark last element as sorted
    if (array.isNotEmpty) sortedCount = array.length;
    steps.add(
      SortingStep(
        array: array.snapshot,
        sortedIndices: SortedPrefix(sortedCount),
        description: '¡Ordenamiento completado! ${problem.order.description}.',
      ),
    );

    return SortingResult(
      steps: steps,
      totalComparisons: totalComparisons,
      totalSwaps: totalSwaps,
    );
  }

  SortingResult _solveInsertionSort(SortingProblem problem) {
    final steps = <SortingStep>[];
    final array = SortingArray(problem.originalArray);
    var sortedCount = 0;
    int totalComparisons = 0;
    int totalSwaps = 0;

    // Mark first element as sorted
    if (array.isNotEmpty) sortedCount = 1;
    steps.add(
      SortingStep(
        array: array.snapshot,
        sortedIndices: SortedPrefix(sortedCount),
        description:
            'Insertion Sort · ${problem.order.description}. ${array.isEmpty ? 'No hay elementos.' : 'El primer elemento inicia la porción ordenada.'}',
      ),
    );

    for (int i = 1; i < array.length; i++) {
      final key = array[i];

      steps.add(
        SortingStep(
          array: array.snapshot,
          movingIndex: i,
          sortedIndices: SortedPrefix(sortedCount),
          description:
              'Tomando elemento $i: ${array[i]}. Buscando posición correcta.',
        ),
      );

      int j = i - 1;

      // Count every element comparison, including the one that stops shifting.
      while (j >= 0) {
        final shouldShift = problem.order.comesBefore(key, array[j]);
        totalComparisons++;

        steps.add(
          SortingStep(
            array: array.snapshot,
            comparingIndex1: j,
            movingIndex: j + 1,
            sortedIndices: SortedPrefix(sortedCount),
            description:
                'Comparando ${array[j]} (posición $j) con $key. ${shouldShift ? 'Se desplaza para dejar espacio.' : 'La posición de inserción está lista.'}',
          ),
        );

        if (!shouldShift) break;

        array[j + 1] = array[j];
        totalSwaps++;

        steps.add(
          SortingStep(
            array: array.snapshot,
            movingIndex: j + 1,
            sortedIndices: SortedPrefix(sortedCount),
            description: 'Desplazando ${array[j]} a posición ${j + 1}',
          ),
        );

        j--;
      }

      // Insert key at correct position
      array[j + 1] = key;

      steps.add(
        SortingStep(
          array: array.snapshot,
          sortedIndices: SortedPrefix(sortedCount),
          description: 'Insertando $key en posición ${j + 1}',
        ),
      );

      sortedCount = i + 1;
      steps.add(
        SortingStep(
          array: array.snapshot,
          sortedIndices: SortedPrefix(sortedCount),
          description: 'Elementos 0-$i están en orden relativo correcto.',
        ),
      );
    }

    steps.add(
      SortingStep(
        array: array.snapshot,
        sortedIndices: SortedPrefix(sortedCount),
        description: '¡Ordenamiento completado! ${problem.order.description}.',
      ),
    );

    return SortingResult(
      steps: steps,
      totalComparisons: totalComparisons,
      totalSwaps: totalSwaps,
    );
  }

  SortingResult _solveMergeSort(SortingProblem problem) {
    final array = SortingArray(problem.originalArray);
    final buffer = List<Object>.filled(array.length, 0);
    final steps = <SortingStep>[];
    var comparisons = 0;
    var writes = 0;
    void record(
      String description, {
      int? first,
      int? second,
      int? moving,
      bool complete = false,
    }) {
      steps.add(
        SortingStep(
          array: array.snapshot,
          comparingIndex1: first,
          comparingIndex2: second,
          movingIndex: moving,
          sortedIndices: complete ? SortedPrefix(array.length) : {},
          description: description,
        ),
      );
    }

    void sortRange(int start, int end) {
      if (end - start <= 1) return;
      final middle = (start + end) ~/ 2;
      record('Dividiendo posiciones $start–${end - 1} en dos mitades.');
      sortRange(start, middle);
      sortRange(middle, end);
      var left = start;
      var right = middle;
      var target = start;
      while (left < middle && right < end) {
        comparisons++;
        record(
          'Combinando: comparar ${array[left]} con ${array[right]}.',
          first: left,
          second: right,
        );
        // Prefer the left value on equality to keep the merge stable.
        if (!problem.order.comesBefore(array[right], array[left])) {
          buffer[target++] = array[left++];
        } else {
          buffer[target++] = array[right++];
        }
      }
      while (left < middle) {
        buffer[target++] = array[left++];
      }
      while (right < end) {
        buffer[target++] = array[right++];
      }
      for (var i = start; i < end; i++) {
        array[i] = buffer[i];
        writes++;
        record(
          'Escribiendo ${array[i]} en la posición $i de la combinación.',
          moving: i,
        );
      }
      record('Tramo $start–${end - 1} combinado en orden.');
    }

    record(
      'Merge Sort · ${problem.order.description}. ${array.length} elementos por ordenar.',
    );
    sortRange(0, array.length);
    record(
      '¡Ordenamiento completado! ${problem.order.description}.',
      complete: true,
    );
    return SortingResult(
      steps: steps,
      totalComparisons: comparisons,
      totalSwaps: writes,
    );
  }

  SortingResult _solveShellSort(SortingProblem problem) {
    final array = SortingArray(problem.originalArray);
    final steps = <SortingStep>[];
    var comparisons = 0;
    var shifts = 0;
    void record(
      String description, {
      int? comparing,
      int? moving,
      bool complete = false,
    }) {
      steps.add(
        SortingStep(
          array: array.snapshot,
          comparingIndex1: comparing,
          movingIndex: moving,
          sortedIndices: complete ? SortedPrefix(array.length) : {},
          description: description,
        ),
      );
    }

    record(
      'Shell Sort · ${problem.order.description}. ${array.length} elementos por ordenar.',
    );
    for (var gap = array.length ~/ 2; gap > 0; gap ~/= 2) {
      record('Nueva pasada con salto $gap.');
      for (var i = gap; i < array.length; i++) {
        final key = array[i];
        var j = i;
        record('Tomando $key en posición $i; salto $gap.', moving: i);
        while (j >= gap) {
          comparisons++;
          final shouldShift = problem.order.comesBefore(key, array[j - gap]);
          record(
            'Salto $gap: comparar ${array[j - gap]} con $key.',
            comparing: j - gap,
            moving: j,
          );
          if (!shouldShift) break;
          array[j] = array[j - gap];
          shifts++;
          record(
            'Desplazando ${array[j]} a posición $j con salto $gap.',
            moving: j,
          );
          j -= gap;
        }
        array[j] = key;
        record('Insertando $key en posición $j.', moving: j);
      }
      record('Pasada con salto $gap completada.');
    }
    record(
      '¡Ordenamiento completado! ${problem.order.description}.',
      complete: true,
    );
    return SortingResult(
      steps: steps,
      totalComparisons: comparisons,
      totalSwaps: shifts,
    );
  }
}
