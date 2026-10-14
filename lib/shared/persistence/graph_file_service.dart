import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:file_selector/file_selector.dart';

import 'package:app_grafos/shared/persistence/graph_document.dart';
import 'package:app_grafos/shared/persistence/graph_document_codec.dart';

typedef JsonFileWriter = Future<String?> Function(String name, Uint8List bytes);
typedef JsonFileReader = Future<String?> Function();

/// Descarga en web y selector nativo de destino en móvil y escritorio.
class GraphFileService {
  const GraphFileService({this.writer = _writeJson, this.reader = _readJson});

  final JsonFileWriter writer;
  final JsonFileReader reader;

  Future<String?> readJson() => reader();

  static Future<String?> _readJson() async {
    final file = await openFile(acceptedTypeGroups: [jsonType]);
    return file == null ? null : await file.readAsString();
  }

  static const jsonType = XTypeGroup(
    label: 'Archivos JSON',
    extensions: ['json'],
    mimeTypes: ['application/json'],
    uniformTypeIdentifiers: ['public.json'],
  );

  static String baseName(String input) {
    var name = input.trim().replaceAll(
      RegExp(r'(\.json)+$', caseSensitive: false),
      '',
    );
    name = name
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), '_')
        .replaceAll(RegExp(r'[. ]+$'), '');
    if (name.isEmpty) name = 'grafo';
    if (RegExp(
      r'^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\.|$)',
      caseSensitive: false,
    ).hasMatch(name)) {
      name = 'archivo_$name';
    }
    return name;
  }

  static GraphDocument withName(GraphDocument document, String name) =>
      GraphDocument(
        name: baseName(name),
        nodes: document.nodes,
        connections: document.connections,
        metadata: document.metadata,
      );

  Future<bool> save(GraphDocument document) async {
    final normalized = withName(document, document.name);
    return saveJson(
      normalized.name,
      const GraphDocumentCodec().encode(normalized),
    );
  }

  Future<bool> saveJson(String name, String json) async {
    jsonDecode(json); // Solo se exportan documentos JSON válidos.
    final bytes = Uint8List.fromList(utf8.encode(json));
    final destination = await writer(baseName(name), bytes);
    // Cancelar el selector es una acción normal y no equivale a un guardado.
    return destination != null && destination.isNotEmpty;
  }

  static Future<String?> _writeJson(String name, Uint8List bytes) =>
      FileSaver.instance.saveAs(
        name: name,
        bytes: bytes,
        fileExtension: 'json',
        mimeType: MimeType.json,
      );
}
