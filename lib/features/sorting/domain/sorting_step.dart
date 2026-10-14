/// Represents a single step in the sorting process.
/// Each step contains the array state and visual indicators.
class SortingStep {
  final List<int> array;
  final int? comparingIndex1;
  final int? comparingIndex2;
  final int? movingIndex;
  final Set<int> sortedIndices;
  final String description;

  const SortingStep({
    required this.array,
    this.comparingIndex1,
    this.comparingIndex2,
    this.movingIndex,
    required this.sortedIndices,
    required this.description,
  });

  /// Creates a copy with modified fields
  SortingStep copyWith({
    List<int>? array,
    int? comparingIndex1,
    int? comparingIndex2,
    int? movingIndex,
    Set<int>? sortedIndices,
    String? description,
  }) {
    return SortingStep(
      array: array ?? this.array,
      comparingIndex1: comparingIndex1 ?? this.comparingIndex1,
      comparingIndex2: comparingIndex2 ?? this.comparingIndex2,
      movingIndex: movingIndex ?? this.movingIndex,
      sortedIndices: sortedIndices ?? this.sortedIndices,
      description: description ?? this.description,
    );
  }
}
