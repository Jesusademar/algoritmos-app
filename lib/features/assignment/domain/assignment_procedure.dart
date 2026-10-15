import 'package:app_grafos/features/assignment/domain/assignment_problem.dart';
import 'package:app_grafos/features/assignment/domain/assignment_result.dart';
import 'package:app_grafos/features/assignment/domain/optimization_mode.dart';
import 'package:app_grafos/shared/domain/mathematical_procedure.dart';

/// Registra alternativas durante la misma búsqueda que obtiene el resultado.
class AssignmentProcedureRecorder {
  AssignmentProcedureRecorder(this.original, this.square);
  final AssignmentProblem original;
  final AssignmentProblem square;
  int evaluated = 0;
  final List<String> _alternatives = [];
  final List<String> _improvements = [];

  void candidate(List<int> columns, num total, bool improves) {
    evaluated++;
    if (_alternatives.length < 24) {
      final terms = [
        for (var i = 0; i < columns.length; i++)
          mathTerm(
            square.costFor(
              square.origins[i].id,
              square.destinations[columns[i]].id,
            )!,
          ),
      ];
      final pairs = [
        for (var i = 0; i < columns.length; i++)
          '${square.origins[i].label} -> ${square.destinations[columns[i]].label}',
      ];
      _alternatives.add(
        'Alternativa $evaluated: ${pairs.join('; ')}\nZ = ${terms.join(' + ')} = ${mathNumber(total)}',
      );
    }
    if (improves && _improvements.length < 24) {
      _improvements.add(
        'Alternativa $evaluated: mejor valor hasta aquí = ${mathNumber(total)}.',
      );
    }
  }

  MathematicalProcedure finish(List<AssignmentMatch> matches) {
    final minimizing = square.mode == OptimizationMode.minimize;
    final total = matches.fold<num>(0, (sum, match) => sum + match.value);
    final dummyRows = square.origins.where((item) => item.isDummy).length;
    final dummyColumns = square.destinations
        .where((item) => item.isDummy)
        .length;
    final numericSum = matches
        .map((match) => mathTerm(match.value))
        .join(' + ');
    return MathematicalProcedure(
      title: 'Procedimiento matemático · Asignación',
      description: 'Se comparan asignaciones completas, usando una columna distinta por fila. El procedimiento corresponde a la búsqueda exhaustiva que ejecuta este módulo.',
      steps: [
        MathematicalStep(
          title: 'Datos de entrada y matriz cuadrada',
          description:
              'Matriz original: ${original.origins.length} × ${original.destinations.length}. Matriz de cálculo: ${square.origins.length} × ${square.destinations.length}. '
              '${dummyRows + dummyColumns == 0 ? 'No se necesitan elementos ficticios.' : 'Se añaden $dummyRows filas y $dummyColumns columnas ficticias de costo cero.'} Una ruta no disponible se indica con — y no puede elegirse.',
          table: MathematicalTable(
            columns: [
              'Origen / Destino',
              ...square.destinations.map((item) => item.label),
            ],
            rows: [
              for (final origin in square.origins)
                [
                  origin.label,
                  for (final destination in square.destinations)
                    square.costFor(origin.id, destination.id) == null
                        ? '—'
                        : mathNumber(
                            square.costFor(origin.id, destination.id)!,
                          ),
                ],
            ],
          ),
        ),
        MathematicalStep(
          title: 'Función objetivo y restricciones',
          description: 'x[i,j] vale 1 si el origen i se asigna al destino j, y 0 en caso contrario. c[i,j] es el costo de esa asignación y Σ indica una suma. Las restricciones se aplican a la matriz cuadrada, incluidos los ficticios.',
          expressions: [
            '${minimizing ? 'Minimizar' : 'Maximizar'} Z = Σ(i) Σ(j) c[i,j] × x[i,j]',
            'Para cada origen i: Σ(j) x[i,j] = 1',
            'Para cada destino j: Σ(i) x[i,j] = 1',
            'x[i,j] = 0 o 1; x[i,j] = 0 en rutas no disponibles.',
          ],
        ),
        MathematicalStep(
          title: 'Comparación de alternativas',
          description:
              'Se evaluaron $evaluated asignaciones completas válidas. '
              '${evaluated > _alternatives.length ? 'Se muestran las primeras ${_alternatives.length}; la selección considera las $evaluated alternativas.' : 'Estas son todas las alternativas válidas evaluadas.'}',
          expressions: _alternatives,
        ),
        MathematicalStep(
          title: 'Elección del ${minimizing ? 'mínimo' : 'máximo'}',
          description:
              'Cada nueva alternativa se compara con el mejor valor encontrado. Se conserva ${minimizing ? 'el menor' : 'el mayor'}; si hay empate, se mantiene la primera solución encontrada. El resumen lista hasta 24 actualizaciones del mejor valor.',
          expressions: [
            ..._improvements,
            'Z* = ${minimizing ? 'mínimo' : 'máximo'} de las $evaluated alternativas válidas = ${mathNumber(total)}',
          ],
        ),
        MathematicalStep(
          title: 'Asignaciones y resultado final',
          description: 'Cada origen y cada destino de la matriz cuadrada aparecen una sola vez. Las asignaciones ficticias tienen costo cero y representan recursos o tareas sin pareja real.',
          expressions: [
            for (final match in matches)
              '${match.origin.label} -> ${match.destination.label}: x = 1, costo = ${mathNumber(match.value)}${match.origin.isDummy || match.destination.isDummy ? ' (ficticio)' : ''}',
            'Z = $numericSum = ${mathNumber(total)}',
          ],
        ),
      ],
    );
  }
}
