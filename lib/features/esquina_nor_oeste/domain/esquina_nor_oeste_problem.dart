import 'package:app_grafos/features/esquina_nor_oeste/domain/optimization_mode.dart';

/// Elemento que participa como origen (oferta) o destino (demanda).
class EsquinaNorOesteItem {
  const EsquinaNorOesteItem({
    required this.id,
    required this.label,
    this.supply = 0,
    this.demand = 0,
  });

  final String id;
  final String label;
  final num supply;
  final num demand;
}

/// Costo unitario de transporte entre un origen y un destino.
class EsquinaNorOesteCost {
  const EsquinaNorOesteCost({
    required this.originId,
    required this.destinationId,
    required this.value,
  });

  final String originId;
  final String destinationId;
  final num value;
}

/// Definición del problema de transporte para Esquina Nor-Oeste.
class EsquinaNorOesteProblem {
  EsquinaNorOesteProblem({
    required List<EsquinaNorOesteItem> origins,
    required List<EsquinaNorOesteItem> destinations,
    required List<EsquinaNorOesteCost> costs,
    required this.mode,
  }) : origins = List.unmodifiable(origins),
       destinations = List.unmodifiable(destinations),
       costs = List.unmodifiable(costs);

  final List<EsquinaNorOesteItem> origins;
  final List<EsquinaNorOesteItem> destinations;
  final List<EsquinaNorOesteCost> costs;
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
