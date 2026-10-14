import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/app/navigation/algorithm_examples.dart';
import 'package:app_grafos/features/sorting/domain/sorting_algorithm.dart';
import 'package:app_grafos/features/sorting/presentation/screens/sorting_visualization_screen.dart';
import 'package:app_grafos/features/assignment/presentation/screens/asignacion_screen.dart';
import 'package:app_grafos/features/binary_tree/presentation/screens/binary_tree_screen.dart';
import 'package:app_grafos/features/esquina_nor_oeste/presentation/screens/esquina_nor_oeste_screen.dart';
import 'package:app_grafos/features/graph/presentation/screens/grafo_screen.dart';
import 'package:app_grafos/features/johnson/presentation/screens/johnson_screen.dart';
import 'package:app_grafos/features/sorting/presentation/screens/sorting_methods_screen.dart';

/// Catálogo único utilizado por el dashboard y el menú.
class AlgorithmModule {
  const AlgorithmModule({
    required this.id,
    required this.category,
    required this.menuTitle,
    required this.summary,
    required this.label,
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
    required this.input,
    required this.output,
    required this.tip,
    required this.screen,
  });
  final String id;
  final String category;
  final String menuTitle;
  final String summary;
  final String label;
  final String title;
  final IconData icon;
  final Color color;
  final String description;
  final String input;
  final String output;
  final String tip;
  final Widget screen;
}

const algorithmModules = [
  AlgorithmModule(
    id: 'graph',
    category: 'Modelado',
    menuTitle: 'Redes y Grafos',
    summary: 'Construye redes, consulta su matriz y explora las relaciones entre nodos.',
    label: 'Grafos',
    title: 'Redes y Grafos',
    icon: Icons.hub_rounded,
    color: AppColors.graph,
    description: 'Un grafo representa relaciones mediante nodos y conexiones. Puedes usarlo para modelar redes, rutas o dependencias y estudiar su estructura.',
    input: 'Nodos, conexiones y pesos definidos en el lienzo.',
    output: 'La matriz de adyacencia y los grados de los nodos.',
    tip: 'Prueba: agrega una conexión y observa qué cambia en la matriz.',
    screen: GrafoScreen(),
  ),
  AlgorithmModule(
    id: 'assignment',
    category: 'Optimización',
    menuTitle: 'Método de Asignación',
    summary:
        'Distribuye recursos entre tareas y compara costos mínimos y máximos.',
    label: 'Asignación',
    title: 'Método de Asignación',
    icon: Icons.assignment_turned_in_rounded,
    color: AppColors.primary,
    description: 'El problema de asignación vincula recursos con tareas, buscando una distribución que minimice o maximice el costo total según el objetivo.',
    input: 'Recursos, tareas y costos de cada posible asignación.',
    output: 'Las asignaciones seleccionadas y su costo total.',
    tip: 'Prueba: compara minimizar y maximizar con la misma matriz de costos.',
    screen: AsignacionScreen(),
  ),
  AlgorithmModule(
    id: 'johnson',
    category: 'Planificación',
    menuTitle: 'Algoritmo de Johnson',
    summary: 'Estudia dependencias, tiempos de actividades y la ruta crítica.',
    label: 'Johnson',
    title: 'Red de actividades y ruta crítica',
    icon: Icons.account_tree_rounded,
    color: AppColors.johnson,
    description: 'Este módulo representa actividades y sus dependencias. Calcula tiempos tempranos, tiempos tardíos y holguras para interpretar la duración de una red de actividades.',
    input: 'Eventos, conexiones con duración y un nodo de inicio.',
    output: 'Tiempos, holguras y actividades de la ruta crítica.',
    tip: 'Prueba: cambia la duración de una actividad y vuelve a calcular la red.',
    screen: JohnsonScreen(),
  ),
  AlgorithmModule(
    id: 'transport',
    category: 'Optimización',
    menuTitle: 'Esquina Noroeste',
    summary:
        'Distribuye ofertas entre destinos y analiza el costo de tus rutas.',
    label: 'Transporte',
    title: 'Distribución de recursos',
    icon: Icons.local_shipping_rounded,
    color: AppColors.success,
    description: 'Un problema de transporte distribuye la oferta de distintos orígenes para satisfacer la demanda de los destinos, considerando el costo de cada ruta.',
    input: 'Orígenes, destinos, ofertas, demandas y costos unitarios.',
    output: 'Las cantidades asignadas y el costo de la distribución.',
    tip: 'Prueba: modifica una oferta o una demanda y compara la nueva distribución.',
    screen: EsquinaNorOesteScreen(),
  ),
  AlgorithmModule(
    id: 'sorting',
    category: 'Secuencias',
    menuTitle: 'Métodos de Ordenamiento',
    summary: 'Compara Selection, Insertion, Merge y Shell Sort paso a paso.',
    label: 'Ordenamiento',
    title: 'Selection, Insertion, Merge y Shell Sort',
    icon: Icons.sort_rounded,
    color: AppColors.sorting,
    description: 'Selection Sort busca el menor elemento en cada pasada. Insertion Sort inserta cada valor en la parte ya ordenada. Merge Sort combina mitades ordenadas y Shell Sort usa saltos decrecientes. Los cuatro permiten estudiar cómo se transforma un arreglo paso a paso.',
    input: 'Hasta 20 números entre 1 y 100.',
    output: 'Comparaciones, movimientos y el arreglo ordenado.',
    tip: 'Compara las operaciones al terminar: Merge Sort tiene una cota de O(n log n). Shell Sort usa saltos decrecientes y esta versión tiene una cota de O(n²) en el peor caso.',
    screen: SortingMethodsScreen(),
  ),
  AlgorithmModule(
    id: 'binary-tree',
    category: 'Estructuras',
    menuTitle: 'Árboles binarios',
    summary: 'Construye árboles, mueve sus nodos y reconstruye sus recorridos.',
    label: 'Árboles',
    title: 'Árboles binarios y recorridos',
    icon: Icons.account_tree_rounded,
    color: AppColors.primary,
    description: 'Inserta números para crear un árbol de búsqueda o reconstruye un árbol binario combinando cualquier pareja de Pre-order, In-order y Post-order.',
    input:
        'Números por teclado, un rango aleatorio o dos recorridos compatibles.',
    output: 'El dibujo del árbol y sus tres recorridos.',
    tip: 'Los recorridos para reconstruir deben tener los mismos valores únicos; su orden determina la forma del árbol.',
    screen: BinaryTreeScreen(),
  ),
];

void openAlgorithmModule(BuildContext context, AlgorithmModule module) {
  _openScreen(context, module.screen, '/algoritmos/${module.id}');
}

void openAlgorithmExample(BuildContext context, AlgorithmModule module) {
  final Widget screen = switch (module.id) {
    'graph' => GrafoScreen(initialDocument: graphExample('graph')),
    'assignment' => AsignacionScreen(
      initialDocument: graphExample('assignment'),
    ),
    'johnson' => JohnsonScreen(initialDocument: graphExample('johnson')),
    'transport' => EsquinaNorOesteScreen(
      initialDocument: graphExample('transport'),
    ),
    'sorting' => const SortingVisualizationScreen(
      algorithm: SortingAlgorithm.mergeSort,
      initialArray: [72, 18, 91, 34, 9, 56, 25, 63],
    ),
    'binary-tree' => const BinaryTreeScreen(
      initialNumbers: [8, 3, 10, 1, 6, 14, 4, 7, 13],
    ),
    _ => module.screen,
  };
  _openScreen(context, screen, '/ejemplos/${module.id}');
}

Future<void> _openScreen(
  BuildContext context,
  Widget screen,
  String route,
) async {
  ScaffoldMessenger.of(context).clearSnackBars();
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: RouteSettings(name: route),
      builder: (_) => screen,
    ),
  );
  if (context.mounted) ScaffoldMessenger.of(context).clearSnackBars();
}
