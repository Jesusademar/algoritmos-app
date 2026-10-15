import 'package:flutter_test/flutter_test.dart';

import 'package:app_grafos/features/sorting/domain/sorting_algorithm.dart';
import 'package:app_grafos/features/sorting/domain/sorting_document.dart';
import 'package:app_grafos/features/sorting/domain/sorting_numbers.dart';
import 'package:app_grafos/features/sorting/domain/sorting_order.dart';
import 'package:app_grafos/features/sorting/domain/sorting_problem.dart';
import 'package:app_grafos/features/sorting/domain/sorting_solver.dart';
import 'package:app_grafos/features/sorting/domain/sorting_validator.dart';

void main() {
  test('aleatorios acotados, únicos y válidos también en navegador', () {
    for (var size = 1; size <= 100; size++) {
      final numbers = SortingValidator.generateRandomArray(size, unique: true);
      expect(numbers, hasLength(size));
      expect(numbers.toSet(), hasLength(size));
      expect(
        numbers.every(
          (number) =>
              SortingNumbers.compare(number, 1) >= 0 &&
              SortingNumbers.compare(number, 100) <= 0,
        ),
        isTrue,
      );
      expect(SortingValidator.validateArray(numbers).$1, isTrue);
    }
    expect(() => SortingValidator.generateRandomArray(0), throwsArgumentError);
    expect(
      () => SortingValidator.generateRandomArray(101, unique: true),
      throwsArgumentError,
    );
  });

  test('los cuatro métodos ordenan 100 números en ambos sentidos y se pueden cargar', () {
    final numbers = SortingValidator.generateRandomArray(100, unique: true);
    final (parsed, error) = SortingValidator.parseInputString(
      numbers.join(', '),
    );
    expect(error, isNull);
    expect(parsed, numbers);
    for (final algorithm in SortingAlgorithm.values) {
      for (final order in SortingOrder.values) {
        final result = const SortingSolver().solve(
          SortingProblem(
            originalArray: numbers,
            algorithm: algorithm,
            order: order,
          ),
        );
        final expected = List.generate(100, (index) => index + 1);
        expect(
          result.finalArray,
          order == SortingOrder.ascending
              ? expected
              : expected.reversed.toList(),
        );
        expect(numbers.toSet(), hasLength(100));
        final document = SortingDocument.decode(
          SortingDocument(
            name: '100 aleatorios',
            algorithm: algorithm,
            order: order,
            originalArray: numbers,
            stepIndex: result.stepCount - 1,
          ).encode(),
        );
        expect(document.originalArray, numbers);
        expect(document.stepIndex, result.stepCount - 1);
      }
    }
  });
}
