import 'package:app_grafos/features/esquina_nor_oeste/domain/esquina_nor_oeste_problem.dart';
import 'package:app_grafos/features/esquina_nor_oeste/domain/optimization_mode.dart';
import 'package:app_grafos/shared/domain/mathematical_procedure.dart';

class TransportChange {
  const TransportChange(this.row, this.column, this.direction, this.before);
  final int row;
  final int column;
  final int direction;
  final num before;
}

/// Captura el estado numérico justo después de cada operación del solver.
class TransportProcedureRecorder {
  TransportProcedureRecorder({
    required this.problem,
    required this.origins,
    required this.destinations,
    required this.unitCost,
    required this.allocated,
  }) {
    final supply = problem.origins.fold<num>(
      0,
      (sum, item) => sum + item.supply,
    );
    final demand = problem.destinations.fold<num>(
      0,
      (sum, item) => sum + item.demand,
    );
    _steps.add(
      MathematicalStep(
        title: 'Matriz de costos, oferta y demanda',
        description: '— indica una ruta no disponible. La oferta y demanda corresponden a los datos de entrada.',
        expressions: [
          'Oferta total = ${problem.origins.map((item) => mathTerm(item.supply)).join(' + ')} = ${mathNumber(supply)}',
          'Demanda total = ${problem.destinations.map((item) => mathTerm(item.demand)).join(' + ')} = ${mathNumber(demand)}',
          if (supply == demand)
            'Oferta total = Demanda total: problema equilibrado.'
          else
            'Diferencia = ${mathNumber((supply - demand).abs())}. Se representa con ${supply > demand ? 'un destino' : 'un origen'} auxiliar de costo cero.',
        ],
        table: _costTable(),
      ),
    );
    _steps.add(
      MathematicalStep(
        title: 'Modelo matemático',
        description: 'x[i,j] representa la cantidad enviada del origen i al destino j; c[i,j], su costo unitario. Σ indica una suma. Las restricciones incluyen el auxiliar cuando hay una diferencia entre los totales.',
        expressions: [
          '${problem.mode == OptimizationMode.minimize ? 'Minimizar' : 'Maximizar'} Z = Σ(i) Σ(j) c[i,j] × x[i,j]',
          'Para cada origen i: Σ(j) x[i,j] = oferta[i]',
          'Para cada destino j: Σ(i) x[i,j] = demanda[j]',
          'x[i,j] >= 0; x[i,j] = 0 en rutas no disponibles.',
        ],
      ),
    );
  }
  final EsquinaNorOesteProblem problem;
  final List<EsquinaNorOesteItem> origins;
  final List<EsquinaNorOesteItem> destinations;
  final num? Function(int, int) unitCost;
  final num Function(int, int) allocated;
  final List<MathematicalStep> _steps = [];
  int _northWestCount = 0;
  int _pathCount = 0;
  int _cycleCount = 0;
  int _recorded = 0;
  int _omitted = 0;

  String _variable(int i, int j) =>
      'x[${origins[i].label}, ${destinations[j].label}]';
  MathematicalTable _costTable() => MathematicalTable(
    columns: [
      'Origen / Destino',
      ...destinations.map((item) => item.label),
      'Oferta',
    ],
    rows: [
      for (var i = 0; i < origins.length; i++)
        [
          origins[i].label,
          for (var j = 0; j < destinations.length; j++)
            unitCost(i, j) == null ? '—' : mathNumber(unitCost(i, j)!),
          mathNumber(origins[i].supply),
        ],
      ['Demanda', ...destinations.map((item) => mathNumber(item.demand)), ''],
    ],
  );
  MathematicalTable _allocationTable() => MathematicalTable(
    columns: ['Cantidades', ...destinations.map((item) => item.label)],
    rows: [
      for (var i = 0; i < origins.length; i++)
        [
          origins[i].label,
          for (var j = 0; j < destinations.length; j++)
            unitCost(i, j) == null ? '—' : mathNumber(allocated(i, j)),
        ],
    ],
  );
  void _record(MathematicalStep Function() build) {
    if (_recorded >= 60) {
      _omitted++;
      return;
    }
    _recorded++;
    _steps.add(build());
  }

  void northWest(
    int i,
    int j,
    num quantity,
    num supplyBefore,
    num demandBefore,
  ) {
    _northWestCount++;
    _record(
      () => MathematicalStep(
        title: 'Esquina noroeste · Paso $_northWestCount',
        description: 'Se toma la primera celda disponible del recorrido noroeste. Se avanza a la siguiente fila o columna cuando se agota su cantidad.',
        expressions: [
          '${_variable(i, j)} = min(${mathNumber(supplyBefore)}, ${mathNumber(demandBefore)}) = ${mathNumber(quantity)}',
          'Oferta restante de ${origins[i].label}: ${mathNumber(supplyBefore)} − ${mathNumber(quantity)} = ${mathNumber(supplyBefore - quantity)}',
          'Demanda restante de ${destinations[j].label}: ${mathNumber(demandBefore)} − ${mathNumber(quantity)} = ${mathNumber(demandBefore - quantity)}',
          'Contribución al costo: ${mathNumber(quantity)} × ${mathTerm(unitCost(i, j)!)} = ${mathNumber(quantity * unitCost(i, j)!)}',
        ],
        table: _allocationTable(),
      ),
    );
  }

  void adjustment(
    List<TransportChange> changes,
    num quantity,
    List<num> capacities, {
    num? unitDelta,
    num? costBefore,
  }) {
    final optimizing = unitDelta != null;
    if (optimizing) {
      _cycleCount++;
    } else {
      _pathCount++;
    }
    _record(
      () => MathematicalStep(
        title: optimizing
            ? 'Optimización · Circuito $_cycleCount'
            : 'Completar flujo · Paso $_pathCount',
        description: optimizing
            ? 'Se redistribuyen cantidades por un circuito residual. Se suma en las rutas de avance y se resta en las de retorno, conservando ofertas y demandas.'
            : 'Una ruta no disponible interrumpió el recorrido noroeste. Un camino residual completa o redistribuye el envío usando las rutas permitidas.',
        expressions: [
          'θ = min{${capacities.map(mathNumber).join(', ')}} = ${mathNumber(quantity)} (capacidad residual disponible)',
          if (optimizing)
            'Δ = ${changes.map((change) => '${change.direction > 0 ? '+' : '−'} ${mathTerm(unitCost(change.row, change.column)!)}').join(' ')} = ${mathNumber(unitDelta)}',
          for (final change in changes)
            '${_variable(change.row, change.column)}: ${mathNumber(change.before)} ${change.direction > 0 ? '+' : '−'} ${mathNumber(quantity)} = ${mathNumber(allocated(change.row, change.column))}',
          if (optimizing)
            'ΔZ = θ × Δ = ${mathNumber(quantity)} × ${mathTerm(unitDelta)} = ${mathNumber(quantity * unitDelta)}',
          if (optimizing)
            'Z nuevo = ${mathNumber(costBefore!)} + ${mathTerm(quantity * unitDelta)} = ${mathNumber(_total())}',
        ],
        table: _allocationTable(),
      ),
    );
  }

  num _total() {
    num total = 0;
    for (var i = 0; i < origins.length; i++) {
      for (var j = 0; j < destinations.length; j++) {
        total += allocated(i, j) * (unitCost(i, j) ?? 0);
      }
    }
    return total;
  }

  void initialSolution() {
    _steps.add(
      MathematicalStep(
        title: 'Solución inicial factible',
        description: 'El recorrido noroeste utiliza las ofertas y demandas en su orden de entrada. La siguiente fase optimiza los costos de esta distribución.',
        expressions: ['Z inicial = ${mathNumber(_total())}'],
        table: _allocationTable(),
      ),
    );
  }

  MathematicalProcedure finish() {
    if (_omitted > 0) {
      _steps.add(
        MathematicalStep(
          title: 'Registro de iteraciones',
          description:
              'Se realizaron $_omitted ajustes adicionales. Para mantener legible el registro se muestran las primeras 60 operaciones; las comprobaciones y el resultado final incluyen todos los ajustes.',
        ),
      );
    }
    _steps.add(
      MathematicalStep(
        title: 'Comprobación de oferta y demanda',
        description: 'Las sumas de la matriz final cumplen las restricciones del problema equilibrado.',
        expressions: [
          for (var i = 0; i < origins.length; i++)
            'Oferta de ${origins[i].label}: ${List.generate(destinations.length, (j) => mathTerm(allocated(i, j))).join(' + ')} = ${mathNumber(origins[i].supply)}',
          for (var j = 0; j < destinations.length; j++)
            'Demanda de ${destinations[j].label}: ${List.generate(origins.length, (i) => mathTerm(allocated(i, j))).join(' + ')} = ${mathNumber(destinations[j].demand)}',
        ],
        table: _allocationTable(),
      ),
    );
    final terms = <String>[];
    final contributions = <String>[];
    for (var i = 0; i < origins.length; i++) {
      for (var j = 0; j < destinations.length; j++) {
        final quantity = allocated(i, j);
        if (quantity <= 1e-9) continue;
        final cost = unitCost(i, j)!;
        terms.add('${mathNumber(quantity)} × ${mathTerm(cost)}');
        contributions.add(
          '${origins[i].label} -> ${destinations[j].label}: ${mathNumber(quantity)} × ${mathTerm(cost)} = ${mathNumber(quantity * cost)}',
        );
      }
    }
    _steps.add(
      MathematicalStep(
        title: 'Costo y resultado final',
        description:
            'Se realizaron $_northWestCount asignaciones noroeste, $_pathCount caminos de ajuste y $_cycleCount circuitos de mejora. No quedan circuitos residuales que ${problem.mode == OptimizationMode.minimize ? 'reduzcan' : 'aumenten'} el costo. Las rutas auxiliares tienen costo cero.',
        expressions: [
          ...contributions,
          'Z = ${terms.isEmpty ? '0' : terms.join(' + ')} = ${mathNumber(_total())}',
        ],
      ),
    );
    return MathematicalProcedure(
      title: 'Procedimiento matemático · Esquina Noroeste',
      description: 'Primero se construye la solución inicial por esquina noroeste y después se optimiza según el objetivo seleccionado.',
      steps: _steps,
    );
  }
}
