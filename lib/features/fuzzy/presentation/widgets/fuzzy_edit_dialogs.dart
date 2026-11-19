import 'package:flutter/material.dart';
import 'package:app_grafos/features/fuzzy/domain/fuzzy_system.dart';

import 'membership_chart.dart';

const _nameHint = 'Letras sin tildes, números y _; empieza con letra.';

class FuzzyVariableDialog extends StatefulWidget {
  const FuzzyVariableDialog({
    super.key,
    required this.usedNames,
    this.variable,
  });
  final Set<String> usedNames;
  final FuzzyVariable? variable;
  @override
  State<FuzzyVariableDialog> createState() => _FuzzyVariableDialogState();
}

class _FuzzyVariableDialogState extends State<FuzzyVariableDialog> {
  late final _name = TextEditingController(text: widget.variable?.name ?? '');
  late final _min = TextEditingController(text: '${widget.variable?.min ?? 0}');
  late final _max = TextEditingController(
    text: '${widget.variable?.max ?? 100}',
  );
  String? _error;
  late List<MembershipFunction> _functions = List.of(
    widget.variable?.functions ?? [],
  );

  @override
  void dispose() {
    _name.dispose();
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  FuzzyVariable? _candidate() {
    final name = _name.text.trim();
    final min = double.tryParse(_min.text.trim());
    final max = double.tryParse(_max.text.trim());
    String? error = fuzzyNameError(name);
    if (widget.usedNames.contains(name.toLowerCase())) {
      error = 'Ya existe una variable con ese nombre.';
    }
    if (min == null ||
        max == null ||
        !min.isFinite ||
        !max.isFinite ||
        min >= max ||
        !(max - min).isFinite) {
      error = 'Introduce un rango finito con mínimo menor que máximo. Usa punto decimal.';
    }
    if (error != null) {
      setState(() => _error = error);
      return null;
    }
    return widget.variable?.copyWith(
          name: name,
          min: min,
          max: max,
          functions: _functions,
        ) ??
        FuzzyVariable.defaults(name, min!, max!);
  }

  void _save() {
    final variable = _candidate();
    if (variable != null) Navigator.pop(context, variable);
  }

  Future<void> _editFunction([int? index]) async {
    final variable = _candidate();
    if (variable == null) return;
    var number = 1;
    while (_functions.any(
      (mf) => mf.name.toLowerCase() == 'conjunto_$number',
    )) {
      number++;
    }
    final result = await showDialog<MembershipFunction>(
      context: context,
      builder: (_) => MembershipDialog(
        variable: variable,
        index: index,
        initialName: 'conjunto_$number',
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _error = null;
      _functions = List.of(_functions);
      if (index == null) {
        _functions.add(result);
      } else {
        _functions[index] = result;
      }
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: Text(widget.variable == null ? 'Nueva variable' : 'Editar variable'),
    content: SizedBox(
      width: 480,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Nombre de la variable',
              helperText: _nameHint,
              helperMaxLines: 3,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _min,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: const InputDecoration(labelText: 'Mínimo'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _max,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: const InputDecoration(labelText: 'Máximo'),
          ),
          const SizedBox(height: 16),
          Text(
            widget.variable == null
                ? 'Se crearán tres conjuntos triangulares: bajo, medio y alto. Puedes editarlos después.'
                : 'Cambiar el rango conserva los parámetros de los conjuntos. Revisa sus curvas después.',
          ),
          if (widget.variable != null) ...[
            const Divider(height: 32),
            Text(
              'Conjuntos de la variable',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Edita o añade un conjunto y elige su forma: triangular, trapezoidal o gaussiana. Los cambios se aplican al guardar la variable.',
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < _functions.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_functions[i].name),
                subtitle: Text(
                  '${_functions[i].type.label} [${_functions[i].parameters.join(' ')}]',
                ),
                trailing: IconButton(
                  tooltip: 'Editar conjunto ${_functions[i].name}',
                  onPressed: () => _editFunction(i),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _editFunction,
                icon: const Icon(Icons.add),
                label: const Text('Añadir conjunto'),
              ),
            ),
          ],
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
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _save, child: const Text('Guardar variable')),
    ],
  );
}

class MembershipDialog extends StatefulWidget {
  const MembershipDialog({
    super.key,
    required this.variable,
    required this.initialName,
    this.index,
    this.initialType = MembershipType.triangular,
  });
  final FuzzyVariable variable;
  final String initialName;
  final int? index;
  final MembershipType initialType;
  @override
  State<MembershipDialog> createState() => _MembershipDialogState();
}

class _MembershipDialogState extends State<MembershipDialog> {
  MembershipFunction? get _original =>
      widget.index == null ? null : widget.variable.functions[widget.index!];
  late final _name = TextEditingController(
    text: _original?.name ?? widget.initialName,
  );
  late MembershipType _type = _original?.type ?? widget.initialType;
  late final _parameters = TextEditingController(
    text: (_original?.parameters ?? _defaults(_type)).join(' '),
  );
  late final _trapezoidParameters = [
    for (final value
        in (_original?.type == MembershipType.trapezoidal
            ? _original!.parameters
            : _defaults(MembershipType.trapezoidal)))
      TextEditingController(text: '$value'),
  ];
  String? _error;

  List<double> _defaults(MembershipType type) {
    final v = widget.variable;
    final span = v.max - v.min;
    return switch (type) {
      MembershipType.triangular => [v.min, v.min + span / 2, v.max],
      MembershipType.trapezoidal => [
        v.min,
        v.min + span / 4,
        v.min + span * 3 / 4,
        v.max,
      ],
      MembershipType.gaussian => [span / 6, v.min + span / 2],
    };
  }

  MembershipFunction? _candidate() {
    final values = _type == MembershipType.trapezoidal
        ? _trapezoidParameters
              .map((controller) => double.tryParse(controller.text.trim()))
              .toList()
        : _parameters.text
              .trim()
              .split(RegExp(r'[\s,;]+'))
              .map(double.tryParse)
              .toList();
    if (values.any((v) => v == null)) return null;
    return MembershipFunction(
      name: _name.text.trim(),
      type: _type,
      parameters: values.cast<double>(),
    );
  }

  void _save() {
    final mf = _candidate();
    var error =
        mf?.validate() ??
        (mf == null
            ? _type == MembershipType.trapezoidal
                  ? 'Completa a, b, c y d con un número en cada campo. Usa punto decimal.'
                  : 'Introduce parámetros numéricos separados por espacios, con punto decimal.'
            : null);
    if (mf != null &&
        widget.variable.functions.indexed.any(
          (item) =>
              item.$1 != widget.index &&
              item.$2.name.toLowerCase() == mf.name.toLowerCase(),
        )) {
      error = 'Ya existe un conjunto con ese nombre en esta variable.';
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context, mf);
  }

  @override
  void dispose() {
    _name.dispose();
    _parameters.dispose();
    for (final controller in _trapezoidParameters) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _trapezoidFields() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Cuatro puntos del trapezoide: a ≤ b ≤ c ≤ d.\nEntre b y c, la pertenencia es 1.',
      ),
      const SizedBox(height: 12),
      for (var row = 0; row < 2; row++)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              for (var column = 0; column < 2; column++) ...[
                if (column > 0) const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    key: Key(
                      'trapezoid-parameter-${['a', 'b', 'c', 'd'][row * 2 + column]}',
                    ),
                    controller: _trapezoidParameters[row * 2 + column],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: InputDecoration(
                      labelText: [
                        'a · Inicio',
                        'b · Meseta',
                        'c · Meseta',
                        'd · Fin',
                      ][row * 2 + column],
                    ),
                    onChanged: (_) => setState(() {
                      _error = null;
                    }),
                  ),
                ),
              ],
            ],
          ),
        ),
      const Text(
        'Usa punto decimal. Puedes repetir a = b o c = d para crear un hombro.',
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final mf = _candidate();
    final previewError = mf?.validate();
    return AlertDialog(
      scrollable: true,
      title: const Text('Función de pertenencia'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _name,
              onChanged: (_) => setState(() => _error = null),
              decoration: const InputDecoration(
                labelText: 'Nombre del conjunto',
                helperText: _nameHint,
                helperMaxLines: 3,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<MembershipType>(
              initialValue: _type,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Forma de la curva'),
              items: [
                for (final t in MembershipType.values)
                  DropdownMenuItem(
                    value: t,
                    child: Text('${t.label} (${t.matlab})'),
                  ),
              ],
              onChanged: (value) => setState(() {
                _type = value!;
                final defaults = _defaults(_type);
                _parameters.text = defaults.join(' ');
                if (_type == MembershipType.trapezoidal) {
                  for (var i = 0; i < 4; i++) {
                    _trapezoidParameters[i].text = '${defaults[i]}';
                  }
                }
                _error = null;
              }),
            ),
            const SizedBox(height: 16),
            if (_type == MembershipType.trapezoidal)
              _trapezoidFields()
            else
              TextField(
                controller: _parameters,
                onChanged: (_) => setState(() => _error = null),
                decoration: InputDecoration(
                  labelText: 'Parámetros: ${_type.parametersLabel}',
                  helperText: _type == MembershipType.gaussian
                      ? 'Sigma > 0 y centro. Separa con espacios; usa punto decimal.'
                      : 'En orden creciente o igual. Separa con espacios; usa punto decimal.',
                  helperMaxLines: 3,
                ),
              ),
            const SizedBox(height: 16),
            if (mf != null && previewError == null)
              MembershipChart(
                variable: widget.variable.copyWith(functions: [mf]),
              )
            else
              Text(
                previewError ?? 'Introduce los parámetros para ver la curva.',
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _save, child: const Text('Guardar conjunto')),
      ],
    );
  }
}

class FuzzyRuleDialog extends StatefulWidget {
  const FuzzyRuleDialog({super.key, required this.system, this.rule});
  final FuzzySystem system;
  final FuzzyRule? rule;
  @override
  State<FuzzyRuleDialog> createState() => _FuzzyRuleDialogState();
}

class _FuzzyRuleDialogState extends State<FuzzyRuleDialog> {
  late final _inputs = List<int>.of(
    widget.rule?.inputs ?? List.filled(widget.system.inputs.length, 1),
  );
  late final _outputs = List<int>.of(
    widget.rule?.outputs ?? List.filled(widget.system.outputs.length, 1),
  );
  late bool _useAnd = widget.rule?.useAnd ?? true;
  late final _weight = TextEditingController(
    text: '${widget.rule?.weight ?? 1}',
  );
  String? _error;

  @override
  void dispose() {
    _weight.dispose();
    super.dispose();
  }

  void _save() {
    final weight = double.tryParse(_weight.text.trim());
    if (weight == null || !weight.isFinite || weight < 0 || weight > 1) {
      setState(() => _error = 'El peso debe ser un número entre 0 y 1.');
      return;
    }
    final rule = FuzzyRule(
      inputs: _inputs,
      outputs: _outputs,
      weight: weight,
      useAnd: _useAnd,
    );
    final errors = widget.system.copyWith(rules: [rule]).validate();
    if (errors.isNotEmpty) {
      setState(() => _error = errors.first);
      return;
    }
    Navigator.pop(context, rule);
  }

  Widget _selector(
    FuzzyVariable variable,
    List<int> indices,
    int index,
    bool input,
  ) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: DropdownButtonFormField<int>(
      initialValue: indices[index],
      isExpanded: true,
      decoration: InputDecoration(labelText: variable.name),
      items: [
        DropdownMenuItem(
          value: 0,
          child: Text(input ? 'Cualquiera (no usar)' : 'Sin efecto (no usar)'),
        ),
        for (var j = 0; j < variable.functions.length; j++)
          DropdownMenuItem(
            value: j + 1,
            child: Text(variable.functions[j].name),
          ),
      ],
      onChanged: (value) => setState(() {
        indices[index] = value!;
        _error = null;
      }),
    ),
  );

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: Text(widget.rule == null ? 'Nueva regla' : 'Editar regla'),
    content: SizedBox(
      width: 520,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Si se cumplen estas condiciones:'),
          for (var i = 0; i < widget.system.inputs.length; i++)
            _selector(widget.system.inputs[i], _inputs, i, true),
          const SizedBox(height: 16),
          DropdownButtonFormField<bool>(
            initialValue: _useAnd,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Unir condiciones con',
            ),
            items: const [
              DropdownMenuItem(value: true, child: Text('Y (AND · mínimo)')),
              DropdownMenuItem(value: false, child: Text('O (OR · máximo)')),
            ],
            onChanged: (value) => setState(() => _useAnd = value!),
          ),
          const SizedBox(height: 20),
          const Text('Entonces:'),
          for (var i = 0; i < widget.system.outputs.length; i++)
            _selector(widget.system.outputs[i], _outputs, i, false),
          const SizedBox(height: 16),
          TextField(
            controller: _weight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Peso de la regla (0 a 1)',
              helperText:
                  '1 aplica toda la fuerza de la regla. Usa punto decimal.',
            ),
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
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _save, child: const Text('Guardar regla')),
    ],
  );
}
