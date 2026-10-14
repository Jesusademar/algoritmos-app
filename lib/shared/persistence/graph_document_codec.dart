import 'dart:convert';

import 'package:app_grafos/shared/graph_editor/models/conexion.dart';
import 'package:app_grafos/shared/graph_editor/models/nodo.dart';
import 'package:app_grafos/shared/persistence/graph_document.dart';

/// Único lugar encargado de definir el formato JSON de los grafos.
class GraphDocumentCodec {
  const GraphDocumentCodec();

  String encode(GraphDocument document) {
    final json = <String, dynamic>{
      'nombreArchivo': document.name,
      ...document.metadata,
      'nodos': document.nodes.map((node) => node.toJson()).toList(),
      'conexiones': document.connections
          .map((connection) => connection.toJson())
          .toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(json);
  }

  GraphDocument decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('El documento JSON debe ser un objeto.');
    }

    final json = Map<String, dynamic>.from(decoded);
    final rawNodes = json['nodos'];
    final rawConnections = json['conexiones'];
    if (rawNodes is! List || rawConnections is! List) {
      throw const FormatException(
        'El documento debe contener listas de nodos y conexiones.',
      );
    }

    final metadata = Map<String, dynamic>.from(json)
      ..remove('nombreArchivo')
      ..remove('nodos')
      ..remove('conexiones');

    return GraphDocument(
      name: json['nombreArchivo']?.toString() ?? 'grafo',
      nodes: rawNodes
          .map((node) => Nodo.fromJson(Map<String, dynamic>.from(node as Map)))
          .toList(),
      connections: rawConnections
          .map(
            (connection) =>
                Conexion.fromJson(Map<String, dynamic>.from(connection as Map)),
          )
          .toList(),
      metadata: metadata,
    );
  }
}
