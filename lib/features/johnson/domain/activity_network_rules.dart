import 'package:app_grafos/features/johnson/domain/activity_network_problem.dart';

/// Las actividades forman una red dirigida sin bucles ni ciclos.
class ActivityNetworkRules {
  const ActivityNetworkRules();

  String? connectionError(
    String source,
    String target,
    Iterable<ActivityEdge> edges,
  ) {
    if (source == target) return 'No se permiten bucles en un mismo nodo.';
    final existing = edges.toList();
    if (existing.any((e) => e.sourceId == target && e.targetId == source)) {
      return 'Solo se permite un sentido entre dos nodos. Ya existe la conexión inversa.';
    }
    final pending = <String>[target];
    final visited = <String>{};
    while (pending.isNotEmpty) {
      final node = pending.removeLast();
      if (node == source) return 'La conexión crearía un ciclo en la red.';
      if (!visited.add(node)) continue;
      pending.addAll(
        existing.where((e) => e.sourceId == node).map((e) => e.targetId),
      );
    }
    return null;
  }

  String? networkError(Iterable<ActivityEdge> edges) {
    final accepted = <ActivityEdge>[];
    for (final edge in edges) {
      final error = connectionError(edge.sourceId, edge.targetId, accepted);
      if (error != null) return error;
      accepted.add(edge);
    }
    return null;
  }
}
