import 'package:app_grafos/features/sorting/domain/sorting_algorithm.dart';
import 'package:app_grafos/features/sorting/domain/sorting_order.dart';

/// Represents the sorting problem domain model.
/// Contains the data to be sorted and the algorithm to use.
class SortingProblem {
  final List<int> originalArray;
  final SortingAlgorithm algorithm;
  final SortingOrder order;

  const SortingProblem({
    required this.originalArray,
    required this.algorithm,
    this.order = SortingOrder.ascending,
  });

  /// Total number of elements to be sorted
  int get size => originalArray.length;

  /// Creates a copy of this problem with modified fields
  SortingProblem copyWith({
    List<int>? originalArray,
    SortingAlgorithm? algorithm,
    SortingOrder? order,
  }) {
    return SortingProblem(
      originalArray: originalArray ?? this.originalArray,
      algorithm: algorithm ?? this.algorithm,
      order: order ?? this.order,
    );
  }
}
