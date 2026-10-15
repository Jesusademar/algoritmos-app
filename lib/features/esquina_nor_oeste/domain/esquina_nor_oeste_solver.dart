import 'dart:collection';
import 'dart:math';

import 'package:app_grafos/features/esquina_nor_oeste/domain/esquina_nor_oeste_problem.dart';
import 'package:app_grafos/features/esquina_nor_oeste/domain/esquina_nor_oeste_result.dart';
import 'package:app_grafos/features/esquina_nor_oeste/domain/optimization_mode.dart';
import 'package:app_grafos/features/esquina_nor_oeste/domain/transport_procedure.dart';

/// Obtiene una solución inicial por esquina noroeste y mejora su costo
/// mediante circuitos en la red residual. Para maximizar, invierte los costos
/// de optimización, conservando los costos originales en el resultado.
/// Una ruta ausente está prohibida; no equivale a un costo cero.
class EsquinaNorOesteSolver {
  const EsquinaNorOesteSolver();
  static const _epsilon = 1e-9;

  /// Balancea internamente con un origen o destino auxiliar de costo cero.
  /// Devuelve null si los datos son inválidos o las rutas no permiten enviar
  /// toda la cantidad disponible para el transporte.
  EsquinaNorOesteResult? solve(
    EsquinaNorOesteProblem problem, {
    bool includeProcedure = false,
  }) {
    final origins = List<EsquinaNorOesteItem>.of(problem.origins);
    final destinations = List<EsquinaNorOesteItem>.of(problem.destinations);
    if (origins.isEmpty || destinations.isEmpty) return null;
    if (origins.map((o) => o.id).toSet().length != origins.length ||
        destinations.map((d) => d.id).toSet().length != destinations.length) {
      return null;
    }
    if (origins.any((o) => !o.supply.isFinite || o.supply < 0) ||
        destinations.any((d) => !d.demand.isFinite || d.demand < 0) ||
        problem.costs.any((c) => !c.value.isFinite)) {
      return null;
    }
    final totalSupply = origins.fold<num>(0, (sum, o) => sum + o.supply);
    final totalDemand = destinations.fold<num>(0, (sum, d) => sum + d.demand);
    if (!totalSupply.isFinite || !totalDemand.isFinite) return null;
    if (totalSupply - totalDemand > _epsilon) {
      destinations.add(
        EsquinaNorOesteItem(
          id: '',
          label: 'Oferta sin utilizar',
          demand: totalSupply - totalDemand,
        ),
      );
    } else if (totalDemand - totalSupply > _epsilon) {
      origins.add(
        EsquinaNorOesteItem(
          id: '',
          label: 'Demanda pendiente',
          supply: totalDemand - totalSupply,
        ),
      );
    }
    final targetTotal = max(totalSupply, totalDemand);

    num? unitCost(int i, int j) =>
        i >= problem.origins.length || j >= problem.destinations.length
        ? 0
        : problem.costFor(origins[i].id, destinations[j].id);

    final source = origins.length + destinations.length;
    final sink = source + 1;
    final network = List.generate(sink + 1, (_) => <_FlowEdge>[]);
    _FlowEdge addEdge(int from, int to, num capacity, num cost) {
      final forward = _FlowEdge(from, to, capacity, cost);
      final reverse = _FlowEdge(to, from, 0, -cost);
      forward.reverse = reverse;
      reverse.reverse = forward;
      network[from].add(forward);
      network[to].add(reverse);
      return forward;
    }

    final supplyEdges = [
      for (var i = 0; i < origins.length; i++)
        addEdge(source, i, origins[i].supply, 0),
    ];
    final demandEdges = [
      for (var j = 0; j < destinations.length; j++)
        addEdge(origins.length + j, sink, destinations[j].demand, 0),
    ];
    final routes = List.generate(
      origins.length,
      (_) => List<_FlowEdge?>.filled(destinations.length, null),
    );
    final coordinates = <_FlowEdge, (int, int, int)>{};
    final sign = problem.mode == OptimizationMode.minimize ? 1 : -1;
    for (var i = 0; i < origins.length; i++) {
      for (var j = 0; j < destinations.length; j++) {
        final cost = unitCost(i, j);
        if (cost != null) {
          routes[i][j] = addEdge(
            i,
            origins.length + j,
            min(origins[i].supply, destinations[j].demand),
            sign * cost,
          );
          if (includeProcedure) {
            coordinates[routes[i][j]!] = (i, j, 1);
            coordinates[routes[i][j]!.reverse] = (i, j, -1);
          }
        }
      }
    }

    final procedure = includeProcedure
        ? TransportProcedureRecorder(
            problem: problem,
            origins: origins,
            destinations: destinations,
            unitCost: unitCost,
            allocated: (i, j) => routes[i][j]?.reverse.remaining ?? 0,
          )
        : null;
    List<TransportChange> captureChanges(List<_FlowEdge> edges) => [
      for (final edge in edges)
        if (coordinates[edge] case final position?)
          TransportChange(
            position.$1,
            position.$2,
            position.$3,
            routes[position.$1][position.$2]!.reverse.remaining,
          ),
    ];
    num currentCost() {
      num value = 0;
      for (var i = 0; i < origins.length; i++) {
        for (var j = 0; j < destinations.length; j++) {
          value +=
              (routes[i][j]?.reverse.remaining ?? 0) * (unitCost(i, j) ?? 0);
        }
      }
      return value;
    }

    var sent = _seedNorthWest(
      supplyEdges,
      demandEdges,
      routes,
      onAllocation: procedure?.northWest,
    );
    // Sparse matrices may block the northwest route. Residual paths complete
    // or reroute the initial flow without inventing unavailable connections.
    while (targetTotal - sent > _epsilon) {
      final path = _augmentingPath(network, source, sink);
      if (path == null) return null;
      var quantity = targetTotal - sent;
      for (final edge in path) {
        quantity = min(quantity, edge.remaining);
      }
      final changes = procedure == null ? null : captureChanges(path);
      final capacities = procedure == null
          ? null
          : path.map((edge) => edge.remaining).toList();
      for (final edge in path) {
        edge.send(quantity);
      }
      if (procedure != null) {
        procedure.adjustment(changes!, quantity, capacities!);
      }
      sent += quantity;
    }

    procedure?.initialSolution();
    // A feasible transportation flow is optimal iff its residual network has
    // no negative cost cycle. Each circuit preserves every row/column total.
    while (true) {
      final circuit = _negativeCycle(network);
      if (circuit == null) break;
      var quantity = circuit.first.remaining;
      for (final edge in circuit) {
        quantity = min(quantity, edge.remaining);
      }
      final changes = procedure == null ? null : captureChanges(circuit);
      final capacities = procedure == null
          ? null
          : circuit.map((edge) => edge.remaining).toList();
      final before = procedure == null ? null : currentCost();
      final delta = circuit.fold<num>(0, (sum, edge) => sum + sign * edge.cost);
      for (final edge in circuit) {
        edge.send(quantity);
      }
      if (procedure != null) {
        procedure.adjustment(
          changes!,
          quantity,
          capacities!,
          unitDelta: delta,
          costBefore: before,
        );
      }
    }

    return EsquinaNorOesteResult(
      procedure: procedure?.finish(),
      unshippedSupply: max(0, totalSupply - totalDemand),
      unmetDemand: max(0, totalDemand - totalSupply),
      assignments: [
        for (var i = 0; i < problem.origins.length; i++)
          for (var j = 0; j < problem.destinations.length; j++)
            if (routes[i][j] != null &&
                routes[i][j]!.reverse.remaining > _epsilon)
              EsquinaNorOesteAssignment(
                origin: origins[i],
                destination: destinations[j],
                quantity: routes[i][j]!.reverse.remaining,
                unitCost: unitCost(i, j)!,
              ),
      ],
    );
  }

  num _seedNorthWest(
    List<_FlowEdge> supplies,
    List<_FlowEdge> demands,
    List<List<_FlowEdge?>> routes, {
    void Function(
      int i,
      int j,
      num quantity,
      num supplyBefore,
      num demandBefore,
    )?
    onAllocation,
  }) {
    var i = 0;
    var j = 0;
    num sent = 0;
    while (i < supplies.length && j < demands.length) {
      if (supplies[i].remaining <= _epsilon) {
        i++;
        continue;
      }
      if (demands[j].remaining <= _epsilon) {
        j++;
        continue;
      }
      final route = routes[i][j];
      if (route == null) break;
      final supplyBefore = supplies[i].remaining;
      final demandBefore = demands[j].remaining;
      final quantity = min(supplyBefore, demandBefore);
      supplies[i].send(quantity);
      route.send(quantity);
      demands[j].send(quantity);
      onAllocation?.call(i, j, quantity, supplyBefore, demandBefore);
      sent += quantity;
    }
    return sent;
  }

  List<_FlowEdge>? _augmentingPath(
    List<List<_FlowEdge>> network,
    int source,
    int sink,
  ) {
    final parents = List<_FlowEdge?>.filled(network.length, null);
    final visited = List<bool>.filled(network.length, false);
    final queue = Queue<int>()..add(source);
    visited[source] = true;
    while (queue.isNotEmpty && !visited[sink]) {
      for (final edge in network[queue.removeFirst()]) {
        if (edge.remaining <= _epsilon || visited[edge.to]) continue;
        parents[edge.to] = edge;
        visited[edge.to] = true;
        queue.add(edge.to);
      }
    }
    if (!visited[sink]) return null;
    final path = <_FlowEdge>[];
    for (var node = sink; node != source; node = parents[node]!.from) {
      path.add(parents[node]!);
    }
    return path;
  }

  List<_FlowEdge>? _negativeCycle(List<List<_FlowEdge>> network) {
    // A virtual source of zero-cost edges reaches every component.
    final distances = List<num>.filled(network.length, 0);
    final parents = List<_FlowEdge?>.filled(network.length, null);
    var changed = -1;
    for (var pass = 0; pass < network.length; pass++) {
      changed = -1;
      for (final edges in network) {
        for (final edge in edges) {
          if (edge.remaining <= _epsilon) continue;
          final candidate = distances[edge.from] + edge.cost;
          if (candidate < distances[edge.to] - _epsilon) {
            distances[edge.to] = candidate;
            parents[edge.to] = edge;
            changed = edge.to;
          }
        }
      }
      if (changed == -1) return null;
    }
    // Following V predecessors enters the cycle, even if the last updated
    // vertex lies on a path leaving it.
    var node = changed;
    for (var i = 0; i < network.length; i++) {
      node = parents[node]!.from;
    }
    final start = node;
    final circuit = <_FlowEdge>[];
    do {
      final edge = parents[node]!;
      circuit.add(edge);
      node = edge.from;
    } while (node != start);
    return circuit;
  }
}

class _FlowEdge {
  _FlowEdge(this.from, this.to, this.remaining, this.cost);
  final int from;
  final int to;
  num remaining;
  final num cost;
  late final _FlowEdge reverse;

  void send(num quantity) {
    remaining -= quantity;
    reverse.remaining += quantity;
  }
}
