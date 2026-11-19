import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:app_grafos/features/fuzzy/domain/fuzzy_codecs.dart';
import 'package:app_grafos/features/fuzzy/domain/fuzzy_system.dart';

void main() {
  test('trapezoides con hombros, meseta y extremos coincidentes se evalúan sin división por cero', () {
    for (final parameters in <List<double>>[
      [0, 0, 10, 20],
      [0, 10, 20, 20],
      [0, 0, 20, 20],
      [0, 10, 10, 20],
    ]) {
      final mf = MembershipFunction(
        name: 'trapezoide',
        type: MembershipType.trapezoidal,
        parameters: parameters,
      );
      expect(mf.validate(), isNull);
      expect(mf.membership(parameters[1]), 1);
      expect(mf.membership(parameters[2]), 1);
      for (final x in [-1.0, 0.0, 5.0, 10.0, 15.0, 20.0, 21.0]) {
        expect(mf.membership(x).isFinite, isTrue);
        expect(mf.membership(x), inInclusiveRange(0, 1));
      }
    }
  });

  test(
    'el ejemplo de trapezoides conserva cobertura de reglas y sus archivos',
    () {
      final system = FuzzySystem.trapezoidExample();
      expect(system.validate(), isEmpty);
      expect(
        [...system.inputs, ...system.outputs]
            .expand((v) => v.functions)
            .every((mf) => mf.type == MembershipType.trapezoidal),
        isTrue,
      );
      for (var temperature = 0; temperature <= 40; temperature += 2) {
        for (var humidity = 0; humidity <= 100; humidity += 5) {
          final values = [temperature.toDouble(), humidity.toDouble()];
          final active = system.rules.any((rule) {
            final degrees = [
              for (var i = 0; i < rule.inputs.length; i++)
                if (rule.inputs[i] > 0)
                  system.inputs[i].functions[rule.inputs[i] - 1].membership(
                    values[i],
                  ),
            ];
            return rule.useAnd
                ? degrees.every((v) => v > 0)
                : degrees.any((v) => v > 0);
          });
          expect(active, isTrue, reason: 'Entradas: $values');
        }
      }
      final restored = const FuzzyDocumentCodec().decode(
        const FuzzyDocumentCodec().encode(system),
      );
      expect(
        const FisCodec().encode(restored),
        const FisCodec().encode(system),
      );
    },
  );
  test('las curvas incluyen hombros y usan sigma, centro para gaussmf', () {
    final low = FuzzyVariable.defaults('temperatura', 0, 40).functions.first;
    final high = FuzzyVariable.defaults('temperatura', 0, 40).functions.last;
    expect(low.membership(0), 1);
    expect(low.membership(10), 0.5);
    expect(low.membership(20), 0);
    expect(high.membership(40), 1);
    final trap = MembershipFunction(
      name: 'templado',
      type: MembershipType.trapezoidal,
      parameters: [0, 10, 20, 30],
    );
    expect(
      [
        for (final x in [0.0, 5.0, 10.0, 20.0, 25.0, 30.0]) trap.membership(x),
      ],
      [0, 0.5, 1, 1, 0.5, 0],
    );
    final gaussian = MembershipFunction(
      name: 'templado',
      type: MembershipType.gaussian,
      parameters: [2, 10],
    );
    expect(gaussian.membership(10), 1);
    expect(gaussian.membership(12), closeTo(math.exp(-0.5), 1e-12));
    expect(gaussian.membership(8), gaussian.membership(12));
  });

  test(
    'rechaza parámetros inválidos, rangos no finitos y nombres inseguros',
    () {
      for (final mf in [
        MembershipFunction(
          name: 'a',
          type: MembershipType.gaussian,
          parameters: [0, 2],
        ),
        MembershipFunction(
          name: 'a',
          type: MembershipType.gaussian,
          parameters: [double.nan, 2],
        ),
        MembershipFunction(
          name: 'a',
          type: MembershipType.triangular,
          parameters: [2, 0, 4],
        ),
        MembershipFunction(
          name: 'a',
          type: MembershipType.triangular,
          parameters: [2, 2, 2],
        ),
        MembershipFunction(
          name: 'a',
          type: MembershipType.trapezoidal,
          parameters: [0, 2, 1, 3],
        ),
        MembershipFunction(
          name: 'a',
          type: MembershipType.triangular,
          parameters: [0, 1],
        ),
      ]) {
        expect(mf.validate(), isNotNull);
      }
      final system = FuzzySystem.ventilationExample();
      expect(system.inputs.first.copyWith(min: 40).validate(), isNotNull);
      expect(
        system.inputs.first.copyWith(max: double.infinity).validate(),
        isNotNull,
      );
      for (final name in ["bad'\n[Rules]", '../archivo', '', 'or']) {
        expect(
          () => const FisCodec().encode(system.copyWith(name: name)),
          throwsFormatException,
        );
      }
      expect(FuzzySystem().validate(), hasLength(3));
      expect(
        () => const FisCodec().encode(FuzzySystem()),
        throwsFormatException,
      );
      expect(
        system.copyWith(outputs: [system.inputs.first]).validate(),
        isNotEmpty,
      );
    },
  );

  test(
    'exporta secciones, tres formas y reglas MATLAB con índices desde uno',
    () {
      final variable = FuzzyVariable(
        name: 'sensor',
        min: -5,
        max: 10,
        functions: [
          MembershipFunction(
            name: 'bajo',
            type: MembershipType.triangular,
            parameters: [-5, -5, 5],
          ),
          MembershipFunction(
            name: 'medio',
            type: MembershipType.trapezoidal,
            parameters: [0, 2, 4, 8],
          ),
          MembershipFunction(
            name: 'alto',
            type: MembershipType.gaussian,
            parameters: [2, 8],
          ),
        ],
      );
      final system = FuzzySystem(
        name: 'control',
        inputs: [variable, FuzzyVariable.defaults('humedad', 0, 100)],
        outputs: [
          FuzzyVariable.defaults('motor', 0, 100),
          FuzzyVariable.defaults('alarma', 0, 1),
        ],
        rules: [
          FuzzyRule(inputs: [1, 0], outputs: [2, 0], weight: 0.75),
          FuzzyRule(inputs: [3, 2], outputs: [3, 1], useAnd: false),
        ],
      );
      final fis = const FisCodec().encode(system);
      expect(
        fis,
        startsWith(
          "[System]\nName='control'\nType='mamdani'\nVersion=2.0\nNumInputs=2\nNumOutputs=2\nNumRules=2\n",
        ),
      );
      expect(
        fis,
        contains(
          "AndMethod='min'\nOrMethod='max'\nImpMethod='min'\nAggMethod='max'\nDefuzzMethod='centroid'",
        ),
      );
      expect(
        fis,
        contains(
          "[Input1]\nName='sensor'\nRange=[-5.0 10.0]\nNumMFs=3\nMF1='bajo':'trimf',[-5.0 -5.0 5.0]\nMF2='medio':'trapmf',[0.0 2.0 4.0 8.0]\nMF3='alto':'gaussmf',[2.0 8.0]",
        ),
      );
      expect(fis, contains('[Output2]'));
      expect(
        fis,
        endsWith('[Rules]\n1 0, 2 0 (0.75) : 1\n3 2, 3 1 (1.0) : 2\n'),
      );
    },
  );

  test('no exporta reglas sin condiciones, índices fuera de rango ni pesos inválidos', () {
    final system = FuzzySystem.ventilationExample();
    for (final rule in [
      FuzzyRule(inputs: [0, 0], outputs: [1]),
      FuzzyRule(inputs: [1, 0], outputs: [0]),
      FuzzyRule(inputs: [4, 0], outputs: [1]),
      FuzzyRule(inputs: [1], outputs: [1]),
      FuzzyRule(inputs: [1, 0], outputs: [1], weight: 1.1),
      FuzzyRule(inputs: [1, 0], outputs: [1], weight: double.nan),
    ]) {
      expect(
        () => const FisCodec().encode(system.copyWith(rules: [rule])),
        throwsFormatException,
      );
    }
  });

  test('el JSON recupera el diseño y admite borradores incompletos', () {
    const codec = FuzzyDocumentCodec();
    final system = FuzzySystem.ventilationExample();
    final restored = codec.decode(codec.encode(system));
    expect(const FisCodec().encode(restored), const FisCodec().encode(system));
    expect(codec.decode(codec.encode(FuzzySystem())).inputs, isEmpty);
    for (final raw in [
      '{}',
      '[]',
      '{',
      jsonEncode({'format': 'logiverse-fuzzy', 'version': 2}),
      codec.encode(system).replaceFirst('trimf', 'unknown'),
    ]) {
      expect(() => codec.decode(raw), throwsFormatException);
    }
    final data = jsonDecode(codec.encode(system));
    data['rules'][0]['inputs'] = [9, 0];
    expect(() => codec.decode(jsonEncode(data)), throwsFormatException);
  });

  test('editar la estructura conserva las reglas independientes y ajusta sus índices', () {
    final system = FuzzySystem.ventilationExample();
    final added = system.addVariable(
      FuzzyVariable.defaults('presion', 0, 1),
      input: true,
    );
    expect(added.rules.first.inputs, [1, 0, 0]);
    expect(added.removeVariable(2, input: true).rules.length, 4);
    final removed = system.removeVariable(1, input: true);
    expect(removed.rules.length, 1);
    expect(removed.rules.single.inputs, [1]);
    expect(removed.validate(), isEmpty);
    final withoutFirstSet = system.removeFunction(0, 0, input: true);
    expect(withoutFirstSet.rules.length, 3);
    expect(withoutFirstSet.rules.first.inputs, [1, 2]);
    expect(withoutFirstSet.rules[1].inputs, [2, 3]);
    expect(withoutFirstSet.validate(), isEmpty);
    final addedOutput = system.addVariable(
      FuzzyVariable.defaults('alarma', 0, 1),
      input: false,
    );
    expect(addedOutput.rules.first.outputs, [1, 0]);
    expect(addedOutput.removeVariable(1, input: false).validate(), isEmpty);
    expect(system.removeFunction(0, 1, input: false).validate(), isEmpty);
  });
}
