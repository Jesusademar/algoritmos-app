@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:app_grafos/features/fuzzy/data/fis_file_service.dart';
import 'package:app_grafos/features/fuzzy/domain/fuzzy_system.dart';

void main() {
  test('Chrome inicia la descarga del archivo .fis', () async {
    expect(
      await const FisFileService().save(FuzzySystem.ventilationExample()),
      isTrue,
    );
  });
}
