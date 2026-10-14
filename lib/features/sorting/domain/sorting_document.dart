import 'dart:convert';

import 'package:app_grafos/features/sorting/domain/sorting_algorithm.dart';
import 'package:app_grafos/features/sorting/domain/sorting_order.dart';
import 'package:app_grafos/features/sorting/domain/sorting_problem.dart';
import 'package:app_grafos/features/sorting/domain/sorting_solver.dart';
import 'package:app_grafos/features/sorting/domain/sorting_validator.dart';

/// Conserva la entrada original; los pasos se recalculan al cargar.
class SortingDocument {
  SortingDocument({
    required this.name,
    required this.algorithm,
    required this.order,
    required List<int> originalArray,
    this.speed = 1,
    this.stepIndex = 0,
  }) : originalArray = List.unmodifiable(originalArray);

  final String name;
  final SortingAlgorithm algorithm;
  final SortingOrder order;
  final List<int> originalArray;
  final double speed;
  final int stepIndex;

  String encode({String? name}) => const JsonEncoder.withIndent('  ').convert({
    'formato': 'logiverse.sorting',
    'version': 1,
    'nombreArchivo': name ?? this.name,
    'algoritmo': algorithm.name,
    'sentido': order.name,
    'numeros': originalArray,
    'velocidad': speed,
    'paso': stepIndex,
  });

  factory SortingDocument.decode(String json) {
    final data = jsonDecode(json);
    if (data is! Map ||
        data['formato'] != 'logiverse.sorting' ||
        data['version'] != 1) {
      throw const FormatException(
        'El archivo no es un documento de ordenamiento compatible.',
      );
    }
    SortingAlgorithm? algorithm;
    for (final candidate in SortingAlgorithm.values) {
      if (candidate.name == data['algoritmo']) algorithm = candidate;
    }
    SortingOrder? order;
    for (final candidate in SortingOrder.values) {
      if (candidate.name == data['sentido']) order = candidate;
    }
    if (algorithm == null || order == null) {
      throw const FormatException(
        'El método o el sentido de ordenamiento del archivo no es válido.',
      );
    }
    final rawArray = data['numeros'];
    if (rawArray is! List || rawArray.any((value) => value is! int)) {
      throw const FormatException(
        'El archivo debe contener una lista de números enteros.',
      );
    }
    final array = List<int>.from(rawArray);
    final (valid, error) = SortingValidator.validateArray(array);
    if (!valid) {
      throw FormatException(error ?? 'Los números del archivo no son válidos.');
    }
    final speed = data['velocidad'];
    final step = data['paso'];
    if (speed is! num ||
        !speed.isFinite ||
        speed < 0.5 ||
        speed > 2 ||
        step is! int ||
        step < 0) {
      throw const FormatException(
        'La velocidad o el paso guardado no es válido.',
      );
    }
    final result = const SortingSolver().solve(
      SortingProblem(originalArray: array, algorithm: algorithm, order: order),
    );
    if (step >= result.stepCount) {
      throw const FormatException(
        'El paso guardado está fuera del proceso de este algoritmo.',
      );
    }
    return SortingDocument(
      name: data['nombreArchivo'] is String
          ? data['nombreArchivo']
          : 'ordenamiento',
      algorithm: algorithm,
      order: order,
      originalArray: array,
      speed: speed.toDouble(),
      stepIndex: step,
    );
  }
}
