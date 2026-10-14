import 'package:app_grafos/features/johnson/domain/activity_network_problem.dart';
import 'package:app_grafos/features/johnson/domain/activity_network_result.dart';
import 'package:app_grafos/features/johnson/domain/activity_network_rules.dart';

/// Calcula tiempos tempranos, tardíos, holguras y aristas de la ruta elegida.
///
/// Esta clase no conoce widgets, colores ni cuadros de diálogo. Por eso puede
/// probarse y modificarse sin depender de Flutter.
class ActivityNetworkSolver {
  const ActivityNetworkSolver({this.maxRelaxationPasses = 100});

  final int maxRelaxationPasses;

  ActivityNetworkResult solve(ActivityNetworkProblem problem) {
    final error = const ActivityNetworkRules().networkError(problem.edges);
    if (error != null) throw ArgumentError(error);
    final incoming = <String, List<ActivityEdge>>{
      for (final nodeId in problem.nodeIds) nodeId: <ActivityEdge>[],
    };
    final outgoing = <String, List<ActivityEdge>>{
      for (final nodeId in problem.nodeIds) nodeId: <ActivityEdge>[],
    };

    for (final edge in problem.edges) {
      incoming[edge.targetId]?.add(edge);
      outgoing[edge.sourceId]?.add(edge);
    }

    final earlyTimes = <String, int>{
      for (final nodeId in problem.nodeIds) nodeId: 0,
    };
    final startNodeId = problem.startNodeId;
    if (startNodeId != null && earlyTimes.containsKey(startNodeId)) {
      earlyTimes[startNodeId] = problem.initialValue;
    } else {
      for (final nodeId in problem.nodeIds) {
        if (incoming[nodeId]!.isEmpty) {
          earlyTimes[nodeId] = problem.initialValue;
        }
      }
    }

    var changed = true;
    var iterations = 0;
    while (changed && iterations < maxRelaxationPasses) {
      changed = false;
      iterations++;
      for (final edge in problem.edges) {
        if (!earlyTimes.containsKey(edge.sourceId) ||
            !earlyTimes.containsKey(edge.targetId)) {
          continue;
        }
        final candidate = earlyTimes[edge.sourceId]! + edge.duration;
        if (candidate > earlyTimes[edge.targetId]!) {
          earlyTimes[edge.targetId] = candidate;
          changed = true;
        }
      }
    }

    var totalDuration = 0;
    for (final time in earlyTimes.values) {
      if (time > totalDuration) totalDuration = time;
    }

    final lateTimes = <String, int>{
      for (final nodeId in problem.nodeIds) nodeId: totalDuration,
    };
    changed = true;
    iterations = 0;
    while (changed && iterations < maxRelaxationPasses) {
      changed = false;
      iterations++;
      for (final nodeId in problem.nodeIds) {
        final nextEdges = outgoing[nodeId]!;
        if (nextEdges.isEmpty) continue;

        int? limit;
        for (final edge in nextEdges) {
          final targetTime = lateTimes[edge.targetId];
          if (targetTime == null) continue;
          final candidate = targetTime - edge.duration;
          if (limit == null || candidate < limit) limit = candidate;
        }
        if (limit != null && limit < lateTimes[nodeId]!) {
          lateTimes[nodeId] = limit;
          changed = true;
        }
      }
    }

    final slacks = <String, int>{
      for (final nodeId in problem.nodeIds)
        nodeId: (lateTimes[nodeId]! - earlyTimes[nodeId]!).abs(),
    };
    final criticalEdges = <String>{};

    if (problem.mode == NetworkOptimizationMode.maximize) {
      for (final edge in problem.edges) {
        final sourceEarly = earlyTimes[edge.sourceId];
        final targetLate = lateTimes[edge.targetId];
        if (sourceEarly == null || targetLate == null) continue;
        final edgeSlack = (targetLate - sourceEarly - edge.duration).abs();
        if (edgeSlack == 0 &&
            lateTimes[edge.sourceId] == earlyTimes[edge.sourceId]) {
          criticalEdges.add(edge.id);
        }
      }
    } else {
      final finalNodes = problem.nodeIds
          .where((nodeId) => outgoing[nodeId]!.isEmpty)
          .toList();
      String? optimalFinalNode;
      int? lowestTotal;
      for (final nodeId in finalNodes) {
        final cost = earlyTimes[nodeId]!;
        if (lowestTotal == null || cost < lowestTotal) {
          lowestTotal = cost;
          optimalFinalNode = nodeId;
        }
      }

      if (optimalFinalNode != null && lowestTotal != null) {
        totalDuration = lowestTotal;
        String? current = optimalFinalNode;
        final visited = <String>{};
        while (current != null && visited.add(current)) {
          ActivityEdge? bestIncoming;
          int? lowestPreviousTime;
          for (final edge in incoming[current]!) {
            final sourceTime = earlyTimes[edge.sourceId]!;
            if (sourceTime + edge.duration == earlyTimes[current] &&
                (lowestPreviousTime == null ||
                    sourceTime < lowestPreviousTime)) {
              lowestPreviousTime = sourceTime;
              bestIncoming = edge;
            }
          }
          if (bestIncoming == null) break;
          criticalEdges.add(bestIncoming.id);
          current = bestIncoming.sourceId;
        }
      }
    }

    return ActivityNetworkResult(
      earlyTimes: earlyTimes,
      lateTimes: lateTimes,
      slacks: slacks,
      criticalEdgeIds: criticalEdges,
      totalDuration: totalDuration,
    );
  }
}
