import 'package:app_grafos/shared/domain/mathematical_procedure.dart';
import 'package:app_grafos/features/esquina_nor_oeste/domain/esquina_nor_oeste_problem.dart';

/// Asignación o cantidad enviada de un origen a un destino.
class EsquinaNorOesteAssignment {
  const EsquinaNorOesteAssignment({
    required this.origin,
    required this.destination,
    required this.quantity,
    required this.unitCost,
  });

  final EsquinaNorOesteItem origin;
  final EsquinaNorOesteItem destination;
  final num quantity;
  final num unitCost;

  num get totalCost => quantity * unitCost;
}

/// Resultado de la ejecución del algoritmo de Esquina Nor-Oeste.
class EsquinaNorOesteResult {
  EsquinaNorOesteResult({
    required List<EsquinaNorOesteAssignment> assignments,
    this.unshippedSupply = 0,
    this.unmetDemand = 0,
    this.procedure,
  }) : assignments = List.unmodifiable(assignments),
       totalCost = assignments.fold<num>(0, (sum, a) => sum + a.totalCost);

  final List<EsquinaNorOesteAssignment> assignments;
  final num totalCost;
  final num unshippedSupply;
  final num unmetDemand;
  final MathematicalProcedure? procedure;
}
