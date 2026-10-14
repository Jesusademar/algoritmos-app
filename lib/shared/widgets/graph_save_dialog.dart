import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/shared/persistence/graph_document.dart';
import 'package:app_grafos/shared/persistence/graph_document_codec.dart';
import 'package:app_grafos/shared/persistence/graph_file_service.dart';

Future<String?> showGraphSaveDialog(
  BuildContext context,
  GraphDocument document, {
  GraphFileService service = const GraphFileService(),
}) async {
  return _showSaveDialog(
    context,
    GraphSaveDialog(document: document, service: service),
  );
}

Future<String?> showJsonSaveDialog(
  BuildContext context, {
  required String initialName,
  required String Function(String) jsonBuilder,
  GraphFileService service = const GraphFileService(),
}) => _showSaveDialog(
  context,
  GraphSaveDialog.json(
    initialName: initialName,
    jsonBuilder: jsonBuilder,
    service: service,
  ),
);

Future<String?> _showSaveDialog(
  BuildContext context,
  GraphSaveDialog dialog,
) async {
  final name = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => dialog,
  );
  if (name != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          kIsWeb
              ? 'Descarga iniciada: $name.json'
              : 'Archivo guardado: $name.json',
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }
  return name;
}

class GraphSaveDialog extends StatefulWidget {
  const GraphSaveDialog({
    super.key,
    required this.document,
    this.service = const GraphFileService(),
  }) : initialName = null,
       jsonBuilder = null;

  const GraphSaveDialog.json({
    super.key,
    required this.initialName,
    required this.jsonBuilder,
    this.service = const GraphFileService(),
  }) : document = null;

  final GraphDocument? document;
  final String? initialName;
  final String Function(String)? jsonBuilder;
  final GraphFileService service;

  @override
  State<GraphSaveDialog> createState() => _GraphSaveDialogState();
}

class _GraphSaveDialogState extends State<GraphSaveDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.document?.name ?? widget.initialName!,
  );
  bool _saving = false;
  String? _error;

  String _json(String name) => widget.jsonBuilder != null
      ? widget.jsonBuilder!(name)
      : const GraphDocumentCodec().encode(
          GraphFileService.withName(widget.document!, name),
        );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = GraphFileService.baseName(_name.text);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await widget.service.saveJson(name, _json(name));
      if (!mounted) return;
      if (saved) {
        Navigator.pop(context, name);
      } else {
        setState(() => _saving = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error =
            'No se pudo guardar el archivo. Intenta elegir otra ubicación.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final json = _json(GraphFileService.baseName(_name.text));
    final previewHeight = (MediaQuery.sizeOf(context).height * 0.32).clamp(
      100.0,
      300.0,
    );
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        scrollable: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.save_rounded, color: AppColors.primary),
            SizedBox(width: 12),
            Expanded(child: Text('Guardar archivo JSON')),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _name,
                enabled: !_saving,
                decoration: const InputDecoration(
                  labelText: 'Nombre del archivo',
                  helperText: 'Se guardará con la extensión .json',
                  prefixIcon: Icon(Icons.insert_drive_file_outlined),
                ),
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: 16),
              const Text(
                'Estructura JSON generada:',
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              Container(
                height: previewHeight,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: SelectableText(
                    json,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded, size: 18),
            label: Text(
              _saving
                  ? 'Guardando…'
                  : kIsWeb
                  ? 'Descargar JSON'
                  : 'Guardar JSON',
            ),
          ),
        ],
      ),
    );
  }
}
