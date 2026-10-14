import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:app_grafos/features/esquina_nor_oeste/domain/esquina_nor_oeste_problem.dart';
import 'package:app_grafos/features/esquina_nor_oeste/domain/esquina_nor_oeste_result.dart';
import 'package:app_grafos/features/esquina_nor_oeste/domain/esquina_nor_oeste_solver.dart';
import 'package:app_grafos/features/esquina_nor_oeste/domain/optimization_mode.dart';

EsquinaNorOesteProblem problemFor(
  List<num> supplies,
  List<num> demands,
  List<List<num?>> costs,
  OptimizationMode mode,
) => EsquinaNorOesteProblem(
  origins: [
    for (var i = 0; i < supplies.length; i++)
      EsquinaNorOesteItem(id: 'o$i', label: 'O$i', supply: supplies[i]),
  ],
  destinations: [
    for (var j = 0; j < demands.length; j++)
      EsquinaNorOesteItem(id: 'd$j', label: 'D$j', demand: demands[j]),
  ],
  costs: [
    for (var i = 0; i < supplies.length; i++)
      for (var j = 0; j < demands.length; j++)
        if (costs[i][j] != null)
          EsquinaNorOesteCost(
            originId: 'o$i',
            destinationId: 'd$j',
            value: costs[i][j]!,
          ),
  ],
  mode: mode,
);

void expectConservation(
  EsquinaNorOesteProblem problem,
  EsquinaNorOesteResult result,
) {
  for (final origin in problem.origins) {
    final sent = result.assignments
        .where((a) => a.origin.id == origin.id)
        .fold<num>(0, (sum, a) => sum + a.quantity);
    if (result.unshippedSupply == 0) {
      expect(sent, closeTo(origin.supply, 1e-8));
    } else {
      expect(sent, lessThanOrEqualTo(origin.supply));
    }
  }
  for (final destination in problem.destinations) {
    final received = result.assignments
        .where((a) => a.destination.id == destination.id)
        .fold<num>(0, (sum, a) => sum + a.quantity);
    if (result.unmetDemand == 0) {
      expect(received, closeTo(destination.demand, 1e-8));
    } else {
      expect(received, lessThanOrEqualTo(destination.demand));
    }
  }
  for (final allocation in result.assignments) {
    expect(allocation.quantity, greaterThan(0));
    expect(
      allocation.unitCost,
      problem.costFor(allocation.origin.id, allocation.destination.id),
    );
  }
}

// Independent exhaustive oracle for tiny integer transportation problems.
num? exhaustiveOptimum(EsquinaNorOesteProblem problem) {
  final supply = problem.origins.map((o) => o.supply.toInt()).toList();
  final demand = problem.destinations.map((d) => d.demand.toInt()).toList();
  final supplySurplus = max(
    0,
    supply.fold<int>(0, (sum, q) => sum + q) -
        demand.fold<int>(0, (sum, q) => sum + q),
  );
  final demandShortage = max(
    0,
    demand.fold<int>(0, (sum, q) => sum + q) -
        supply.fold<int>(0, (sum, q) => sum + q),
  );
  num? best;
  void visit(int cell, num cost) {
    if (cell == supply.length * demand.length) {
      if (supply.fold<int>(0, (sum, q) => sum + q) != supplySurplus ||
          demand.fold<int>(0, (sum, q) => sum + q) != demandShortage) {
        return;
      }
      if (best == null ||
          (problem.mode == OptimizationMode.minimize
              ? cost < best!
              : cost > best!)) {
        best = cost;
      }
      return;
    }
    final i = cell ~/ demand.length;
    final j = cell % demand.length;
    final unitCost = problem.costFor(
      problem.origins[i].id,
      problem.destinations[j].id,
    );
    final limit = unitCost == null ? 0 : min(supply[i], demand[j]);
    for (var quantity = 0; quantity <= limit; quantity++) {
      supply[i] -= quantity;
      demand[j] -= quantity;
      visit(cell + 1, cost + quantity * (unitCost ?? 0));
      supply[i] += quantity;
      demand[j] += quantity;
    }
  }

  visit(0, 0);
  return best;
}

void main() {
  const solver = EsquinaNorOesteSolver();
  test('mínimo y máximo difieren y no inventan cantidades', () {
    for (final mode in OptimizationMode.values) {
      final problem = problemFor([10, 10], [10, 10], [
        [1, 2],
        [2, 100],
      ], mode);
      final result = solver.solve(problem)!;
      expect(result.totalCost, mode == OptimizationMode.minimize ? 40 : 1010);
      expectConservation(problem, result);
    }
  });

  test('costos iguales pueden producir el mismo óptimo en ambos modos', () {
    for (final mode in OptimizationMode.values) {
      final problem = problemFor([4, 6], [5, 5], [
        [3, 3],
        [3, 3],
      ], mode);
      final result = solver.solve(problem)!;
      expect(result.totalCost, 30);
      expectConservation(problem, result);
    }
  });

  test('rutas ausentes, costos cero/negativos y cantidades decimales', () {
    for (final mode in OptimizationMode.values) {
      final sparse = problemFor([10, 10], [10, 10], [
        [1, 2],
        [2, null],
      ], mode);
      final result = solver.solve(sparse)!;
      expect(result.totalCost, 40);
      expectConservation(sparse, result);
      final decimals = problemFor([1.5, 0.5], [0.5, 1.5], [
        [0, -2],
        [3, 0],
      ], mode);
      final decimalResult = solver.solve(decimals)!;
      expect(
        decimalResult.totalCost,
        mode == OptimizationMode.minimize ? -2 : -1.5,
      );
      // The exhaustive integer oracle is checked separately below.
      expectConservation(decimals, decimalResult);
    }
  });

  test(
    'calcula directamente con exceso de oferta o demanda en ambos modos',
    () {
      for (final mode in OptimizationMode.values) {
        for (final demands in <List<num>>[
          [9, 10],
          [11, 10],
        ]) {
          final problem = problemFor(
            [10, 10],
            demands,
            [
              [1, 2],
              [2, 100],
            ],
            mode,
          );
          final result = solver.solve(problem)!;
          expect(result.totalCost, exhaustiveOptimum(problem));
          expect(
            result.assignments.fold<num>(0, (sum, a) => sum + a.quantity),
            demands.first == 9 ? 19 : 20,
          );
          expect(result.unshippedSupply, demands.first == 9 ? 1 : 0);
          expect(result.unmetDemand, demands.first == 11 ? 1 : 0);
          expectConservation(problem, result);
        }
        final onlyDemand = solver.solve(
          problemFor([0], [7], [
            [null],
          ], mode),
        )!;
        expect(onlyDemand.assignments, isEmpty);
        expect(onlyDemand.unmetDemand, 7);
        final onlySupply = solver.solve(
          problemFor([7], [0], [
            [null],
          ], mode),
        )!;
        expect(onlySupply.assignments, isEmpty);
        expect(onlySupply.unshippedSupply, 7);
      }
    },
  );

  test('rechaza datos inválidos y soluciones parciales', () {
    for (final mode in OptimizationMode.values) {
      expect(
        solver.solve(
          problemFor([-1], [-1], [
            [1],
          ], mode),
        ),
        isNull,
      );
      expect(
        solver.solve(
          problemFor([double.infinity], [double.infinity], [
            [1],
          ], mode),
        ),
        isNull,
      );
      expect(
        solver.solve(
          problemFor([1], [1], [
            [double.nan],
          ], mode),
        ),
        isNull,
      );
      expect(
        solver.solve(
          problemFor([1, 1], [1, 1], [
            [1, null],
            [1, null],
          ], mode),
        ),
        isNull,
      );
      final emptyFlow = solver.solve(
        problemFor([0], [0], [
          [null],
        ], mode),
      )!;
      expect(emptyFlow.assignments, isEmpty);
      expect(emptyFlow.totalCost, 0);
    }
  });

  test('coincide con búsqueda exhaustiva en 160 matrices pequeñas', () {
    final random = Random(42);
    for (var trial = 0; trial < 160; trial++) {
      final supplies = trial.isEven ? [1, 2, 1] : [2, 2];
      final demands = switch (trial % 4) {
        0 => [2, 3],
        1 => [1, 2],
        2 => [1, 1, 2],
        _ => [2, 2],
      };
      final costs = [
        for (var i = 0; i < supplies.length; i++)
          [
            for (var j = 0; j < demands.length; j++)
              random.nextInt(5) == 0 ? null : random.nextInt(13) - 4,
          ],
      ];
      for (final mode in OptimizationMode.values) {
        final problem = problemFor(supplies, demands, costs, mode);
        final expected = exhaustiveOptimum(problem);
        final result = solver.solve(problem);
        if (expected == null) {
          expect(result, isNull);
        } else {
          expect(result, isNotNull);
          expect(
            result!.totalCost,
            expected,
            reason: 'Caso $trial, $mode, $costs',
          );
          expectConservation(problem, result);
        }
      }
    }
  });
}
