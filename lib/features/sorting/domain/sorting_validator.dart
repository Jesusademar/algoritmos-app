import 'dart:math';

import 'package:app_grafos/features/sorting/domain/sorting_numbers.dart';

class SortingValidator {
  static (bool, String?) validateArray(List<Object> numbers) {
    if (numbers.isEmpty) return (false, 'La lista no puede estar vacía.');
    if (numbers.any((value) => value is! int && value is! BigInt)) {
      return (false, 'Utiliza únicamente números enteros.');
    }
    return (true, null);
  }

  static (List<Object>, String?) parseInputString(String input) {
    if (input.trim().isEmpty) return ([], 'Ingresa al menos un número.');
    try {
      return (input.split(',').map(SortingNumbers.parse).toList(), null);
    } on FormatException catch (error) {
      return ([], error.message);
    }
  }

  /// Rango inclusivo sin crear una lista con todos sus posibles valores.
  static List<Object> generateRandomArray(
    int size, {
    Object minimum = 1,
    Object maximum = 100,
    bool unique = false,
    Random? random,
  }) {
    if (size <= 0) {
      throw ArgumentError('La cantidad debe ser un entero mayor que cero.');
    }
    final lower = SortingNumbers.integer(minimum);
    final upper = SortingNumbers.integer(maximum);
    if (lower > upper) {
      throw ArgumentError('El mínimo no puede ser mayor que el máximo.');
    }
    final width = upper - lower + BigInt.one;
    if (unique && BigInt.from(size) > width) {
      throw ArgumentError(
        'El rango no contiene suficientes números distintos. Permite repetidos o amplía el rango.',
      );
    }
    final generator = random ?? Random();
    if (!unique) {
      return List.generate(
        size,
        (_) => SortingNumbers.compact(lower + _below(width, generator)),
      );
    }
    // Muestreo de Floyd: cantidad exacta sin reintentos por colisiones.
    final chosen = <BigInt>{};
    for (
      var remaining = width - BigInt.from(size);
      remaining < width;
      remaining += BigInt.one
    ) {
      final candidate = _below(remaining + BigInt.one, generator);
      chosen.add(chosen.contains(candidate) ? remaining : candidate);
    }
    return chosen.map((value) => SortingNumbers.compact(lower + value)).toList()
      ..shuffle(generator);
  }

  static BigInt _below(BigInt bound, Random random) {
    if (bound == BigInt.one) return BigInt.zero;
    final bits = (bound - BigInt.one).bitLength;
    while (true) {
      var number = BigInt.zero;
      var remaining = bits;
      while (remaining > 0) {
        final take = min(26, remaining);
        number = (number << take) | BigInt.from(random.nextInt(1 << take));
        remaining -= take;
      }
      if (number < bound) return number;
    }
  }
}
