import 'package:app_grafos/shared/graph_editor/models/conexion.dart';
import 'package:app_grafos/shared/graph_editor/models/nodo.dart';

/// Documento intercambiable entre los editores gráficos de la aplicación.
class GraphDocument {
  GraphDocument({
    required this.name,
    required List<Nodo> nodes,
    required List<Conexion> connections,
    Map<String, dynamic> metadata = const {},
  }) : nodes = List.unmodifiable(nodes),
       connections = List.unmodifiable(connections),
       metadata = Map.unmodifiable(metadata);

  final String name;
  final List<Nodo> nodes;
  final List<Conexion> connections;
  final Map<String, dynamic> metadata;
}
