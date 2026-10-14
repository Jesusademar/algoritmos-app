/// Enum defining available sorting algorithms
enum SortingAlgorithm {
  selectionSort('Selection Sort'),
  insertionSort('Insertion Sort'),
  mergeSort('Merge Sort'),
  shellSort('Shell Sort');

  final String displayName;

  const SortingAlgorithm(this.displayName);

  String get bestCase => switch (this) {
    insertionSort => 'O(n)',
    mergeSort || shellSort => 'O(n log n)',
    selectionSort => 'O(n²)',
  };
  String get averageCase => this == mergeSort ? 'O(n log n)' : 'O(n²)';
  String get worstCase => this == mergeSort ? 'O(n log n)' : 'O(n²)';
  String get auxiliarySpace => this == mergeSort ? 'O(n)' : 'O(1)';
  String get movementLabel => switch (this) {
    selectionSort => 'Intercambios',
    mergeSort => 'Escrituras',
    insertionSort || shellSort => 'Desplazamientos',
  };
  String get complexityDescription => switch (this) {
    insertionSort =>
      'Con los datos ya ordenados, el trabajo es lineal. '
          'En el peor caso, su cota temporal es O(n²).',
    selectionSort =>
      'Busca el siguiente elemento en toda la porción pendiente.',
    mergeSort =>
      'Divide el arreglo y combina las mitades ordenadas. '
          'Su cota temporal es O(n log n) y utiliza O(n) de espacio auxiliar.',
    shellSort =>
      'Ordena con saltos n/2, n/4, …, 1. Para esta secuencia, '
          'la cota temporal en el peor caso es O(n²).',
  };
}
