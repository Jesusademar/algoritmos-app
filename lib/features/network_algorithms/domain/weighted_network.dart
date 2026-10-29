import 'package:app_grafos/shared/domain/mathematical_procedure.dart';
import 'package:app_grafos/features/network_algorithms/domain/network_objective.dart';

class WeightedEdge {
  const WeightedEdge(this.from, this.to, this.weight);
  final String from;
  final String to;
  final int weight;
  (String, String) get id => (from, to);
}

class WeightedNetwork {
  WeightedNetwork({
    required Iterable<String> nodes,
    required Iterable<WeightedEdge> edges,
    Map<String, String> labels = const {},
  }) : nodes = List.unmodifiable(nodes),
       edges = List.unmodifiable(edges),
       labels = Map.unmodifiable(labels);
  final Map<String, String> labels;
  String label(String id) => labels[id] ?? id;
  final List<String> nodes;
  final List<WeightedEdge> edges;

  void validate({bool nonNegative = false}) {
    if (nodes.isEmpty) throw ArgumentError('Agrega al menos un nodo.');
    if (nodes.toSet().length != nodes.length) {
      throw ArgumentError('Los nodos deben tener identificadores únicos.');
    }
    final ids = nodes.toSet();
    for (final edge in edges) {
      if (!ids.contains(edge.from) || !ids.contains(edge.to)) {
        throw ArgumentError('Una conexión apunta a un nodo inexistente.');
      }
      if (edge.from == edge.to) {
        throw ArgumentError('No se permiten bucles en un nodo.');
      }
      if (nonNegative && edge.weight < 0) {
        throw ArgumentError(
          'Dijkstra requiere pesos mayores o iguales a cero.',
        );
      }
    }
  }
}

class KruskalResult {
  KruskalResult({
    required Iterable<WeightedEdge> edges,
    required this.components,
    this.objective = NetworkObjective.minimize,
    required this.procedure,
  }) : edges = List.unmodifiable(edges);
  final List<WeightedEdge> edges;
  final int components;
  final NetworkObjective objective;
  final MathematicalProcedure procedure;
  int get total => edges.fold(0, (sum, edge) => sum + edge.weight);
}

enum NetworkPathMethod { dijkstra, topological, simplePaths }

class NetworkPathResult {
  NetworkPathResult({
    required this.source,
    this.objective = NetworkObjective.minimize,
    required Map<String, int> distances,
    required Map<String, WeightedEdge> predecessors,
    required this.procedure,
    this.method = NetworkPathMethod.dijkstra,
    Map<String, List<WeightedEdge>> paths = const {},
  }) : distances = Map.unmodifiable(distances),
       predecessors = Map.unmodifiable(predecessors),
       paths = Map.unmodifiable({
         for (final entry in paths.entries)
           entry.key: List<WeightedEdge>.unmodifiable(entry.value),
       });
  final String source;
  final NetworkObjective objective;
  final Map<String, int> distances;
  final Map<String, WeightedEdge> predecessors;
  final MathematicalProcedure procedure;
  final NetworkPathMethod method;
  // En redes con ciclos la mejor ruta a cada destino se conserva completa:
  // sus predecesores pueden ser incompatibles con los de otros destinos.
  final Map<String, List<WeightedEdge>> paths;
  String get timeComplexity => switch (method) {
    NetworkPathMethod.dijkstra => 'O(V² + E)',
    NetworkPathMethod.topological => 'O(V + E)',
    NetworkPathMethod.simplePaths => 'O(V!)',
  };
  String get spaceComplexity =>
      method == NetworkPathMethod.simplePaths ? 'O(V² + E)' : 'O(V + E)';
  String get methodLabel => switch (method) {
    NetworkPathMethod.dijkstra => 'Dijkstra',
    NetworkPathMethod.topological => 'Orden topológico',
    NetworkPathMethod.simplePaths => 'Búsqueda exacta de rutas simples',
  };
  List<WeightedEdge>? pathTo(String target) {
    if (!distances.containsKey(target)) return null;
    if (paths.containsKey(target)) return paths[target];
    final visited = <String>{};
    final reversed = <WeightedEdge>[];
    var current = target;
    while (current != source) {
      if (!visited.add(current)) return null;
      final edge = predecessors[current];
      if (edge == null) return null;
      reversed.add(edge);
      current = edge.from;
    }
    return reversed.reversed.toList(growable: false);
  }
}
