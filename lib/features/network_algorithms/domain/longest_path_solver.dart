import 'dart:collection';

import 'package:app_grafos/features/network_algorithms/domain/network_objective.dart';
import 'package:app_grafos/features/network_algorithms/domain/weighted_network.dart';
import 'package:app_grafos/shared/domain/mathematical_procedure.dart';

/// Rutas máximas sin repetir nodos. En DAG utiliza orden topológico; con
/// ciclos explora todas las rutas simples. No aplica la selección de Dijkstra.
class LongestPathSolver {
  const LongestPathSolver();

  NetworkPathResult solve(WeightedNetwork network, String source) =>
      _steps(network, source).last!;

  /// Comparte el cálculo exacto con solve, cediendo tiempo a la interfaz.
  /// Cancelar descarta la búsqueda completa, sin presentar resultados parciales.
  Future<NetworkPathResult?> solveAsync(
    WeightedNetwork network,
    String source, {
    bool Function()? isCancelled,
  }) async {
    final watch = Stopwatch()..start();
    for (final result in _steps(network, source)) {
      if (isCancelled?.call() ?? false) return null;
      if (result != null) return result;
      if (watch.elapsedMilliseconds >= 8) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
        watch.reset();
      }
    }
    return null;
  }

  Iterable<NetworkPathResult?> _steps(
    WeightedNetwork network,
    String source,
  ) sync* {
    network.validate(nonNegative: true);
    if (!network.nodes.contains(source)) {
      throw ArgumentError('Selecciona un nodo de inicio válido.');
    }
    final adjacency = {for (final id in network.nodes) id: <WeightedEdge>[]};
    final incoming = {for (final id in network.nodes) id: 0};
    for (final edge in network.edges) {
      adjacency[edge.from]!.add(edge);
      incoming[edge.to] = incoming[edge.to]! + 1;
      yield null;
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
        yield null;
      }
    }
    if (ordered.length == network.nodes.length) {
      yield _acyclic(network, source, adjacency, ordered);
      return;
    }

    final distances = <String, int>{source: 0};
    final bestPaths = <String, List<WeightedEdge>>{source: const []};
    final visited = <String>{source};
    final path = <WeightedEdge>[];
    final stack = <_PathFrame>[
      _PathFrame(source, adjacency[source]!.iterator, 0),
    ];
    var explored = 0;
    var rejected = 0;
    while (stack.isNotEmpty) {
      yield null;
      final frame = stack.last;
      if (!frame.edges.moveNext()) {
        stack.removeLast();
        visited.remove(frame.node);
        if (path.isNotEmpty) path.removeLast();
        continue;
      }
      final edge = frame.edges.current;
      if (visited.contains(edge.to)) {
        rejected++;
        continue;
      }
      explored++;
      final candidate = frame.cost + edge.weight;
      path.add(edge);
      final previous = distances[edge.to];
      if (previous == null || candidate > previous) {
        distances[edge.to] = candidate;
        bestPaths[edge.to] = List.of(path);
      }
      // No se descarta un prefijo por ser más barato: deja disponibles otros
      // nodos y puede dar la mejor ruta a un destino posterior.
      visited.add(edge.to);
      stack.add(_PathFrame(edge.to, adjacency[edge.to]!.iterator, candidate));
    }
    final steps = <MathematicalStep>[
      MathematicalStep(
        title: 'Criterio de maximización',
        description: 'Se permiten ciclos en la red. Cada ruta empieza en el origen y visita cada nodo como máximo una vez. No se acumula un ciclo indefinidamente.',
        expressions: ['d(${network.label(source)}) = 0'],
      ),
      MathematicalStep(
        title: 'Explorar todas las rutas simples',
        description: 'Búsqueda exacta con retroceso. Se prueban las conexiones disponibles, se evita volver a un nodo de la ruta actual y se conserva el mejor camino completo para cada destino.',
        expressions: [
          'Rutas no vacías exploradas = $explored',
          'Extensiones descartadas por repetir nodo = $rejected',
        ],
      ),
      for (final id in network.nodes)
        MathematicalStep(
          title: 'Mejor ruta a ${network.label(id)}',
          description: !bestPaths.containsKey(id)
              ? 'Sin ruta desde el inicio.'
              : [
                  network.label(source),
                  ...bestPaths[id]!.map((edge) => network.label(edge.to)),
                ].join(' → '),
          expressions: [
            if (id == source)
              'd(${network.label(id)}) = 0'
            else if (bestPaths.containsKey(id))
              '${bestPaths[id]!.map((edge) => edge.weight).join(' + ')} = ${distances[id]}'
            else
              'd(${network.label(id)}) = −∞ · inalcanzable',
          ],
        ),
    ];
    yield NetworkPathResult(
      source: source,
      objective: NetworkObjective.maximize,
      method: NetworkPathMethod.simplePaths,
      distances: distances,
      predecessors: const {},
      paths: bestPaths,
      procedure: MathematicalProcedure(
        title: 'Procedimiento matemático · Rutas máximas',
        description: 'Mayor costo entre todas las rutas dirigidas sin repetir nodos. Se conservan caminos completos independientes por destino; no se utiliza Dijkstra para maximizar.',
        steps: steps,
      ),
    );
  }

  NetworkPathResult _acyclic(
    WeightedNetwork network,
    String source,
    Map<String, List<WeightedEdge>> adjacency,
    List<String> ordered,
  ) {
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
      method: NetworkPathMethod.topological,
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

class _PathFrame {
  _PathFrame(this.node, this.edges, this.cost);
  final String node;
  final Iterator<WeightedEdge> edges;
  final int cost;
}
