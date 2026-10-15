import 'package:flutter_test/flutter_test.dart';

import 'package:app_grafos/features/esquina_nor_oeste/domain/esquina_nor_oeste_problem.dart';
import 'package:app_grafos/features/esquina_nor_oeste/domain/esquina_nor_oeste_solver.dart';
import 'package:app_grafos/features/esquina_nor_oeste/domain/optimization_mode.dart';

void main() {
  const solver = EsquinaNorOesteSolver();
  EsquinaNorOesteProblem problem(
    OptimizationMode mode, {
    bool sparse = false,
    num extraDemand = 0,
    bool swapCosts = false,
  }) => EsquinaNorOesteProblem(
    origins: const [
      EsquinaNorOesteItem(id: 'a', label: 'A', supply: 10),
      EsquinaNorOesteItem(id: 'b', label: 'B', supply: 10),
    ],
    destinations: [
      const EsquinaNorOesteItem(id: 'x', label: 'X', demand: 10),
      EsquinaNorOesteItem(id: 'y', label: 'Y', demand: 10 + extraDemand),
    ],
    costs: [
      const EsquinaNorOesteCost(originId: 'a', destinationId: 'x', value: 1),
      EsquinaNorOesteCost(
        originId: 'a',
        destinationId: 'y',
        value: swapCosts ? 100 : 2,
      ),
      const EsquinaNorOesteCost(originId: 'b', destinationId: 'x', value: 2),
      if (!sparse)
        EsquinaNorOesteCost(
          originId: 'b',
          destinationId: 'y',
          value: swapCosts ? 3 : 100,
        ),
    ],
    mode: mode,
  );
  test(
    'registra mínimos, restos y mejora por circuito sin alterar el resultado',
    () {
      final input = problem(OptimizationMode.minimize);
      final result = solver.solve(input, includeProcedure: true)!;
      expect(result.totalCost, solver.solve(input)!.totalCost);
      expect(result.totalCost, 40);
      final procedure = result.procedure!;
      final first = procedure.steps.firstWhere(
        (step) => step.title == 'Esquina noroeste · Paso 1',
      );
      expect(first.expressions.first, 'x[A, X] = min(10, 10) = 10');
      expect(first.table!.rows.first[1], '10');
      expect(
        procedure.steps
            .firstWhere((step) => step.title == 'Solución inicial factible')
            .expressions
            .single,
        'Z inicial = 1010',
      );
      final cycle = procedure.steps.firstWhere(
        (step) => step.title == 'Optimización · Circuito 1',
      );
      expect(cycle.expressions.join('\n'), contains('= -97'));
      expect(cycle.expressions.last, 'Z nuevo = 1010 + (-970) = 40');
      final finalTable = procedure.steps
          .firstWhere(
            (step) => step.title == 'Comprobación de oferta y demanda',
          )
          .table!;
      expect(finalTable.rows.first[1], '0');
      expect(
        first.table!.rows.first[1],
        '10',
      ); // La matriz anterior es una instantánea.
      expect(procedure.steps.last.expressions.last, 'Z = 10 × 2 + 10 × 2 = 40');
    },
  );
  test(
    'los circuitos de maximización muestran incrementos con costos originales',
    () {
      final input = problem(OptimizationMode.maximize, swapCosts: true);
      final result = solver.solve(input, includeProcedure: true)!;
      expect(result.totalCost, 1020);
      final cycle = result.procedure!.steps.firstWhere(
        (step) => step.title == 'Optimización · Circuito 1',
      );
      expect(cycle.expressions.join('\n'), contains('= 98'));
      expect(cycle.expressions.last, 'Z nuevo = 40 + 980 = 1020');
      expect(
        result.procedure!.steps.last.expressions.last,
        'Z = 10 × 100 + 10 × 2 = 1020',
      );
    },
  );
  test(
    'explica la redistribución por rutas residuales cuando falta una conexión',
    () {
      final result = solver.solve(
        problem(OptimizationMode.minimize, sparse: true),
        includeProcedure: true,
      )!;
      expect(result.totalCost, 40);
      final path = result.procedure!.steps.firstWhere(
        (step) => step.title == 'Completar flujo · Paso 1',
      );
      expect(path.expressions, contains('x[A, X]: 10 − 10 = 0'));
      expect(path.expressions, contains('x[A, Y]: 0 + 10 = 10'));
      expect(result.procedure!.steps.first.table!.rows[1][2], '—');
    },
  );
  test('incluye auxiliares y la contribución cero cuando falta oferta', () {
    final result = solver.solve(
      problem(OptimizationMode.minimize, extraDemand: 5),
      includeProcedure: true,
    )!;
    expect(result.unmetDemand, 5);
    expect(
      result.procedure!.steps.first.expressions.join('\n'),
      contains('Diferencia = 5'),
    );
    expect(
      result.procedure!.steps.last.expressions.join('\n'),
      contains('Demanda pendiente'),
    );
    expect(result.procedure!.steps.last.expressions.last, endsWith('= 40'));
    expect(solver.solve(problem(OptimizationMode.minimize))!.procedure, isNull);
  });
}
