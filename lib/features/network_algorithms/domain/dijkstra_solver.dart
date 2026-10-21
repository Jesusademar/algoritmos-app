import 'package:app_grafos/features/network_algorithms/domain/weighted_network.dart';
import 'package:app_grafos/shared/domain/mathematical_procedure.dart';

/// Selección del mínimo por exploración: O(V² + E), sin dependencias externas.
class DijkstraSolver {
  const DijkstraSolver();
  NetworkPathResult solve(WeightedNetwork network, String source) {
    network.validate(nonNegative: true);
    if (!network.nodes.contains(source)) {
      throw ArgumentError('Selecciona un nodo de inicio válido.');
    }
    final adjacency = {for (final id in network.nodes) id: <WeightedEdge>[]};
    for (final edge in network.edges) {
      adjacency[edge.from]!.add(edge);
    }
    final distances = <String, int>{source: 0};
    final predecessors = <String, WeightedEdge>{};
    final settled = <String>{};
    final steps = <MathematicalStep>[
      MathematicalStep(
        title: 'Inicialización',
        description: 'El inicio tiene distancia cero. Los demás nodos tienen distancia infinita hasta que se descubra una ruta.',
        expressions: ['d(${network.label(source)}) = 0'],
      ),
    ];
    while (true) {
      String? current;
      int? best;
      for (final id in network.nodes) {
        final distance = distances[id];
        if (!settled.contains(id) &&
            distance != null &&
            (best == null || distance < best)) {
          current = id;
          best = distance;
        }
      }
      if (current == null) break;
      settled.add(current);
      final expressions = <String>[];
      for (final edge in adjacency[current]!) {
        if (settled.contains(edge.to)) continue;
        final candidate = best! + edge.weight;
        final previous = distances[edge.to];
        final improves = previous == null || candidate < previous;
        expressions.add(
          'd(${network.label(edge.to)}) = min(${previous ?? '∞'}, $best + ${edge.weight}) = ${improves ? candidate : previous}',
        );
        if (improves) {
          distances[edge.to] = candidate;
          predecessors[edge.to] = edge;
        }
      }
      steps.add(
        MathematicalStep(
          title: 'Fijar ${network.label(current)} · distancia $best',
          description: 'Es el nodo pendiente con menor distancia. Se revisan sus conexiones de salida.',
          expressions: expressions,
        ),
      );
    }
    steps.add(
      MathematicalStep(
        title: 'Distancias finales',
        description:
            '∞ indica que no existe un camino dirigido desde el inicio.',
        expressions: [
          for (final id in network.nodes)
            'd(${network.label(id)}) = ${distances[id] ?? '∞'}',
        ],
      ),
    );
    return NetworkPathResult(
      source: source,
      distances: distances,
      predecessors: predecessors,
      procedure: MathematicalProcedure(
        title: 'Procedimiento matemático · Dijkstra',
        description:
            'Rutas mínimas desde ${network.label(source)} con pesos no negativos. Relajación: d(v) = min(d(v), d(u) + peso(u,v)).',
        steps: steps,
      ),
    );
  }
}
