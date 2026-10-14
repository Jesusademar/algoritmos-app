import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:app_grafos/features/sorting/domain/sorting_algorithm.dart';
import 'package:app_grafos/features/sorting/domain/sorting_document.dart';
import 'package:app_grafos/features/sorting/domain/sorting_order.dart';
import 'package:app_grafos/features/sorting/presentation/providers/sorting_visualization_provider.dart';

void main() {
  test('los cuatro métodos conservan entrada, sentido, velocidad y paso', () {
    for (final algorithm in SortingAlgorithm.values) {
      final input = [9, 3, 6, 3];
      final document = SortingDocument(
        name: 'sesión ñ',
        algorithm: algorithm,
        order: SortingOrder.descending,
        originalArray: input,
        speed: 2,
        stepIndex: 2,
      );
      input[0] = 100;
      final loaded = SortingDocument.decode(document.encode());
      expect(loaded.originalArray, [9, 3, 6, 3]);
      expect(loaded.algorithm, algorithm);
      expect(loaded.order, SortingOrder.descending);
      expect(loaded.speed, 2);
      expect(loaded.stepIndex, 2);
      final provider = SortingVisualizationProvider(
        array: loaded.originalArray,
        algorithm: loaded.algorithm,
        order: loaded.order,
        initialSpeed: loaded.speed,
        initialStepIndex: loaded.stepIndex,
      );
      expect(provider.isPlaying, isFalse);
      expect(provider.currentStepIndex, 2);
      expect(provider.finalArray, [9, 6, 3, 3]);
      provider.reset();
      expect(provider.currentArray, [9, 3, 6, 3]);
      provider.dispose();
    }
  });

  test(
    'rechaza datos incompletos, otros módulos y parámetros fuera de rango',
    () {
      final original = jsonDecode(
        SortingDocument(
          name: 'prueba',
          algorithm: SortingAlgorithm.mergeSort,
          order: SortingOrder.ascending,
          originalArray: [5, 1, 2],
        ).encode(),
      ) as Map<String, dynamic>;
      for (final change in <Map<String, dynamic>>[
        {'formato': 'logiverse.binary_tree'},
        {'version': 2},
        {'algoritmo': 'otro'},
        {'sentido': 'otro'},
        {'numeros': []},
        {
          'numeros': [0, 2],
        },
        {
          'numeros': [101],
        },
        {
          'numeros': [1.5],
        },
        {
          'numeros': ['1'],
        },
        {'numeros': List.filled(21, 1)},
        {'velocidad': 0},
        {'velocidad': '2'},
        {'paso': -1},
        {'paso': 999999},
        {'paso': 0.5},
      ]) {
        expect(
          () => SortingDocument.decode(jsonEncode({...original, ...change})),
          throwsFormatException,
        );
      }
      expect(() => SortingDocument.decode('[]'), throwsFormatException);
      expect(() => SortingDocument.decode('no json'), throwsFormatException);
    },
  );
}
