import 'dart:collection';

import 'package:app_grafos/features/johnson/domain/activity_network_problem.dart';
import 'package:app_grafos/features/johnson/domain/activity_network_result.dart';
import 'package:app_grafos/features/johnson/domain/activity_network_rules.dart';

/// Rutas extremas en una red dirigida acíclica, con inicio fijo en cero.
/// Maximizar usa máximo en la ida y mínimo en el retorno; Minimizar invierte
/// ambas operaciones. Los nodos sin camino desde el inicio no reciben etiquetas.
class ActivityNetworkSolver {
  const ActivityNetworkSolver();

  ActivityNetworkResult solve(ActivityNetworkProblem problem) {
    final error = const ActivityNetworkRules().networkError(problem.edges);
    if (error != null) throw ArgumentError(error);
    final ids = problem.nodeIds.toSet();
    if (ids.length != problem.nodeIds.length) {
      throw ArgumentError('Los identificadores de los nodos deben ser únicos.');
    }
    final incoming = {for (final id in ids) id: <ActivityEdge>[]};
    final outgoing = {for (final id in ids) id: <ActivityEdge>[]};
    for (final edge in problem.edges) {
      if (!ids.contains(edge.sourceId) || !ids.contains(edge.targetId)) {
        throw ArgumentError(
          'Una conexión hace referencia a un nodo inexistente.',
        );
      }
      incoming[edge.targetId]!.add(edge);
      outgoing[edge.sourceId]!.add(edge);
    }
    if (problem.startNodeId != null && !ids.contains(problem.startNodeId)) {
      throw ArgumentError('El nodo inicial no existe en la red.');
    }
    final degree = {for (final id in ids) id: incoming[id]!.length};
    final queue = Queue<String>.of(ids.where((id) => degree[id] == 0));
    final ordered = <String>[];
    while (queue.isNotEmpty) {
      final id = queue.removeFirst();
      ordered.add(id);
      for (final edge in outgoing[id]!) {
        degree[edge.targetId] = degree[edge.targetId]! - 1;
        if (degree[edge.targetId] == 0) queue.add(edge.targetId);
      }
    }
    if (ordered.length != ids.length) {
      throw ArgumentError('La red contiene un ciclo.');
    }

    final maximizing = problem.mode == NetworkOptimizationMode.maximize;
    bool better(int candidate, int current) =>
        maximizing ? candidate > current : candidate < current;
    final forward = <String, int>{
      if (problem.startNodeId case final start?)
        start: 0
      else
        for (final id in ids.where((id) => incoming[id]!.isEmpty)) id: 0,
    };
    for (final id in ordered) {
      final distance = forward[id];
      if (distance == null) continue;
      for (final edge in outgoing[id]!) {
        final candidate = distance + edge.duration;
        final previous = forward[edge.targetId];
        if (previous == null || better(candidate, previous)) {
          forward[edge.targetId] = candidate;
        }
      }
    }
    final terminals = ordered
        .where((id) => forward.containsKey(id) && outgoing[id]!.isEmpty)
        .toList();
    final total = terminals.isEmpty
        ? 0
        : terminals
              .map((id) => forward[id]!)
              .reduce((a, b) => better(a, b) ? a : b);

    // Costo extremo que queda desde cada nodo hasta un terminal alcanzable.
    final remaining = <String, int>{for (final id in terminals) id: 0};
    for (final id in ordered.reversed) {
      if (!forward.containsKey(id)) continue;
      for (final edge in outgoing[id]!) {
        final suffix = remaining[edge.targetId];
        if (suffix == null) continue;
        final candidate = edge.duration + suffix;
        final previous = remaining[id];
        if (previous == null || better(candidate, previous)) {
          remaining[id] = candidate;
        }
      }
    }
    final backward = {
      for (final id in forward.keys) id: total - remaining[id]!,
    };
    final slacks = {
      for (final id in forward.keys)
        id: maximizing
            ? backward[id]! - forward[id]!
            : forward[id]! - backward[id]!,
    };
    final edgeSlacks = <String, int>{};
    for (final edge in problem.edges) {
      final prefix = forward[edge.sourceId];
      final suffix = remaining[edge.targetId];
      if (prefix == null || suffix == null) continue;
      final throughEdge = prefix + edge.duration + suffix;
      edgeSlacks[edge.id] = maximizing
          ? total - throughEdge
          : throughEdge - total;
    }
    return ActivityNetworkResult(
      earlyTimes: forward,
      lateTimes: backward,
      slacks: slacks,
      edgeSlacks: edgeSlacks,
      unreachableNodeIds: ids.difference(forward.keys.toSet()),
      criticalEdgeIds: {
        for (final entry in edgeSlacks.entries)
          if (entry.value == 0) entry.key,
      },
      totalDuration: total,
    );
  }
}
