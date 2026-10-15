import 'dart:math';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/features/assignment/domain/assignment_problem.dart';
import 'package:app_grafos/features/assignment/domain/assignment_solver.dart';
import 'package:app_grafos/features/assignment/domain/optimization_mode.dart';
import 'package:app_grafos/features/assignment/presentation/widgets/assignment_painter.dart';
import 'package:app_grafos/shared/domain/mathematical_procedure.dart';
import 'package:app_grafos/shared/graph_editor/geometry/offset_geometry.dart';
import 'package:app_grafos/shared/graph_editor/models/conexion.dart';
import 'package:app_grafos/shared/graph_editor/models/nodo.dart';
import 'package:app_grafos/shared/persistence/graph_document.dart';
import 'package:app_grafos/shared/persistence/graph_document_codec.dart';
import 'package:app_grafos/shared/persistence/graph_file_service.dart';
import 'package:app_grafos/shared/widgets/algorithm_scaffold.dart';
import 'package:app_grafos/shared/widgets/graph_save_dialog.dart';
import 'package:app_grafos/shared/widgets/manual_step.dart';
import 'package:app_grafos/shared/widgets/mathematical_procedure_dialog.dart';

class AsignacionScreen extends StatefulWidget {
  const AsignacionScreen({super.key, this.initialDocument});
  final GraphDocument? initialDocument;

  @override
  State<AsignacionScreen> createState() => _AsignacionScreenState();
}

class _AsignacionScreenState extends State<AsignacionScreen> {
  static const _solver = AssignmentSolver();
  static const _documentCodec = GraphDocumentCodec();

  List<Nodo> nodos = [];
  List<Conexion> conexiones = [];
  Nodo? nodoOrigen;
  Nodo? nodoDragging;
  bool mostrarProceso = false;
  String tipoOptimizacion = 'minimizar'; // 'minimizar' o 'maximizar'
  List<String> idsConexionesOptimas = [];

  num? ultimoCostoOptimo;
  MathematicalProcedure? _procedure;
  List<String> detalleAsignaciones = [];

  final nombreController = TextEditingController();
  final pesoController = TextEditingController();
  final nombreArchivoController = TextEditingController(
    text: 'asignacion_proyecto',
  );

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDocument;
    if (initial == null) return;
    final document = _documentCodec.decode(_documentCodec.encode(initial));
    nodos = document.nodes.toList();
    conexiones = document.connections.toList();
    nombreArchivoController.text = document.name;
    tipoOptimizacion = document.metadata['tipoOptimizacion'] ?? 'minimizar';
    mostrarProceso = true;
  }

  void _invalidarResultado() {
    idsConexionesOptimas.clear();
    ultimoCostoOptimo = null;
    detalleAsignaciones = [];
    _procedure = null;
  }

  void limpiarTodo() {
    setState(() {
      nodos.clear();
      conexiones.clear();
      nodoOrigen = null;
      nodoDragging = null;
      _invalidarResultado();
      ultimoCostoOptimo = null;
      detalleAsignaciones.clear();
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
              color: AppColors.primary,
              size: 24,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Manual de Uso - Asignación',
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
                titulo: 'Crear Nodos (Orígenes y Destinos)',
                descripcion: 'Haz clic en cualquier espacio vacío del lienzo para crear un nuevo nodo. Escribe un nombre descriptivo (ej. A, B para orígenes o T1, T2 para destinos).',
              ),
              ManualStep(
                numero: '2',
                titulo: 'Conectar y Asignar Costos',
                descripcion: 'Haz clic primero en un nodo origen (se resaltará) y luego haz clic en el nodo destino. Se abrirá una ventana para ingresar el costo numérico de la asignación.',
              ),
              ManualStep(
                numero: '3',
                titulo: 'Matrices Cuadradas y No Cuadradas',
                descripcion: 'El sistema equilibra automáticamente las matrices rectangulares (más orígenes que destinos o viceversa) usando filas/columnas ficticias (dummy) con costo 0.',
              ),
              ManualStep(
                numero: '4',
                titulo: 'Mover y Editar',
                descripcion: 'Puedes arrastrar los nodos libremente por el lienzo. Si haces clic secundario (o doble clic/pulsación larga) sobre un nodo o conexión, podrás editar sus datos o eliminarlos.',
              ),
              ManualStep(
                numero: '5',
                titulo: 'Cálculo Óptimo y Matriz',
                descripcion: 'Abre el panel derecho con el botón "Matriz". Selecciona si deseas "Minimizar" o "Maximizar" y presiona "Calcular Asignación Óptima" para ver el resultado y la ruta resaltada.',
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
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
        ? 'asignacion'
        : nombreArchivoController.text;
    final savedName = await showGraphSaveDialog(
      context,
      GraphDocument(
        name: name,
        nodes: nodos,
        connections: conexiones,
        metadata: {'tipoOptimizacion': tipoOptimizacion},
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
      if (document.connections.any(
        (connection) => connection.nodoA == connection.nodoB,
      )) {
        throw const FormatException('No se permiten bucles en asignación.');
      }

      if (!mounted) return;

      setState(() {
        nombreArchivoController.text = document.name;
        if (document.metadata['tipoOptimizacion'] != null) {
          tipoOptimizacion = document.metadata['tipoOptimizacion'];
        }
        nodos = document.nodes.toList();
        conexiones = document.connections.toList();
        nodoOrigen = null;
        _invalidarResultado();
        ultimoCostoOptimo = null;
        detalleAsignaciones.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✨ ¡Asignación cargada exitosamente al lienzo!'),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Nuevo Vértice',
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
          decoration: InputDecoration(
            labelText: 'Nombre (ej. A, B, T1, T2...)',
            prefixIcon: const Icon(
              Icons.radio_button_checked,
              color: AppColors.primary,
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
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              if (nombreController.text.isNotEmpty) {
                setState(() {
                  nodos.add(
                    Nodo(
                      id: 'n${DateTime.now().millisecondsSinceEpoch}',
                      nombre: nombreController.text,
                      posicion: posicion,
                    ),
                  );
                  _invalidarResultado();
                });
                Navigator.pop(context);
              }
            },
            child: const Text(
              'Crear Nodo',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void mostrarOpcionesNodo(Nodo nodo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            const Icon(Icons.settings_outlined, color: AppColors.primary),
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
        content: const Text(
          'Selecciona una opción de gestión:',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              borrarNodo(nodo);
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
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              editarNombreNodo(nodo);
            },
            child: const Text(
              'Cambiar Nombre',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void editarNombreNodo(Nodo nodo) {
    nombreController.text = nodo.nombre;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.surface,
        title: const Text(
          'Editar Nombre del Nodo',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text),
        ),
        content: TextField(
          controller: nombreController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Nuevo Nombre',
            prefixIcon: const Icon(Icons.edit, color: AppColors.primary),
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
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              if (nombreController.text.isNotEmpty) {
                setState(() {
                  nodo.nombre = nombreController.text;
                  _invalidarResultado();
                });
                Navigator.pop(context);
              }
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

  void conectarNodos(Nodo nodoDestino) {
    if (nodoOrigen == null) return;
    final nodoOrigenTemp = nodoOrigen!;
    setState(() => nodoOrigen = null);
    if (nodoOrigenTemp.id == nodoDestino.id) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('No se permiten bucles en un mismo nodo.'),
          ),
        );
      return;
    }
    pesoController.clear();

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
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      nodoOrigenTemp.nombre,
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
                      nodoDestino.nombre,
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
                'Costo / Valor de Asignación',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: pesoController,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  labelText: 'Costo numérico (ej. 1, 2, 5...)',
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
                      color: AppColors.primary,
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
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: AppColors.primary.withValues(alpha: 0.5),
                    ),
                    onPressed: () {
                      final int pesoFinal =
                          int.tryParse(pesoController.text) ?? 1;
                      setState(() {
                        conexiones.removeWhere(
                          (c) =>
                              (c.nodoA == nodoOrigenTemp.id &&
                                  c.nodoB == nodoDestino.id) ||
                              (c.nodoA == nodoDestino.id &&
                                  c.nodoB == nodoOrigenTemp.id),
                        );
                        final randomColor = Color(
                          (Random().nextDouble() * 0xFFFFFF).toInt(),
                        ).withValues(alpha: 1.0);
                        conexiones.add(
                          Conexion(
                            nodoA: nodoOrigenTemp.id,
                            nodoB: nodoDestino.id,
                            peso: pesoFinal,
                            tipo: 'unidireccional',
                            color: randomColor,
                          ),
                        );
                        _invalidarResultado();
                      });
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Guardar Asignación',
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

  void borrarNodo(Nodo nodo) {
    setState(() {
      conexiones.removeWhere((c) => c.nodoA == nodo.id || c.nodoB == nodo.id);
      nodos.remove(nodo);
      if (nodoOrigen?.id == nodo.id) nodoOrigen = null;
      _invalidarResultado();
    });
  }

  void borrarConexion(Conexion conexion) {
    setState(() {
      conexiones.remove(conexion);
      _invalidarResultado();
    });
  }

  void mostrarOpcionesConexion(Conexion conexion) {
    pesoController.text = conexion.peso.toString();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.surface,
        title: const Text(
          'Editar Costo de Asignación',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text),
        ),
        content: TextField(
          controller: pesoController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Nuevo Costo',
            prefixIcon: const Icon(
              Icons.line_weight_rounded,
              color: AppColors.primary,
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
              Navigator.pop(context);
              borrarConexion(conexion);
            },
            child: const Text(
              'Borrar',
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
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final int pesoEditado = int.tryParse(pesoController.text) ?? 1;
              setState(() {
                final index = conexiones.indexOf(conexion);
                if (index != -1) {
                  conexiones[index] = Conexion(
                    nodoA: conexion.nodoA,
                    nodoB: conexion.nodoB,
                    peso: pesoEditado,
                    tipo: conexion.tipo,
                    color: conexion.color,
                  );
                }
                _invalidarResultado();
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
      if (destinos.isEmpty && nodos.length > 1) {
        destinos = nodos.sublist(1);
      }
    }
    return destinos;
  }

  AssignmentProblem? _crearProblemaAsignacion() {
    final origenes = obtenerOrigenes();
    final destinos = obtenerDestinos();

    if (origenes.isEmpty || destinos.isEmpty) return null;

    final costos = <AssignmentCost>[];
    for (final origen in origenes) {
      for (final destino in destinos) {
        Conexion? conexionEncontrada;
        for (final conexion in conexiones) {
          final conectaPar =
              (conexion.nodoA == origen.id && conexion.nodoB == destino.id) ||
              (conexion.nodoA == destino.id && conexion.nodoB == origen.id);
          if (conectaPar) {
            conexionEncontrada = conexion;
            break;
          }
        }
        if (conexionEncontrada != null) {
          costos.add(
            AssignmentCost(
              originId: origen.id,
              destinationId: destino.id,
              value: conexionEncontrada.peso,
            ),
          );
        }
      }
    }

    return AssignmentProblem(
      origins: origenes
          .map((nodo) => AssignmentItem(id: nodo.id, label: nodo.nombre))
          .toList(),
      destinations: destinos
          .map((nodo) => AssignmentItem(id: nodo.id, label: nodo.nombre))
          .toList(),
      costs: costos,
      mode: tipoOptimizacion == 'minimizar'
          ? OptimizationMode.minimize
          : OptimizationMode.maximize,
    );
  }

  void calcularSolucionOptima() {
    final problema = _crearProblemaAsignacion();
    if (problema == null) {
      setState(_invalidarResultado);
      return;
    }
    final resultado = _solver.solve(problema, includeProcedure: true);

    final idsOptimos = <String>[];
    final detalles = <String>[];
    if (resultado != null) {
      for (final asignacion in resultado.matches) {
        if (!asignacion.origin.isDummy && !asignacion.destination.isDummy) {
          idsOptimos
            ..add('${asignacion.origin.id}-${asignacion.destination.id}')
            ..add('${asignacion.destination.id}-${asignacion.origin.id}');
        }
        detalles.add(
          '${asignacion.origin.label} ➔ ${asignacion.destination.label} '
          '(Costo: ${asignacion.value}${asignacion.origin.isDummy || asignacion.destination.isDummy ? ', ficticio' : ''})',
        );
      }
    }

    setState(() {
      ultimoCostoOptimo = resultado?.total;
      _procedure = resultado?.procedure;
      detalleAsignaciones = detalles;
      idsConexionesOptimas = idsOptimos;
      mostrarProceso = true;
    });

    if (ultimoCostoOptimo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ No existe una asignación completa válida.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✨ ¡Solución óptima calculada! Costo Total: $ultimoCostoOptimo.',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Nodo? obtenerNodoEnPosicion(Offset posicion) {
    for (var nodo in nodos) {
      if ((nodo.posicion - posicion).distance < 30) {
        return nodo;
      }
    }
    return null;
  }

  Conexion? obtenerConexionEnPosicion(Offset posicion) {
    for (var conexion in conexiones) {
      try {
        final nodoA = nodos.firstWhere((n) => n.id == conexion.nodoA);
        final nodoB = nodos.firstWhere((n) => n.id == conexion.nodoB);
        final direccion = (nodoB.posicion - nodoA.posicion).normalize();
        final desdeAjustado = nodoA.posicion + direccion * 28;
        final hastaAjustado = nodoB.posicion - direccion * 28;
        final l2 = (hastaAjustado - desdeAjustado).distanceSquared;
        if (l2 > 0) {
          var t =
              ((posicion.dx - desdeAjustado.dx) *
                      (hastaAjustado.dx - desdeAjustado.dx) +
                  (posicion.dy - desdeAjustado.dy) *
                      (hastaAjustado.dy - desdeAjustado.dy)) /
              l2;
          t = t.clamp(0.0, 1.0);
          final projection =
              desdeAjustado + (hastaAjustado - desdeAjustado) * t;
          if ((posicion - projection).distance < 20) {
            return conexion;
          }
        }
      } catch (_) {}
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlgorithmScaffold(
      accent: AppColors.primary,
      title: 'Método de Asignación',
      icon: Icons.assignment_turned_in_rounded,
      actions: [
        IconButton(
          onPressed: () {
            setState(() {
              mostrarProceso = !mostrarProceso;
            });
          },
          icon: Icon(
            mostrarProceso ? Icons.close_rounded : Icons.calculate_rounded,
            color: AppColors.primary,
          ),
          tooltip: mostrarProceso ? 'Ocultar matriz' : 'Mostrar matriz',
        ),
        PopupMenuButton<String>(
          tooltip: 'Más opciones',
          onSelected: (value) {
            switch (value) {
              case 'ayuda':
                mostrarManualAyuda();
              case 'guardar':
                mostrarGuardarJson();
              case 'cargar':
                cargarArchivoJson();
            }
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
        const SizedBox(width: 4),
      ],
      body: Column(
        children: [
          Expanded(
            child: AlgorithmWorkspace(
              isEmpty: nodos.isEmpty,
              accent: AppColors.primary,
              emptyIcon: Icons.assignment_outlined,
              emptyTitle: 'Conecta recursos y tareas',
              canvas: Stack(
                children: [
                  Listener(
                    onPointerDown: (event) {
                      if (event.buttons == kSecondaryButton) {
                        final nodo = obtenerNodoEnPosicion(event.localPosition);
                        if (nodo != null) {
                          mostrarOpcionesNodo(nodo);
                        }
                      }
                    },
                    child: GestureDetector(
                      onTapDown: (details) {
                        final nodo = obtenerNodoEnPosicion(
                          details.localPosition,
                        );
                        if (nodo != null) {
                          if (nodoOrigen == null) {
                            setState(() => nodoOrigen = nodo);
                          } else {
                            conectarNodos(nodo);
                          }
                        } else {
                          final conexion = obtenerConexionEnPosicion(
                            details.localPosition,
                          );
                          if (conexion != null) {
                            mostrarOpcionesConexion(conexion);
                          } else {
                            agregarNodo(details.localPosition);
                          }
                        }
                      },
                      onDoubleTapDown: (details) {
                        final nodo = obtenerNodoEnPosicion(
                          details.localPosition,
                        );
                        if (nodo != null) {
                          mostrarOpcionesNodo(nodo);
                        }
                      },
                      onLongPressStart: (details) {
                        final nodo = obtenerNodoEnPosicion(
                          details.localPosition,
                        );
                        if (nodo != null) {
                          mostrarOpcionesNodo(nodo);
                        }
                      },
                      onPanStart: (details) {
                        final nodo = obtenerNodoEnPosicion(
                          details.localPosition,
                        );
                        if (nodo != null) {
                          nodoDragging = nodo;
                        }
                      },
                      onPanUpdate: (details) {
                        if (nodoDragging != null) {
                          setState(() {
                            nodoDragging!.posicion += details.delta;
                            _invalidarResultado();
                          });
                        }
                      },
                      onPanEnd: (details) {
                        nodoDragging = null;
                      },
                      child: Container(
                        color: Colors.transparent,
                        child: CustomPaint(
                          painter: AsignacionPainter(
                            nodos,
                            conexiones,
                            nodoOrigen,
                            idsConexionesOptimas,
                          ),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                  ),
                  // Botón Limpiar Lienzo Abajo a la Izquierda
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
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: AppColors.border),
                              ),
                            ),
                            child: Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                const Text(
                                  'Proceso y Optimización',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.text,
                                  ),
                                ),
                                DropdownButton<String>(
                                  value: tipoOptimizacion,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'minimizar',
                                      child: Text('Minimizar'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'maximizar',
                                      child: Text('Maximizar'),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        tipoOptimizacion = val;
                                        _invalidarResultado();
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.all(20),
                              children: [
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: calcularSolucionOptima,
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  label: const Text(
                                    'Calcular Asignación Óptima',
                                    style: TextStyle(
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
                                        ),
                                  icon: const Icon(
                                    Icons.functions_rounded,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'Ver procedimiento matemático',
                                  ),
                                ),
                                const SizedBox(height: 20),

                                const Text(
                                  'Matriz de Asignación (Costos)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.text,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                buildMatrizAsignacionWidget(),
                                const SizedBox(height: 20),

                                if (ultimoCostoOptimo != null) ...[
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.verified_rounded,
                                              color: AppColors.success,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Resultado Óptimo ($tipoOptimizacion)',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.successText,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Costo Total: $ultimoCostoOptimo',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: AppColors.successText,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Asignaciones:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        ...detalleAsignaciones.map(
                                          (asig) => Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 2.0,
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.arrow_right_rounded,
                                                  color: AppColors.success,
                                                  size: 18,
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    asig,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: AppColors.text,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 20,
                                      ),
                                      child: Text(
                                        'Presiona "Calcular Asignación Óptima"\npara ver los resultados.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMatrizAsignacionWidget() {
    final problem = _crearProblemaAsignacion()?.toSquare();
    if (problem == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Coloca nodos en el lienzo (izq: orígenes, der: destinos).',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      );
    }
    final origenes = problem.origins;
    final destinos = problem.destinations;
    final filas = origenes.length;
    final colsCount = destinos.length;
    final matrizValores = [
      for (final origen in origenes)
        [
          for (final destino in destinos)
            problem.costFor(origen.id, destino.id)?.toString() ?? '-',
        ],
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 36,
          dataRowMinHeight: 32,
          dataRowMaxHeight: 36,
          columnSpacing: 16,
          horizontalMargin: 12,
          headingRowColor: WidgetStateProperty.all(AppColors.primarySoft),
          columns: [
            const DataColumn(
              label: Text(
                'Origen \\ Dest',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            ...destinos.map(
              (nodo) => DataColumn(
                label: Text(
                  nodo.label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: nodo.isDummy
                        ? AppColors.warningText
                        : AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
          rows: List.generate(filas, (i) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    origenes[i].label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: origenes[i].isDummy
                          ? AppColors.warningText
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                ...List.generate(colsCount, (j) {
                  final val = matrizValores[i][j];
                  return DataCell(
                    Text(
                      val,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: val == '-'
                            ? FontWeight.normal
                            : FontWeight.bold,
                        color: val == '-'
                            ? const Color(0xFF94A3B8)
                            : AppColors.text,
                      ),
                    ),
                  );
                }),
              ],
            );
          }),
        ),
      ),
    );
  }
}
