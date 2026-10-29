import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:app_grafos/features/network_algorithms/domain/weighted_network.dart';
import 'package:app_grafos/features/network_algorithms/domain/longest_path_solver.dart';
import 'package:app_grafos/features/network_algorithms/domain/dijkstra_solver.dart';

void main() {
  const solver = LongestPathSolver();
  final cyclic = WeightedNetwork(
    nodes: ['a', 'b', 'c', 'd', 'x'],
    edges: const [
      WeightedEdge('a', 'b', 1),
      WeightedEdge('a', 'c', 1),
      WeightedEdge('b', 'c', 10),
      WeightedEdge('c', 'b', 10),
      WeightedEdge('b', 'd', 1),
      WeightedEdge('c', 'd', 1),
    ],
  );
  test(
    'acepta ciclos positivos y guarda una ruta independiente por destino',
    () {
      final result = solver.solve(cyclic, 'a');
      expect(result.method, NetworkPathMethod.simplePaths);
      expect(result.distances, {'a': 0, 'b': 11, 'c': 11, 'd': 12});
      expect(result.pathTo('b')!.map((e) => e.id), [('a', 'c'), ('c', 'b')]);
      expect(result.pathTo('c')!.map((e) => e.id), [('a', 'b'), ('b', 'c')]);
      expect(result.pathTo('d')!.map((e) => e.id), [
        ('a', 'b'),
        ('b', 'c'),
        ('c', 'd'),
      ]);
      expect(result.pathTo('a'), isEmpty);
      expect(result.pathTo('x'), isNull);
      expect(result.predecessors, isEmpty);
      expect(result.timeComplexity, 'O(V!)');
      expect(result.procedure.description, contains('sin repetir'));
      expect(() => result.paths['b']!.clear(), throwsUnsupportedError);
      expect(const DijkstraSolver().solve(cyclic, 'a').distances['d'], 2);
    },
  );
  test('ciclos de peso cero y de retorno al inicio no repiten nodos', () {
    final result = solver.solve(
      WeightedNetwork(
        nodes: ['a', 'b', 'c'],
        edges: const [
          WeightedEdge('a', 'b', 0),
          WeightedEdge('b', 'a', 100),
          WeightedEdge('b', 'c', 0),
          WeightedEdge('c', 'b', 0),
        ],
      ),
      'a',
    );
    expect(result.distances, {'a': 0, 'b': 0, 'c': 0});
    expect(result.pathTo('a'), isEmpty);
    expect(result.pathTo('c')!.map((e) => e.id), [('a', 'b'), ('b', 'c')]);
  });
  test(
    'una ruta con prefijo menor puede ser óptima para un destino posterior',
    () {
      final result = solver.solve(
        WeightedNetwork(
          nodes: ['a', 'b', 'c', 'd'],
          edges: const [
            WeightedEdge('a', 'c', 1),
            WeightedEdge('c', 'b', 10),
            WeightedEdge('a', 'b', 1),
            WeightedEdge('b', 'c', 10),
            WeightedEdge('c', 'd', 100),
            WeightedEdge('b', 'd', 1),
          ],
        ),
        'a',
      );
      expect(result.distances['b'], 11);
      expect(result.distances['d'], 111);
      expect(result.pathTo('d')!.map((e) => e.id), [
        ('a', 'b'),
        ('b', 'c'),
        ('c', 'd'),
      ]);
    },
  );
  test(
    'la búsqueda exacta coincide con programación dinámica por subconjuntos',
    () {
      final random = Random(728);
      const n = 7;
      for (var sample = 0; sample < 60; sample++) {
        final edges = <WeightedEdge>[];
        for (var a = 0; a < n; a++) {
          for (var b = 0; b < n; b++) {
            if (a != b && random.nextInt(3) == 0) {
              edges.add(WeightedEdge('$a', '$b', random.nextInt(10)));
            }
          }
        }
        final source = random.nextInt(n);
        final states = List.generate(1 << n, (_) => <int, int>{});
        states[1 << source][source] = 0;
        final expected = <String, int>{'$source': 0};
        for (var mask = 0; mask < states.length; mask++) {
          for (final entry in states[mask].entries) {
            for (final edge in edges.where((e) => e.from == '${entry.key}')) {
              final next = int.parse(edge.to);
              if (mask & (1 << next) != 0) continue;
              final cost = entry.value + edge.weight;
              final nextState = states[mask | (1 << next)];
              nextState[next] = max(nextState[next] ?? cost, cost);
              expected[edge.to] = max(expected[edge.to] ?? cost, cost);
            }
          }
        }
        final result = solver.solve(
          WeightedNetwork(
            nodes: [for (var i = 0; i < n; i++) '$i'],
            edges: edges,
          ),
          '$source',
        );
        expect(result.distances, expected, reason: 'red $sample');
        for (final target in expected.keys) {
          final path = result.pathTo(target)!;
          var current = '$source';
          final visited = {current};
          for (final edge in path) {
            expect(edge.from, current);
            expect(visited.add(edge.to), isTrue);
            current = edge.to;
          }
          expect(current, target);
          expect(path.fold(0, (sum, e) => sum + e.weight), expected[target]);
        }
      }
    },
  );
  test('conserva la vía lineal en redes acíclicas', () {
    final result = solver.solve(
      WeightedNetwork(
        nodes: ['a', 'b', 'x'],
        edges: const [WeightedEdge('a', 'b', 3)],
      ),
      'a',
    );
    expect(result.method, NetworkPathMethod.topological);
    expect(result.timeComplexity, 'O(V + E)');
    expect(result.pathTo('x'), isNull);
  });
  test('la versión asíncrona produce las mismas rutas completas', () async {
    final result = await solver.solveAsync(cyclic, 'a');
    expect(result!.distances, solver.solve(cyclic, 'a').distances);
    expect(result.pathTo('d')!.map((e) => e.id), [
      ('a', 'b'),
      ('b', 'c'),
      ('c', 'd'),
    ]);
  });
  test(
    'cede tiempo a otros eventos y cancelar descarta el resultado parcial',
    () async {
      final dense = WeightedNetwork(
        nodes: [for (var i = 0; i < 15; i++) '$i'],
        edges: [
          for (var a = 0; a < 15; a++)
            for (var b = 0; b < 15; b++)
              if (a != b) WeightedEdge('$a', '$b', 1),
        ],
      );
      var cancel = false;
      final event = Future<void>(() => cancel = true);
      final result = await solver.solveAsync(
        dense,
        '0',
        isCancelled: () => cancel,
      );
      await event;
      expect(cancel, isTrue);
      expect(result, isNull);
    },
  );
}
