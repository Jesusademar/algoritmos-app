import 'dart:math' as math;

enum MembershipType {
  triangular('trimf', 'Triangular', 'a b c'),
  trapezoidal('trapmf', 'Trapezoidal', 'a b c d'),
  gaussian('gaussmf', 'Gaussiana', 'sigma centro');

  const MembershipType(this.matlab, this.label, this.parametersLabel);
  final String matlab;
  final String label;
  final String parametersLabel;
}

String? fuzzyNameError(String name) {
  if (!RegExp(r'^[A-Za-z][A-Za-z0-9_]*$').hasMatch(name) ||
      {'and', 'or', 'not', 'none', 'if', 'then'}.contains(name.toLowerCase())) {
    return 'Usa letras sin tildes, números y _; empieza con letra y evita palabras reservadas.';
  }
  return null;
}

class MembershipFunction {
  MembershipFunction({
    required this.name,
    required this.type,
    required List<double> parameters,
  }) : parameters = List.unmodifiable(parameters);

  final String name;
  final MembershipType type;
  final List<double> parameters;

  String? validate() {
    if (fuzzyNameError(name) != null) {
      return 'Nombre de conjunto inválido: $name.';
    }
    final count = switch (type) {
      MembershipType.triangular => 3,
      MembershipType.trapezoidal => 4,
      MembershipType.gaussian => 2,
    };
    if (parameters.length != count || parameters.any((p) => !p.isFinite)) {
      return '$name: introduce $count parámetros finitos (${type.parametersLabel}).';
    }
    if (type == MembershipType.gaussian) {
      if (parameters.first <= 0) return '$name: sigma debe ser mayor que cero.';
    } else {
      for (var i = 1; i < parameters.length; i++) {
        if (parameters[i] < parameters[i - 1]) {
          return '$name: los parámetros deben estar en orden creciente o igual.';
        }
      }
      if (parameters.first == parameters.last ||
          !(parameters.last - parameters.first).isFinite) {
        return '$name: los extremos deben ser distintos y su diferencia finita.';
      }
    }
    return null;
  }

  double membership(double x) {
    final p = parameters;
    if (type == MembershipType.gaussian) {
      final z = (x - p[1]) / p[0];
      return math.exp(-0.5 * z * z);
    }
    final b = p[1];
    final c = type == MembershipType.triangular ? b : p[2];
    if (x >= b && x <= c) return 1;
    if (x <= p.first || x >= p.last) return 0;
    return (x < b ? (x - p.first) / (b - p.first) : (p.last - x) / (p.last - c))
        .clamp(0.0, 1.0);
  }
}

class FuzzyVariable {
  FuzzyVariable({
    required this.name,
    required this.min,
    required this.max,
    required List<MembershipFunction> functions,
  }) : functions = List.unmodifiable(functions);
  final String name;
  final double min;
  final double max;
  final List<MembershipFunction> functions;

  FuzzyVariable copyWith({
    String? name,
    double? min,
    double? max,
    List<MembershipFunction>? functions,
  }) => FuzzyVariable(
    name: name ?? this.name,
    min: min ?? this.min,
    max: max ?? this.max,
    functions: functions ?? this.functions,
  );

  String? validate() {
    if (fuzzyNameError(name) != null) {
      return 'Nombre de variable inválido: $name.';
    }
    if (!min.isFinite || !max.isFinite || min >= max || !(max - min).isFinite) {
      return '$name: el mínimo debe ser menor que el máximo y el rango debe ser finito.';
    }
    if (functions.isEmpty) return '$name: agrega al menos un conjunto.';
    final names = <String>{};
    for (final mf in functions) {
      if (!names.add(mf.name.toLowerCase())) {
        return '$name: hay conjuntos con nombres repetidos.';
      }
      final error = mf.validate();
      if (error != null) return error;
    }
    return null;
  }

  static FuzzyVariable defaults(String name, double min, double max) {
    final mid = min + (max - min) / 2;
    return FuzzyVariable(
      name: name,
      min: min,
      max: max,
      functions: [
        MembershipFunction(
          name: 'bajo',
          type: MembershipType.triangular,
          parameters: [min, min, mid],
        ),
        MembershipFunction(
          name: 'medio',
          type: MembershipType.triangular,
          parameters: [min, mid, max],
        ),
        MembershipFunction(
          name: 'alto',
          type: MembershipType.triangular,
          parameters: [mid, max, max],
        ),
      ],
    );
  }
}

class FuzzyRule {
  FuzzyRule({
    required List<int> inputs,
    required List<int> outputs,
    this.weight = 1,
    this.useAnd = true,
  }) : inputs = List.unmodifiable(inputs),
       outputs = List.unmodifiable(outputs);
  // MATLAB uses one-based indices; zero means the variable is not used.
  final List<int> inputs;
  final List<int> outputs;
  final double weight;
  final bool useAnd;

  String describe(FuzzySystem system) {
    String terms(
      List<int> indices,
      List<FuzzyVariable> variables,
      String join,
    ) => [
      for (var i = 0; i < indices.length; i++)
        if (indices[i] != 0)
          '${variables[i].name} es ${variables[i].functions[indices[i] - 1].name}',
    ].join(join);
    return 'Si ${terms(inputs, system.inputs, useAnd ? ' Y ' : ' O ')}, entonces ${terms(outputs, system.outputs, ' Y ')}.';
  }
}

class FuzzySystem {
  FuzzySystem({
    this.name = 'sistema_difuso',
    List<FuzzyVariable> inputs = const [],
    List<FuzzyVariable> outputs = const [],
    List<FuzzyRule> rules = const [],
  }) : inputs = List.unmodifiable(inputs),
       outputs = List.unmodifiable(outputs),
       rules = List.unmodifiable(rules);
  final String name;
  final List<FuzzyVariable> inputs;
  final List<FuzzyVariable> outputs;
  final List<FuzzyRule> rules;

  FuzzySystem copyWith({
    String? name,
    List<FuzzyVariable>? inputs,
    List<FuzzyVariable>? outputs,
    List<FuzzyRule>? rules,
  }) => FuzzySystem(
    name: name ?? this.name,
    inputs: inputs ?? this.inputs,
    outputs: outputs ?? this.outputs,
    rules: rules ?? this.rules,
  );

  FuzzySystem addVariable(FuzzyVariable variable, {required bool input}) =>
      copyWith(
        inputs: input ? [...inputs, variable] : inputs,
        outputs: input ? outputs : [...outputs, variable],
        rules: [
          for (final rule in rules)
            FuzzyRule(
              inputs: input ? [...rule.inputs, 0] : rule.inputs,
              outputs: input ? rule.outputs : [...rule.outputs, 0],
              weight: rule.weight,
              useAnd: rule.useAnd,
            ),
        ],
      );

  FuzzySystem removeVariable(int index, {required bool input}) {
    final variables = List<FuzzyVariable>.of(input ? inputs : outputs)
      ..removeAt(index);
    return copyWith(
      inputs: input ? variables : inputs,
      outputs: input ? outputs : variables,
      rules: [
        for (final rule in rules)
          if ((input ? rule.inputs : rule.outputs)[index] == 0)
            FuzzyRule(
              inputs: input
                  ? (List<int>.of(rule.inputs)..removeAt(index))
                  : rule.inputs,
              outputs: input
                  ? rule.outputs
                  : (List<int>.of(rule.outputs)..removeAt(index)),
              weight: rule.weight,
              useAnd: rule.useAnd,
            ),
      ],
    );
  }

  FuzzySystem removeFunction(
    int variableIndex,
    int functionIndex, {
    required bool input,
  }) {
    final variables = List<FuzzyVariable>.of(input ? inputs : outputs);
    final variable = variables[variableIndex];
    if (variable.functions.length == 1) {
      throw StateError('Conserva al menos un conjunto.');
    }
    variables[variableIndex] = variable.copyWith(
      functions: List<MembershipFunction>.of(variable.functions)
        ..removeAt(functionIndex),
    );
    final removed = functionIndex + 1;
    List<int> remap(List<int> indices) => [
      for (var j = 0; j < indices.length; j++)
        j == variableIndex && indices[j] > removed
            ? indices[j] - 1
            : indices[j],
    ];
    return copyWith(
      inputs: input ? variables : inputs,
      outputs: input ? outputs : variables,
      rules: [
        for (final rule in rules)
          if ((input ? rule.inputs : rule.outputs)[variableIndex] != removed)
            FuzzyRule(
              inputs: input ? remap(rule.inputs) : rule.inputs,
              outputs: input ? rule.outputs : remap(rule.outputs),
              weight: rule.weight,
              useAnd: rule.useAnd,
            ),
      ],
    );
  }

  List<String> validate({bool requireComplete = true}) {
    final errors = <String>[];
    if (fuzzyNameError(name) != null) {
      errors.add('El nombre del sistema no es válido.');
    }
    if (requireComplete) {
      if (inputs.isEmpty) {
        errors.add('Agrega al menos una variable de entrada.');
      }
      if (outputs.isEmpty) {
        errors.add('Agrega al menos una variable de salida.');
      }
      if (rules.isEmpty) errors.add('Agrega al menos una regla.');
    }
    final names = <String>{};
    for (final variable in [...inputs, ...outputs]) {
      if (!names.add(variable.name.toLowerCase())) {
        errors.add(
          'El nombre ${variable.name} está repetido entre las variables.',
        );
      }
      final error = variable.validate();
      if (error != null) errors.add(error);
    }
    for (var i = 0; i < rules.length; i++) {
      final rule = rules[i];
      bool validIndices(List<int> indices, List<FuzzyVariable> variables) =>
          indices.length == variables.length &&
          indices.any((index) => index != 0) &&
          List.generate(
            indices.length,
            (j) =>
                indices[j] >= 0 && indices[j] <= variables[j].functions.length,
          ).every((valid) => valid);
      if (!validIndices(rule.inputs, inputs) ||
          !validIndices(rule.outputs, outputs)) {
        errors.add(
          'Regla ${i + 1}: selecciona al menos una entrada y una salida con conjuntos existentes.',
        );
      }
      if (!rule.weight.isFinite || rule.weight < 0 || rule.weight > 1) {
        errors.add('Regla ${i + 1}: el peso debe estar entre 0 y 1.');
      }
    }
    return errors;
  }

  static FuzzySystem trapezoidExample() {
    final example = ventilationExample();
    FuzzyVariable convert(FuzzyVariable variable) {
      final min = variable.min;
      final span = variable.max - min;
      return variable.copyWith(
        functions: [
          MembershipFunction(
            name: 'bajo',
            type: MembershipType.trapezoidal,
            parameters: [min, min, min + span * 0.2, min + span * 0.45],
          ),
          MembershipFunction(
            name: 'medio',
            type: MembershipType.trapezoidal,
            parameters: [
              min + span * 0.2,
              min + span * 0.4,
              min + span * 0.6,
              min + span * 0.8,
            ],
          ),
          MembershipFunction(
            name: 'alto',
            type: MembershipType.trapezoidal,
            parameters: [
              min + span * 11 / 20,
              min + span * 0.8,
              variable.max,
              variable.max,
            ],
          ),
        ],
      );
    }

    return example.copyWith(
      name: 'ventilacion_trapezoidal',
      inputs: example.inputs.map(convert).toList(),
      outputs: example.outputs.map(convert).toList(),
    );
  }

  static FuzzySystem academicPerformanceExample() {
    MembershipFunction crearTrapecio(String name, List<double> parameters) =>
        MembershipFunction(
          name: name,
          type: MembershipType.trapezoidal,
          parameters: parameters,
        );

    int calcularSalida(int interes, int docente, int infraestructura) {
      final puntaje = interes + docente + infraestructura - 3;
      if (puntaje <= 2) return 1;
      return puntaje <= 4 ? 2 : 3;
    }

    return FuzzySystem(
      name: 'rendimiento_academico',
      inputs: [
        FuzzyVariable(
          name: 'Interes',
          min: 0,
          max: 10,
          functions: [
            crearTrapecio('Malo', [-3.75, -0.417, 4.58, 6.927]),
            crearTrapecio('Regular', [4, 4.6, 5.5, 8]),
            crearTrapecio('Bueno', [7, 8.1, 10.4, 13.75]),
          ],
        ),
        FuzzyVariable(
          name: 'Calidad_Docente',
          min: 0,
          max: 100,
          functions: [
            crearTrapecio('Mala', [-37.4, -4.02, 42.62, 69.8]),
            crearTrapecio('Regular', [41, 50, 60, 80]),
            crearTrapecio('Excelente', [60, 88, 104, 137.6]),
          ],
        ),
        FuzzyVariable(
          name: 'Infraestructura',
          min: 0,
          max: 100,
          functions: [
            crearTrapecio('mala', [-37.5, -4.17, 28.9, 50.21]),
            crearTrapecio('regular', [30, 45, 64, 88]),
            crearTrapecio('Buena', [65, 91, 104, 137.5]),
          ],
        ),
      ],
      outputs: [
        FuzzyVariable(
          name: 'Rendimiento_Academico',
          min: 0,
          max: 100,
          functions: [
            crearTrapecio('Pesimo', [-37.6, -4.27, 22.1, 48.5]),
            crearTrapecio('Regular', [30, 45, 60, 76]),
            crearTrapecio('Excelente', [64, 81, 104, 137.6]),
          ],
        ),
      ],
      rules: [
        for (var interes = 1; interes <= 3; interes++)
          for (var docente = 1; docente <= 3; docente++)
            for (
              var infraestructura = 1;
              infraestructura <= 3;
              infraestructura++
            )
              FuzzyRule(
                inputs: [interes, docente, infraestructura],
                outputs: [calcularSalida(interes, docente, infraestructura)],
              ),
      ],
    );
  }

  static FuzzySystem ventilationExample() => FuzzySystem(
    name: 'ventilacion',
    inputs: [
      FuzzyVariable.defaults('temperatura', 0, 40),
      FuzzyVariable.defaults('humedad', 0, 100),
    ],
    outputs: [FuzzyVariable.defaults('ventilacion', 0, 100)],
    rules: [
      FuzzyRule(inputs: [1, 0], outputs: [1]),
      FuzzyRule(inputs: [2, 2], outputs: [2]),
      FuzzyRule(inputs: [3, 3], outputs: [3], useAnd: false),
      FuzzyRule(inputs: [2, 1], outputs: [2]),
    ],
  );
}
