import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:app_grafos/features/network_algorithms/domain/weighted_network.dart';
import 'package:app_grafos/features/network_algorithms/domain/network_objective.dart';
import 'package:app_grafos/features/network_algorithms/domain/kruskal_solver.dart';
import 'package:app_grafos/features/network_algorithms/domain/dijkstra_solver.dart';
import 'package:app_grafos/features/network_algorithms/domain/longest_path_solver.dart';

void main() {
  final example = WeightedNetwork(
    nodes: ['a', 'b', 'c', 'd'],
    edges: const [
      WeightedEdge('a', 'b', 4),
      WeightedEdge('a', 'c', 1),
      WeightedEdge('c', 'b', 2),
      WeightedEdge('b', 'd', 1),
      WeightedEdge('c', 'd', 5),
    ],
  );
  test('Kruskal mínimo 4 y máximo 11 sobre la misma red', () {
    final minimum = const KruskalSolver().solve(example);
    final maximum = const KruskalSolver().solve(
      example,
      objective: NetworkObjective.maximize,
    );
    expect(minimum.total, 4);
    expect(maximum.total, 11);
    expect(maximum.components, 1);
    expect(maximum.objective, NetworkObjective.maximize);
    expect(maximum.edges.map((e) => e.id).toSet(), {
      ('c', 'd'),
      ('a', 'b'),
      ('c', 'b'),
    });
    expect(
      maximum.procedure.steps.first.description,
      contains('mayor a menor'),
    );
    expect(maximum.procedure.steps.last.title, 'Árbol máximo completo');
  });
  test('Kruskal maximiza también bosques con pesos negativos', () {
    final result = const KruskalSolver().solve(
      WeightedNetwork(
        nodes: ['a', 'b', 'c', 'x'],
        edges: const [
          WeightedEdge('a', 'b', -5),
          WeightedEdge('a', 'c', -1),
          WeightedEdge('b', 'c', -2),
        ],
      ),
      objective: NetworkObjective.maximize,
    );
    expect(result.total, -3);
    expect(result.components, 2);
    expect(result.procedure.steps.last.title, 'Bosque máximo');
  });
  test('el árbol máximo coincide con enumeración de todos los árboles', () {
    final random = Random(270);
    for (var sample = 0; sample < 30; sample++) {
      final edges = [
        for (var i = 0; i < 4; i++)
          for (var j = i + 1; j < 5; j++)
            WeightedEdge('$i', '$j', random.nextInt(17) - 8),
      ];
      int? best;
      for (var mask = 0; mask < (1 << edges.length); mask++) {
        final chosen = [
          for (var i = 0; i < edges.length; i++)
            if (mask & (1 << i) != 0) edges[i],
        ];
        if (chosen.length != 4) continue;
        final seen = {'0'};
        for (var pass = 0; pass < 5; pass++) {
          for (final e in chosen) {
            if (seen.contains(e.from)) seen.add(e.to);
            if (seen.contains(e.to)) seen.add(e.from);
          }
        }
        if (seen.length != 5) continue;
        final sum = chosen.fold(0, (s, e) => s + e.weight);
        best = best == null ? sum : max(best, sum);
      }
      final actual = const KruskalSolver().solve(
        WeightedNetwork(
          nodes: [for (var i = 0; i < 5; i++) '$i'],
          edges: edges,
        ),
        objective: NetworkObjective.maximize,
      );
      expect(actual.total, best, reason: 'muestra $sample');
    }
  });
  test('rutas mínimas y máximas tienen caminos y totales diferentes', () {
    final minimum = const DijkstraSolver().solve(example, 'a');
    final maximum = const LongestPathSolver().solve(example, 'a');
    expect(minimum.distances['d'], 4);
    expect(maximum.distances['d'], 6);
    expect(maximum.pathTo('d')!.map((e) => e.id), [('a', 'c'), ('c', 'd')]);
    expect(maximum.objective, NetworkObjective.maximize);
    expect(maximum.pathTo('a'), isEmpty);
  });
  test('la ruta máxima espera todos los predecesores de una convergencia', () {
    final result = const LongestPathSolver().solve(
      WeightedNetwork(
        nodes: ['d', 'b', 'a', 'c', 'x'],
        edges: const [
          WeightedEdge('b', 'd', 1),
          WeightedEdge('a', 'b', 10),
          WeightedEdge('a', 'c', 1),
          WeightedEdge('c', 'b', 20),
        ],
      ),
      'a',
    );
    expect(result.distances['d'], 22);
    expect(result.pathTo('d')!.map((e) => e.id), [
      ('a', 'c'),
      ('c', 'b'),
      ('b', 'd'),
    ]);
    expect(result.pathTo('x'), isNull);
    expect(result.distances.containsKey('x'), isFalse);
  });
  test(
    'rutas máximas coinciden con enumeración de todos los caminos en DAG',
    () {
      final random = Random(92);
      for (var sample = 0; sample < 100; sample++) {
        final nodes = [for (var i = 0; i < 7; i++) '$i'];
        final edges = <WeightedEdge>[];
        for (var i = 0; i < 6; i++) {
          for (var j = i + 1; j < 7; j++) {
            if (random.nextBool()) {
              edges.add(WeightedEdge('$i', '$j', random.nextInt(8)));
            }
          }
        }
        final start = '${random.nextInt(5)}';
        final expected = <String, int>{};
        void visit(String id, int cost) {
          expected[id] = max(expected[id] ?? cost, cost);
          for (final edge in edges.where((e) => e.from == id)) {
            visit(edge.to, cost + edge.weight);
          }
        }

        visit(start, 0);
        final actual = const LongestPathSolver().solve(
          WeightedNetwork(nodes: nodes.reversed, edges: edges.reversed),
          start,
        );
        expect(actual.distances, expected);
        for (final id in expected.keys) {
          expect(
            actual.pathTo(id)!.fold(0, (s, e) => s + e.weight),
            expected[id],
          );
        }
      }
    },
  );
  test('máximo admite ciclos sin repetir nodos y valida el origen', () {
    final cyclic = WeightedNetwork(
      nodes: ['a', 'b'],
      edges: const [WeightedEdge('a', 'b', 2), WeightedEdge('b', 'a', 3)],
    );
    final maximum = const LongestPathSolver().solve(cyclic, 'a');
    expect(maximum.distances, {'a': 0, 'b': 2});
    expect(maximum.pathTo('b')!.map((edge) => edge.id), [('a', 'b')]);
    expect(const DijkstraSolver().solve(cyclic, 'a').distances['b'], 2);
    expect(
      () => const LongestPathSolver().solve(example, 'inexistente'),
      throwsArgumentError,
    );
  });
}
