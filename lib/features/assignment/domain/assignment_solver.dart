import 'dart:math';

import 'package:app_grafos/features/assignment/domain/assignment_problem.dart';
import 'package:app_grafos/features/assignment/domain/assignment_procedure.dart';
import 'package:app_grafos/features/assignment/domain/assignment_result.dart';
import 'package:app_grafos/features/assignment/domain/optimization_mode.dart';

/// Resuelve minimización y maximización sin depender de widgets ni estado UI.
///
/// Se conserva la regla existente de completar con filas o columnas ficticias
/// de costo cero cuando la matriz no es cuadrada.
class AssignmentSolver {
  const AssignmentSolver();

  AssignmentResult? solve(
    AssignmentProblem problem, {
    bool includeProcedure = false,
  }) {
    if (problem.origins.isEmpty || problem.destinations.isEmpty) return null;
    final original = problem;
    problem = problem.toSquare();
    final procedure = includeProcedure
        ? AssignmentProcedureRecorder(original, problem)
        : null;

    final size = max(problem.origins.length, problem.destinations.length);
    final usedColumns = List<bool>.filled(size, false);
    final currentColumns = List<int>.filled(size, -1);
    List<int>? bestColumns;
    num? bestCost;

    void search(int row, num currentCost) {
      if (row == size) {
        final improvesBest =
            bestCost == null ||
            (problem.mode == OptimizationMode.minimize
                ? currentCost < bestCost!
                : currentCost > bestCost!);
        procedure?.candidate(currentColumns, currentCost, improvesBest);
        if (improvesBest) {
          bestCost = currentCost;
          bestColumns = List<int>.from(currentColumns);
        }
        return;
      }

      for (var column = 0; column < size; column++) {
        if (usedColumns[column]) continue;

        num value = 0;
        final isRealPair =
            row < problem.origins.length &&
            column < problem.destinations.length;
        if (isRealPair) {
          final origin = problem.origins[row];
          final destination = problem.destinations[column];
          final pairCost = problem.costFor(origin.id, destination.id);
          if (pairCost == null) continue;
          value = pairCost;
        }

        usedColumns[column] = true;
        currentColumns[row] = column;
        search(row + 1, currentCost + value);
        currentColumns[row] = -1;
        usedColumns[column] = false;
      }
    }

    search(0, 0);
    final solution = bestColumns;
    if (solution == null) return null;

    final matches = <AssignmentMatch>[];
    for (var row = 0; row < problem.origins.length; row++) {
      final column = solution[row];
      if (column < 0 || column >= problem.destinations.length) continue;

      final origin = problem.origins[row];
      final destination = problem.destinations[column];
      final value = problem.costFor(origin.id, destination.id);
      if (value == null) continue;
      matches.add(
        AssignmentMatch(origin: origin, destination: destination, value: value),
      );
    }

    return AssignmentResult(
      matches: matches,
      procedure: procedure?.finish(matches),
    );
  }
}
