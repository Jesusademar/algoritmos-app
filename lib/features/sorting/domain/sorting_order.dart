import 'package:app_grafos/features/sorting/domain/sorting_numbers.dart';

enum SortingOrder {
  ascending('Ascendente', 'De menor a mayor'),
  descending('Descendente', 'De mayor a menor');

  const SortingOrder(this.label, this.description);

  final String label;
  final String description;

  /// Whether [candidate] belongs before [current] in the chosen order.
  bool comesBefore(Object candidate, Object current) => switch (this) {
    ascending => SortingNumbers.compare(candidate, current) < 0,
    descending => SortingNumbers.compare(candidate, current) > 0,
  };
}
