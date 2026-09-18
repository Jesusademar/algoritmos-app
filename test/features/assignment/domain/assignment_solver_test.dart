import 'package:app_grafos/features/assignment/domain/assignment_problem.dart';
import 'package:app_grafos/features/assignment/domain/assignment_solver.dart';
import 'package:app_grafos/features/assignment/domain/optimization_mode.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
