import 'package:flutter_test/flutter_test.dart';

import 'package:app_grafos/features/johnson/domain/activity_network_problem.dart';
import 'package:app_grafos/features/johnson/domain/activity_network_solver.dart';

void main() {
  const solver = ActivityNetworkSolver();
  const edges = [
    ActivityEdge(sourceId: 'a', targetId: 'b', duration: 3),
    ActivityEdge(sourceId: 'a', targetId: 'c', duration: 2),
    ActivityEdge(sourceId: 'b', targetId: 'd', duration: 4),
    ActivityEdge(sourceId: 'c', targetId: 'd', duration: 6),
  ];

  test('calcula tiempos, holguras y ruta crítica', () {
    final result = solver.solve(
      ActivityNetworkProblem(
        nodeIds: const ['a', 'b', 'c', 'd'],
        edges: edges,
        startNodeId: 'a',
        initialValue: 0,
        mode: NetworkOptimizationMode.maximize,
      ),
    );

    expect(result.totalDuration, 8);
    expect(result.earlyTimes, {'a': 0, 'b': 3, 'c': 2, 'd': 8});
    expect(result.slacks['b'], 1);
    expect(result.criticalEdgeIds, {'a-c', 'c-d'});
  });

  test('selecciona el nodo final de menor valor en modo minimizar', () {
    final result = solver.solve(
      ActivityNetworkProblem(
        nodeIds: const ['a', 'b', 'c'],
        edges: const [
          ActivityEdge(sourceId: 'a', targetId: 'b', duration: 3),
          ActivityEdge(sourceId: 'a', targetId: 'c', duration: 2),
        ],
        startNodeId: 'a',
        initialValue: 0,
        mode: NetworkOptimizationMode.minimize,
      ),
    );

    expect(result.totalDuration, 2);
    expect(result.criticalEdgeIds, {'a-c'});
  });
}
