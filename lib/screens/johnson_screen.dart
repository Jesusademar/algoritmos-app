import 'dart:math';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_selector/file_selector.dart';

import '../features/johnson/domain/activity_network_problem.dart';
import '../features/johnson/domain/activity_network_solver.dart';
import '../models/nodo.dart';
import '../models/conexion.dart';
import '../shared/persistence/graph_document.dart';
import '../shared/persistence/graph_document_codec.dart';

class JohnsonScreen extends StatefulWidget {
  const JohnsonScreen({super.key});

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
  final jsonController = TextEditingController();
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
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(
              Icons.help_outline_rounded,
              color: Color(0xFF6366F1),
              size: 24,
            ),
            SizedBox(width: 12),
            Text(
              'Manual Extendido - Red de Actividades',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 540,
          height: 480,
          child: ListView(
            children: const [
              _ItemAyuda(
                numero: '1',
                titulo: 'Creación de Nodos (Eventos)',
                descripcion: 'Haz clic en cualquier espacio vacío del lienzo blanco para desplegar el formulario. El primer nodo creado será automáticamente el nodo raíz y te solicitará su valor inicial.',
              ),
              _ItemAyuda(
                numero: '2',
                titulo: 'Conexión y Ponderación',
                descripcion: 'Haz clic primero en el nodo de origen y luego en el de destino para establecer la actividad y su duración obligatoria.',
              ),
              _ItemAyuda(
                numero: '3',
                titulo: 'Maximizar o Minimizar',
                descripcion: 'Alterna el modo en la barra superior. En el modo Minimizar, el sistema calcula el camino de costo mínimo (ruta crítica inversa).',
              ),
              _ItemAyuda(
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
              backgroundColor: const Color(0xFF6366F1),
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

  Future<void> guardarEnDescargas() async {
    try {
      final nombre = nombreArchivoController.text.isNotEmpty
          ? nombreArchivoController.text
          : 'red_actividades';
      final jsonString = _documentCodec.encode(
        GraphDocument(
          name: nombre,
          nodes: nodos,
          connections: conexiones,
          metadata: {
            'esMaximizar': esMaximizar,
            'nodoInicialSeleccionadoId': nodoInicialSeleccionadoId,
            'valorInicialNodo': valorInicialNodoController.text,
          },
        ),
      );
      final directory = await getDownloadsDirectory();

      if (!mounted) return;

      if (directory != null) {
        final filePath = '${directory.path}/$nombre.json';
        final file = File(filePath);
        await file.writeAsString(jsonString);

        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✨ ¡Guardado exitoso en Descargas: $nombre.json!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar el archivo.')),
      );
    }
  }

  void mostrarGuardarJson() {
    jsonController.text = _documentCodec.encode(
      GraphDocument(
        name: nombreArchivoController.text.isNotEmpty
            ? nombreArchivoController.text
            : 'red_actividades',
        nodes: nodos,
        connections: conexiones,
        metadata: {
          'esMaximizar': esMaximizar,
          'nodoInicialSeleccionadoId': nodoInicialSeleccionadoId,
          'valorInicialNodo': valorInicialNodoController.text,
        },
      ),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.save_rounded, color: Color(0xFF6366F1), size: 24),
            SizedBox(width: 12),
            Text(
              'Guardar Problema',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nombre del archivo:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nombreArchivoController,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.description_outlined,
                    color: Color(0xFF64748B),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Estructura JSON:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: jsonController,
                    maxLines: null,
                    readOnly: true,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Color(0xFF334155),
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: guardarEnDescargas,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text(
              'Descargar JSON',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> cargarArchivoJson() async {
    try {
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'Archivos JSON',
        extensions: <String>['json'],
      );
      final XFile? file = await openFile(
        acceptedTypeGroups: <XTypeGroup>[typeGroup],
      );
      if (file == null) return;

      final contenido = await file.readAsString();
      final document = _documentCodec.decode(contenido);

      if (!mounted) return;

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
          backgroundColor: const Color(0xFF10B981),
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
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(
              esPrimero ? Icons.star_rounded : Icons.add_circle_outline_rounded,
              color: const Color(0xFF6366F1),
            ),
            const SizedBox(width: 10),
            Text(
              esPrimero ? 'Nuevo Nodo Raíz (Inicial)' : 'Nuevo Nodo (Evento)',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
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
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                labelText: 'Nombre del nodo (ej. 1, a, Inicio...)',
                labelStyle: const TextStyle(color: Color(0xFF64748B)),
                prefixIcon: const Icon(
                  Icons.radio_button_checked,
                  color: Color(0xFF6366F1),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFF6366F1),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
            ),
            if (esPrimero) ...[
              const SizedBox(height: 16),
              TextField(
                controller: valorNodoController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  labelText: 'Insertar valor inicial',
                  labelStyle: const TextStyle(color: Color(0xFF64748B)),
                  prefixIcon: const Icon(
                    Icons.line_weight_rounded,
                    color: Color(0xFF6366F1),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFF6366F1),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
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
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
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
        backgroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.settings_outlined, color: Color(0xFF6366F1)),
            const SizedBox(width: 10),
            Text(
              'Nodo: ${nodo.nombre}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        content: TextField(
          controller: nombreController,
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            labelText: 'Nuevo nombre',
            labelStyle: const TextStyle(color: Color(0xFF64748B)),
            prefixIcon: const Icon(Icons.edit, color: Color(0xFF6366F1)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
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
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
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

  void crearConexion(Nodo origen, Nodo destino) {
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
                      color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.4),
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
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
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
                  color: Colors.white,
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
                  color: Colors.white,
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
                      color: Color(0xFF6366F1),
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
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: const Color(0xFF6366F1)
                          .withValues(alpha: 0.5),
                    ),
                    onPressed: () {
                      final peso = int.tryParse(pesoAristaController.text);
                      if (peso != null) {
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
                        color: Colors.white,
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
        backgroundColor: Colors.white,
        title: const Text(
          'Editar Duración de Línea',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        content: TextField(
          controller: pesoAristaController,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            labelText: 'Nuevo Peso',
            labelStyle: const TextStyle(color: Color(0xFF64748B)),
            prefixIcon: const Icon(
              Icons.line_weight_rounded,
              color: Color(0xFF6366F1),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
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
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
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
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.account_tree_rounded,
                color: Color(0xFF6366F1),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'Red de Actividades y Ruta Crítica',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
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
              color: const Color(0xFF6366F1),
            ),
            tooltip: mostrarProceso ? 'Ocultar resultado' : 'Calcular',
          ),
          PopupMenuButton<String>(
            tooltip: 'Más opciones',
            icon: Icon(
              esMaximizar
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              color: const Color(0xFF6366F1),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: Row(
        children: [
          Expanded(
            child: Stack(
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
                        (n) =>
                            (n.posicion - details.localPosition).distance < 30,
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
                        (n) =>
                            (n.posicion - details.localPosition).distance < 30,
                        orElse: () =>
                            Nodo(id: '', nombre: '', posicion: Offset.infinite),
                      );
                      if (nodoTocado.id.isNotEmpty) {
                        mostrarOpcionesNodo(nodoTocado);
                      }
                    },
                    onLongPressStart: (details) {
                      final nodoTocado = nodos.firstWhere(
                        (n) =>
                            (n.posicion - details.localPosition).distance < 30,
                        orElse: () =>
                            Nodo(id: '', nombre: '', posicion: Offset.infinite),
                      );
                      if (nodoTocado.id.isNotEmpty) {
                        mostrarOpcionesNodo(nodoTocado);
                      }
                    },
                    onPanStart: (details) {
                      nodoDragging = nodos.firstWhere(
                        (n) =>
                            (n.posicion - details.localPosition).distance < 30,
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
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: limpiarTodo,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: Color(0xFFEF4444),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Limpiar lienzo',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      'Nodos: ${nodos.length} • Conexiones: ${conexiones.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (mostrarProceso) ...[
            Container(width: 1, color: const Color(0xFFE2E8F0)),
            Container(
              width: 380,
              color: Colors.white,
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
                        bottom: BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.bar_chart_rounded,
                          color: Color(0xFF6366F1),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Resultados:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
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
                                      ? const Color(0xFFEEF2FF)
                                      : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  esMaximizar ? 'MAXIMIZAR' : 'MINIMIZAR',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: esMaximizar
                                        ? const Color(0xFF6366F1)
                                        : const Color(0xFFD97706),
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
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: valorInicialNodoController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              color: Color(0xFF1E293B),
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
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                            ),
                            onChanged: (_) => calcularRedActividades(),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF10B981),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.verified_rounded,
                                  color: Color(0xFF10B981),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Valor Total: $proyectoDuracionTotal',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF047857),
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
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView(
                              children: nodos.map((n) {
                                int tTemp = tiemposTempranos[n.id] ?? 0;
                                int tTard = tiemposTardios[n.id] ?? 0;
                                int holg = holguras[n.id] ?? 0;
                                bool esRaiz = n.id == nodoInicialSeleccionadoId;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8.0),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Text(
                                    'Nodo [${n.nombre}]${esRaiz ? " (Raíz)" : ""} ➔ ES/EF: $tTemp | LS/LF: $tTard | H = $holg',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF334155),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ItemAyuda extends StatelessWidget {
  final String numero;
  final String titulo;
  final String descripcion;

  const _ItemAyuda({
    required this.numero,
    required this.titulo,
    required this.descripcion,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              numero,
              style: const TextStyle(
                color: Color(0xFF6366F1),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  descripcion,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RedActividadesPainter extends CustomPainter {
  final List<Nodo> nodos;
  final List<Conexion> conexiones;
  final Nodo? nodoOrigenParaConexion;
  final Map<String, int> tiemposTempranos;
  final Map<String, int> tiemposTardios;
  final Map<String, int> holguras;
  final Set<String> aristasCriticas;
  final bool mostrarProceso;

  RedActividadesPainter(
    this.nodos,
    this.conexiones,
    this.nodoOrigenParaConexion,
    this.tiemposTempranos,
    this.tiemposTardios,
    this.holguras,
    this.aristasCriticas,
    this.mostrarProceso,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paintNodo = Paint()..style = PaintingStyle.fill;
    final paintBorde = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (var c in conexiones) {
      final nA = nodos.firstWhere(
        (n) => n.id == c.nodoA,
        orElse: () => nodos.first,
      );
      final nB = nodos.firstWhere(
        (n) => n.id == c.nodoB,
        orElse: () => nodos.first,
      );
      if (nA.id.isNotEmpty && nB.id.isNotEmpty) {
        bool esCritica =
            mostrarProceso && aristasCriticas.contains('${c.nodoA}-${c.nodoB}');

        final paintArista = Paint()
          ..color = esCritica ? const Color(0xFF10B981) : c.color
          ..strokeWidth = esCritica ? 4.5 : 2.5
          ..style = PaintingStyle.stroke;

        _dibujarLineaConFlecha(canvas, nA.posicion, nB.posicion, paintArista);

        final mid = Offset(
          (nA.posicion.dx + nB.posicion.dx) / 2,
          (nA.posicion.dy + nB.posicion.dy) / 2,
        );

        final textSpan = TextSpan(
          text: ' ${c.peso} ',
          style: TextStyle(
            color: esCritica
                ? const Color(0xFF065F46)
                : const Color(0xFF1E293B),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        );
        final tp = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );
        tp.layout();

        final rectBg = Rect.fromCenter(
          center: mid,
          width: tp.width + 6,
          height: tp.height + 4,
        );

        canvas.drawRRect(
          RRect.fromRectAndRadius(rectBg, const Radius.circular(4)),
          Paint()..color = esCritica ? const Color(0xFFD1FAE5) : Colors.white,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rectBg, const Radius.circular(4)),
          Paint()
            ..color = esCritica
                ? const Color(0xFF10B981)
                : const Color(0xFFCBD5E1)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );

        tp.paint(canvas, mid - Offset(tp.width / 2, tp.height / 2));

        if (mostrarProceso) {
          int hA = holguras[c.nodoA] ?? 0;
          final textHolgura = TextSpan(
            text: ' H=$hA ',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          );
          final tpH = TextPainter(
            text: textHolgura,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
          );
          tpH.layout();

          final rectBgH = Rect.fromCenter(
            center: mid + const Offset(0, 16),
            width: tpH.width + 4,
            height: tpH.height + 2,
          );

          canvas.drawRRect(
            RRect.fromRectAndRadius(rectBgH, const Radius.circular(4)),
            Paint()..color = Colors.white,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(rectBgH, const Radius.circular(4)),
            Paint()
              ..color = const Color(0xFFCBD5E1)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1,
          );

          tpH.paint(
            canvas,
            mid + const Offset(0, 16) - Offset(tpH.width / 2, tpH.height / 2),
          );
        }
      }
    }

    for (var nodo in nodos) {
      final isOrigen = nodoOrigenParaConexion?.id == nodo.id;
      paintNodo.color = isOrigen ? const Color(0xFFEEF2FF) : Colors.white;
      paintBorde.color = isOrigen
          ? const Color(0xFF6366F1)
          : const Color(0xFF475569);

      canvas.drawCircle(nodo.posicion, 24, paintNodo);
      canvas.drawCircle(nodo.posicion, 24, paintBorde);

      final textSpan = TextSpan(
        text: nodo.nombre,
        style: const TextStyle(
          color: Color(0xFF1E293B),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        nodo.posicion - Offset(textPainter.width / 2, textPainter.height / 2),
      );

      if (mostrarProceso) {
        int tTemp = tiemposTempranos[nodo.id] ?? 0;
        int tTard = tiemposTardios[nodo.id] ?? 0;

        final leftSpan = TextSpan(
          text: '$tTemp',
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        );
        final leftTP = TextPainter(
          text: leftSpan,
          textDirection: TextDirection.ltr,
        );
        leftTP.layout();
        leftTP.paint(canvas, nodo.posicion + const Offset(-40, -6));

        final rightSpan = TextSpan(
          text: '$tTard',
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        );
        final rightTP = TextPainter(
          text: rightSpan,
          textDirection: TextDirection.ltr,
        );
        rightTP.layout();
        rightTP.paint(canvas, nodo.posicion + const Offset(30, -6));
      }
    }
  }

  void _dibujarLineaConFlecha(
    Canvas canvas,
    Offset origen,
    Offset destino,
    Paint paint,
  ) {
    const double radioNodo = 24.0;
    final double angulo = atan2(destino.dy - origen.dy, destino.dx - origen.dx);

    final Offset puntoFinal = Offset(
      destino.dx - radioNodo * cos(angulo),
      destino.dy - radioNodo * sin(angulo),
    );

    final Offset puntoInicio = Offset(
      origen.dx + radioNodo * cos(angulo),
      origen.dy + radioNodo * sin(angulo),
    );

    canvas.drawLine(puntoInicio, puntoFinal, paint);

    const double tamFlecha = 12.0;
    final Path pathFlecha = Path();
    pathFlecha.moveTo(puntoFinal.dx, puntoFinal.dy);
    pathFlecha.lineTo(
      puntoFinal.dx - tamFlecha * cos(angulo - pi / 6),
      puntoFinal.dy - tamFlecha * sin(angulo - pi / 6),
    );
    pathFlecha.lineTo(
      puntoFinal.dx - tamFlecha * cos(angulo + pi / 6),
      puntoFinal.dy - tamFlecha * sin(angulo + pi / 6),
    );
    pathFlecha.close();

    final Paint paintFlecha = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;

    canvas.drawPath(pathFlecha, paintFlecha);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
