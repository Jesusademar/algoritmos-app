import 'dart:math';

import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/features/johnson/domain/activity_network_problem.dart';
import 'package:app_grafos/features/johnson/domain/activity_network_rules.dart';
import 'package:app_grafos/features/johnson/domain/activity_network_result.dart';
import 'package:app_grafos/features/johnson/domain/activity_network_solver.dart';
import 'package:app_grafos/features/johnson/presentation/widgets/activity_network_painter.dart';
import 'package:app_grafos/features/johnson/presentation/widgets/activity_network_panel.dart';
import 'package:app_grafos/shared/graph_editor/models/conexion.dart';
import 'package:app_grafos/shared/graph_editor/models/nodo.dart';
import 'package:app_grafos/shared/help/algorithm_manuals.dart';
import 'package:app_grafos/shared/persistence/graph_document.dart';
import 'package:app_grafos/shared/persistence/graph_document_codec.dart';
import 'package:app_grafos/shared/persistence/graph_file_service.dart';
import 'package:app_grafos/shared/widgets/algorithm_manual_dialog.dart';
import 'package:app_grafos/shared/widgets/algorithm_scaffold.dart';
import 'package:app_grafos/shared/graph_editor/widgets/graph_canvas_viewport.dart';
import 'package:app_grafos/shared/widgets/graph_save_dialog.dart';

class JohnsonScreen extends StatefulWidget {
  const JohnsonScreen({
    super.key,
    this.initialDocument,
    this.fileService = const GraphFileService(),
  });
  final GraphDocument? initialDocument;
  final GraphFileService fileService;

  @override
  State<JohnsonScreen> createState() => _JohnsonScreenState();
}

class _JohnsonScreenState extends State<JohnsonScreen> {
  static const _solver = ActivityNetworkSolver();
  static const _documentCodec = GraphDocumentCodec();

  List<Nodo> nodos = [];
  List<Conexion> conexiones = [];

  Nodo? nodoOrigenParaConexion;
  Nodo? nodoDragging;
  bool mostrarProceso = false;

  Map<String, int> tiemposTempranos = {};
  Map<String, int> tiemposTardios = {};
  Map<String, int> holguras = {};
  Map<String, int> holgurasAristas = {};
  Set<String> aristasCriticas = {};
  int proyectoDuracionTotal = 0;

  bool esMaximizar = true;

  String? nodoInicialSeleccionadoId;

  final nombreController = TextEditingController();
  final pesoAristaController = TextEditingController();
  final nombreArchivoController = TextEditingController(
    text: 'red_actividades',
  );

  final List<Color> paletaColores = [
    const Color(0xFF3B82F6), // Azul
    const Color(0xFFE67E22), // Naranja
    const Color(0xFF2ECC71), // Verde
    const Color(0xFF9B59B6), // Morado
    const Color(0xFFE74C3C), // Rojo
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDocument;
    if (initial == null) return;
    final document = _documentCodec.decode(_documentCodec.encode(initial));
    _aplicarDocumento(document);
  }

  void _aplicarDocumento(GraphDocument document) {
    nodos = document.nodes.toList();
    for (final nodo in nodos) {
      nodo.valorInicial = 0;
    }
    conexiones = document.connections.toList();
    nombreArchivoController.text = document.name;
    final inicio = document.metadata['nodoInicialSeleccionadoId'];
    nodoInicialSeleccionadoId = nodos.any((nodo) => nodo.id == inicio)
        ? inicio as String
        : (nodos.isEmpty ? null : nodos.first.id);
    esMaximizar = document.metadata['esMaximizar'] ?? true;
  }

  @override
  void dispose() {
    nombreController.dispose();
    pesoAristaController.dispose();
    nombreArchivoController.dispose();
    super.dispose();
  }

  void limpiarTodo() {
    setState(() {
      nodos.clear();
      conexiones.clear();
      tiemposTempranos.clear();
      tiemposTardios.clear();
      holguras.clear();
      holgurasAristas.clear();
      aristasCriticas.clear();
      nodoOrigenParaConexion = null;
      nodoDragging = null;
      proyectoDuracionTotal = 0;
      mostrarProceso = false;
      nodoInicialSeleccionadoId = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('🗑️ Lienzo y datos limpiados correctamente.'),
        backgroundColor: AppColors.errorSoft,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _invalidarResultado() {
    tiemposTempranos.clear();
    tiemposTardios.clear();
    holguras.clear();
    holgurasAristas.clear();
    aristasCriticas.clear();
    proyectoDuracionTotal = 0;
    mostrarProceso = false;
  }

  void _actualizarRed(VoidCallback change) {
    final recalcular = mostrarProceso;
    setState(() {
      change();
      _invalidarResultado();
    });
    if (recalcular && nodos.isNotEmpty) {
      calcularRedActividades(notificar: false);
    }
  }

  void mostrarManualAyuda() {
    showAlgorithmManual(
      context,
      AlgorithmManual.johnson,
      accent: AppColors.johnson,
    );
  }

  Future<void> mostrarGuardarJson() async {
    final name = nombreArchivoController.text.trim().isEmpty
        ? 'red_actividades'
        : nombreArchivoController.text;
    final savedName = await showGraphSaveDialog(
      context,
      GraphDocument(
        name: name,
        nodes: nodos,
        connections: conexiones,
        metadata: {
          'esMaximizar': esMaximizar,
          'nodoInicialSeleccionadoId': nodoInicialSeleccionadoId,
          'valorInicialNodo': 0,
        },
      ),
      service: widget.fileService,
    );
    if (savedName != null && mounted) nombreArchivoController.text = savedName;
  }

  Future<void> cargarArchivoJson() async {
    try {
      final contenido = await widget.fileService.readJson();
      if (contenido == null) return;
      final document = _documentCodec.decode(contenido);

      if (!mounted) return;

      final error = _networkRules.networkError(
        _aristasDe(document.connections),
      );
      if (error != null ||
          document.connections.any((c) => c.tipo == 'bidireccional')) {
        _mostrarErrorConexion(
          error ?? 'Solo se permite un sentido entre dos nodos.',
        );
        return;
      }

      setState(() {
        _aplicarDocumento(document);

        nodoOrigenParaConexion = null;
        tiemposTempranos.clear();
        tiemposTardios.clear();
        holguras.clear();
        holgurasAristas.clear();
        aristasCriticas.clear();
        proyectoDuracionTotal = 0;
        mostrarProceso = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✨ ¡Archivo cargado exitosamente al lienzo!'),
          backgroundColor: AppColors.successSoft,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al leer el archivo JSON.')),
      );
    }
  }

  void agregarNodo(Offset posicion) {
    nombreController.clear();
    bool esPrimero = nodos.isEmpty;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Icon(
              esPrimero ? Icons.star_rounded : Icons.add_circle_outline_rounded,
              color: AppColors.johnson,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                esPrimero ? 'Nuevo Nodo Raíz (Inicial)' : 'Nuevo Nodo (Evento)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              autofocus: true,
              style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                labelText: 'Nombre del nodo (ej. 1, a, Inicio...)',
                labelStyle: const TextStyle(color: AppColors.textMuted),
                prefixIcon: const Icon(
                  Icons.radio_button_checked,
                  color: AppColors.johnson,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.johnson,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: AppColors.background,
              ),
            ),
            if (esPrimero) ...[
              const SizedBox(height: 16),
              const Text(
                'Tiempo inicial: 0',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.buttonFill(AppColors.johnson),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              if (nombreController.text.isNotEmpty) {
                _actualizarRed(() {
                  final nuevoId = 'n${DateTime.now().millisecondsSinceEpoch}';
                  nodos.add(
                    Nodo(
                      id: nuevoId,
                      nombre: nombreController.text,
                      posicion: posicion,
                    ),
                  );
                  if (esPrimero) {
                    nodoInicialSeleccionadoId = nuevoId;
                  }
                });
                Navigator.pop(context);
              }
            },
            child: const Text(
              'Crear',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void mostrarOpcionesNodo(Nodo nodo) {
    nombreController.text = nodo.nombre;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            const Icon(Icons.settings_outlined, color: AppColors.johnson),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Nodo: ${nodo.nombre}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ),
          ],
        ),
        content: TextField(
          controller: nombreController,
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            labelText: 'Nuevo nombre',
            labelStyle: const TextStyle(color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.edit, color: AppColors.johnson),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            filled: true,
            fillColor: AppColors.background,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _actualizarRed(() {
                conexiones.removeWhere(
                  (c) => c.nodoA == nodo.id || c.nodoB == nodo.id,
                );
                nodos.remove(nodo);
                if (nodoOrigenParaConexion?.id == nodo.id) {
                  nodoOrigenParaConexion = null;
                }
                if (nodoInicialSeleccionadoId == nodo.id) {
                  nodoInicialSeleccionadoId = nodos.isNotEmpty
                      ? nodos.first.id
                      : null;
                }
              });
              Navigator.pop(context);
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.buttonFill(AppColors.johnson),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              _actualizarRed(() {
                nodo.nombre = nombreController.text;
              });
              Navigator.pop(context);
            },
            child: const Text(
              'Guardar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  static const _networkRules = ActivityNetworkRules();

  List<ActivityEdge> _aristasDe(Iterable<Conexion> connections) => [
    for (final connection in connections)
      ActivityEdge(
        sourceId: connection.nodoA,
        targetId: connection.nodoB,
        duration: connection.peso,
      ),
  ];

  void _mostrarErrorConexion(String mensaje) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  bool _conexionPermitida(Nodo origen, Nodo destino) {
    final error = _networkRules.connectionError(
      origen.id,
      destino.id,
      _aristasDe(conexiones),
    );
    if (error == null) return true;
    _mostrarErrorConexion(error);
    return false;
  }

  void crearConexion(Nodo origen, Nodo destino) {
    if (!_conexionPermitida(origen, destino)) return;
    pesoAristaController.clear();
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duración de Actividad'),
        scrollable: true,
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${origen.nombre} → ${destino.nombre}',
                style: const TextStyle(
                  color: AppColors.johnson,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: pesoAristaController,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                ),
                autofocus: true,
                validator: (text) => int.tryParse(text?.trim() ?? '') == null
                    ? 'Ingresa un peso entero válido.'
                    : null,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: const InputDecoration(
                  labelText: 'Valor / Peso de la línea',
                  prefixIcon: Icon(Icons.line_weight_rounded),
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
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.buttonFill(AppColors.johnson),
            ),
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              if (!_conexionPermitida(origen, destino)) return;
              final peso = int.parse(pesoAristaController.text.trim());
              final color =
                  paletaColores[Random().nextInt(paletaColores.length)];
              _actualizarRed(() {
                conexiones.removeWhere(
                  (c) => c.nodoA == origen.id && c.nodoB == destino.id,
                );
                conexiones.add(
                  Conexion(
                    nodoA: origen.id,
                    nodoB: destino.id,
                    peso: peso,
                    tipo: 'normal',
                    color: color,
                  ),
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Conectar'),
          ),
        ],
      ),
    );
  }

  void editarConexion(Conexion conexion) {
    pesoAristaController.text = conexion.peso.toString();
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.surface,
        title: const Text(
          'Editar Duración de Línea',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            validator: (text) => int.tryParse(text?.trim() ?? '') == null
                ? 'Ingresa un peso entero válido.'
                : null,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            controller: pesoAristaController,
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            autofocus: true,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              labelText: 'Nuevo Peso',
              labelStyle: const TextStyle(color: AppColors.textMuted),
              prefixIcon: const Icon(
                Icons.line_weight_rounded,
                color: AppColors.johnson,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              filled: true,
              fillColor: AppColors.background,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _actualizarRed(() => conexiones.remove(conexion));
              Navigator.pop(context);
            },
            child: const Text(
              'Eliminar Línea',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.buttonFill(AppColors.johnson),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final nuevoPeso = int.parse(pesoAristaController.text.trim());
              _actualizarRed(() {
                final index = conexiones.indexOf(conexion);
                if (index != -1) {
                  conexiones[index] = Conexion(
                    nodoA: conexion.nodoA,
                    nodoB: conexion.nodoB,
                    peso: nuevoPeso,
                    tipo: conexion.tipo,
                    color: conexion.color,
                  );
                }
              });
              Navigator.pop(context);
            },
            child: const Text(
              'Guardar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void calcularRedActividades({bool notificar = true}) {
    if (nodos.isEmpty) return;
    final error = _networkRules.networkError(_aristasDe(conexiones));
    if (error != null) {
      setState(_invalidarResultado);
      _mostrarErrorConexion(error);
      return;
    }

    if (nodoInicialSeleccionadoId == null && nodos.isNotEmpty) {
      nodoInicialSeleccionadoId = nodos.first.id;
    }

    final problema = ActivityNetworkProblem(
      nodeIds: nodos.map((nodo) => nodo.id).toList(),
      edges: conexiones
          .map(
            (conexion) => ActivityEdge(
              sourceId: conexion.nodoA,
              targetId: conexion.nodoB,
              duration: conexion.peso,
            ),
          )
          .toList(),
      startNodeId: nodoInicialSeleccionadoId,
      mode: esMaximizar
          ? NetworkOptimizationMode.maximize
          : NetworkOptimizationMode.minimize,
    );
    final ActivityNetworkResult resultado;
    try {
      resultado = _solver.solve(problema);
    } on ArgumentError catch (error) {
      setState(_invalidarResultado);
      _mostrarErrorConexion(error.message.toString());
      return;
    }

    setState(() {
      tiemposTempranos = Map.of(resultado.earlyTimes);
      tiemposTardios = Map.of(resultado.lateTimes);
      holguras = Map.of(resultado.slacks);
      holgurasAristas = Map.of(resultado.edgeSlacks);
      aristasCriticas = Set.of(resultado.criticalEdgeIds);
      proyectoDuracionTotal = resultado.totalDuration;
      mostrarProceso = true;
    });

    if (!notificar) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✨ ¡Red calculada (${esMaximizar ? "Maximizar" : "Minimizar"}) con éxito! Valor: $proyectoDuracionTotal.',
        ),
        backgroundColor: AppColors.successSoft,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _seleccionarModo(NetworkOptimizationMode mode) {
    setState(() => esMaximizar = mode == NetworkOptimizationMode.maximize);
    if (mostrarProceso) {
      calcularRedActividades(notificar: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlgorithmScaffold(
      accent: AppColors.johnson,
      title: 'Algoritmo de Johnson',
      icon: Icons.account_tree_rounded,
      actions: [
        IconButton(
          tooltip: 'Calcular',
          onPressed: calcularRedActividades,
          icon: const Icon(Icons.play_arrow_rounded),
        ),
        PopupMenuButton<String>(
          tooltip: 'Más opciones',
          onSelected: (value) {
            switch (value) {
              case 'guardar':
                mostrarGuardarJson();
              case 'cargar':
                cargarArchivoJson();
              case 'ayuda':
                mostrarManualAyuda();
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'guardar', child: Text('Guardar')),
            PopupMenuItem(value: 'cargar', child: Text('Cargar')),
            PopupMenuItem(value: 'ayuda', child: Text('Manual de uso')),
          ],
        ),
      ],
      body: AlgorithmWorkspace(
        isEmpty: nodos.isEmpty,
        accent: AppColors.johnson,
        emptyIcon: Icons.account_tree_outlined,
        emptyTitle: 'Dibuja tus actividades',
        canvas: Stack(
          children: [
            GraphCanvasViewport(
              nodes: nodos,
              painter: RedActividadesPainter(
                nodos,
                conexiones,
                nodoOrigenParaConexion,
                tiemposTempranos,
                tiemposTardios,
                holguras,
                aristasCriticas,
                mostrarProceso,
                edgeSlacks: holgurasAristas,
              ),
              onTap: (position) {
                final nodoTocado = nodos.firstWhere(
                  (n) => (n.posicion - position).distance < 30,
                  orElse: () =>
                      Nodo(id: '', nombre: '', posicion: Offset.infinite),
                );

                if (nodoTocado.id.isNotEmpty) {
                  if (nodoOrigenParaConexion == null) {
                    setState(() => nodoOrigenParaConexion = nodoTocado);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Nodo "${nodoTocado.nombre}" seleccionado como origen. Haz clic en otro destino.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    if (nodoOrigenParaConexion!.id == nodoTocado.id) {
                      _mostrarErrorConexion(
                        'No se permiten bucles en un mismo nodo.',
                      );
                      setState(() => nodoOrigenParaConexion = null);
                    } else {
                      crearConexion(nodoOrigenParaConexion!, nodoTocado);
                      setState(() => nodoOrigenParaConexion = null);
                    }
                  }
                } else {
                  Conexion? conexionToca;
                  for (var c in conexiones) {
                    final nA = nodos.firstWhere((n) => n.id == c.nodoA);
                    final nB = nodos.firstWhere((n) => n.id == c.nodoB);
                    final mid = Offset(
                      (nA.posicion.dx + nB.posicion.dx) / 2,
                      (nA.posicion.dy + nB.posicion.dy) / 2,
                    );
                    if ((mid - position).distance < 25) {
                      conexionToca = c;
                      break;
                    }
                  }

                  if (conexionToca != null) {
                    editarConexion(conexionToca);
                  } else {
                    agregarNodo(position);
                  }
                  setState(() => nodoOrigenParaConexion = null);
                }
              },
              onEdit: (position) {
                final nodoTocado = nodos.firstWhere(
                  (n) => (n.posicion - position).distance < 30,
                  orElse: () =>
                      Nodo(id: '', nombre: '', posicion: Offset.infinite),
                );
                if (nodoTocado.id.isNotEmpty) {
                  mostrarOpcionesNodo(nodoTocado);
                }
              },
              onNodeMoved: (node, position) => setState(() {
                node.posicion = position;
              }),
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
        panel: ActivityNetworkPanel(
          nodes: nodos,
          startId: nodoInicialSeleccionadoId,
          selectedNode: nodoOrigenParaConexion,
          maximizing: esMaximizar,
          hasResult: mostrarProceso,
          total: proyectoDuracionTotal,
          forward: tiemposTempranos,
          backward: tiemposTardios,
          slacks: holguras,
          highlightedEdges: aristasCriticas.length,
          onModeChanged: _seleccionarModo,
          onCalculate: calcularRedActividades,
        ),
      ),
    );
  }
}
