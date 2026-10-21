class ActivityNetworkResult {
  ActivityNetworkResult({
    required Map<String, int> earlyTimes,
    required Map<String, int> lateTimes,
    required Map<String, int> slacks,
    required Set<String> criticalEdgeIds,
    required this.totalDuration,
    Map<String, int> edgeSlacks = const {},
    Set<String> unreachableNodeIds = const {},
  }) : earlyTimes = Map.unmodifiable(earlyTimes),
       lateTimes = Map.unmodifiable(lateTimes),
       slacks = Map.unmodifiable(slacks),
       criticalEdgeIds = Set.unmodifiable(criticalEdgeIds),
       edgeSlacks = Map.unmodifiable(edgeSlacks),
       unreachableNodeIds = Set.unmodifiable(unreachableNodeIds);

  final Map<String, int> earlyTimes;
  final Map<String, int> lateTimes;
  final Map<String, int> slacks;
  final Set<String> criticalEdgeIds;
  final int totalDuration;
  final Map<String, int> edgeSlacks;
  final Set<String> unreachableNodeIds;
}
