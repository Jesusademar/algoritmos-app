import 'package:flutter_test/flutter_test.dart';

import 'package:app_grafos/features/sorting/domain/sorting_validator.dart';

void main() {
  test('aleatorios acotados, únicos y válidos también en navegador', () {
    for (var size = 1; size <= 20; size++) {
      final numbers = SortingValidator.generateRandomArray(size);
      expect(numbers, hasLength(size));
      expect(numbers.toSet(), hasLength(size));
      expect(numbers.every((number) => number >= 1 && number <= 100), isTrue);
      expect(SortingValidator.validateArray(numbers).$1, isTrue);
    }
    expect(() => SortingValidator.generateRandomArray(0), throwsArgumentError);
    expect(() => SortingValidator.generateRandomArray(21), throwsArgumentError);
  });
}
