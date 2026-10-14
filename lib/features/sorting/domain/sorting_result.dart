import 'package:app_grafos/features/sorting/domain/sorting_step.dart';

/// Result of solving a sorting problem.
/// Contains all steps needed to visualize the sorting process.
class SortingResult {
  final List<SortingStep> steps;
  final int totalComparisons;
  final int totalSwaps;

  const SortingResult({
    required this.steps,
    required this.totalComparisons,
    required this.totalSwaps,
  });

  /// Total number of steps in the sorting animation
  int get stepCount => steps.length;

  /// The final sorted array
  List<int> get finalArray => steps.isNotEmpty ? steps.last.array : [];

  /// Whether the array is fully sorted
  bool get isComplete => steps.isNotEmpty;
}
