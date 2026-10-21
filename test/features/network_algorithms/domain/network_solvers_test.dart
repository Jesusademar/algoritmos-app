import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:app_grafos/features/network_algorithms/domain/weighted_network.dart';
import 'package:app_grafos/features/network_algorithms/domain/kruskal_solver.dart';
import 'package:app_grafos/features/network_algorithms/domain/dijkstra_solver.dart';

void main() {
  const kruskal = KruskalSolver();
  const dijkstra = DijkstraSolver();
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
  test('Kruskal conecta todos los nodos con costo 4 sin crear ciclos', () {
    final result = kruskal.solve(example);
    expect(result.total, 4);
    expect(result.components, 1);
    expect(result.edges.map((e) => e.id).toSet(), {
      ('a', 'c'),
      ('c', 'b'),
      ('b', 'd'),
    });
    expect(
      result.procedure.steps.any((s) => s.title.contains('descartar')),
      isTrue,
    );
  });
  test('Kruskal permite negativos, empates, componentes y nodos aislados', () {
    final result = kruskal.solve(
      WeightedNetwork(
        nodes: ['a', 'b', 'c', 'd', 'e'],
        edges: const [
          WeightedEdge('a', 'b', -2),
          WeightedEdge('b', 'c', 0),
          WeightedEdge('a', 'c', 0),
        ],
      ),
    );
    expect(result.total, -2);
    expect(result.components, 3);
    expect(result.edges.length, 2);
    final single = kruskal.solve(WeightedNetwork(nodes: ['a'], edges: []));
    expect(single.total, 0);
    expect(single.components, 1);
  });
  test(
    'Kruskal coincide con enumeración exhaustiva de árboles en redes pequeñas',
    () {
      final random = Random(46);
      for (var sample = 0; sample < 40; sample++) {
        const nodes = ['0', '1', '2', '3', '4'];
        final edges = <WeightedEdge>[];
        for (var i = 0; i < 4; i++) {
          for (var j = i + 1; j < 5; j++) {
            if (j == i + 1 || random.nextBool()) {
              edges.add(WeightedEdge('$i', '$j', random.nextInt(13) - 4));
            }
          }
        }
        int? best;
        for (var mask = 0; mask < (1 << edges.length); mask++) {
          final chosen = [
            for (var i = 0; i < edges.length; i++)
              if (mask & (1 << i) != 0) edges[i],
          ];
          if (chosen.length != nodes.length - 1) continue;
          final reached = {'0'};
          for (var pass = 0; pass < nodes.length; pass++) {
            for (final e in chosen) {
              if (reached.contains(e.from)) reached.add(e.to);
              if (reached.contains(e.to)) reached.add(e.from);
            }
          }
          if (reached.length != nodes.length) continue;
          final total = chosen.fold(0, (sum, e) => sum + e.weight);
          best = best == null ? total : min(best, total);
        }
        expect(
          kruskal.solve(WeightedNetwork(nodes: nodes, edges: edges)).total,
          best,
          reason: 'muestra $sample',
        );
      }
    },
  );
  test(
    'Dijkstra obtiene ruta completa y distancias respetando las flechas',
    () {
      final result = dijkstra.solve(example, 'a');
      expect(result.distances, {'a': 0, 'c': 1, 'b': 3, 'd': 4});
      expect(result.pathTo('d')!.map((e) => e.id), [
        ('a', 'c'),
        ('c', 'b'),
        ('b', 'd'),
      ]);
      expect(result.pathTo('a'), isEmpty);
      expect(dijkstra.solve(example, 'd').pathTo('a'), isNull);
    },
  );
  test(
    'Dijkstra maneja ciclos de costo cero y empates sin ciclar predecesores',
    () {
      final result = dijkstra.solve(
        WeightedNetwork(
          nodes: ['a', 'b', 'c', 'x'],
          edges: const [
            WeightedEdge('a', 'b', 0),
            WeightedEdge('b', 'a', 0),
            WeightedEdge('a', 'c', 1),
            WeightedEdge('b', 'c', 1),
          ],
        ),
        'a',
      );
      expect(result.distances['c'], 1);
      expect(result.pathTo('x'), isNull);
      expect(result.pathTo('c')!.fold(0, (sum, e) => sum + e.weight), 1);
    },
  );
  test(
    'Dijkstra coincide con Bellman-Ford para redes dirigidas con ciclos',
    () {
      final random = Random(75);
      for (var sample = 0; sample < 80; sample++) {
        final nodes = [for (var i = 0; i < 8; i++) '$i'];
        final edges = <WeightedEdge>[];
        for (final a in nodes) {
          for (final b in nodes) {
            if (a != b && random.nextInt(4) == 0) {
              edges.add(WeightedEdge(a, b, random.nextInt(12)));
            }
          }
        }
        final expected = <String, int>{'0': 0};
        for (var pass = 0; pass < nodes.length - 1; pass++) {
          for (final e in edges) {
            final start = expected[e.from];
            if (start == null) continue;
            if (expected[e.to] == null || start + e.weight < expected[e.to]!) {
              expected[e.to] = start + e.weight;
            }
          }
        }
        final actual = dijkstra.solve(
          WeightedNetwork(nodes: nodes, edges: edges),
          '0',
        );
        expect(actual.distances, expected, reason: 'muestra $sample');
        for (final id in expected.keys) {
          expect(
            actual.pathTo(id)!.fold(0, (sum, e) => sum + e.weight),
            expected[id],
          );
        }
      }
    },
  );
  test('datos incompatibles se rechazan sin inventar resultados', () {
    expect(
      () => dijkstra.solve(
        WeightedNetwork(
          nodes: ['a', 'b'],
          edges: const [WeightedEdge('a', 'b', -1)],
        ),
        'a',
      ),
      throwsArgumentError,
    );
    expect(() => dijkstra.solve(example, 'inexistente'), throwsArgumentError);
    expect(
      () => kruskal.solve(
        WeightedNetwork(nodes: ['a'], edges: const [WeightedEdge('a', 'a', 1)]),
      ),
      throwsArgumentError,
    );
    expect(
      () => kruskal.solve(
        WeightedNetwork(nodes: ['a'], edges: const [WeightedEdge('a', 'b', 1)]),
      ),
      throwsArgumentError,
    );
    expect(
      () => kruskal.solve(WeightedNetwork(nodes: [], edges: [])),
      throwsArgumentError,
    );
  });
}
