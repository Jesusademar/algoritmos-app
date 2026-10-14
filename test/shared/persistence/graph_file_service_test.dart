import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:app_grafos/shared/graph_editor/models/nodo.dart';
import 'package:app_grafos/shared/persistence/graph_document.dart';
import 'package:app_grafos/shared/persistence/graph_document_codec.dart';
import 'package:app_grafos/shared/persistence/graph_file_service.dart';

void main() {
  test(
    'exporta JSON UTF-8 con el nombre actual y conserva datos y metadatos',
    () async {
      final document = GraphDocument(
        name: ' Prueba ñ.json ',
        nodes: [Nodo(id: 'a', nombre: 'Jesús', posicion: const Offset(1, 2))],
        connections: [],
        metadata: {
          'ofertas': {'a': 7},
          'tipoOptimizacion': 'maximizar',
        },
      );
      final service = GraphFileService(
        writer: (name, bytes) async {
          expect(name, 'Prueba ñ');
          final decoded = const GraphDocumentCodec().decode(utf8.decode(bytes));
          expect(decoded.name, 'Prueba ñ');
          expect(decoded.nodes.single.nombre, 'Jesús');
          expect(decoded.metadata, document.metadata);
          return '/destino/Prueba ñ.json';
        },
      );
      expect(await service.save(document), isTrue);
      expect(document.name, ' Prueba ñ.json ');
    },
  );

  test('cancelar no informa guardado y los errores permiten al diálogo recuperarse', () async {
    final document = GraphDocument(name: 'prueba', nodes: [], connections: []);
    expect(
      await GraphFileService(writer: (_, _) async => null).save(document),
      isFalse,
    );
    expect(
      () => GraphFileService(
        writer: (_, _) async => throw Exception('Sin acceso'),
      ).save(document),
      throwsException,
    );
  });

  test('nombres portables sin rutas, controles ni extensiones duplicadas', () {
    expect(GraphFileService.baseName('a/b:c?d.json.json'), 'a_b_c_d');
    expect(GraphFileService.baseName(' .json '), 'grafo');
    expect(GraphFileService.baseName('CON.json'), 'archivo_CON');
    expect(GraphFileService.baseName('CON.extra.json'), 'archivo_CON.extra');
    expect(GraphFileService.baseName('reporte.JSON'), 'reporte');
  });
}
