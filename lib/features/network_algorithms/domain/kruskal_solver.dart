import 'package:app_grafos/features/network_algorithms/domain/weighted_network.dart';
import 'package:app_grafos/features/network_algorithms/domain/network_objective.dart';
import 'package:app_grafos/shared/domain/mathematical_procedure.dart';

class KruskalSolver {
  const KruskalSolver();
  KruskalResult solve(
    WeightedNetwork network, {
    NetworkObjective objective = NetworkObjective.minimize,
  }) {
    final maximizing = objective == NetworkObjective.maximize;
    final optimum = maximizing ? 'máximo' : 'mínimo';
    network.validate();
    final parent = {for (final id in network.nodes) id: id};
    final rank = {for (final id in network.nodes) id: 0};
    String root(String id) {
      var current = id;
      while (parent[current] != current) {
        parent[current] = parent[parent[current]]!;
        current = parent[current]!;
      }
      return current;
    }

    final ordered = [...network.edges]
      ..sort((a, b) {
        final byWeight = maximizing
            ? b.weight.compareTo(a.weight)
            : a.weight.compareTo(b.weight);
        if (byWeight != 0) return byWeight;
        final byFrom = a.from.compareTo(b.from);
        return byFrom != 0 ? byFrom : a.to.compareTo(b.to);
      });
    final chosen = <WeightedEdge>[];
    var components = network.nodes.length;
    var total = 0;
    final steps = <MathematicalStep>[
      MathematicalStep(
        title: 'Ordenar conexiones',
        description:
            'Se consideran ${maximizing ? 'de mayor a menor' : 'de menor a mayor'} peso. Cada nodo empieza en su propio conjunto.',
        expressions: [
          for (final e in ordered)
            '${network.label(e.from)} — ${network.label(e.to)}: ${e.weight}',
        ],
      ),
    ];
    for (final edge in ordered) {
      var a = root(edge.from);
      var b = root(edge.to);
      final accept = a != b;
      if (accept) {
        if (rank[a]! < rank[b]!) {
          final temp = a;
          a = b;
          b = temp;
        }
        parent[b] = a;
        if (rank[a] == rank[b]) rank[a] = rank[a]! + 1;
        chosen.add(edge);
        components--;
        total += edge.weight;
      }
      steps.add(
        MathematicalStep(
          title:
              '${network.label(edge.from)} — ${network.label(edge.to)}: ${accept ? 'aceptar' : 'descartar'}',
          description: accept
              ? 'Une dos componentes diferentes sin crear un ciclo.'
              : 'Sus extremos ya pertenecen al mismo componente: crearía un ciclo.',
          expressions: [
            'Peso = ${edge.weight}',
            'Costo acumulado = $total; componentes = $components',
          ],
        ),
      );
    }
    steps.add(
      MathematicalStep(
        title: components == 1 ? 'Árbol $optimum completo' : 'Bosque $optimum',
        description: components == 1
            ? 'Todos los nodos están conectados con el ${maximizing ? 'mayor' : 'menor'} costo total.'
            : 'El grafo no es conexo. Se obtiene un árbol $optimum para cada uno de los $components componentes, incluidos nodos aislados.',
        expressions: [
          'Aristas elegidas = ${chosen.length}',
          'Costo total = $total',
        ],
      ),
    );
    return KruskalResult(
      edges: chosen,
      objective: objective,
      components: components,
      procedure: MathematicalProcedure(
        title: 'Procedimiento matemático · Kruskal',
        description:
            'Kruskal: ${maximizing ? 'maximizar' : 'minimizar'} el costo total mediante selección por peso y unión de conjuntos. Los pesos negativos son válidos.',
        steps: steps,
      ),
    );
  }
}
