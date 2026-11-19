import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:app_grafos/features/fuzzy/data/fis_file_service.dart';
import 'package:app_grafos/features/fuzzy/domain/fuzzy_codecs.dart';
import 'package:app_grafos/features/fuzzy/domain/fuzzy_system.dart';

void main() {
  test('normaliza nombres de archivo reservados en Windows', () {
    expect(FisFileService.baseName(FuzzySystem(name: 'CON')), 'archivo_CON');
  });
  test(
    'guarda bytes del .fis, distingue cancelación y propaga errores',
    () async {
      final system = FuzzySystem.ventilationExample();
      final service = FisFileService(
        writer: (name, bytes) async {
          expect(name, 'ventilacion');
          expect(utf8.decode(bytes), const FisCodec().encode(system));
          return '/destino/ventilacion.fis';
        },
      );
      expect(await service.save(system), isTrue);
      expect(
        await FisFileService(writer: (_, _) async => null).save(system),
        isFalse,
      );
      expect(
        () => FisFileService(
          writer: (_, _) async => throw Exception('sin espacio'),
        ).save(system),
        throwsException,
      );
      var called = false;
      await expectLater(
        () => FisFileService(
          writer: (_, _) async {
            called = true;
            return 'archivo';
          },
        ).save(FuzzySystem()),
        throwsFormatException,
      );
      expect(called, isFalse);
    },
  );
}
