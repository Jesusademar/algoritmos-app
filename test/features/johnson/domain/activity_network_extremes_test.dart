import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:app_grafos/features/johnson/domain/activity_network_problem.dart';
import 'package:app_grafos/features/johnson/domain/activity_network_solver.dart';

void main() {
  const solver = ActivityNetworkSolver();
  const diamond = [
    ActivityEdge(sourceId: 'a', targetId: 'b', duration: 3),
    ActivityEdge(sourceId: 'a', targetId: 'c', duration: 2),
    ActivityEdge(sourceId: 'b', targetId: 'd', duration: 4),
    ActivityEdge(sourceId: 'c', targetId: 'd', duration: 6),
  ];
  test('mínimo y máximo difieren aunque compartan el mismo terminal', () {
    for (final mode in NetworkOptimizationMode.values) {
      final max = mode == NetworkOptimizationMode.maximize;
      final result = solver.solve(
        ActivityNetworkProblem(
          nodeIds: const ['a', 'b', 'c', 'd'],
          edges: diamond,
          startNodeId: 'a',
          mode: mode,
        ),
      );
      expect(result.totalDuration, max ? 8 : 7);
      expect(result.earlyTimes['d'], max ? 8 : 7);
      expect(result.criticalEdgeIds, max ? {'a-c', 'c-d'} : {'a-b', 'b-d'});
      expect(result.edgeSlacks['a-b'], max ? 1 : 0);
      expect(result.edgeSlacks['a-c'], max ? 0 : 1);
      expect(result.slacks['a'], 0);
      expect(result.slacks[max ? 'b' : 'c'], 1);
    }
  });
  test('descarta componentes no alcanzables incluso con pesos negativos', () {
    for (final mode in NetworkOptimizationMode.values) {
      final result = solver.solve(
        ActivityNetworkProblem(
          nodeIds: const ['a', 'b', 'x', 'y'],
          edges: const [
            ActivityEdge(sourceId: 'a', targetId: 'b', duration: -5),
            ActivityEdge(sourceId: 'x', targetId: 'y', duration: -100),
          ],
          startNodeId: 'a',
          mode: mode,
        ),
      );
      expect(result.totalDuration, -5);
      expect(result.earlyTimes, {'a': 0, 'b': -5});
      expect(result.unreachableNodeIds, {'x', 'y'});
      expect(result.criticalEdgeIds, {'a-b'});
      expect(result.edgeSlacks.containsKey('x-y'), isFalse);
    }
  });
  test('red larga con conexiones en orden inverso no trunca el cálculo', () {
    final result = solver.solve(
      ActivityNetworkProblem(
        nodeIds: [for (var i = 0; i <= 220; i++) '$i'],
        edges: [
          for (var i = 219; i >= 0; i--)
            ActivityEdge(sourceId: '$i', targetId: '${i + 1}', duration: 2),
        ],
        startNodeId: '0',
        mode: NetworkOptimizationMode.minimize,
      ),
    );
    expect(result.totalDuration, 440);
    expect(result.earlyTimes['220'], 440);
    expect(result.criticalEdgeIds.length, 220);
  });
  test(
    'compara ambos modos y todas las aristas óptimas con rutas enumeradas',
    () {
      final random = Random(857);
      // Un camino base garantiza conectividad; ramas extra crean convergencias,
      // empates y rutas con pesos positivos, negativos y cero.
      for (var sample = 0; sample < 100; sample++) {
        final edges = <ActivityEdge>[];
        for (var i = 0; i < 6; i++) {
          for (var j = i + 1; j < 7; j++) {
            if (j == i + 1 || random.nextBool()) {
              edges.add(
                ActivityEdge(
                  sourceId: '$i',
                  targetId: '$j',
                  duration: random.nextInt(14) - 4,
                ),
              );
            }
          }
        }
        final routes = <(int, Set<String>)>[];
        void walk(String id, int cost, Set<String> path) {
          final next = edges.where((e) => e.sourceId == id);
          if (next.isEmpty) routes.add((cost, path));
          for (final edge in next) {
            walk(edge.targetId, cost + edge.duration, {...path, edge.id});
          }
        }

        walk('0', 0, {});
        for (final mode in NetworkOptimizationMode.values) {
          final maximizing = mode == NetworkOptimizationMode.maximize;
          final expected = routes
              .map((route) => route.$1)
              .reduce(maximizing ? max : min);
          final optimal = {
            for (final route in routes.where((route) => route.$1 == expected))
              ...route.$2,
          };
          final result = solver.solve(
            ActivityNetworkProblem(
              nodeIds: [for (var i = 0; i < 7; i++) '$i'],
              edges: edges.reversed.toList(),
              startNodeId: '0',
              mode: mode,
            ),
          );
          expect(
            result.totalDuration,
            expected,
            reason: '$mode muestra $sample',
          );
          expect(
            result.criticalEdgeIds,
            optimal,
            reason: '$mode muestra $sample',
          );
          expect(result.slacks.values.every((h) => h >= 0), isTrue);
          expect(result.edgeSlacks.values.every((h) => h >= 0), isTrue);
        }
      }
    },
  );
  test(
    'empates resaltan todas las rutas y pueden dar igual total en ambos modos',
    () {
      for (final mode in NetworkOptimizationMode.values) {
        final result = solver.solve(
          ActivityNetworkProblem(
            nodeIds: const ['a', 'b', 'c', 'd'],
            edges: [
              for (final edge in diamond)
                ActivityEdge(
                  sourceId: edge.sourceId,
                  targetId: edge.targetId,
                  duration: edge.id == 'c-d' ? 5 : edge.duration,
                ),
            ],
            startNodeId: 'a',
            mode: mode,
          ),
        );
        expect(result.totalDuration, 7);
        expect(result.criticalEdgeIds, diamond.map((e) => e.id).toSet());
      }
    },
  );
}
