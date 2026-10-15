import 'package:flutter_test/flutter_test.dart';

import 'package:app_grafos/features/assignment/domain/assignment_problem.dart';
import 'package:app_grafos/features/assignment/domain/assignment_solver.dart';
import 'package:app_grafos/features/assignment/domain/optimization_mode.dart';

void main() {
  const solver = AssignmentSolver();
  AssignmentProblem problem(OptimizationMode mode) => AssignmentProblem(
    origins: const [
      AssignmentItem(id: 'a', label: 'A'),
      AssignmentItem(id: 'b', label: 'B'),
    ],
    destinations: const [
      AssignmentItem(id: 'x', label: 'X'),
      AssignmentItem(id: 'y', label: 'Y'),
    ],
    costs: const [
      AssignmentCost(originId: 'a', destinationId: 'x', value: 4),
      AssignmentCost(originId: 'a', destinationId: 'y', value: 1),
      AssignmentCost(originId: 'b', destinationId: 'x', value: 2),
      AssignmentCost(originId: 'b', destinationId: 'y', value: 5),
    ],
    mode: mode,
  );
  test(
    'registra las dos alternativas y la suma real en minimizar y maximizar',
    () {
      for (final mode in OptimizationMode.values) {
        final input = problem(mode);
        final regular = solver.solve(input)!;
        expect(regular.procedure, isNull);
        final result = solver.solve(input, includeProcedure: true)!;
        expect(result.total, regular.total);
        final procedure = result.procedure!;
        expect(procedure.steps[2].expressions, hasLength(2));
        expect(
          procedure.steps[2].expressions.join('\n'),
          contains('Z = 4 + 5 = 9'),
        );
        expect(
          procedure.steps[2].expressions.join('\n'),
          contains('Z = 1 + 2 = 3'),
        );
        expect(
          procedure.steps.last.expressions.last,
          mode == OptimizationMode.minimize ? 'Z = 1 + 2 = 3' : 'Z = 4 + 5 = 9',
        );
        expect(() => procedure.steps.clear(), throwsUnsupportedError);
        expect(
          () => procedure.steps.first.table!.rows.first.clear(),
          throwsUnsupportedError,
        );
      }
    },
  );
  test('explica ficticios de costo cero y excluye rutas reales ausentes', () {
    final input = AssignmentProblem(
      origins: const [AssignmentItem(id: 'a', label: 'A')],
      destinations: problem(OptimizationMode.minimize).destinations,
      costs: const [
        AssignmentCost(originId: 'a', destinationId: 'y', value: 2),
      ],
      mode: OptimizationMode.minimize,
    );
    final result = solver.solve(input, includeProcedure: true)!;
    expect(result.total, 2);
    expect(
      result.procedure!.steps.first.description,
      contains('1 filas y 0 columnas ficticias'),
    );
    expect(result.procedure!.steps.first.table!.rows.first[1], '—');
    expect(result.procedure!.steps[2].expressions, hasLength(1));
    expect(result.procedure!.steps.last.expressions.last, 'Z = 2 + 0 = 2');
  });
  test('limita el listado sin omitir alternativas de la búsqueda', () {
    final input = AssignmentProblem(
      origins: [
        for (var i = 0; i < 5; i++) AssignmentItem(id: 'o$i', label: 'O$i'),
      ],
      destinations: [
        for (var i = 0; i < 5; i++) AssignmentItem(id: 'd$i', label: 'D$i'),
      ],
      costs: [
        for (var i = 0; i < 5; i++)
          for (var j = 0; j < 5; j++)
            AssignmentCost(
              originId: 'o$i',
              destinationId: 'd$j',
              value: i == j ? -1 : 4,
            ),
      ],
      mode: OptimizationMode.minimize,
    );
    final result = solver.solve(input, includeProcedure: true)!;
    expect(result.total, -5);
    expect(
      result.procedure!.steps[2].description,
      contains('120 asignaciones'),
    );
    expect(result.procedure!.steps[2].expressions, hasLength(24));
    expect(
      result.procedure!.steps.last.expressions.last,
      'Z = (-1) + (-1) + (-1) + (-1) + (-1) = -5',
    );
  });
}
