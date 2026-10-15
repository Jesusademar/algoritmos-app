import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:app_grafos/features/sorting/domain/sorting_algorithm.dart';
import 'package:app_grafos/features/sorting/domain/sorting_document.dart';
import 'package:app_grafos/features/sorting/domain/sorting_numbers.dart';
import 'package:app_grafos/features/sorting/domain/sorting_order.dart';
import 'package:app_grafos/features/sorting/domain/sorting_problem.dart';
import 'package:app_grafos/features/sorting/domain/sorting_snapshot.dart';
import 'package:app_grafos/features/sorting/domain/sorting_solver.dart';
import 'package:app_grafos/features/sorting/domain/sorting_validator.dart';

void main() {
  test('cantidad libre y rango inclusivo definido por el usuario, con o sin repetidos', () {
    final many = SortingValidator.generateRandomArray(
      5000,
      minimum: -2,
      maximum: 2,
      random: Random(14),
    );
    expect(many, hasLength(5000));
    expect(many.toSet(), {-2, -1, 0, 1, 2});
    final unique = SortingValidator.generateRandomArray(
      200,
      minimum: 1000,
      maximum: 1199,
      unique: true,
      random: Random(14),
    );
    expect(unique.toSet(), List.generate(200, (i) => i + 1000).toSet());
    expect(
      SortingValidator.generateRandomArray(240, minimum: 0, maximum: 0),
      everyElement(0),
    );
    expect(
      () => SortingValidator.generateRandomArray(
        6,
        minimum: -2,
        maximum: 2,
        unique: true,
      ),
      throwsArgumentError,
    );
    expect(
      () => SortingValidator.generateRandomArray(2, minimum: 5, maximum: -1),
      throwsArgumentError,
    );
    expect(() => SortingValidator.generateRandomArray(0), throwsArgumentError);
  });
  test(
    'rangos de cientos de cifras conservan precisión sin enumerar el rango',
    () {
      final huge = BigInt.parse('9' * 300);
      for (final unique in [true, false]) {
        final values = SortingValidator.generateRandomArray(
          200,
          minimum: -huge,
          maximum: huge,
          unique: unique,
          random: Random(2),
        );
        expect(values, hasLength(200));
        expect(
          values.every((value) => SortingNumbers.integer(value).abs() <= huge),
          isTrue,
        );
        if (unique) expect(values.toSet(), hasLength(200));
      }
      final narrow = SortingValidator.generateRandomArray(
        10,
        minimum: huge,
        maximum: huge + BigInt.from(9),
        unique: true,
        random: Random(2),
      );
      expect(
        narrow.toSet(),
        List.generate(10, (i) => huge + BigInt.from(i)).toSet(),
      );
    },
  );
  test(
    'los cuatro métodos ordenan enteros de mil cifras y JSON conserva su valor',
    () {
      final huge = '9' * 1000;
      final (input, error) = SortingValidator.parseInputString(
        '+$huge, -$huge, 0, 9007199254740993, 9007199254740992, -1, 0',
      );
      expect(error, isNull);
      final expected = [
        '-$huge',
        '-1',
        '0',
        '0',
        '9007199254740992',
        '9007199254740993',
        huge,
      ];
      for (final method in SortingAlgorithm.values) {
        for (final order in SortingOrder.values) {
          final result = const SortingSolver().solve(
            SortingProblem(
              originalArray: input,
              algorithm: method,
              order: order,
            ),
          );
          expect(
            result.finalArray.map((value) => value.toString()).toList(),
            order == SortingOrder.ascending
                ? expected
                : expected.reversed.toList(),
          );
          expect(result.steps.first.array, input);
          final document = SortingDocument(
            name: 'cifras completas',
            algorithm: method,
            order: order,
            originalArray: input,
            stepIndex: result.stepCount - 1,
          );
          final loaded = SortingDocument.decode(document.encode());
          expect(loaded.originalArray, input);
          expect(loaded.stepIndex, result.stepCount - 1);
          expect(jsonDecode(document.encode())['version'], 2);
        }
      }
    },
  );
  test(
    'archivos anteriores siguen funcionando y entradas inválidas se rechazan',
    () {
      final loaded = SortingDocument.decode(
        jsonEncode({
          'formato': 'logiverse.sorting',
          'version': 1,
          'nombreArchivo': 'anterior',
          'algoritmo': 'mergeSort',
          'sentido': 'ascending',
          'numeros': [-1000, 0, 2000],
          'velocidad': 1,
          'paso': 0,
        }),
      );
      expect(loaded.originalArray, [-1000, 0, 2000]);
      for (final invalid in ['', '1,,2', '1.2,3', 'abc', '1e8']) {
        expect(SortingValidator.parseInputString(invalid).$2, isNotNull);
      }
    },
  );
  test(
    'instantáneas y prefijos inmutables no cambian al avanzar el algoritmo',
    () {
      final array = SortingArray(List.generate(1024, (i) => i));
      final before = array.snapshot;
      array[0] = -1;
      final middle = array.snapshot;
      array[0] = -2;
      array[1023] = BigInt.parse('9' * 100);
      expect(before[0], 0);
      expect(before[1023], 1023);
      expect(middle[0], -1);
      expect(middle[1023], 1023);
      expect(() => before[0] = 10, throwsUnsupportedError);
      final prefix = SortedPrefix(3);
      expect(prefix, {0, 1, 2});
      expect(prefix.contains(-1), isFalse);
      expect(prefix.contains(3), isFalse);
      expect(() => prefix.add(3), throwsUnsupportedError);
      final scale = SortingScale([-1, 0, BigInt.parse('9' * 1000)]);
      expect(scale.fraction(-1), 0);
      expect(scale.fraction(BigInt.parse('9' * 1000)), 1);
    },
  );
  test('Merge ordena miles de valores sin conservar copias completas por comparación', () {
    final input = List.generate(3000, (i) => 1500 - i);
    final result = const SortingSolver().solve(
      SortingProblem(
        originalArray: input,
        algorithm: SortingAlgorithm.mergeSort,
      ),
    );
    expect(result.finalArray, List.generate(3000, (i) => i - 1499));
    expect(result.steps.first.array, input);
  });
}
