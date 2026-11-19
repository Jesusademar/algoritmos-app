import 'dart:convert';

import 'fuzzy_system.dart';

/// Type-1 Mamdani FIS, using MATLAB's indexed rule notation.
class FisCodec {
  const FisCodec();

  String encode(FuzzySystem system) {
    final errors = system.validate();
    if (errors.isNotEmpty) throw FormatException(errors.join('\n'));
    final out = StringBuffer()
      ..writeln('[System]')
      ..writeln("Name='${system.name}'")
      ..writeln("Type='mamdani'")
      ..writeln('Version=2.0')
      ..writeln('NumInputs=${system.inputs.length}')
      ..writeln('NumOutputs=${system.outputs.length}')
      ..writeln('NumRules=${system.rules.length}')
      ..writeln("AndMethod='min'")
      ..writeln("OrMethod='max'")
      ..writeln("ImpMethod='min'")
      ..writeln("AggMethod='max'")
      ..writeln("DefuzzMethod='centroid'");
    void variables(String kind, List<FuzzyVariable> variables) {
      for (var i = 0; i < variables.length; i++) {
        final v = variables[i];
        out
          ..writeln()
          ..writeln('[$kind${i + 1}]')
          ..writeln("Name='${v.name}'")
          ..writeln('Range=[${v.min} ${v.max}]')
          ..writeln('NumMFs=${v.functions.length}');
        for (var j = 0; j < v.functions.length; j++) {
          final mf = v.functions[j];
          out.writeln(
            "MF${j + 1}='${mf.name}':'${mf.type.matlab}',[${mf.parameters.join(' ')}]",
          );
        }
      }
    }

    variables('Input', system.inputs);
    variables('Output', system.outputs);
    out
      ..writeln()
      ..writeln('[Rules]');
    for (final rule in system.rules) {
      out.writeln(
        '${rule.inputs.join(' ')}, ${rule.outputs.join(' ')} (${rule.weight}) : ${rule.useAnd ? 1 : 2}',
      );
    }
    return out.toString();
  }
}

/// Editable application document, separate from MATLAB's exchange format.
class FuzzyDocumentCodec {
  const FuzzyDocumentCodec();

  String encode(FuzzySystem system) {
    final errors = system.validate(requireComplete: false);
    if (errors.isNotEmpty) throw FormatException(errors.join('\n'));
    List<Object> variables(List<FuzzyVariable> values) => [
      for (final v in values)
        {
          'name': v.name,
          'range': [v.min, v.max],
          'functions': [
            for (final mf in v.functions)
              {
                'name': mf.name,
                'type': mf.type.matlab,
                'parameters': mf.parameters,
              },
          ],
        },
    ];
    return const JsonEncoder.withIndent('  ').convert({
      'format': 'logiverse-fuzzy',
      'version': 1,
      'type': 'mamdani',
      'name': system.name,
      'inputs': variables(system.inputs),
      'outputs': variables(system.outputs),
      'rules': [
        for (final rule in system.rules)
          {
            'inputs': rule.inputs,
            'outputs': rule.outputs,
            'weight': rule.weight,
            'useAnd': rule.useAnd,
          },
      ],
    });
  }

  FuzzySystem decode(String source) {
    try {
      final data = jsonDecode(source) as Map<String, dynamic>;
      if (data['format'] != 'logiverse-fuzzy' ||
          data['version'] != 1 ||
          data['type'] != 'mamdani') {
        throw const FormatException(
          'Selecciona un diseño JSON de Lógica difusa, versión 1.',
        );
      }
      List<FuzzyVariable> variables(dynamic raw) => [
        for (final v in raw as List)
          FuzzyVariable(
            name: v['name'] as String,
            min: (v['range'][0] as num).toDouble(),
            max: (v['range'][1] as num).toDouble(),
            functions: [
              for (final mf in v['functions'] as List)
                MembershipFunction(
                  name: mf['name'] as String,
                  type: MembershipType.values.firstWhere(
                    (t) => t.matlab == mf['type'],
                  ),
                  parameters: (mf['parameters'] as List)
                      .map((p) => (p as num).toDouble())
                      .toList(),
                ),
            ],
          ),
      ];
      final system = FuzzySystem(
        name: data['name'] as String,
        inputs: variables(data['inputs']),
        outputs: variables(data['outputs']),
        rules: [
          for (final r in data['rules'] as List)
            FuzzyRule(
              inputs: (r['inputs'] as List).cast<int>(),
              outputs: (r['outputs'] as List).cast<int>(),
              weight: (r['weight'] as num).toDouble(),
              useAnd: r['useAnd'] as bool,
            ),
        ],
      );
      final errors = system.validate(requireComplete: false);
      if (errors.isNotEmpty) throw FormatException(errors.join('\n'));
      return system;
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException(
        'El archivo no contiene un diseño difuso válido.',
      );
    }
  }
}
