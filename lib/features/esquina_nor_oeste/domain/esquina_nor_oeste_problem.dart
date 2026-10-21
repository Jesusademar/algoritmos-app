import 'package:app_grafos/features/esquina_nor_oeste/domain/optimization_mode.dart';

/// Elemento que participa como origen (oferta) o destino (demanda).
class EsquinaNorOesteItem {
  const EsquinaNorOesteItem({
    required this.id,
    required this.label,
    this.supply = 0,
    this.demand = 0,
    this.isDummy = false,
  });

  final String id;
  final String label;
  final num supply;
  final num demand;
  final bool isDummy;
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

  num get totalSupply =>
      origins.fold<num>(0, (sum, origin) => sum + origin.supply);
  num get totalDemand =>
      destinations.fold<num>(0, (sum, destination) => sum + destination.demand);

  /// La misma matriz ampliada se utiliza para calcular y para mostrar los datos.
  EsquinaNorOesteProblem toBalanced() {
    if (origins.any((item) => !item.supply.isFinite || item.supply < 0) ||
        destinations.any((item) => !item.demand.isFinite || item.demand < 0) ||
        !totalSupply.isFinite ||
        !totalDemand.isFinite) {
      return this;
    }
    final difference = totalSupply - totalDemand;
    if (difference.abs() <= 1e-9) return this;
    final ids = {
      ...origins.map((item) => item.id),
      ...destinations.map((item) => item.id),
    };
    var dummyId = '__transport_dummy__';
    while (ids.contains(dummyId)) {
      dummyId += '_';
    }
    final extraOrigin = difference < 0;
    final dummy = EsquinaNorOesteItem(
      id: dummyId,
      label: extraOrigin ? 'Origen ficticio' : 'Destino ficticio',
      isDummy: true,
      supply: extraOrigin ? -difference : 0,
      demand: extraOrigin ? 0 : difference,
    );
    return EsquinaNorOesteProblem(
      origins: [...origins, if (extraOrigin) dummy],
      destinations: [...destinations, if (!extraOrigin) dummy],
      costs: [
        ...costs,
        if (extraOrigin)
          for (final destination in destinations)
            EsquinaNorOesteCost(
              originId: dummy.id,
              destinationId: destination.id,
              value: 0,
            )
        else
          for (final origin in origins)
            EsquinaNorOesteCost(
              originId: origin.id,
              destinationId: dummy.id,
              value: 0,
            ),
      ],
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
