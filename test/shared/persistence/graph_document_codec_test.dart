import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_grafos/shared/graph_editor/models/conexion.dart';
import 'package:app_grafos/shared/graph_editor/models/nodo.dart';
import 'package:app_grafos/shared/persistence/graph_document.dart';
import 'package:app_grafos/shared/persistence/graph_document_codec.dart';

void main() {
  const codec = GraphDocumentCodec();

  test('conserva grafo y metadatos al convertir a JSON y volver', () {
    final encoded = codec.encode(
      GraphDocument(
        name: 'ejemplo',
        nodes: [
          Nodo(
            id: 'a',
            nombre: 'Origen',
            posicion: const Offset(10, 20),
            valorInicial: 2,
          ),
        ],
        connections: const [],
        metadata: const {'tipoOptimizacion': 'maximizar'},
      ),
    );

    final decoded = codec.decode(encoded);

    expect(decoded.name, 'ejemplo');
    expect(decoded.nodes.single.nombre, 'Origen');
    expect(decoded.nodes.single.posicion, const Offset(10, 20));
    expect(decoded.nodes.single.valorInicial, 2);
    expect(decoded.connections, isEmpty);
    expect(decoded.metadata['tipoOptimizacion'], 'maximizar');
  });

  test('conserva los datos de una conexión', () {
    final encoded = codec.encode(
      GraphDocument(
        name: 'conexion',
        nodes: const [],
        connections: [
          Conexion(
            nodoA: 'a',
            nodoB: 'b',
            peso: 7,
            tipo: 'dirigida',
            color: const Color(0xFF123456),
          ),
        ],
      ),
    );

    final connection = codec.decode(encoded).connections.single;

    expect(connection.nodoA, 'a');
    expect(connection.nodoB, 'b');
    expect(connection.peso, 7);
    expect(connection.tipo, 'dirigida');
    expect(connection.color.toARGB32(), const Color(0xFF123456).toARGB32());
  });
}
