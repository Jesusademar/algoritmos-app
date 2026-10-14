enum SortingOrder {
  ascending('Ascendente', 'De menor a mayor'),
  descending('Descendente', 'De mayor a menor');

  const SortingOrder(this.label, this.description);

  final String label;
  final String description;

  /// Whether [candidate] belongs before [current] in the chosen order.
  bool comesBefore(int candidate, int current) => switch (this) {
    ascending => candidate < current,
    descending => candidate > current,
  };
}
