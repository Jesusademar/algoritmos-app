/// Valores enteros int o BigInt; los índices y contadores siguen siendo int.
/// BigInt conserva todas las cifras también en navegador.
abstract final class SortingNumbers {
  static final _safeInteger = BigInt.parse('9007199254740991');
  static BigInt integer(Object value) => switch (value) {
    int number => BigInt.from(number),
    BigInt number => number,
    _ => throw const FormatException('Utiliza únicamente números enteros.'),
  };
  static Object compact(BigInt value) =>
      value.abs() <= _safeInteger ? value.toInt() : value;
  static Object parse(String text) {
    final cleaned = text.trim();
    if (!RegExp(r'^[+-]?\d+$').hasMatch(cleaned)) {
      throw const FormatException(
        'Utiliza números enteros, por ejemplo: -25, 0, 1500.',
      );
    }
    return compact(BigInt.parse(cleaned));
  }

  static int compare(Object first, Object second) =>
      first is int && second is int
      ? first.compareTo(second)
      : integer(first).compareTo(integer(second));
}

/// Escala visual independiente de la cantidad de cifras y del signo.
class SortingScale {
  SortingScale(List<Object> values) {
    minimum = values.isEmpty
        ? BigInt.zero
        : SortingNumbers.integer(values.first);
    maximum = minimum;
    for (final value in values.skip(1)) {
      final number = SortingNumbers.integer(value);
      if (number < minimum) minimum = number;
      if (number > maximum) maximum = number;
    }
  }
  late BigInt minimum;
  late BigInt maximum;
  double fraction(Object value) {
    final span = maximum - minimum;
    if (span == BigInt.zero) return 0.5;
    final scaled =
        ((SortingNumbers.integer(value) - minimum) * BigInt.from(1000000)) ~/
        span;
    return (scaled.toDouble() / 1000000).clamp(0, 1);
  }
}
