import 'package:flutter_test/flutter_test.dart';
import 'package:app_grafos/features/esquina_nor_oeste/domain/esquina_nor_oeste_problem.dart';
import 'package:app_grafos/features/esquina_nor_oeste/domain/optimization_mode.dart';

void main() {
  EsquinaNorOesteProblem problem(num supply, num demand) =>
      EsquinaNorOesteProblem(
        origins: [EsquinaNorOesteItem(id: 'a', label: 'A', supply: supply)],
        destinations: [
          EsquinaNorOesteItem(id: 'x', label: 'X', demand: demand),
          const EsquinaNorOesteItem(id: 'y', label: 'Y', demand: 5),
        ],
        costs: const [
          EsquinaNorOesteCost(originId: 'a', destinationId: 'x', value: 7),
        ],
        mode: OptimizationMode.minimize,
      );
  test(
    'oferta insuficiente muestra fila ficticia y conserva rutas prohibidas',
    () {
      final original = problem(10, 10);
      final balanced = original.toBalanced();
      final dummy = balanced.origins.last;
      expect(dummy.label, 'Origen ficticio');
      expect(dummy.isDummy, isTrue);
      expect(dummy.supply, 5);
      expect(balanced.costFor(dummy.id, 'x'), 0);
      expect(balanced.costFor(dummy.id, 'y'), 0);
      expect(balanced.costFor('a', 'y'), isNull);
      expect(balanced.totalSupply, balanced.totalDemand);
      expect(original.origins.length, 1);
      expect(original.costs.length, 1);
      expect(identical(balanced.toBalanced(), balanced), isTrue);
    },
  );
  test('oferta sobrante muestra columna ficticia de costo cero', () {
    final balanced = problem(20, 10).toBalanced();
    final dummy = balanced.destinations.last;
    expect(dummy.label, 'Destino ficticio');
    expect(dummy.demand, 5);
    expect(dummy.isDummy, isTrue);
    expect(balanced.costFor('a', dummy.id), 0);
    expect(balanced.totalSupply, balanced.totalDemand);
  });
  test('totales iguales no añaden fila ni columna', () {
    final original = problem(15, 10);
    expect(identical(original.toBalanced(), original), isTrue);
  });
}
