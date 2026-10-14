import 'dart:math';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/features/johnson/domain/activity_network_problem.dart';
import 'package:app_grafos/features/johnson/domain/activity_network_rules.dart';
import 'package:app_grafos/features/johnson/domain/activity_network_solver.dart';
import 'package:app_grafos/features/johnson/presentation/widgets/activity_network_painter.dart';
import 'package:app_grafos/shared/graph_editor/models/conexion.dart';
import 'package:app_grafos/shared/graph_editor/models/nodo.dart';
import 'package:app_grafos/shared/persistence/graph_document.dart';
import 'package:app_grafos/shared/persistence/graph_document_codec.dart';
import 'package:app_grafos/shared/persistence/graph_file_service.dart';
import 'package:app_grafos/shared/widgets/algorithm_scaffold.dart';
import 'package:app_grafos/shared/widgets/graph_save_dialog.dart';
import 'package:app_grafos/shared/widgets/manual_step.dart';

class JohnsonScreen extends StatefulWidget {
  const JohnsonScreen({super.key, this.initialDocument});
  final GraphDocument? initialDocument;

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
  Set<String> aristasCriticas = {};
  int proyectoDuracionTotal = 0;

  bool esMaximizar = true;

  String? nodoInicialSeleccionadoId;
  final valorInicialNodoController = TextEditingController(text: '0');
  final valorNodoController = TextEditingController(text: '0');

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
    nodos = document.nodes.toList();
    conexiones = document.connections.toList();
    nombreArchivoController.text = document.name;
    nodoInicialSeleccionadoId =
        document.metadata['nodoInicialSeleccionadoId'] ??
        (nodos.isEmpty ? null : nodos.first.id);
    esMaximizar = document.metadata['esMaximizar'] ?? true;
  }

  void limpiarTodo() {
    setState(() {
      nodos.clear();
      conexiones.clear();
      tiemposTempranos.clear();
      tiemposTardios.clear();
      holguras.clear();
      aristasCriticas.clear();
      nodoOrigenParaConexion = null;
      nodoDragging = null;
      proyectoDuracionTotal = 0;
      mostrarProceso = false;
      nodoInicialSeleccionadoId = null;
      valorInicialNodoController.text = '0';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('🗑️ Lienzo y datos limpiados correctamente.'),
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
              color: AppColors.johnson,
              size: 24,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Manual Extendido - Red de Actividades',
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
          width: 540,
          height: 480,
          child: ListView(
            children: const [
              ManualStep(
                numero: '1',
                titulo: 'Creación de Nodos (Eventos)',
                descripcion: 'Haz clic en cualquier espacio vacío del lienzo blanco para desplegar el formulario. El primer nodo creado será automáticamente el nodo raíz y te solicitará su valor inicial.',
              ),
              ManualStep(
                numero: '2',
                titulo: 'Conexión y Ponderación',
                descripcion: 'Haz clic primero en el nodo de origen y luego en el de destino para establecer la actividad y su duración obligatoria. No se permiten bucles, conexiones inversas ni ciclos.',
              ),
              ManualStep(
                numero: '3',
                titulo: 'Maximizar o Minimizar',
                descripcion: 'Alterna el modo en la barra superior. En el modo Minimizar, el sistema calcula el camino de costo mínimo (ruta crítica inversa).',
              ),
              ManualStep(
                numero: '4',
                titulo: 'Valor Inicial del Nodo Raíz',
                descripcion: 'Puedes modificar el valor inicial del nodo raíz en el panel lateral de resultados en cualquier momento.',
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.johnson,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          'valorInicialNodo': valorInicialNodoController.text,
        },
      ),
    );
    if (savedName != null && mounted) nombreArchivoController.text = savedName;
  }

  Future<void> cargarArchivoJson() async {
    try {
      const typeGroup = GraphFileService.jsonType;
      final XFile? file = await openFile(
        acceptedTypeGroups: <XTypeGroup>[typeGroup],
      );
      if (file == null) return;

      final contenido = await file.readAsString();
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
        nombreArchivoController.text = document.name;
        if (document.metadata['esMaximizar'] != null) {
          esMaximizar = document.metadata['esMaximizar'];
        }
        if (document.metadata['nodoInicialSeleccionadoId'] != null) {
          nodoInicialSeleccionadoId =
              document.metadata['nodoInicialSeleccionadoId'];
        }
        if (document.metadata['valorInicialNodo'] != null) {
          valorInicialNodoController.text = document
              .metadata['valorInicialNodo']
              .toString();
        }
        nodos = document.nodes.toList();
        conexiones = document.connections.toList();

        if (nodoInicialSeleccionadoId == null && nodos.isNotEmpty) {
          nodoInicialSeleccionadoId = nodos.first.id;
        }

        nodoOrigenParaConexion = null;
        tiemposTempranos.clear();
        tiemposTardios.clear();
        holguras.clear();
        aristasCriticas.clear();
        proyectoDuracionTotal = 0;
        mostrarProceso = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✨ ¡Archivo cargado exitosamente al lienzo!'),
          backgroundColor: AppColors.success,
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
    if (esPrimero) {
      valorNodoController.text = valorInicialNodoController.text;
    }

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
              TextField(
                controller: valorNodoController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  labelText: 'Insertar valor inicial',
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
              backgroundColor: AppColors.johnson,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              if (nombreController.text.isNotEmpty) {
                setState(() {
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
                    if (valorNodoController.text.isNotEmpty) {
                      valorInicialNodoController.text =
                          valorNodoController.text;
                    }
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
              setState(() {
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
              backgroundColor: AppColors.johnson,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              setState(() {
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
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF121214),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.johnson.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.johnson.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      origen.nombre,
                      style: const TextStyle(
                        color: Color(0xFF818CF8),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.grey,
                      size: 18,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      destino.nombre,
                      style: const TextStyle(
                        color: Color(0xFF34D399),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Duración de Actividad',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: pesoAristaController,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  labelText: 'Valor / Peso de la línea (Obligatorio)',
                  labelStyle: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.line_weight_rounded,
                    color: Color(0xFF818CF8),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1E1E24),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.johnson,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        color: Colors.white60,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.johnson,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: AppColors.johnson.withValues(alpha: 0.5),
                    ),
                    onPressed: () {
                      final peso = int.tryParse(pesoAristaController.text);
                      if (peso != null) {
                        if (!_conexionPermitida(origen, destino)) return;
                        final colorAleatorio =
                            paletaColores[Random().nextInt(
                              paletaColores.length,
                            )];
                        setState(() {
                          conexiones.removeWhere(
                            (c) =>
                                c.nodoA == origen.id && c.nodoB == destino.id,
                          );
                          conexiones.add(
                            Conexion(
                              nodoA: origen.id,
                              nodoB: destino.id,
                              peso: peso,
                              tipo: 'normal',
                              color: colorAleatorio,
                            ),
                          );
                        });
                        Navigator.pop(context);
                      }
                    },
                    child: const Text(
                      'Conectar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.background,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void editarConexion(Conexion conexion) {
    pesoAristaController.text = conexion.peso.toString();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.surface,
        title: const Text(
          'Editar Duración de Línea',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text),
        ),
        content: TextField(
          controller: pesoAristaController,
          keyboardType: TextInputType.number,
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
        actions: [
          TextButton(
            onPressed: () {
              setState(() => conexiones.remove(conexion));
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
              backgroundColor: AppColors.johnson,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final nuevoPeso =
                  int.tryParse(pesoAristaController.text) ?? conexion.peso;
              setState(() {
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

  void calcularRedActividades() {
    if (nodos.isEmpty) return;
    final error = _networkRules.networkError(_aristasDe(conexiones));
    if (error != null) {
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
      initialValue: int.tryParse(valorInicialNodoController.text) ?? 0,
      mode: esMaximizar
          ? NetworkOptimizationMode.maximize
          : NetworkOptimizationMode.minimize,
    );
    final resultado = _solver.solve(problema);

    setState(() {
      tiemposTempranos = Map.of(resultado.earlyTimes);
      tiemposTardios = Map.of(resultado.lateTimes);
      holguras = Map.of(resultado.slacks);
      aristasCriticas = Set.of(resultado.criticalEdgeIds);
      proyectoDuracionTotal = resultado.totalDuration;
      mostrarProceso = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✨ ¡Red calculada (${esMaximizar ? "Maximizar" : "Minimizar"}) con éxito! Valor: $proyectoDuracionTotal.',
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlgorithmScaffold(
      accent: AppColors.johnson,
      title: 'Algoritmo de Johnson',
      icon: Icons.account_tree_rounded,
      actions: [
        IconButton(
          onPressed: () {
            if (mostrarProceso) {
              setState(() {
                mostrarProceso = false;
              });
            } else {
              calcularRedActividades();
            }
          },
          icon: Icon(
            mostrarProceso ? Icons.close_rounded : Icons.bolt_rounded,
            color: AppColors.johnson,
          ),
          tooltip: mostrarProceso ? 'Ocultar resultado' : 'Calcular',
        ),
        PopupMenuButton<String>(
          tooltip: 'Más opciones',
          icon: Icon(
            esMaximizar
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            color: AppColors.johnson,
          ),
          onSelected: (value) {
            switch (value) {
              case 'modo':
                setState(() {
                  esMaximizar = !esMaximizar;
                });
                if (mostrarProceso) {
                  calcularRedActividades();
                }
              case 'ayuda':
                mostrarManualAyuda();
              case 'guardar':
                mostrarGuardarJson();
              case 'cargar':
                cargarArchivoJson();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'modo',
              child: ListTile(
                leading: Icon(
                  esMaximizar
                      ? Icons.trending_down_rounded
                      : Icons.trending_up_rounded,
                ),
                title: Text(
                  esMaximizar ? 'Cambiar a Minimizar' : 'Cambiar a Maximizar',
                ),
              ),
            ),
            const PopupMenuItem(
              value: 'guardar',
              child: ListTile(
                leading: Icon(Icons.save_alt_rounded),
                title: Text('Guardar'),
              ),
            ),
            const PopupMenuItem(
              value: 'cargar',
              child: ListTile(
                leading: Icon(Icons.folder_open_rounded),
                title: Text('Cargar'),
              ),
            ),
            const PopupMenuItem(
              value: 'ayuda',
              child: ListTile(
                leading: Icon(Icons.help_outline_rounded),
                title: Text('Manual de uso'),
              ),
            ),
          ],
        ),
        const SizedBox(width: 4),
      ],
      body: AlgorithmWorkspace(
        isEmpty: nodos.isEmpty,
        accent: AppColors.johnson,
        emptyIcon: Icons.account_tree_outlined,
        emptyTitle: 'Dibuja tus actividades',
        canvas: Stack(
          children: [
            Listener(
              onPointerDown: (event) {
                if (event.buttons == kSecondaryButton) {
                  final nodoTocado = nodos.firstWhere(
                    (n) => (n.posicion - event.localPosition).distance < 30,
                    orElse: () =>
                        Nodo(id: '', nombre: '', posicion: Offset.infinite),
                  );
                  if (nodoTocado.id.isNotEmpty) {
                    mostrarOpcionesNodo(nodoTocado);
                  }
                }
              },
              child: GestureDetector(
                onTapDown: (details) {
                  final nodoTocado = nodos.firstWhere(
                    (n) => (n.posicion - details.localPosition).distance < 30,
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
                      if ((mid - details.localPosition).distance < 25) {
                        conexionToca = c;
                        break;
                      }
                    }

                    if (conexionToca != null) {
                      editarConexion(conexionToca);
                    } else {
                      agregarNodo(details.localPosition);
                    }
                    setState(() => nodoOrigenParaConexion = null);
                  }
                },
                onDoubleTapDown: (details) {
                  final nodoTocado = nodos.firstWhere(
                    (n) => (n.posicion - details.localPosition).distance < 30,
                    orElse: () =>
                        Nodo(id: '', nombre: '', posicion: Offset.infinite),
                  );
                  if (nodoTocado.id.isNotEmpty) {
                    mostrarOpcionesNodo(nodoTocado);
                  }
                },
                onLongPressStart: (details) {
                  final nodoTocado = nodos.firstWhere(
                    (n) => (n.posicion - details.localPosition).distance < 30,
                    orElse: () =>
                        Nodo(id: '', nombre: '', posicion: Offset.infinite),
                  );
                  if (nodoTocado.id.isNotEmpty) {
                    mostrarOpcionesNodo(nodoTocado);
                  }
                },
                onPanStart: (details) {
                  nodoDragging = nodos.firstWhere(
                    (n) => (n.posicion - details.localPosition).distance < 30,
                    orElse: () =>
                        Nodo(id: '', nombre: '', posicion: Offset.infinite),
                  );
                  if (nodoDragging!.id.isEmpty) nodoDragging = null;
                },
                onPanUpdate: (details) {
                  if (nodoDragging != null) {
                    setState(() => nodoDragging!.posicion += details.delta);
                  }
                },
                onPanEnd: (_) => nodoDragging = null,
                child: Container(
                  color: Colors.transparent,
                  child: CustomPaint(
                    painter: RedActividadesPainter(
                      nodos,
                      conexiones,
                      nodoOrigenParaConexion,
                      tiemposTempranos,
                      tiemposTardios,
                      holguras,
                      aristasCriticas,
                      mostrarProceso,
                    ),
                    size: Size.infinite,
                  ),
                ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.bar_chart_rounded,
                            color: AppColors.johnson,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Resultados:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: esMaximizar
                                          ? AppColors.warningSoft
                                          : AppColors.warningSoft,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      esMaximizar ? 'MAXIMIZAR' : 'MINIMIZAR',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: esMaximizar
                                            ? AppColors.johnson
                                            : AppColors.warningText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Valor Inicial del Nodo Raíz:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: valorInicialNodoController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: AppColors.border,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: AppColors.border,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: AppColors.background,
                                ),
                                onChanged: (_) => calcularRedActividades(),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.successSoft,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.success),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.verified_rounded,
                                      color: AppColors.success,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Valor Total: $proyectoDuracionTotal',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.successText,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 24),
                              const Text(
                                'Detalle por Nodo (Temprano / Tardío / Holgura):',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ListView(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                children: nodos.map((n) {
                                  int tTemp = tiemposTempranos[n.id] ?? 0;
                                  int tTard = tiemposTardios[n.id] ?? 0;
                                  int holg = holguras[n.id] ?? 0;
                                  bool esRaiz =
                                      n.id == nodoInicialSeleccionadoId;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8.0),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    child: Text(
                                      'Nodo [${n.nombre}]${esRaiz ? " (Raíz)" : ""} ➔ ES/EF: $tTemp | LS/LF: $tTard | H = $holg',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}
