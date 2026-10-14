import 'package:app_grafos/features/assignment/domain/optimization_mode.dart';

/// Elemento que participa como origen o destino de una asignación.
class AssignmentItem {
  const AssignmentItem({
    required this.id,
    required this.label,
    this.isDummy = false,
  });

  final String id;
  final String label;
  final bool isDummy;
}

/// Costo o beneficio disponible entre un origen y un destino.
class AssignmentCost {
  const AssignmentCost({
    required this.originId,
    required this.destinationId,
    required this.value,
  });

  final String originId;
  final String destinationId;
  final num value;
}

/// Entrada independiente de Flutter para el problema de asignación.
class AssignmentProblem {
  AssignmentProblem({
    required List<AssignmentItem> origins,
    required List<AssignmentItem> destinations,
    required List<AssignmentCost> costs,
    required this.mode,
  }) : origins = List.unmodifiable(origins),
       destinations = List.unmodifiable(destinations),
       costs = List.unmodifiable(costs);

  final List<AssignmentItem> origins;
  final List<AssignmentItem> destinations;
  final List<AssignmentCost> costs;
  final OptimizationMode mode;

  /// Completa únicamente el lado más corto con elementos de costo cero.
  /// Las rutas reales ausentes siguen estando prohibidas.
  AssignmentProblem toSquare() {
    if (origins.length == destinations.length) return this;
    final rows = List<AssignmentItem>.of(origins);
    final columns = List<AssignmentItem>.of(destinations);
    final squareCosts = List<AssignmentCost>.of(costs);
    final usedIds = {
      ...rows.map((item) => item.id),
      ...columns.map((item) => item.id),
    };
    String dummyId(String prefix, int number) {
      var id = '__${prefix}_$number';
      while (usedIds.contains(id)) {
        id = '${id}_';
      }
      usedIds.add(id);
      return id;
    }

    final size = rows.length > columns.length ? rows.length : columns.length;
    while (rows.length < size) {
      final number = rows.length - origins.length + 1;
      rows.add(
        AssignmentItem(
          id: dummyId('origin', number),
          label: 'Origen ficticio $number',
          isDummy: true,
        ),
      );
    }
    while (columns.length < size) {
      final number = columns.length - destinations.length + 1;
      columns.add(
        AssignmentItem(
          id: dummyId('destination', number),
          label: 'Destino ficticio $number',
          isDummy: true,
        ),
      );
    }
    for (final row in rows) {
      for (final column in columns) {
        if (row.isDummy || column.isDummy) {
          squareCosts.add(
            AssignmentCost(
              originId: row.id,
              destinationId: column.id,
              value: 0,
            ),
          );
        }
      }
    }
    return AssignmentProblem(
      origins: rows,
      destinations: columns,
      costs: squareCosts,
      mode: mode,
    );
  }

  num? costFor(String originId, String destinationId) {
    for (final cost in costs) {
      if (cost.originId == originId && cost.destinationId == destinationId) {
        return cost.value;
      }
    }
    return null;
  }
}
