@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:app_grafos/shared/persistence/graph_document.dart';
import 'package:app_grafos/shared/persistence/graph_file_service.dart';

void main() {
  test(
    'Chrome inicia una descarga JSON sin acceder al sistema de archivos',
    () async {
      final document = GraphDocument(
        name: 'prueba_chrome',
        nodes: [],
        connections: [],
        metadata: {'tipoOptimizacion': 'minimizar'},
      );
      expect(await const GraphFileService().save(document), isTrue);
    },
  );
}
