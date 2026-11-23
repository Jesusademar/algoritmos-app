import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/features/fuzzy/domain/fuzzy_system.dart';
import 'package:app_grafos/features/fuzzy/presentation/widgets/membership_chart.dart';

const _acento = AppColors.sorting;

MembershipFunction _crearTrapecio(String nombre, List<double> parametros) =>
    MembershipFunction(
      name: nombre,
      type: MembershipType.trapezoidal,
      parameters: parametros,
    );

final _templadoClasico = FuzzyVariable(
  name: 'clasico',
  min: 0,
  max: 40,
  functions: [
    _crearTrapecio('templado', [15, 15, 25, 25]),
  ],
);

final _templadoDifuso = FuzzyVariable(
  name: 'difuso',
  min: 0,
  max: 40,
  functions: [
    _crearTrapecio('templado', [10, 17, 23, 30]),
  ],
);

final _edad = FuzzyVariable(
  name: 'edad',
  min: 0,
  max: 90,
  functions: [
    _crearTrapecio('Niño', [0, 0, 9, 19]),
    _crearTrapecio('Adolescente', [9, 14, 17, 22]),
    _crearTrapecio('Joven', [17, 27, 35, 45]),
    _crearTrapecio('Adulto', [35, 45, 55, 70]),
    _crearTrapecio('3ra edad', [55, 70, 90, 90]),
  ],
);

final _interes = FuzzyVariable(
  name: 'interes',
  min: 0,
  max: 10,
  functions: [
    _crearTrapecio('Bajo', [0, 0, 4, 6]),
    _crearTrapecio('Medio', [4, 5, 7, 8]),
    _crearTrapecio('Alto', [7, 8, 10, 10]),
  ],
);

final _docente = FuzzyVariable(
  name: 'docente',
  min: 0,
  max: 100,
  functions: [
    _crearTrapecio('Malo', [0, 0, 50, 60]),
    _crearTrapecio('Regular', [50, 60, 70, 80]),
    _crearTrapecio('Bueno', [70, 80, 100, 100]),
  ],
);

final _rendimiento = FuzzyVariable(
  name: 'rendimiento',
  min: 0,
  max: 100,
  functions: [
    _crearTrapecio('Malo', [0, 0, 50, 75]),
    _crearTrapecio('Regular', [40, 65, 75, 85]),
    _crearTrapecio('Bueno', [70, 85, 100, 100]),
  ],
);

Future<void> mostrarGuiaDifusa(BuildContext context) => showDialog<void>(
  context: context,
  builder: (_) => const FuzzyGuideDialog(),
);

class FuzzyGuideDialog extends StatefulWidget {
  const FuzzyGuideDialog({super.key});

  @override
  State<FuzzyGuideDialog> createState() => _FuzzyGuideDialogState();
}

class _FuzzyGuideDialogState extends State<FuzzyGuideDialog> {
  static const _titulos = [
    'Idea',
    'Variable',
    'Proceso',
    'Ejemplo',
    'Métodos',
    'Usar la app',
    'Tu computadora',
  ];

  final _desplazamiento = ScrollController();
  int _pagina = 0;

  @override
  void dispose() {
    _desplazamiento.dispose();
    super.dispose();
  }

  void _cambiarPagina(int pagina) {
    setState(() => _pagina = pagina);
    if (_desplazamiento.hasClients) _desplazamiento.jumpTo(0);
  }

  Widget _construirPagina() => switch (_pagina) {
    0 => const _PaginaIdea(),
    1 => const _PaginaVariable(),
    2 => const _PaginaProceso(),
    3 => const _PaginaEjemplo(),
    4 => const _PaginaMetodos(),
    5 => const _PaginaUso(),
    _ => const _PaginaComputadora(),
  };

  @override
  Widget build(BuildContext context) {
    final alto = MediaQuery.sizeOf(context).height;
    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 880, maxHeight: alto * 0.92),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 8, 6),
              child: Row(
                children: [
                  const Icon(Icons.blur_on_rounded, color: _acento),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Guía visual de lógica difusa',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar guía',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 46,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _titulos.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (_, i) => ChoiceChip(
                  label: Text('${i + 1}. ${_titulos[i]}'),
                  selected: _pagina == i,
                  onSelected: (_) => _cambiarPagina(i),
                ),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: Scrollbar(
                controller: _desplazamiento,
                child: SingleChildScrollView(
                  controller: _desplazamiento,
                  padding: const EdgeInsets.all(20),
                  child: _construirPagina(),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: _pagina == 0
                        ? null
                        : () => _cambiarPagina(_pagina - 1),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Anterior'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _pagina == _titulos.length - 1
                        ? null
                        : () => _cambiarPagina(_pagina + 1),
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text('Siguiente'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Entendido'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaginaIdea extends StatefulWidget {
  const _PaginaIdea();

  @override
  State<_PaginaIdea> createState() => _PaginaIdeaState();
}

class _PaginaIdeaState extends State<_PaginaIdea> {
  double _temperatura = 14;

  @override
  Widget build(BuildContext context) {
    final clasico = _templadoClasico.functions.first.membership(_temperatura);
    final difuso = _templadoDifuso.functions.first.membership(_temperatura);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Encabezado(
          titulo: '¿Qué es un sistema difuso?',
          texto:
              'Las personas no pensamos solo en sí o no: decimos «hace un poco de frío» o «estoy muy cansada». '
              'Un sistema difuso convierte esas ideas en números y decide con reglas parecidas a las de un experto.',
        ),
        const SizedBox(height: 16),
        Text(
          'Mueve la temperatura: ¿el día está templado?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Slider(
          value: _temperatura,
          min: 0,
          max: 40,
          divisions: 80,
          label: '${_temperatura.toStringAsFixed(1)} °C',
          semanticFormatterCallback: (v) => '${v.toStringAsFixed(1)} grados',
          onChanged: (v) => setState(() => _temperatura = v),
        ),
        _Adaptable(
          children: [
            _TarjetaGrafica(
              titulo: 'Lógica clásica',
              resultado: clasico == 1 ? 'Sí está templado' : 'No está templado',
              detalle: 'Solo existen 0 o 1. Un grado cambia todo.',
              color: AppColors.graph,
              grafica: _GraficaDifusa(
                variable: _templadoClasico,
                colores: const [AppColors.graph],
                marcador: _temperatura,
                unidad: '°C',
              ),
            ),
            _TarjetaGrafica(
              titulo: 'Lógica difusa',
              resultado: '${(difuso * 100).round()}% templado',
              detalle: 'Se pertenece poco a poco, con un grado de 0 a 100%.',
              color: _acento,
              grafica: _GraficaDifusa(
                variable: _templadoDifuso,
                colores: const [_acento],
                marcador: _temperatura,
                unidad: '°C',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _Nota(
          icono: Icons.lightbulb_outline,
          texto: 'Difuso no significa impreciso ni azar: el grado se calcula con una curva exacta. Ejemplos de variables difusas: temperatura, edad, hambre, fuerza del viento y aprendizaje.',
        ),
      ],
    );
  }
}

class _PaginaVariable extends StatefulWidget {
  const _PaginaVariable();

  @override
  State<_PaginaVariable> createState() => _PaginaVariableState();
}

class _PaginaVariableState extends State<_PaginaVariable> {
  double _anios = 18;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Encabezado(
          titulo: 'Las 3 partes de una variable difusa',
          texto: 'Con la edad se ve claro: una persona de 18 años no es solo adolescente. Pertenece a varias etiquetas al mismo tiempo, cada una con su grado.',
        ),
        const SizedBox(height: 14),
        const _Adaptable(
          columnas: 3,
          children: [
            _Concepto(
              numero: '1',
              titulo: 'Grado de pertenencia',
              texto: 'Eje vertical. Cuánto pertenece: de 0 a 1 o de 0 a 100%.',
              icono: Icons.height,
            ),
            _Concepto(
              numero: '2',
              titulo: 'Conversión',
              texto: 'Eje horizontal. El valor real que medimos: años.',
              icono: Icons.straighten,
            ),
            _Concepto(
              numero: '3',
              titulo: 'Etiqueta lingüística',
              texto: 'La palabra de cada curva: niño, joven, adulto.',
              icono: Icons.sell_outlined,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _GraficaDifusa(
          variable: _edad,
          marcador: _anios,
          unidad: 'años',
          alto: 220,
          mostrarLeyenda: true,
        ),
        Row(
          children: [
            Text('${_anios.round()} años'),
            Expanded(
              child: Slider(
                value: _anios,
                min: 0,
                max: 90,
                divisions: 90,
                label: '${_anios.round()} años',
                onChanged: (v) => setState(() => _anios = v),
              ),
            ),
          ],
        ),
        for (var i = 0; i < _edad.functions.length; i++)
          _BarraGrado(
            etiqueta: _edad.functions[i].name,
            valor: _edad.functions[i].membership(_anios),
            color: membershipColors[i % membershipColors.length],
          ),
        const SizedBox(height: 10),
        const _Nota(
          icono: Icons.draw_outlined,
          texto: 'La forma de cada curva la define el experto en el tema. Lo que queda debajo de una curva es un conjunto difuso.',
        ),
      ],
    );
  }
}

class _PaginaProceso extends StatelessWidget {
  const _PaginaProceso();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Encabezado(
          titulo: 'Cómo decide un sistema difuso',
          texto: 'Entra un número, se transforma en palabras, las reglas razonan con esas palabras y al final vuelve a salir un número.',
        ),
        SizedBox(height: 16),
        _FlujoProceso(),
        SizedBox(height: 18),
        _CalculoReglas(),
        SizedBox(height: 12),
        _Nota(
          icono: Icons.rule,
          texto: 'Una regla se lee así: SI el interés es alto Y el docente es bueno ENTONCES el rendimiento es bueno. Cada combinación de etiquetas puede tener su regla.',
        ),
      ],
    );
  }
}

class _FlujoProceso extends StatelessWidget {
  const _FlujoProceso();

  static const _etapas = [
    (
      Icons.input,
      'Entrada',
      'Valor exacto',
      'Interés = 7.2',
      AppColors.textSecondary,
    ),
    (
      Icons.blur_linear,
      'Fuzzificación',
      'De número a grados',
      'Medio 80%, Alto 20%',
      _acento,
    ),
    (
      Icons.account_tree_outlined,
      'Reglas',
      'SI… Y… ENTONCES…',
      'Se activan y recortan',
      AppColors.johnson,
    ),
    (
      Icons.center_focus_strong,
      'Defuzzificación',
      'De área a número',
      'Centro de gravedad',
      AppColors.graph,
    ),
    (
      Icons.output,
      'Salida',
      'Valor exacto',
      'Rendimiento = 75.5',
      AppColors.success,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, limites) {
        final horizontal = limites.maxWidth >= 720;
        final tarjetas = <Widget>[];
        for (var i = 0; i < _etapas.length; i++) {
          final etapa = _crearEtapa(_etapas[i]);
          tarjetas.add(horizontal ? Expanded(child: etapa) : etapa);
          if (i < _etapas.length - 1) {
            tarjetas.add(
              Padding(
                padding: const EdgeInsets.all(3),
                child: Icon(
                  horizontal ? Icons.arrow_forward : Icons.arrow_downward,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ),
            );
          }
        }
        return horizontal
            ? IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final t in tarjetas)
                      t is Expanded ? t : Center(child: t),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final t in tarjetas) t is Padding ? Center(child: t) : t,
                ],
              );
      },
    );
  }

  Widget _crearEtapa((IconData, String, String, String, Color) etapa) {
    final (icono, titulo, funcion, ejemplo, color) = etapa;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, color: color),
          const SizedBox(height: 4),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(
            funcion,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
          ),
          const SizedBox(height: 3),
          Text(
            ejemplo,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _CalculoReglas extends StatelessWidget {
  const _CalculoReglas();

  @override
  Widget build(BuildContext context) {
    return _Superficie(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '¿Cuántas reglas necesito?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _crearFicha('Interés', '3 etiquetas'),
              const Text('×'),
              _crearFicha('Infraestructura', '3 etiquetas'),
              const Text('×'),
              _crearFicha('Docente', '3 etiquetas'),
              const Text('='),
              Text(
                '3³ = 27 reglas',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(color: _acento, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _crearFicha(String titulo, String detalle) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(titulo, style: const TextStyle(fontSize: 12)),
        Text(
          detalle,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
      ],
    ),
  );
}

class _PaginaEjemplo extends StatelessWidget {
  const _PaginaEjemplo();

  static const _reglas = [
    ('Medio 0.8', 'Regular 0.4', 'Regular', '0.4'),
    ('Medio 0.8', 'Bueno 0.6', 'Bueno', '0.6'),
    ('Alto 0.2', 'Regular 0.4', 'Bueno', '0.2'),
    ('Alto 0.2', 'Bueno 0.6', 'Bueno', '0.2'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Encabezado(
          titulo: 'Ejemplo: rendimiento del curso',
          texto: 'Para verlo sin 27 filas usamos 2 entradas: interés del estudiante = 7.2 y calidad del docente = 76.',
        ),
        const SizedBox(height: 14),
        const _Paso(numero: '1', titulo: 'Fuzzificar las entradas'),
        _Adaptable(
          children: [
            _TarjetaGrafica(
              titulo: 'Interés = 7.2',
              resultado: 'Medio 80% · Alto 20%',
              color: _acento,
              grafica: _GraficaDifusa(
                variable: _interes,
                marcador: 7.2,
                mostrarLeyenda: true,
              ),
            ),
            _TarjetaGrafica(
              titulo: 'Docente = 76',
              resultado: 'Regular 40% · Bueno 60%',
              color: _acento,
              grafica: _GraficaDifusa(
                variable: _docente,
                marcador: 76,
                mostrarLeyenda: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _Paso(numero: '2', titulo: 'Evaluar reglas con Y = mínimo'),
        _Superficie(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (interes, docente, salida, fuerza) in _reglas)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'SI interés $interes Y docente $docente, entonces $salida',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'min = $fuerza',
                        style: const TextStyle(
                          color: AppColors.johnson,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              const Divider(),
              const Text(
                'Por salida se toma el máximo: Regular = 0.4 y Bueno = 0.6.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _Paso(numero: '3', titulo: 'Recortar, unir y defuzzificar'),
        _TarjetaGrafica(
          titulo: 'Área final del rendimiento',
          resultado: 'Centroide = 75.5',
          detalle: 'El centro de gravedad del área sombreada es la respuesta. Valor calculado en MATLAB con evalfis(fis, [7.2 76]).',
          color: AppColors.success,
          grafica: _GraficaDifusa(
            variable: _rendimiento,
            niveles: const {1: 0.4, 2: 0.6},
            centroide: 75.4751,
            alto: 210,
            mostrarLeyenda: true,
          ),
        ),
      ],
    );
  }
}

class _PaginaMetodos extends StatelessWidget {
  const _PaginaMetodos();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Encabezado(
          titulo: 'Mamdani y Sugeno',
          texto: 'Ambos usan fuzzificación y reglas. La diferencia está en cómo es la salida y cómo se obtiene el número final.',
        ),
        const SizedBox(height: 14),
        _Adaptable(
          children: [
            _TarjetaGrafica(
              titulo: 'Mamdani',
              resultado: 'Salida = área difusa',
              detalle: 'Une las áreas recortadas y calcula su centro de gravedad. Es fácil de interpretar. Este módulo crea sistemas Mamdani.',
              color: _acento,
              grafica: _GraficaDifusa(
                variable: _rendimiento,
                niveles: const {1: 0.4, 2: 0.6},
                centroide: 75.4751,
              ),
            ),
            const _TarjetaGrafica(
              titulo: 'Sugeno',
              resultado: 'Salida = promedio ponderado',
              detalle: 'Cada regla entrega un valor o función. Resultado = suma(fuerza · valor) / suma(fuerza). Es más rápido de calcular.',
              color: AppColors.johnson,
              grafica: SizedBox(
                height: 170,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _PintorSugeno(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _Nota(
          icono: Icons.compare_arrows,
          texto: 'En ambos métodos, Y usa normalmente el mínimo y O el máximo. La curva y el peso de cada regla los define el experto.',
        ),
      ],
    );
  }
}

class _PaginaUso extends StatelessWidget {
  const _PaginaUso();

  static const _pasos = [
    (
      Icons.badge_outlined,
      'Nombra el sistema',
      'Usa letras sin tildes, números y _. Ejemplo: rendimiento_curso.',
    ),
    (
      Icons.tune,
      'Crea entradas y salidas',
      'Define su rango. Cada variable inicia con tres conjuntos editables.',
    ),
    (
      Icons.show_chart,
      'Dibuja los conjuntos',
      'En Editar variable elige triangular (a b c), trapezoidal (a b c d) o gaussiana (sigma centro).',
    ),
    (
      Icons.rule,
      'Escribe las reglas',
      'Elige Y u O y un peso de 0 a 1. «Cualquiera» ignora una entrada.',
    ),
    (
      Icons.save_outlined,
      'Guarda tu trabajo',
      'Guardar diseño JSON permite volver a editarlo aquí.',
    ),
    (
      Icons.file_download_outlined,
      'Exporta el .fis',
      'Es el archivo que entiende MATLAB.',
    ),
    (
      Icons.open_in_new,
      'Ábrelo en MATLAB',
      'Cargar archivo abre tu .fis. Abrir MATLAB inicia el diseñador vacío.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Encabezado(
          titulo: 'Construye tu sistema en 7 pasos',
          texto: 'Aquí diseñas y exportas. La evaluación del sistema se hace en MATLAB con Fuzzy Logic Toolbox.',
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < _pasos.length; i++)
          _FilaPaso(
            numero: i + 1,
            icono: _pasos[i].$1,
            titulo: _pasos[i].$2,
            texto: _pasos[i].$3,
            ultimo: i == _pasos.length - 1,
          ),
        const SizedBox(height: 10),
        const Text(
          'Para evaluar en la ventana de comandos de MATLAB:',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        const _Comando(
          'fis = readfis("mi_sistema.fis");\nfuzzyLogicDesigner(fis);\nsalida = evalfis(fis, [7.2 76]);',
        ),
        const SizedBox(height: 8),
        const _Nota(
          icono: Icons.warning_amber_rounded,
          texto: 'Cargar un JSON o usar un ejemplo reemplaza el diseño actual. Eliminar una variable o conjunto también elimina las reglas que lo usan.',
        ),
      ],
    );
  }
}

class _PaginaComputadora extends StatefulWidget {
  const _PaginaComputadora();

  @override
  State<_PaginaComputadora> createState() => _PaginaComputadoraState();
}

class _PaginaComputadoraState extends State<_PaginaComputadora> {
  int _sistema = 0;

  static const _python = ['py', 'python3', 'python3'];
  static const _rutas = [
    r'$env:MATLAB_CMD = "C:\Program Files\MATLAB\R2026b\bin\matlab.exe"',
    'export MATLAB_CMD="/Applications/MATLAB_R2026b.app"',
    'export MATLAB_CMD="/usr/local/MATLAB/R2026b/bin/matlab"',
  ];

  @override
  Widget build(BuildContext context) {
    final python = _python[_sistema];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Encabezado(
          titulo: 'Preparar cada computadora',
          texto: 'El sitio publicado sirve para diseñar y exportar. Para que los botones abran MATLAB, la app debe correr localmente en la computadora que tiene MATLAB.',
        ),
        const SizedBox(height: 14),
        const _Adaptable(
          columnas: 3,
          children: [
            _Concepto(
              numero: '1',
              titulo: 'MATLAB',
              texto: 'Con Fuzzy Logic Toolbox y licencia activa.',
              icono: Icons.functions,
            ),
            _Concepto(
              numero: '2',
              titulo: 'Python 3',
              texto: 'Versión 3.7 o superior. No necesita paquetes.',
              icono: Icons.terminal,
            ),
            _Concepto(
              numero: '3',
              titulo: 'Flutter',
              texto: 'Para compilar la app dentro del proyecto.',
              icono: Icons.flutter_dash,
            ),
          ],
        ),
        const SizedBox(height: 16),
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 0, label: Text('Windows')),
            ButtonSegment(value: 1, label: Text('macOS')),
            ButtonSegment(value: 2, label: Text('Linux')),
          ],
          selected: {_sistema},
          onSelectionChanged: (valor) => setState(() => _sistema = valor.first),
        ),
        const SizedBox(height: 14),
        const _Paso(numero: 'A', titulo: 'Desde la carpeta del proyecto'),
        _Comando(
          'flutter pub get\nflutter build web --base-href /\n$python tools/local_matlab_server.py',
        ),
        const SizedBox(height: 8),
        const Text(
          'Deja esa terminal abierta y entra a http://localhost:4187. La carpeta del proyecto puede estar en cualquier lugar.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        const _Paso(numero: 'B', titulo: 'Qué cambia según la máquina'),
        _CasoMaquina(
          titulo: 'La terminal dice «MATLAB: no encontrado»',
          texto: 'Normalmente se detecta solo. Si está en otra carpeta, define su ruta y cambia R2026b por tu versión. Después inicia el servidor en esa misma terminal.',
          comando: _rutas[_sistema],
        ),
        _CasoMaquina(
          titulo: 'El puerto 4187 está ocupado',
          texto: 'Usa otro puerto y abre http://localhost:4188.',
          comando: '$python tools/local_matlab_server.py --port 4188',
        ),
        if (_sistema == 0)
          const _CasoMaquina(
            titulo: '«py» no se reconoce',
            texto: 'Reinstala Python con la opción Add python.exe to PATH y abre una terminal nueva.',
          ),
        const _CasoMaquina(
          titulo: 'Cambiaste código Flutter',
          texto: 'Vuelve a compilar antes de iniciar el servidor.',
          comando: 'flutter build web --base-href /',
        ),
        const _CasoMaquina(
          titulo: 'MATLAB pide licencia o no abre el diseñador',
          texto: 'Abre MATLAB una vez a mano, actívalo y ejecuta ver para confirmar que aparece Fuzzy Logic Toolbox.',
        ),
      ],
    );
  }
}

class _CasoMaquina extends StatelessWidget {
  const _CasoMaquina({required this.titulo, required this.texto, this.comando});

  final String titulo;
  final String texto;
  final String? comando;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _Superficie(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(texto, style: const TextStyle(color: AppColors.textSecondary)),
            if (comando != null) ...[
              const SizedBox(height: 8),
              _Comando(comando!),
            ],
          ],
        ),
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.titulo, required this.texto});

  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        titulo,
        style: Theme.of(context).textTheme.headlineSmall
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 6),
      Text(
        texto,
        style: const TextStyle(color: AppColors.textSecondary, height: 1.45),
      ),
    ],
  );
}

class _Superficie extends StatelessWidget {
  const _Superficie({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surfaceMuted.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );
}

class _Adaptable extends StatelessWidget {
  const _Adaptable({required this.children, this.columnas = 2});

  final List<Widget> children;
  final int columnas;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, limites) {
      const separacion = 12.0;
      final cuenta = limites.maxWidth >= 620 ? columnas : 1;
      final ancho = (limites.maxWidth - separacion * (cuenta - 1)) / cuenta;
      return Wrap(
        spacing: separacion,
        runSpacing: separacion,
        children: [
          for (final hijo in children) SizedBox(width: ancho, child: hijo),
        ],
      );
    },
  );
}

class _TarjetaGrafica extends StatelessWidget {
  const _TarjetaGrafica({
    required this.titulo,
    required this.resultado,
    required this.color,
    required this.grafica,
    this.detalle,
  });

  final String titulo;
  final String resultado;
  final Color color;
  final Widget grafica;
  final String? detalle;

  @override
  Widget build(BuildContext context) => _Superficie(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(
          resultado,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        grafica,
        if (detalle != null) ...[
          const SizedBox(height: 8),
          Text(
            detalle!,
            style: const TextStyle(color: AppColors.textMuted, height: 1.35),
          ),
        ],
      ],
    ),
  );
}

class _Concepto extends StatelessWidget {
  const _Concepto({
    required this.numero,
    required this.titulo,
    required this.texto,
    required this.icono,
  });

  final String numero;
  final String titulo;
  final String texto;
  final IconData icono;

  @override
  Widget build(BuildContext context) => _Superficie(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: _acento.withValues(alpha: 0.15),
          child: Icon(icono, color: _acento, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$numero. $titulo',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                texto,
                style: const TextStyle(color: AppColors.textMuted, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Paso extends StatelessWidget {
  const _Paso({required this.numero, required this.titulo});

  final String numero;
  final String titulo;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: _acento,
          child: Text(
            numero,
            style: const TextStyle(
              color: AppColors.background,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            titulo,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ],
    ),
  );
}

class _FilaPaso extends StatelessWidget {
  const _FilaPaso({
    required this.numero,
    required this.icono,
    required this.titulo,
    required this.texto,
    required this.ultimo,
  });

  final int numero;
  final IconData icono;
  final String titulo;
  final String texto;
  final bool ultimo;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: _acento.withValues(alpha: 0.15),
              child: Icon(icono, color: _acento, size: 18),
            ),
            if (!ultimo)
              Expanded(child: Container(width: 2, color: AppColors.border)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$numero. $titulo',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(texto, style: const TextStyle(color: AppColors.textMuted)),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _Nota extends StatelessWidget {
  const _Nota({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.warningSoft.withValues(alpha: 0.75),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, color: AppColors.warningText, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(color: AppColors.warningText, height: 1.35),
          ),
        ),
      ],
    ),
  );
}

class _Comando extends StatelessWidget {
  const _Comando(this.texto);

  final String texto;

  void _copiarComando(BuildContext context) {
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(const SnackBar(content: Text('Comando copiado')));
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4, right: 4),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Expanded(
          child: SelectableText(
            texto,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12.5,
              color: AppColors.successText,
              height: 1.5,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Copiar comando',
          onPressed: () => _copiarComando(context),
          icon: const Icon(Icons.copy, size: 17),
        ),
      ],
    ),
  );
}

class _BarraGrado extends StatelessWidget {
  const _BarraGrado({
    required this.etiqueta,
    required this.valor,
    required this.color,
  });

  final String etiqueta;
  final double valor;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        SizedBox(
          width: 94,
          child: Text(etiqueta, style: TextStyle(color: color, fontSize: 12)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: valor,
              minHeight: 9,
              color: color,
              backgroundColor: AppColors.surfaceMuted,
            ),
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            '${(valor * 100).round()}%',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    ),
  );
}

class _GraficaDifusa extends StatelessWidget {
  const _GraficaDifusa({
    required this.variable,
    this.colores = membershipColors,
    this.marcador,
    this.niveles = const {},
    this.centroide,
    this.unidad = '',
    this.alto = 170,
    this.mostrarLeyenda = false,
  });

  final FuzzyVariable variable;
  final List<Color> colores;
  final double? marcador;
  final Map<int, double> niveles;
  final double? centroide;
  final String unidad;
  final double alto;
  final bool mostrarLeyenda;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Semantics(
        image: true,
        label:
            'Gráfica de ${variable.name} con los conjuntos ${variable.functions.map((f) => f.name).join(', ')}',
        child: SizedBox(
          height: alto,
          child: CustomPaint(
            size: Size.infinite,
            painter: _PintorDifuso(
              variable: variable,
              colores: colores,
              marcador: marcador,
              niveles: niveles,
              centroide: centroide,
              unidad: unidad,
            ),
          ),
        ),
      ),
      if (mostrarLeyenda)
        Wrap(
          spacing: 12,
          runSpacing: 2,
          children: [
            for (var i = 0; i < variable.functions.length; i++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colores[i % colores.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    variable.functions[i].name,
                    style: TextStyle(
                      color: colores[i % colores.length],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
          ],
        ),
    ],
  );
}

void _pintarTexto(
  Canvas canvas,
  String texto,
  Offset posicion, {
  Color color = AppColors.textMuted,
  double centrado = 0,
  bool negrita = false,
}) {
  final pintor = TextPainter(
    text: TextSpan(
      text: texto,
      style: TextStyle(
        color: color,
        fontSize: 10.5,
        fontWeight: negrita ? FontWeight.bold : FontWeight.normal,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  pintor.paint(canvas, posicion - Offset(pintor.width * centrado, 0));
  pintor.dispose();
}

class _PintorDifuso extends CustomPainter {
  const _PintorDifuso({
    required this.variable,
    required this.colores,
    required this.marcador,
    required this.niveles,
    required this.centroide,
    required this.unidad,
  });

  final FuzzyVariable variable;
  final List<Color> colores;
  final double? marcador;
  final Map<int, double> niveles;
  final double? centroide;
  final String unidad;

  double _calcularAgregado(double x) {
    var resultado = 0.0;
    niveles.forEach((indice, nivel) {
      final recorte = variable.functions[indice].membership(x);
      final valor = recorte < nivel ? recorte : nivel;
      if (valor > resultado) resultado = valor;
    });
    return resultado;
  }

  String _formatearNumero(double valor) => valor == valor.roundToDouble()
      ? valor.toStringAsFixed(0)
      : valor.toStringAsFixed(1);

  @override
  void paint(Canvas canvas, Size size) {
    final area = Rect.fromLTRB(28, 18, size.width - 8, size.height - 22);
    double aX(double x) =>
        area.left +
        (x - variable.min) / (variable.max - variable.min) * area.width;
    double aY(double y) => area.bottom - y * area.height;

    final rejilla = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (final fraccion in const [0.0, 0.5, 1.0]) {
      canvas.drawLine(
        Offset(area.left, aY(fraccion)),
        Offset(area.right, aY(fraccion)),
        rejilla,
      );
      _pintarTexto(
        canvas,
        fraccion == 0.5 ? '.5' : fraccion.toStringAsFixed(0),
        Offset(6, aY(fraccion) - 7),
      );
    }
    for (var i = 0; i <= 4; i++) {
      final valor = variable.min + (variable.max - variable.min) * i / 4;
      _pintarTexto(
        canvas,
        _formatearNumero(valor),
        Offset(aX(valor), area.bottom + 5),
        centrado: i == 0 ? 0 : (i == 4 ? 1 : 0.5),
      );
    }
    if (unidad.isNotEmpty) {
      _pintarTexto(canvas, unidad, Offset(area.right, 0), centrado: 1);
    }

    if (niveles.isNotEmpty) {
      final relleno = Path()..moveTo(area.left, area.bottom);
      for (var j = 0; j <= 400; j++) {
        final x = variable.min + (variable.max - variable.min) * j / 400;
        relleno.lineTo(aX(x), aY(_calcularAgregado(x)));
      }
      relleno
        ..lineTo(area.right, area.bottom)
        ..close();
      canvas.drawPath(
        relleno,
        Paint()..color = AppColors.success.withValues(alpha: 0.32),
      );
    }

    for (var i = 0; i < variable.functions.length; i++) {
      final funcion = variable.functions[i];
      final muestras = <double>[
        for (var j = 0; j <= 240; j++)
          variable.min + (variable.max - variable.min) * j / 240,
        ...funcion.parameters.where(
          (p) => p >= variable.min && p <= variable.max,
        ),
      ]..sort();
      final linea = Path();
      for (var j = 0; j < muestras.length; j++) {
        final punto = Offset(
          aX(muestras[j]),
          aY(funcion.membership(muestras[j])),
        );
        if (j == 0) {
          linea.moveTo(punto.dx, punto.dy);
        } else {
          linea.lineTo(punto.dx, punto.dy);
        }
      }
      canvas.drawPath(
        linea,
        Paint()
          ..color = colores[i % colores.length].withValues(
            alpha: niveles.isEmpty || niveles.containsKey(i) ? 1 : 0.35,
          )
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }

    final valorMarcador = marcador;
    if (valorMarcador != null) {
      final x = aX(valorMarcador);
      canvas.drawLine(
        Offset(x, area.top),
        Offset(x, area.bottom),
        Paint()
          ..color = AppColors.text
          ..strokeWidth = 1.5,
      );
      for (var i = 0; i < variable.functions.length; i++) {
        final grado = variable.functions[i].membership(valorMarcador);
        if (grado > 0) {
          canvas.drawCircle(
            Offset(x, aY(grado)),
            4,
            Paint()..color = colores[i % colores.length],
          );
        }
      }
      _pintarTexto(
        canvas,
        _formatearNumero(valorMarcador),
        Offset(x.clamp(area.left + 12, area.right - 12), 1),
        color: AppColors.text,
        centrado: 0.5,
        negrita: true,
      );
    }

    final valorCentroide = centroide;
    if (valorCentroide != null) {
      final x = aX(valorCentroide);
      canvas.drawLine(
        Offset(x, area.top),
        Offset(x, area.bottom),
        Paint()
          ..color = AppColors.success
          ..strokeWidth = 2.5,
      );
      canvas.drawCircle(
        Offset(x, area.bottom),
        5,
        Paint()..color = AppColors.success,
      );
      _pintarTexto(
        canvas,
        'centroide ${valorCentroide.toStringAsFixed(1)}',
        Offset(x, 2),
        color: AppColors.success,
        centrado: 0.5,
        negrita: true,
      );
    }
  }

  @override
  bool shouldRepaint(_PintorDifuso oldDelegate) =>
      oldDelegate.variable != variable ||
      oldDelegate.marcador != marcador ||
      oldDelegate.centroide != centroide;
}

class _PintorSugeno extends CustomPainter {
  const _PintorSugeno();

  @override
  void paint(Canvas canvas, Size size) {
    final area = Rect.fromLTRB(28, 18, size.width - 8, size.height - 22);
    double aX(double x) => area.left + x / 100 * area.width;
    double aY(double y) => area.bottom - y * area.height;
    final base = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(area.left, area.bottom),
      Offset(area.right, area.bottom),
      base,
    );
    canvas.drawLine(
      Offset(area.left, area.top),
      Offset(area.left, area.bottom),
      base,
    );
    _pintarTexto(canvas, '1', Offset(6, area.top - 7));
    _pintarTexto(canvas, '0', Offset(6, area.bottom - 7));
    const reglas = [(60.0, 0.4), (90.0, 0.6)];
    for (final (valor, fuerza) in reglas) {
      final x = aX(valor);
      canvas.drawLine(
        Offset(x, area.bottom),
        Offset(x, aY(fuerza)),
        Paint()
          ..color = AppColors.johnson
          ..strokeWidth = 5,
      );
      _pintarTexto(
        canvas,
        '$fuerza',
        Offset(x, aY(fuerza) - 15),
        color: AppColors.johnson,
        centrado: 0.5,
      );
      _pintarTexto(
        canvas,
        valor.toStringAsFixed(0),
        Offset(x, area.bottom + 5),
        centrado: 0.5,
      );
    }
    const promedio = (60 * 0.4 + 90 * 0.6) / (0.4 + 0.6);
    final x = aX(promedio);
    canvas.drawLine(
      Offset(x, area.top),
      Offset(x, area.bottom),
      Paint()
        ..color = AppColors.success
        ..strokeWidth = 2,
    );
    _pintarTexto(
      canvas,
      'promedio ${promedio.toStringAsFixed(0)}',
      Offset(x, 2),
      color: AppColors.success,
      centrado: 0.5,
      negrita: true,
    );
  }

  @override
  bool shouldRepaint(_PintorSugeno oldDelegate) => false;
}
