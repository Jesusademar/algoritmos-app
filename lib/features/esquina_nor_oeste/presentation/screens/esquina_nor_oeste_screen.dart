import 'dart:math';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/shared/domain/mathematical_procedure.dart';
import 'package:app_grafos/shared/widgets/mathematical_procedure_dialog.dart';
import 'package:app_grafos/features/esquina_nor_oeste/domain/esquina_nor_oeste_problem.dart';
import 'package:app_grafos/features/esquina_nor_oeste/domain/esquina_nor_oeste_solver.dart';
import 'package:app_grafos/features/esquina_nor_oeste/domain/optimization_mode.dart';
import 'package:app_grafos/features/esquina_nor_oeste/presentation/widgets/transport_painter.dart';
import 'package:app_grafos/shared/graph_editor/models/conexion.dart';
import 'package:app_grafos/shared/graph_editor/models/nodo.dart';
import 'package:app_grafos/shared/persistence/graph_document.dart';
import 'package:app_grafos/shared/persistence/graph_document_codec.dart';
import 'package:app_grafos/shared/persistence/graph_file_service.dart';
import 'package:app_grafos/shared/widgets/algorithm_scaffold.dart';
import 'package:app_grafos/shared/widgets/graph_save_dialog.dart';
import 'package:app_grafos/shared/widgets/manual_step.dart';

class EsquinaNorOesteScreen extends StatefulWidget {
  const EsquinaNorOesteScreen({super.key, this.initialDocument});
  final GraphDocument? initialDocument;

  @override
  State<EsquinaNorOesteScreen> createState() => _EsquinaNorOesteScreenState();
}

class _EsquinaNorOesteScreenState extends State<EsquinaNorOesteScreen> {
  static const _documentCodec = GraphDocumentCodec();

  List<Nodo> nodos = [];
  List<Conexion> conexiones = [];
  Map<String, int> ofertas = {};
  Map<String, int> demandas = {};

  Nodo? nodoOrigen;
  Nodo? nodoDragging;
  bool mostrarProceso = false;
  OptimizationMode modoActual = OptimizationMode.minimize;

  num? ultimoCostoTotal;
  MathematicalProcedure? _procedure;
  num ofertaSinUtilizar = 0;
  num demandaPendiente = 0;
  List<String> detalleAsignaciones = [];
  String? errorCalculo;
  static const _solver = EsquinaNorOesteSolver();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDocument;
    if (initial == null) return;
    final document = _documentCodec.decode(_documentCodec.encode(initial));
    nodos = document.nodes.toList();
    conexiones = document.connections.toList();
    nombreArchivoController.text = document.name;
    ofertas = Map<String, int>.from(document.metadata['ofertas'] ?? {});
    demandas = Map<String, int>.from(document.metadata['demandas'] ?? {});
    mostrarProceso = true;
  }

  void _invalidarResultado() {
    ultimoCostoTotal = null;
    _procedure = null;
    ofertaSinUtilizar = 0;
    demandaPendiente = 0;
    detalleAsignaciones = [];
    errorCalculo = null;
  }

  final nombreController = TextEditingController();
  final costoController = TextEditingController();
  final nombreArchivoController = TextEditingController(
    text: 'transporte_optimizado',
  );

  final List<Color> _paletaColores = [
    AppColors.success,
    const Color(0xFFEF4444),
    AppColors.success,
    const Color(0xFFF59E0B),
    const Color(0xFFEC4899),
    const Color(0xFF3B82F6),
    const Color(0xFF8B5CF6),
    const Color(0xFF14B8A6),
    const Color(0xFFF97316),
  ];

  void limpiarTodo() {
    setState(() {
      nodos.clear();
      conexiones.clear();
      ofertas.clear();
      demandas.clear();
      nodoOrigen = null;
      nodoDragging = null;
      ultimoCostoTotal = null;
      _procedure = null;
      detalleAsignaciones.clear();
      errorCalculo = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('🗑️ Lienzo y datos limpiados.'),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void mostrarManualAyuda() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(
              Icons.help_outline_rounded,
              color: AppColors.success,
              size: 24,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Manual de Uso - Optimización',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.text,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          height: 440,
          child: ListView(
            children: const [
              ManualStep(
                numero: '1',
                titulo: 'Crear Nodos',
                descripcion: 'Haz clic izquierdo para crear Orígenes (izq) y Destinos (der).',
              ),
              ManualStep(
                numero: '2',
                titulo: 'Conectar Costos',
                descripcion: 'Conecta nodos y define sus costos unitarios.',
              ),
              ManualStep(
                numero: '3',
                titulo: 'Gestionar (Clic Derecho)',
                descripcion: 'Usa el clic derecho sobre nodos o conexiones para editar sus valores o eliminarlos.',
              ),
              ManualStep(
                numero: '4',
                titulo: 'Optimizar',
                descripcion: 'Elige minimizar o maximizar. Esquina noroeste genera la solución inicial; después se optimiza respetando la oferta y la demanda. Si las cantidades totales difieren, se calcula directamente con lo disponible.',
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '¡Entendido!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> mostrarGuardarJson() async {
    final name = nombreArchivoController.text.trim().isEmpty
        ? 'transporte'
        : nombreArchivoController.text;
    final savedName = await showGraphSaveDialog(
      context,
      GraphDocument(
        name: name,
        nodes: nodos,
        connections: conexiones,
        metadata: {'ofertas': ofertas, 'demandas': demandas},
      ),
    );
    if (savedName != null && mounted) nombreArchivoController.text = savedName;
  }

  Future<void> cargarArchivoJson() async {
    try {
      const typeGroup = GraphFileService.jsonType;
      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) return;

      final contenido = await file.readAsString();
      final document = _documentCodec.decode(contenido);

      if (!mounted) return;
      setState(() {
        nombreArchivoController.text = document.name;
        nodos = document.nodes.toList();
        conexiones = document.connections.toList();
        if (document.metadata['ofertas'] != null) {
          ofertas = Map<String, int>.from(document.metadata['ofertas']);
        }
        if (document.metadata['demandas'] != null) {
          demandas = Map<String, int>.from(document.metadata['demandas']);
        }
        nodoOrigen = null;
        ultimoCostoTotal = null;
        _procedure = null;
        detalleAsignaciones.clear();
        errorCalculo = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✨ Archivo cargado correctamente.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al leer el archivo JSON.')),
      );
    }
  }

  void agregarNodo(Offset posicion) {
    nombreController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.add_circle_outline_rounded, color: AppColors.success),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Nuevo Nodo',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ),
          ],
        ),
        content: TextField(
          controller: nombreController,
          autofocus: true,
          style: const TextStyle(color: AppColors.text),
          decoration: InputDecoration(
            labelText: 'Nombre (ej. O1, D1...)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            filled: true,
            fillColor: AppColors.background,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () {
              if (nombreController.text.isNotEmpty) {
                final id = 'n${DateTime.now().millisecondsSinceEpoch}';
                setState(() {
                  _invalidarResultado();
                  nodos.add(
                    Nodo(
                      id: id,
                      nombre: nombreController.text,
                      posicion: posicion,
                    ),
                  );
                  final origenes = obtenerOrigenes();
                  if (origenes.any((o) => o.id == id)) {
                    ofertas[id] = 10;
                  } else {
                    demandas[id] = 10;
                  }
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Crear Nodo'),
          ),
        ],
      ),
    );
  }

  void gestionarNodo(Nodo nodo) {
    nombreController.text = nodo.nombre;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            const Icon(Icons.edit_rounded, color: AppColors.success),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Gestionar Nodo: ${nodo.nombre}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.text,
                ),
              ),
            ),
          ],
        ),
        content: TextField(
          controller: nombreController,
          autofocus: true,
          style: const TextStyle(color: AppColors.text),
          decoration: InputDecoration(
            labelText: 'Nuevo nombre',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              setState(() {
                _invalidarResultado();
                nodos.removeWhere((n) => n.id == nodo.id);
                conexiones.removeWhere(
                  (c) => c.nodoA == nodo.id || c.nodoB == nodo.id,
                );
                ofertas.remove(nodo.id);
                demandas.remove(nodo.id);
                if (nodoOrigen?.id == nodo.id) nodoOrigen = null;
              });
              Navigator.pop(context);
            },
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Eliminar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () {
              if (nombreController.text.isNotEmpty) {
                setState(() {
                  _invalidarResultado();
                  final index = nodos.indexWhere((n) => n.id == nodo.id);
                  if (index != -1) {
                    nodos[index] = Nodo(
                      id: nodo.id,
                      nombre: nombreController.text,
                      posicion: nodo.posicion,
                    );
                  }
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void gestionarConexion(Conexion conexion) {
    costoController.text = conexion.peso.toString();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.alt_route_rounded, color: AppColors.success),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Gestionar Conexión / Costo',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.text,
                ),
              ),
            ),
          ],
        ),
        content: TextField(
          controller: costoController,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: AppColors.text),
          decoration: InputDecoration(
            labelText: 'Costo unitario',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              setState(() {
                _invalidarResultado();
                conexiones.removeWhere(
                  (c) => c.nodoA == conexion.nodoA && c.nodoB == conexion.nodoB,
                );
              });
              Navigator.pop(context);
            },
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Eliminar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () {
              final nuevoCosto = int.tryParse(costoController.text);
              if (nuevoCosto != null) {
                setState(() {
                  _invalidarResultado();
                  final index = conexiones.indexWhere(
                    (c) =>
                        c.nodoA == conexion.nodoA && c.nodoB == conexion.nodoB,
                  );
                  if (index != -1) {
                    conexiones[index] = Conexion(
                      nodoA: conexion.nodoA,
                      nodoB: conexion.nodoB,
                      peso: nuevoCosto,
                      tipo: conexion.tipo,
                      color: conexion.color,
                    );
                  }
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  void conectarNodos(Nodo nodoDestino) {
    if (nodoOrigen == null) return;
    final nodoOrigenTemp = nodoOrigen!;
    setState(() => nodoOrigen = null);
    costoController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.surface,
        title: Text(
          'Costo Unitario: ${nodoOrigenTemp.nombre} ➔ ${nodoDestino.nombre}',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        content: TextField(
          controller: costoController,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: AppColors.text),
          decoration: InputDecoration(
            labelText: 'Costo unitario',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () {
              final costo = int.tryParse(costoController.text) ?? 1;
              final colorAleatorio =
                  _paletaColores[Random().nextInt(_paletaColores.length)];
              setState(() {
                _invalidarResultado();
                conexiones.removeWhere(
                  (c) =>
                      (c.nodoA == nodoOrigenTemp.id &&
                      c.nodoB == nodoDestino.id),
                );
                conexiones.add(
                  Conexion(
                    nodoA: nodoOrigenTemp.id,
                    nodoB: nodoDestino.id,
                    peso: costo,
                    tipo: 'unidireccional',
                    color: colorAleatorio,
                  ),
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Guardar Costo'),
          ),
        ],
      ),
    );
  }

  List<Nodo> obtenerOrigenes() {
    if (nodos.isEmpty) return [];
    double promedioX =
        nodos.map((n) => n.posicion.dx).reduce((a, b) => a + b) / nodos.length;
    List<Nodo> origenes = nodos
        .where((n) => n.posicion.dx <= promedioX)
        .toList();
    if (origenes.isEmpty) origenes = [nodos.first];
    return origenes;
  }

  List<Nodo> obtenerDestinos() {
    if (nodos.isEmpty) return [];
    double promedioX =
        nodos.map((n) => n.posicion.dx).reduce((a, b) => a + b) / nodos.length;
    List<Nodo> destinos = nodos
        .where((n) => n.posicion.dx > promedioX)
        .toList();
    if (destinos.isEmpty) {
      destinos = nodos.where((n) => !obtenerOrigenes().contains(n)).toList();
    }
    return destinos;
  }

  void _mostrarErrorCalculo(String mensaje) {
    setState(() {
      errorCalculo = mensaje;
      ultimoCostoTotal = null;
      _procedure = null;
      detalleAsignaciones = [];
      mostrarProceso = true;
    });
  }

  void calcularSolucionOptimizada() {
    final origenes = obtenerOrigenes();
    final destinos = obtenerDestinos();
    if (origenes.isEmpty || destinos.isEmpty) {
      _mostrarErrorCalculo('Agrega al menos un origen y un destino.');
      return;
    }
    final problem = EsquinaNorOesteProblem(
      origins: [
        for (final nodo in origenes)
          EsquinaNorOesteItem(
            id: nodo.id,
            label: nodo.nombre,
            supply: ofertas[nodo.id] ?? 10,
          ),
      ],
      destinations: [
        for (final nodo in destinos)
          EsquinaNorOesteItem(
            id: nodo.id,
            label: nodo.nombre,
            demand: demandas[nodo.id] ?? 10,
          ),
      ],
      costs: [
        for (final origen in origenes)
          for (final destino in destinos)
            for (final conexion in conexiones)
              if (conexion.nodoA == origen.id && conexion.nodoB == destino.id)
                EsquinaNorOesteCost(
                  originId: origen.id,
                  destinationId: destino.id,
                  value: conexion.peso,
                ),
      ],
      mode: modoActual,
    );
    if (problem.origins.any((o) => o.supply < 0) ||
        problem.destinations.any((d) => d.demand < 0)) {
      _mostrarErrorCalculo(
        'La oferta y la demanda deben ser cantidades no negativas.',
      );
      return;
    }
    final resultado = _solver.solve(problem, includeProcedure: true);
    if (resultado == null) {
      _mostrarErrorCalculo(
        'Las rutas disponibles no permiten satisfacer toda '
        'la oferta y demanda. Revisa las conexiones.',
      );
      return;
    }
    setState(() {
      errorCalculo = null;
      ultimoCostoTotal = resultado.totalCost;
      _procedure = resultado.procedure;
      ofertaSinUtilizar = resultado.unshippedSupply;
      demandaPendiente = resultado.unmetDemand;
      detalleAsignaciones = [
        for (final asignacion in resultado.assignments)
          '${asignacion.origin.label} ➔ ${asignacion.destination.label} '
              '(Cant: ${asignacion.quantity}, Costo Unit: ${asignacion.unitCost})',
      ];
      mostrarProceso = true;
    });
  }

  Nodo? obtenerNodoEnPosicion(Offset posicion) {
    for (var nodo in nodos) {
      if ((nodo.posicion - posicion).distance < 30) return nodo;
    }
    return null;
  }

  Conexion? obtenerConexionEnPosicion(Offset posicion) {
    for (var conexion in conexiones) {
      try {
        final nodoA = nodos.firstWhere((n) => n.id == conexion.nodoA);
        final nodoB = nodos.firstWhere((n) => n.id == conexion.nodoB);
        final centro = Offset(
          (nodoA.posicion.dx + nodoB.posicion.dx) / 2,
          (nodoA.posicion.dy + nodoB.posicion.dy) / 2,
        );
        if ((centro - posicion).distance < 25) return conexion;
      } catch (_) {}
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlgorithmScaffold(
      accent: AppColors.success,
      title: 'Esquina Noroeste',
      icon: Icons.local_shipping_rounded,
      actions: [
        IconButton(
          onPressed: () => setState(() => mostrarProceso = !mostrarProceso),
          icon: Icon(
            mostrarProceso ? Icons.close_rounded : Icons.calculate_rounded,
            color: AppColors.success,
          ),
          tooltip: mostrarProceso ? 'Ocultar matriz' : 'Mostrar matriz',
        ),
        PopupMenuButton<String>(
          tooltip: 'Más opciones',
          onSelected: (value) {
            if (value == 'ayuda') mostrarManualAyuda();
            if (value == 'guardar') mostrarGuardarJson();
            if (value == 'cargar') cargarArchivoJson();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'guardar',
              child: ListTile(
                leading: Icon(Icons.save_alt_rounded),
                title: Text('Guardar'),
              ),
            ),
            PopupMenuItem(
              value: 'cargar',
              child: ListTile(
                leading: Icon(Icons.folder_open_rounded),
                title: Text('Cargar'),
              ),
            ),
            PopupMenuItem(
              value: 'ayuda',
              child: ListTile(
                leading: Icon(Icons.help_outline_rounded),
                title: Text('Manual de uso'),
              ),
            ),
          ],
        ),
      ],
      body: AlgorithmWorkspace(
        isEmpty: nodos.isEmpty,
        accent: AppColors.success,
        emptyIcon: Icons.local_shipping_outlined,
        emptyTitle: 'Define orígenes y destinos',
        canvas: Stack(
          children: [
            GestureDetector(
              onTapDown: (details) {
                final nodo = obtenerNodoEnPosicion(details.localPosition);
                if (nodo != null) {
                  if (nodoOrigen == null) {
                    setState(() => nodoOrigen = nodo);
                  } else {
                    conectarNodos(nodo);
                  }
                } else {
                  agregarNodo(details.localPosition);
                }
              },
              onSecondaryTapDown: (details) {
                final conexionTocada = obtenerConexionEnPosicion(
                  details.localPosition,
                );
                if (conexionTocada != null) {
                  gestionarConexion(conexionTocada);
                  return;
                }
                final nodoTocado = obtenerNodoEnPosicion(details.localPosition);
                if (nodoTocado != null) gestionarNodo(nodoTocado);
              },
              onPanStart: (details) {
                final nodo = obtenerNodoEnPosicion(details.localPosition);
                if (nodo != null) nodoDragging = nodo;
              },
              onPanUpdate: (details) {
                if (nodoDragging != null) {
                  setState(() {
                    nodoDragging!.posicion += details.delta;
                    _invalidarResultado();
                  });
                }
              },
              onPanEnd: (_) => nodoDragging = null,
              child: CustomPaint(
                painter: NorOestePainter(
                  nodos,
                  conexiones,
                  nodoOrigen,
                  ofertas,
                  demandas,
                ),
                size: Size.infinite,
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: AlgorithmCanvasControls(
                onClear: limpiarTodo,
                nodeCount: nodos.length,
                connectionCount: conexiones.length,
              ),
            ),
          ],
        ),
        panel: mostrarProceso
            ? Container(
                color: AppColors.surface,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text(
                      'Matriz de Transporte y Ofertas',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    buildMatrizTransporteWidget(),
                    const SizedBox(height: 16),
                    const Text(
                      'Modo de Optimización',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: SegmentedButton<OptimizationMode>(
                        segments: const [
                          ButtonSegment(
                            value: OptimizationMode.minimize,
                            label: Text('Minimizar'),
                            icon: Icon(Icons.arrow_downward_rounded, size: 16),
                          ),
                          ButtonSegment(
                            value: OptimizationMode.maximize,
                            label: Text('Maximizar'),
                            icon: Icon(Icons.arrow_upward_rounded, size: 16),
                          ),
                        ],
                        selected: {modoActual},
                        onSelectionChanged:
                            (Set<OptimizationMode> newSelection) {
                              setState(() {
                                modoActual = newSelection.first;
                                _invalidarResultado();
                              });
                            },
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: calcularSolucionOptimizada,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(
                        modoActual == OptimizationMode.minimize
                            ? 'Calcular mínimo'
                            : 'Calcular máximo',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _procedure == null
                          ? null
                          : () => showMathematicalProcedure(
                              context,
                              _procedure!,
                              accent: AppColors.success,
                            ),
                      icon: const Icon(Icons.functions_rounded, size: 18),
                      label: const Text('Ver procedimiento matemático'),
                    ),
                    const SizedBox(height: 20),
                    if (errorCalculo != null) ...[
                      Text(
                        errorCalculo!,
                        style: const TextStyle(
                          color: AppColors.warningText,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (ultimoCostoTotal != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.successSoft,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.success,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              modoActual == OptimizationMode.minimize
                                  ? 'Resultado Óptimo (Min)'
                                  : 'Resultado Óptimo (Max)',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.successText,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Valor Total: $ultimoCostoTotal',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.successText,
                              ),
                            ),
                            if (ofertaSinUtilizar > 0)
                              Text(
                                'Oferta sin utilizar: $ofertaSinUtilizar',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            if (demandaPendiente > 0)
                              Text(
                                'Demanda pendiente: $demandaPendiente',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            const SizedBox(height: 10),
                            const Text(
                              'Asignaciones Optimizadas:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppColors.text,
                              ),
                            ),
                            ...detalleAsignaciones.map(
                              (asig) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2.0,
                                ),
                                child: Text(
                                  '• $asig',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              )
            : null,
      ),
    );
  }

  Widget buildMatrizTransporteWidget() {
    final origenes = obtenerOrigenes();
    final destinos = obtenerDestinos();
    if (origenes.isEmpty || destinos.isEmpty) {
      return const Text(
        'Agrega orígenes y destinos en el lienzo.',
        style: TextStyle(color: AppColors.textMuted),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: max(
          56,
          56 * MediaQuery.textScalerOf(context).scale(1),
        ),
        headingRowColor: WidgetStateProperty.all(AppColors.successSoft),
        columns: [
          const DataColumn(
            label: Text(
              'Origen \\ Dest',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
          ),
          ...destinos.map(
            (d) => DataColumn(
              label: SizedBox(
                width: 95,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      height: 30,
                      child: TextField(
                        controller:
                            TextEditingController(
                                text: '${demandas[d.id] ?? 10}',
                              )
                              ..selection = TextSelection.collapsed(
                                offset: '${demandas[d.id] ?? 10}'.length,
                              ),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.text,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 6,
                          ),
                          border: OutlineInputBorder(),
                          labelText: 'Dem',
                          labelStyle: TextStyle(fontSize: 9),
                        ),
                        onChanged: (val) {
                          final numVal = int.tryParse(val);
                          if (numVal != null) {
                            demandas[d.id] = numVal;
                            if (ultimoCostoTotal != null ||
                                errorCalculo != null) {
                              setState(_invalidarResultado);
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const DataColumn(
            label: Text(
              'Oferta',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
          ),
        ],
        rows: origenes.map((o) {
          return DataRow(
            cells: [
              DataCell(
                Text(
                  o.nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ),
              ...destinos.map((d) {
                final c = conexiones.firstWhere(
                  (con) => con.nodoA == o.id && con.nodoB == d.id,
                  orElse: () => Conexion(
                    nodoA: '',
                    nodoB: '',
                    peso: 0,
                    tipo: '',
                    color: Colors.transparent,
                  ),
                );
                return DataCell(
                  Text(
                    c.nodoA.isNotEmpty ? '${c.peso}' : '—',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }),
              DataCell(
                SizedBox(
                  width: 75,
                  height: 32,
                  child: TextField(
                    controller:
                        TextEditingController(text: '${ofertas[o.id] ?? 10}')
                          ..selection = TextSelection.collapsed(
                            offset: '${ofertas[o.id] ?? 10}'.length,
                          ),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 6,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      final numVal = int.tryParse(val);
                      if (numVal != null) {
                        ofertas[o.id] = numVal;
                        if (ultimoCostoTotal != null || errorCalculo != null) {
                          setState(_invalidarResultado);
                        }
                      }
                    },
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
