import 'optimization_mode.dart';

/// Elemento que participa como origen o destino de una asignación.
class AssignmentItem {
  const AssignmentItem({required this.id, required this.label});

  final String id;
  final String label;
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

  num? costFor(String originId, String destinationId) {
    for (final cost in costs) {
      if (cost.originId == originId && cost.destinationId == destinationId) {
        return cost.value;
      }
    }
    return null;
  }
}
