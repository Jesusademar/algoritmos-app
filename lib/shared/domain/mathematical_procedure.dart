/// Explicación inmutable de los cálculos, independiente de la interfaz.
class MathematicalProcedure {
  MathematicalProcedure({
    required this.title,
    required this.description,
    required List<MathematicalStep> steps,
  }) : steps = List.unmodifiable(steps);
  final String title;
  final String description;
  final List<MathematicalStep> steps;
}

class MathematicalStep {
  MathematicalStep({
    required this.title,
    required this.description,
    List<String> expressions = const [],
    this.table,
  }) : expressions = List.unmodifiable(expressions);
  final String title;
  final String description;
  final List<String> expressions;
  final MathematicalTable? table;
}

class MathematicalTable {
  MathematicalTable({
    required List<String> columns,
    required List<List<String>> rows,
  }) : columns = List.unmodifiable(columns),
       rows = List.unmodifiable(
         rows.map((row) => List<String>.unmodifiable(row)),
       );
  final List<String> columns;
  final List<List<String>> rows;
}

String mathNumber(num value) {
  if (!value.isFinite) return value.toString();
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  final text = value.toStringAsPrecision(10);
  return text.contains('e')
      ? text
      : text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
}

String mathTerm(num value) =>
    value < 0 ? '(${mathNumber(value)})' : mathNumber(value);
