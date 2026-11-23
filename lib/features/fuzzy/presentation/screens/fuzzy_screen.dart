import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/features/fuzzy/data/fis_file_service.dart';
import 'package:app_grafos/features/fuzzy/data/matlab_launch_service.dart';
import 'package:app_grafos/features/fuzzy/domain/fuzzy_codecs.dart';
import 'package:app_grafos/features/fuzzy/domain/fuzzy_system.dart';
import 'package:app_grafos/features/fuzzy/presentation/widgets/fuzzy_edit_dialogs.dart';
import 'package:app_grafos/features/fuzzy/presentation/widgets/fuzzy_guide_dialog.dart';
import 'package:app_grafos/features/fuzzy/presentation/widgets/membership_chart.dart';
import 'package:app_grafos/shared/persistence/graph_file_service.dart';
import 'package:app_grafos/shared/widgets/algorithm_scaffold.dart';

class FuzzyScreen extends StatefulWidget {
  const FuzzyScreen({
    super.key,
    this.initialSystem,
    this.fisService = const FisFileService(),
    this.documentService = const GraphFileService(),
    this.matlabService = const MatlabLaunchService(),
  });
  final FuzzySystem? initialSystem;
  final FisFileService fisService;
  final GraphFileService documentService;
  final MatlabLaunchService matlabService;

  @override
  State<FuzzyScreen> createState() => _FuzzyScreenState();
}

class _FuzzyScreenState extends State<FuzzyScreen> {
  late FuzzySystem _system = widget.initialSystem ?? FuzzySystem();
  late final _name = TextEditingController(text: _system.name);
  bool _busy = false;
  bool _dirty = false;
  bool _matlabBusy = false;
  String? _matlabStatus;

  Future<void> _openMatlab({bool selectFile = false}) async {
    if (_matlabBusy) return;
    setState(() => _matlabBusy = true);
    try {
      final file = selectFile ? await widget.matlabService.pickFile() : null;
      if (selectFile && file == null) return;
      if (!mounted) return;
      setState(
        () => _matlabStatus = file == null
            ? 'Abriendo MATLAB en Fuzzy Logic Designer…'
            : 'Abriendo ${file.name} en Fuzzy Logic Designer…',
      );
      await widget.matlabService.openFuzzy(file: file);
      if (!mounted) return;
      setState(
        () => _matlabStatus = file == null
            ? 'Fuzzy Logic Designer está abierto en MATLAB.'
            : '${file.name} se abrió en Fuzzy Logic Designer de MATLAB.',
      );
    } on FormatException catch (error) {
      if (mounted) setState(() => _matlabStatus = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _matlabStatus =
              'No se pudo abrir el archivo. Selecciona un archivo .fis válido.',
        );
      }
    } finally {
      if (mounted) setState(() => _matlabBusy = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _update(FuzzySystem value) => setState(() {
    _system = value;
    _dirty = true;
  });
  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<bool> _confirm(String title, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continuar'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _replace(FuzzySystem system, {bool loaded = false}) async {
    if (_dirty &&
        !await _confirm(
          'Reemplazar el diseño',
          'Se reemplazará el diseño actual. Guarda su JSON si quieres conservarlo.',
        )) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _system = system;
      _name.text = system.name;
      _dirty = !loaded;
    });
  }

  Future<void> _variable(bool input, [int? index]) async {
    final variables = input ? _system.inputs : _system.outputs;
    final original = index == null ? null : variables[index];
    final result = await showDialog<FuzzyVariable>(
      context: context,
      builder: (_) => FuzzyVariableDialog(
        variable: original,
        usedNames: {
          for (final v in [..._system.inputs, ..._system.outputs])
            if (!identical(v, original)) v.name.toLowerCase(),
        },
      ),
    );
    if (result == null || !mounted) return;
    if (index == null) {
      _update(_system.addVariable(result, input: input));
      return;
    }
    final updated = List<FuzzyVariable>.of(variables)..[index] = result;
    _update(
      _system.copyWith(
        inputs: input ? updated : null,
        outputs: input ? null : updated,
      ),
    );
  }

  Future<void> _membership(bool input, int variableIndex, [int? index]) async {
    final variables = input ? _system.inputs : _system.outputs;
    final variable = variables[variableIndex];
    const prefix = 'conjunto';
    var number = 1;
    while (variable.functions.any(
      (mf) => mf.name.toLowerCase() == '${prefix}_$number',
    )) {
      number++;
    }
    final result = await showDialog<MembershipFunction>(
      context: context,
      builder: (_) => MembershipDialog(
        variable: variable,
        index: index,
        initialName: '${prefix}_$number',
      ),
    );
    if (result == null || !mounted) return;
    final functions = List<MembershipFunction>.of(variable.functions);
    if (index == null) {
      functions.add(result);
    } else {
      functions[index] = result;
    }
    final updated = List<FuzzyVariable>.of(variables)
      ..[variableIndex] = variable.copyWith(functions: functions);
    _update(
      _system.copyWith(
        inputs: input ? updated : null,
        outputs: input ? null : updated,
      ),
    );
  }

  Future<void> _deleteVariable(bool input, int index) async {
    final variable = (input ? _system.inputs : _system.outputs)[index];
    final count = _system.rules
        .where((r) => (input ? r.inputs : r.outputs)[index] != 0)
        .length;
    if (!await _confirm(
      'Eliminar ${variable.name}',
      'Se eliminará esta variable y $count regla(s) que la utilizan.',
    )) {
      return;
    }
    if (mounted) _update(_system.removeVariable(index, input: input));
  }

  Future<void> _deleteMembership(
    bool input,
    int variableIndex,
    int index,
  ) async {
    final variable = (input ? _system.inputs : _system.outputs)[variableIndex];
    final count = _system.rules
        .where(
          (r) => (input ? r.inputs : r.outputs)[variableIndex] == index + 1,
        )
        .length;
    if (!await _confirm(
      'Eliminar ${variable.functions[index].name}',
      'Se eliminará este conjunto y $count regla(s) que lo utilizan.',
    )) {
      return;
    }
    if (mounted) {
      _update(_system.removeFunction(variableIndex, index, input: input));
    }
  }

  Future<void> _rule([int? index]) async {
    final errors = _system.validate(requireComplete: false);
    if (_system.inputs.isEmpty ||
        _system.outputs.isEmpty ||
        errors.isNotEmpty) {
      _message(
        errors.isNotEmpty
            ? errors.first
            : 'Primero agrega una entrada y una salida con sus conjuntos.',
      );
      return;
    }
    final result = await showDialog<FuzzyRule>(
      context: context,
      builder: (_) => FuzzyRuleDialog(
        system: _system,
        rule: index == null ? null : _system.rules[index],
      ),
    );
    if (result == null || !mounted) return;
    final rules = List<FuzzyRule>.of(_system.rules);
    if (index == null) {
      rules.add(result);
    } else {
      rules[index] = result;
    }
    _update(_system.copyWith(rules: rules));
  }

  Future<void> _saveDesign() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final json = const FuzzyDocumentCodec().encode(_system);
      final saved = await widget.documentService.saveJson(
        '${_system.name}_diseno',
        json,
      );
      if (!mounted) return;
      if (saved) {
        setState(() => _dirty = false);
        _message(
          kIsWeb
              ? 'Descarga del diseño JSON iniciada.'
              : 'Diseño JSON guardado.',
        );
      }
    } on FormatException catch (error) {
      if (mounted) _message(error.message);
    } catch (_) {
      if (mounted) {
        _message(
          'No se pudo guardar el diseño. Intenta elegir otra ubicación.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loadDesign() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final json = await widget.documentService.readJson();
      if (json == null || !mounted) return;
      final system = const FuzzyDocumentCodec().decode(json);
      setState(() => _busy = false);
      await _replace(system, loaded: true);
    } on FormatException catch (error) {
      if (mounted) _message(error.message);
    } catch (_) {
      if (mounted) {
        _message('No se pudo abrir el diseño. Selecciona su archivo JSON.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export() async {
    if (_busy) return;
    final errors = _system.validate();
    if (errors.isNotEmpty) {
      _message(errors.join('\n'));
      return;
    }
    final content = const FisCodec().encode(_system);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FisExportDialog(
        system: _system,
        content: content,
        service: widget.fisService,
      ),
    );
  }

  void _help() => mostrarGuiaDifusa(context);

  Widget _variableCard(bool input, int index) {
    final v = (input ? _system.inputs : _system.outputs)[index];
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: AlgorithmPanelSection(
        title: '${v.name} · Rango [${v.min}, ${v.max}]',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MembershipChart(variable: v),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _variable(input, index),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar variable'),
                ),
                TextButton.icon(
                  onPressed: () => _deleteVariable(input, index),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Eliminar variable'),
                ),
              ],
            ),
            const Divider(height: 28),
            for (var j = 0; j < v.functions.length; j++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${v.functions[j].name}\n${v.functions[j].type.label} [${v.functions[j].parameters.join(' ')}]',
                      ),
                    ),
                    IconButton(
                      tooltip: 'Editar conjunto ${v.functions[j].name}',
                      onPressed: () => _membership(input, index, j),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Eliminar conjunto ${v.functions[j].name}',
                      onPressed: v.functions.length > 1
                          ? () => _deleteMembership(input, index, j)
                          : null,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => _membership(input, index),
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir conjunto'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _variables(bool input) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        input ? 'Variables de entrada' : 'Variables de salida',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 8),
      Text(
        input
            ? 'Describe lo que observa tu sistema, como temperatura o humedad.'
            : 'Define lo que decidirá el sistema, como la velocidad de ventilación.',
      ),
      for (
        var i = 0;
        i < (input ? _system.inputs : _system.outputs).length;
        i++
      )
        _variableCard(input, i),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: () => _variable(input),
          icon: const Icon(Icons.add),
          label: Text(input ? 'Añadir entrada' : 'Añadir salida'),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => AlgorithmScaffold(
    title: 'Lógica difusa',
    icon: Icons.blur_on_rounded,
    accent: AppColors.sorting,
    actions: [
      IconButton(
        tooltip: 'Guía de lógica difusa',
        onPressed: _help,
        icon: const Icon(Icons.help_outline),
      ),
    ],
    body: AbsorbPointer(
      absorbing: _busy,
      child: SingleChildScrollView(
        padding: MediaQuery.sizeOf(context).width < 700
            ? AppLayout.compactPagePadding
            : AppLayout.pagePadding,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppLayout.contentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Diseña tu sistema para MATLAB',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Define variables, dibuja sus conjuntos y conecta decisiones con reglas. Exporta el sistema Mamdani como archivo .fis.',
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _replace(FuzzySystem.ventilationExample()),
                      icon: const Icon(Icons.science_outlined),
                      label: const Text('Ejemplo de ventilación'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _replace(FuzzySystem.trapezoidExample()),
                      icon: const Icon(Icons.show_chart),
                      label: const Text('Ejemplo trapezoidal'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _replace(
                              FuzzySystem.academicPerformanceExample(),
                            ),
                      icon: const Icon(Icons.school_outlined),
                      label: const Text('Ejemplo de rendimiento'),
                    ),
                    TextButton.icon(
                      onPressed: _busy ? null : () => _replace(FuzzySystem()),
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Nuevo diseño'),
                    ),
                    TextButton.icon(
                      onPressed: _busy ? null : _loadDesign,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Cargar diseño JSON'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                AlgorithmPanelSection(
                  title: 'Sistema Mamdani · Tipo 1',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        key: const Key('fuzzy-system-name'),
                        controller: _name,
                        onChanged: (value) =>
                            _update(_system.copyWith(name: value.trim())),
                        decoration: InputDecoration(
                          labelText: 'Nombre del sistema',
                          helperText: 'Letras sin tildes, números y _; empieza con letra.',
                          helperMaxLines: 2,
                          errorText: fuzzyNameError(_system.name),
                          errorMaxLines: 3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Y: mínimo · O: máximo · Implicación: mínimo\nAgregación: máximo · Defuzzificación: centroide',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                LayoutBuilder(
                  builder: (context, constraints) => constraints.maxWidth >= 900
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _variables(true)),
                            const SizedBox(width: 24),
                            Expanded(child: _variables(false)),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _variables(true),
                            const SizedBox(height: 28),
                            _variables(false),
                          ],
                        ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Reglas de inferencia',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (_system.rules.isEmpty)
                  const Text(
                    'Añade tus variables y crea la primera regla para relacionar entradas y salidas.',
                  ),
                for (var i = 0; i < _system.rules.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: AlgorithmPanelSection(
                      title: 'Regla ${i + 1} · Peso ${_system.rules[i].weight}',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(_system.rules[i].describe(_system)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              TextButton(
                                onPressed: () => _rule(i),
                                child: const Text('Editar regla'),
                              ),
                              TextButton(
                                onPressed: () => _update(
                                  _system.copyWith(
                                    rules: List<FuzzyRule>.of(_system.rules)
                                      ..removeAt(i),
                                  ),
                                ),
                                child: const Text('Eliminar regla'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => _rule(),
                    icon: const Icon(Icons.add),
                    label: const Text('Añadir regla'),
                  ),
                ),
                const SizedBox(height: 28),
                AlgorithmPanelSection(
                  title: 'Archivo para MATLAB',
                  highlighted: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${_system.inputs.length} ${_system.inputs.length == 1 ? 'entrada' : 'entradas'} · '
                        '${_system.outputs.length} ${_system.outputs.length == 1 ? 'salida' : 'salidas'} · '
                        '${_system.rules.length} ${_system.rules.length == 1 ? 'regla' : 'reglas'}',
                      ),
                      const SizedBox(height: 8),
                      if (_system.validate().isEmpty)
                        const Text('El sistema está listo para exportarse.')
                      else
                        Text(
                          _system.validate().join('\n'),
                          key: const Key('fuzzy-validation'),
                        ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: _busy ? null : _export,
                            icon: const Icon(Icons.download),
                            label: const Text('Exportar .fis'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _busy ? null : _saveDesign,
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('Guardar diseño JSON'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Guarda el diseño JSON para seguir editándolo aquí. Abre el .fis en MATLAB con Fuzzy Logic Toolbox.',
                      ),
                      const Divider(height: 32),
                      Text(
                        'Fuzzy Logic Designer',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Selecciona un archivo .fis para abrirlo en MATLAB, o inicia el diseñador sin cargar un archivo. Requiere MATLAB con Fuzzy Logic Toolbox y licencia activa en esta computadora.',
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: _matlabBusy
                                ? null
                                : () => _openMatlab(selectFile: true),
                            icon: const Icon(Icons.folder_open),
                            label: const Text('Cargar archivo'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _matlabBusy ? null : _openMatlab,
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Abrir MATLAB'),
                          ),
                        ],
                      ),
                      if (_matlabStatus != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              _matlabStatus!,
                              key: const Key('matlab-status'),
                            ),
                          ),
                        ),
                      if (_matlabBusy)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: LinearProgressIndicator(),
                        ),
                      if (_busy)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: LinearProgressIndicator(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _FisExportDialog extends StatefulWidget {
  const _FisExportDialog({
    required this.system,
    required this.content,
    required this.service,
  });
  final FuzzySystem system;
  final String content;
  final FisFileService service;
  @override
  State<_FisExportDialog> createState() => _FisExportDialogState();
}

class _FisExportDialogState extends State<_FisExportDialog> {
  String get _fileName => '${FisFileService.baseName(widget.system)}.fis';
  bool _saving = false;
  String? _error;
  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await widget.service.save(widget.system);
      if (!mounted) return;
      if (saved) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              kIsWeb
                  ? 'Descarga iniciada: $_fileName'
                  : 'Archivo guardado: $_fileName',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'No se pudo guardar el .fis. Intenta elegir otra ubicación.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      scrollable: true,
      title: Text('Exportar $_fileName'),
      content: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Vista previa del sistema Mamdani:'),
            const SizedBox(height: 12),
            Container(
              height: (MediaQuery.sizeOf(context).height * 0.35).clamp(
                100.0,
                320.0,
              ),
              padding: const EdgeInsets.all(12),
              color: AppColors.background,
              child: SingleChildScrollView(
                child: SelectableText(
                  widget.content,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('En MATLAB, desde la carpeta del archivo:'),
            const SizedBox(height: 8),
            SelectableText(
              'fis = readfis("$_fileName");\nfuzzyLogicDesigner(fis);',
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: const Icon(Icons.download),
          label: Text(
            _saving
                ? 'Guardando…'
                : kIsWeb
                ? 'Descargar .fis'
                : 'Guardar .fis',
          ),
        ),
      ],
    ),
  );
}
