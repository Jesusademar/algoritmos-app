import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MatlabFisFile {
  const MatlabFisFile(this.name, this.content);
  final String name;
  final String content;

  void validate() {
    if (!name.toLowerCase().endsWith('.fis') ||
        !content.contains('[System]') ||
        content.contains('\u0000') ||
        utf8.encode(content).length > 2 * 1024 * 1024) {
      throw const FormatException(
        'Selecciona un archivo .fis válido de hasta 2 MB.',
      );
    }
  }
}

typedef MatlabFilePicker = Future<MatlabFisFile?> Function();

class MatlabLaunchService {
  const MatlabLaunchService({
    this.picker = _pickFile,
    this.clientFactory = http.Client.new,
    this.baseUri,
    this.pollInterval = const Duration(seconds: 1),
    this.maxPolls = 125,
  });

  final MatlabFilePicker picker;
  final http.Client Function() clientFactory;
  final Uri? baseUri;
  final Duration pollInterval;
  final int maxPolls;

  Future<MatlabFisFile?> pickFile() async {
    final file = await picker();
    file?.validate();
    return file;
  }

  static Future<MatlabFisFile?> _pickFile() async {
    final file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(
          label: 'Sistema difuso MATLAB (.fis)',
          extensions: ['fis'],
        ),
      ],
    );
    if (file == null) return null;
    if (await file.length() > 2 * 1024 * 1024) {
      throw const FormatException('El archivo .fis debe ser de hasta 2 MB.');
    }
    return MatlabFisFile(file.name, await file.readAsString());
  }

  Future<void> openFuzzy({MatlabFisFile? file}) async {
    file?.validate();
    final uri =
        baseUri ?? (kIsWeb ? Uri.base : Uri.parse('http://127.0.0.1:4187'));
    if (!{'localhost', '127.0.0.1'}.contains(uri.host) ||
        uri.scheme != 'http') {
      throw const FormatException(
        'Abre la aplicación local para iniciar MATLAB desde estos botones.',
      );
    }
    final client = clientFactory();
    const connectionMessage =
        'No hay conexión con MATLAB. Inicia la aplicación con el servidor local de MATLAB y recarga esta página.';
    try {
      final session = _decode(
        await client
            .get(uri.resolve('/api/matlab/session'))
            .timeout(const Duration(seconds: 5)),
      );
      final token = session['token'];
      if (token is! String) throw const FormatException(connectionMessage);
      final launch = _decode(
        await client
            .post(
              uri.resolve('/api/matlab/open-fuzzy'),
              headers: {
                'Content-Type': 'application/json',
                'X-Logiverse-Token': token,
              },
              body: jsonEncode({
                if (file != null) ...{
                  'name': file.name,
                  'content': file.content,
                },
              }),
            )
            .timeout(const Duration(seconds: 15)),
      );
      final id = launch['jobId'];
      if (id is! String || !RegExp(r'^[a-f0-9]{32}$').hasMatch(id)) {
        throw const FormatException(connectionMessage);
      }
      for (var attempt = 0; attempt < maxPolls; attempt++) {
        final job = _decode(
          await client
              .get(uri.resolve('/api/matlab/jobs/$id'))
              .timeout(const Duration(seconds: 5)),
        );
        if (job['state'] == 'ready') return;
        if (job['state'] == 'error') {
          throw FormatException(
            job['message'] as String? ?? 'MATLAB no pudo abrir el diseñador.',
          );
        }
        if (job['state'] != 'starting') {
          throw const FormatException(connectionMessage);
        }
        await Future<void>.delayed(pollInterval);
      }
      throw const FormatException(
        'MATLAB sigue iniciándose o espera una acción. Revisa su ventana.',
      );
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException(connectionMessage);
    } finally {
      client.close();
    }
  }

  static Map<String, dynamic> _decode(http.Response response) {
    dynamic value;
    try {
      value = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw const FormatException(
        'Inicia la aplicación con el servidor local de MATLAB y recarga esta página.',
      );
    }
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Respuesta no válida del servidor local.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FormatException(
        value['message'] as String? ?? 'No se pudo iniciar MATLAB.',
      );
    }
    return value;
  }
}
