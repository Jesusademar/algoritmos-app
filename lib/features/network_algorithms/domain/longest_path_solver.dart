import 'dart:collection';

import 'package:app_grafos/features/network_algorithms/domain/network_objective.dart';
import 'package:app_grafos/features/network_algorithms/domain/weighted_network.dart';
import 'package:app_grafos/shared/domain/mathematical_procedure.dart';

/// Ruta máxima en una red dirigida acíclica: O(V + E).
/// No utiliza Dijkstra: fijar el mayor acumulado no resuelve caminos máximos.
class LongestPathSolver {
  const LongestPathSolver();

  NetworkPathResult solve(WeightedNetwork network, String source) {
    network.validate(nonNegative: true);
    if (!network.nodes.contains(source)) {
      throw ArgumentError('Selecciona un nodo de inicio válido.');
    }
    final adjacency = {for (final id in network.nodes) id: <WeightedEdge>[]};
    final incoming = {for (final id in network.nodes) id: 0};
    for (final edge in network.edges) {
      adjacency[edge.from]!.add(edge);
      incoming[edge.to] = incoming[edge.to]! + 1;
    }
    final pending = Queue<String>.of(
      network.nodes.where((id) => incoming[id] == 0),
    );
    final ordered = <String>[];
    while (pending.isNotEmpty) {
      final id = pending.removeFirst();
      ordered.add(id);
      for (final edge in adjacency[id]!) {
        incoming[edge.to] = incoming[edge.to]! - 1;
        if (incoming[edge.to] == 0) pending.add(edge.to);
      }
    }
    if (ordered.length != network.nodes.length) {
      throw ArgumentError(
        'Para maximizar, la red debe estar libre de ciclos. Elimina el ciclo o cambia a Minimizar.',
      );
    }
    final distances = <String, int>{source: 0};
    final predecessors = <String, WeightedEdge>{};
    final steps = <MathematicalStep>[
      MathematicalStep(
        title: 'Orden topológico',
        description: 'Se comprueba que no haya ciclos. Cada nodo se procesa después de todos sus predecesores.',
        expressions: [ordered.map(network.label).join(' → ')],
      ),
      MathematicalStep(
        title: 'Inicialización',
        description: 'El inicio tiene valor cero. −∞ identifica los nodos que todavía no tienen ruta desde el inicio.',
        expressions: ['d(${network.label(source)}) = 0'],
      ),
    ];
    for (final id in ordered) {
      final current = distances[id];
      if (current == null) continue;
      final expressions = <String>[];
      for (final edge in adjacency[id]!) {
        final candidate = current + edge.weight;
        final previous = distances[edge.to];
        final improves = previous == null || candidate > previous;
        expressions.add(
          'd(${network.label(edge.to)}) = max(${previous ?? '−∞'}, $current + ${edge.weight}) = ${improves ? candidate : previous}',
        );
        if (improves) {
          distances[edge.to] = candidate;
          predecessors[edge.to] = edge;
        }
      }
      steps.add(
        MathematicalStep(
          title: 'Procesar ${network.label(id)} · distancia $current',
          description:
              'Se conserva el mayor costo acumulado hacia cada sucesor.',
          expressions: expressions,
        ),
      );
    }
    steps.add(
      MathematicalStep(
        title: 'Distancias máximas finales',
        description:
            'Los nodos sin camino desde el inicio permanecen inalcanzables.',
        expressions: [
          for (final id in network.nodes)
            'd(${network.label(id)}) = ${distances[id] ?? '−∞'}',
        ],
      ),
    );
    return NetworkPathResult(
      source: source,
      objective: NetworkObjective.maximize,
      distances: distances,
      predecessors: predecessors,
      procedure: MathematicalProcedure(
        title: 'Procedimiento matemático · Rutas máximas',
        description: 'Modo Maximizar: programación dinámica en orden topológico, no Dijkstra. d(v) = max(d(v), d(u) + peso(u,v)).',
        steps: steps,
      ),
    );
  }
}
