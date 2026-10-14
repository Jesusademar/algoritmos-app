import 'package:flutter_test/flutter_test.dart';

import 'package:app_grafos/features/johnson/domain/activity_network_problem.dart';
import 'package:app_grafos/features/johnson/domain/activity_network_rules.dart';
import 'package:app_grafos/features/johnson/domain/activity_network_solver.dart';

void main() {
  const rules = ActivityNetworkRules();
  const edges = [ActivityEdge(sourceId: 'a', targetId: 'b', duration: 5)];
  test(
    'bloquea bucles y sentido inverso, permite actualizar el mismo sentido',
    () {
      expect(rules.connectionError('a', 'a', edges), isNotNull);
      expect(rules.connectionError('b', 'a', edges), isNotNull);
      expect(rules.connectionError('a', 'b', edges), isNull);
      expect(rules.connectionError('b', 'c', edges), isNull);
    },
  );
  test('bloquea circuitos de tres o más nodos', () {
    const chain = [
      ...edges,
      ActivityEdge(sourceId: 'b', targetId: 'c', duration: 2),
    ];
    expect(rules.connectionError('c', 'a', chain), isNotNull);
    expect(rules.connectionError('a', 'c', chain), isNull);
  });
  test(
    'el cálculo rechaza redes inválidas, incluso si no provienen del editor',
    () {
      for (final invalid in <List<ActivityEdge>>[
        [const ActivityEdge(sourceId: 'a', targetId: 'a', duration: 1)],
        [
          ...edges,
          const ActivityEdge(sourceId: 'b', targetId: 'a', duration: 1),
        ],
        [
          ...edges,
          const ActivityEdge(sourceId: 'b', targetId: 'c', duration: 1),
          const ActivityEdge(sourceId: 'c', targetId: 'a', duration: 1),
        ],
      ]) {
        expect(
          () => const ActivityNetworkSolver().solve(
            ActivityNetworkProblem(
              nodeIds: ['a', 'b', 'c'],
              edges: invalid,
              startNodeId: 'a',
              initialValue: 0,
              mode: NetworkOptimizationMode.maximize,
            ),
          ),
          throwsArgumentError,
        );
      }
    },
  );
}
