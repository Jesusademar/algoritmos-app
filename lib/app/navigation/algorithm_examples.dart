import 'dart:ui';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/shared/graph_editor/models/conexion.dart';
import 'package:app_grafos/shared/graph_editor/models/nodo.dart';
import 'package:app_grafos/shared/persistence/graph_document.dart';

/// Cada apertura crea sus propios nodos; editar un ejemplo no altera el siguiente.
GraphDocument graphExample(String module) {
  final bipartite = module == 'assignment' || module == 'transport';
  final nodes = [
    Nodo(
      id: 'a',
      nombre: bipartite ? 'O1' : 'A',
      posicion: const Offset(75, 90),
    ),
    Nodo(
      id: 'b',
      nombre: bipartite ? 'O2' : 'B',
      posicion: Offset(bipartite ? 75 : 280, bipartite ? 235 : 90),
    ),
    Nodo(
      id: 'c',
      nombre: bipartite ? 'D1' : 'C',
      posicion: Offset(bipartite ? 280 : 75, bipartite ? 90 : 235),
    ),
    Nodo(
      id: 'd',
      nombre: bipartite ? 'D2' : 'D',
      posicion: const Offset(280, 235),
    ),
  ];
  final pairs = bipartite
      ? [('a', 'c', 1), ('a', 'd', 2), ('b', 'c', 2), ('b', 'd', 100)]
      : [('a', 'b', 4), ('a', 'c', 2), ('b', 'd', 3), ('c', 'd', 8)];
  final color = switch (module) {
    'graph' => AppColors.graph,
    'johnson' => AppColors.johnson,
    'transport' => AppColors.success,
    _ => AppColors.primary,
  };
  return GraphDocument(
    name: 'ejemplo_$module',
    nodes: nodes,
    connections: [
      for (final pair in pairs)
        Conexion(
          nodoA: pair.$1,
          nodoB: pair.$2,
          peso: pair.$3,
          tipo: 'unidireccional',
          color: color,
        ),
    ],
    metadata: {
      if (module == 'assignment') 'tipoOptimizacion': 'minimizar',
      if (module == 'johnson') ...{
        'nodoInicialSeleccionadoId': 'a',
        'esMaximizar': true,
      },
      if (module == 'transport') ...{
        'ofertas': {'a': 10, 'b': 10},
        'demandas': {'c': 10, 'd': 10},
      },
    },
  );
}
