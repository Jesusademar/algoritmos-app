enum NetworkOptimizationMode { minimize, maximize }

class ActivityEdge {
  const ActivityEdge({
    required this.sourceId,
    required this.targetId,
    required this.duration,
  });

  final String sourceId;
  final String targetId;
  final int duration;

  String get id => '$sourceId-$targetId';
}

/// Datos necesarios para calcular tiempos y ruta sobre una red de actividades.
class ActivityNetworkProblem {
  ActivityNetworkProblem({
    required List<String> nodeIds,
    required List<ActivityEdge> edges,
    required this.startNodeId,
    required this.initialValue,
    required this.mode,
  }) : nodeIds = List.unmodifiable(nodeIds),
       edges = List.unmodifiable(edges);

  final List<String> nodeIds;
  final List<ActivityEdge> edges;
  final String? startNodeId;
  final int initialValue;
  final NetworkOptimizationMode mode;
}
