enum NetworkAlgorithm {
  kruskal('Kruskal', 'Árbol de expansión mínima'),
  dijkstra('Dijkstra', 'Rutas más cortas');

  const NetworkAlgorithm(this.title, this.subtitle);
  final String title;
  final String subtitle;
}
