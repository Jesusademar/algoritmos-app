import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:app_grafos/features/fuzzy/domain/fuzzy_codecs.dart';
import 'package:app_grafos/features/fuzzy/domain/fuzzy_system.dart';
import 'package:app_grafos/shared/persistence/graph_file_service.dart';

class FisFileService {
  const FisFileService({this.writer = _write});
  final JsonFileWriter writer;

  static String baseName(FuzzySystem system) =>
      GraphFileService.baseName(system.name);

  Future<bool> save(FuzzySystem system) async {
    final content = const FisCodec().encode(system);
    final destination = await writer(
      baseName(system),
      Uint8List.fromList(utf8.encode(content)),
    );
    return destination != null && destination.isNotEmpty;
  }

  static Future<String?> _write(String name, Uint8List bytes) =>
      FileSaver.instance.saveAs(
        name: name,
        bytes: bytes,
        fileExtension: 'fis',
        mimeType: MimeType.custom,
        customMimeType: 'text/plain',
      );
}
