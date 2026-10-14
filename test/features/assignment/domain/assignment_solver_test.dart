import 'package:flutter_test/flutter_test.dart';

import 'package:app_grafos/features/assignment/domain/assignment_problem.dart';
import 'package:app_grafos/features/assignment/domain/assignment_solver.dart';
import 'package:app_grafos/features/assignment/domain/optimization_mode.dart';

void main() {
  const solver = AssignmentSolver();
  const origins = [
    AssignmentItem(id: 'a', label: 'A'),
    AssignmentItem(id: 'b', label: 'B'),
  ];
  const destinations = [
    AssignmentItem(id: 'x', label: 'X'),
    AssignmentItem(id: 'y', label: 'Y'),
  ];
  const costs = [
    AssignmentCost(originId: 'a', destinationId: 'x', value: 4),
    AssignmentCost(originId: 'a', destinationId: 'y', value: 1),
    AssignmentCost(originId: 'b', destinationId: 'x', value: 2),
    AssignmentCost(originId: 'b', destinationId: 'y', value: 5),
  ];

  test('encuentra la asignación de costo mínimo', () {
    final result = solver.solve(
      AssignmentProblem(
        origins: origins,
        destinations: destinations,
        costs: costs,
        mode: OptimizationMode.minimize,
      ),
    );

    expect(result, isNotNull);
    expect(result!.total, 3);
    expect(
      result.matches.map(
        (match) => '${match.origin.id}-${match.destination.id}',
      ),
      containsAll(['a-y', 'b-x']),
    );
  });

  test('encuentra la asignación de beneficio máximo', () {
    final result = solver.solve(
      AssignmentProblem(
        origins: origins,
        destinations: destinations,
        costs: costs,
        mode: OptimizationMode.maximize,
      ),
    );

    expect(result, isNotNull);
    expect(result!.total, 9);
    expect(
      result.matches.map(
        (match) => '${match.origin.id}-${match.destination.id}',
      ),
      containsAll(['a-x', 'b-y']),
    );
  });

  test('informa cuando no existe una asignación completa', () {
    final result = solver.solve(
      AssignmentProblem(
        origins: origins,
        destinations: destinations,
        costs: const [
          AssignmentCost(originId: 'a', destinationId: 'x', value: 4),
        ],
        mode: OptimizationMode.minimize,
      ),
    );

    expect(result, isNull);
  });
  test(
    'completa matrices 2×3 y 3×2 con ficticios de costo cero en ambos modos',
    () {
      for (final moreOrigins in [false, true]) {
        for (final mode in OptimizationMode.values) {
          final problem = AssignmentProblem(
            origins: [
              ...origins,
              if (moreOrigins) const AssignmentItem(id: 'c', label: 'C'),
            ],
            destinations: [
              ...destinations,
              if (!moreOrigins) const AssignmentItem(id: 'z', label: 'Z'),
            ],
            costs: [
              ...costs,
              if (moreOrigins) ...[
                const AssignmentCost(
                  originId: 'c',
                  destinationId: 'x',
                  value: 7,
                ),
                const AssignmentCost(
                  originId: 'c',
                  destinationId: 'y',
                  value: 3,
                ),
              ] else ...[
                const AssignmentCost(
                  originId: 'a',
                  destinationId: 'z',
                  value: 8,
                ),
                const AssignmentCost(
                  originId: 'b',
                  destinationId: 'z',
                  value: 6,
                ),
              ],
            ],
            mode: mode,
          );
          final square = problem.toSquare();
          expect(square.origins.length, 3);
          expect(square.destinations.length, 3);
          final result = solver.solve(problem)!;
          expect(result.matches.length, 3);
          expect(result.matches.map((m) => m.origin.id).toSet().length, 3);
          expect(result.matches.map((m) => m.destination.id).toSet().length, 3);
          final fictitious = result.matches
              .where((m) => m.origin.isDummy || m.destination.isDummy)
              .single;
          expect(fictitious.value, 0);
          expect(
            result.total,
            mode == OptimizationMode.minimize ? 3 : (moreOrigins ? 12 : 13),
          );
          expect(problem.origins.length, moreOrigins ? 3 : 2);
          expect(problem.destinations.length, moreOrigins ? 2 : 3);
          expect(identical(square.toSquare(), square), isTrue);
        }
      }
    },
  );

  test('añade varios ficticios sin inventar conexiones reales ausentes', () {
    final problem = AssignmentProblem(
      origins: [origins.first],
      destinations: [
        ...destinations,
        const AssignmentItem(id: 'z', label: 'Z'),
      ],
      costs: const [],
      mode: OptimizationMode.minimize,
    );
    final square = problem.toSquare();
    expect(square.origins.where((o) => o.isDummy).length, 2);
    expect(square.costFor('a', 'x'), isNull);
    expect(solver.solve(problem), isNull);
  });
}
