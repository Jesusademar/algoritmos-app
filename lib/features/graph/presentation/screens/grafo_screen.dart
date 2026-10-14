import 'dart:math';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/features/graph/presentation/widgets/graph_painter.dart';
import 'package:app_grafos/shared/graph_editor/geometry/offset_geometry.dart';
import 'package:app_grafos/shared/graph_editor/models/conexion.dart';
import 'package:app_grafos/shared/graph_editor/models/nodo.dart';
import 'package:app_grafos/shared/persistence/graph_document.dart';
import 'package:app_grafos/shared/persistence/graph_document_codec.dart';
import 'package:app_grafos/shared/persistence/graph_file_service.dart';
import 'package:app_grafos/shared/widgets/algorithm_scaffold.dart';
import 'package:app_grafos/shared/widgets/graph_save_dialog.dart';

class GrafoScreen extends StatefulWidget {
  const GrafoScreen({super.key, this.initialDocument});
  final GraphDocument? initialDocument;

  @override
  State<GrafoScreen> createState() => _GrafoScreenState();
}

class _GrafoScreenState extends State<GrafoScreen> {
  static const _documentCodec = GraphDocumentCodec();

  List<Nodo> nodos = [];
  List<Conexion> conexiones = [];
  Nodo? nodoOrigen;
  Nodo? nodoDragging;
  bool mostrarMatriz = false;

  final nombreController = TextEditingController();
  final pesoController = TextEditingController();
  final nombreArchivoController = TextEditingController(text: 'grafo_proyecto');
  String tipoConexion = 'unidireccional';

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDocument;
    if (initial == null) return;
    final document = _documentCodec.decode(_documentCodec.encode(initial));
    nodos = document.nodes.toList();
    conexiones = document.connections.toList();
    nombreArchivoController.text = document.name;
    mostrarMatriz = true;
  }

  Future<void> mostrarGuardarJson() async {
    final name = nombreArchivoController.text.trim().isEmpty
        ? 'grafo'
        : nombreArchivoController.text;
    final savedName = await showGraphSaveDialog(
      context,
      GraphDocument(name: name, nodes: nodos, connections: conexiones),
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

      setState(() {
        nombreArchivoController.text = document.name;
        nodos = document.nodes.toList();
        conexiones = document.connections.toList();
        nodoOrigen = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✨ ¡Grafo cargado exitosamente al lienzo!'),
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

  void mostrarAyuda() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.auto_stories_rounded, color: AppColors.graph, size: 28),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'Manual y Guía de Uso del Sistema',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: AppColors.text,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 600,
          height: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAyudaItem(
                  icon: Icons.hub_rounded,
                  titulo: '1. Creación y Desplazamiento de Nodos (Vértices)',
                  descripcion: '• Haz clic izquierdo en cualquier espacio libre del lienzo interactivo para desplegar el diálogo de creación e ingresar el nombre identificador único del vértice.\n• Mantén presionado y arrastra cualquier nodo libremente por el plano para acomodar la red y optimizar la visualización geométrica en tiempo real.',
                ),
                const SizedBox(height: 18),
                _buildAyudaItem(
                  icon: Icons.timeline_rounded,
                  titulo: '2. Enlace de Aristas y Conexiones',
                  descripcion: '• Haz clic primero en un nodo origen (se resaltará automáticamente con un borde índole destacado) y luego haz clic en el nodo destino deseado.\n• En el panel flotante emergente, especifica el peso numérico de la arista (si se deja vacío, el valor predeterminado es 0) y define si el enlace será de tipo "Sin dirección" o "Unidireccional".',
                ),
                const SizedBox(height: 18),
                _buildAyudaItem(
                  icon: Icons.edit_outlined,
                  titulo: '3. Edición y Eliminación Dinámica',
                  descripcion: '• Utiliza el clic derecho (secundario), doble clic o mantén presionado prolongadamente sobre cualquier nodo o arista para acceder al menú de opciones avanzadas.\n• Podrás modificar pesos numéricos, renombrar etiquetas de vértices o eliminar elementos de forma segura.',
                ),
                const SizedBox(height: 18),
                _buildAyudaItem(
                  icon: Icons.grid_on_rounded,
                  titulo: '4. Matriz de Adyacencia y Cálculo de Grados Δ(G)',
                  descripcion: '• Activa el botón superior "Matriz" para desplegar el panel analítico lateral derecho con la representación matricial completa de la red.\n• El grado de cada vértice y el Grado Máximo del Grafo Δ(G) se calculan rigurosamente en tiempo real.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.graph,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '¡Entendido, comencemos!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAyudaItem({
    required IconData icon,
    required String titulo,
    required String descripcion,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.graphSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.graph, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                descripcion,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
            Icon(Icons.add_circle_outline_rounded, color: AppColors.graph),
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
            labelText: 'Nombre o etiqueta del nodo',
            prefixIcon: const Icon(
              Icons.radio_button_checked,
              color: AppColors.graph,
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
              backgroundColor: AppColors.graph,
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
            const Icon(Icons.settings_outlined, color: AppColors.graph),
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
          'Selecciona una opción de gestión para este elemento:',
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
              backgroundColor: AppColors.graph,
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
            prefixIcon: const Icon(Icons.edit, color: AppColors.graph),
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
              backgroundColor: AppColors.graph,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              if (nombreController.text.isNotEmpty) {
                setState(() {
                  nodo.nombre = nombreController.text;
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
    pesoController.clear();
    tipoConexion = 'unidireccional';

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
                      color: AppColors.graph.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.graph.withValues(alpha: 0.4),
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
                'Configurar Enlace',
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
                  labelText: 'Peso de la arista (Vacío = 0)',
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
                      color: AppColors.graph,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Tipo de dirección:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              StatefulBuilder(
                builder: (context, setState) => RadioGroup<String>(
                  groupValue: tipoConexion,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => tipoConexion = value);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: const Color(0xFF1E1E24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Column(
                      children: [
                        const RadioListTile<String>(
                          title: Text(
                            'Sin dirección (No dirigido)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                          ),
                          value: 'sin_direccion',
                          activeColor: AppColors.graph,
                        ),
                        Divider(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                        const RadioListTile<String>(
                          title: Text(
                            'Unidireccional (Dirigido)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                          ),
                          value: 'unidireccional',
                          activeColor: AppColors.graph,
                        ),
                      ],
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
                      backgroundColor: AppColors.graph,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: AppColors.graph.withValues(alpha: 0.5),
                    ),
                    onPressed: () {
                      final int pesoFinal =
                          int.tryParse(pesoController.text) ?? 0;
                      setState(() {
                        final randomColor = Color(
                          (Random().nextDouble() * 0xFFFFFF).toInt(),
                        ).withValues(alpha: 1.0);
                        conexiones.add(
                          Conexion(
                            nodoA: nodoOrigenTemp.id,
                            nodoB: nodoDestino.id,
                            peso: pesoFinal,
                            tipo: tipoConexion,
                            color: randomColor,
                          ),
                        );
                      });
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Conectar Arista',
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.surface,
        title: const Text(
          'Eliminar Vértice',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text),
        ),
        content: Text(
          '¿Deseas eliminar el nodo "${nodo.nombre}" y todas sus conexiones asociadas?',
          style: const TextStyle(color: AppColors.textMuted),
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
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              setState(() {
                conexiones.removeWhere(
                  (c) => c.nodoA == nodo.id || c.nodoB == nodo.id,
                );
                nodos.remove(nodo);
                if (nodoOrigen?.id == nodo.id) nodoOrigen = null;
              });
              Navigator.pop(context);
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void borrarConexion(Conexion conexion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.surface,
        title: const Text(
          'Eliminar Conexión',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text),
        ),
        content: const Text(
          '¿Estás seguro de que deseas eliminar esta arista?',
          style: TextStyle(color: AppColors.textMuted),
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
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              setState(() {
                conexiones.remove(conexion);
              });
              Navigator.pop(context);
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void mostrarOpcionesConexion(Conexion conexion) {
    pesoController.text = conexion.peso.toString();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.surface,
        title: const Text(
          'Editar Conexión',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text),
        ),
        content: TextField(
          controller: pesoController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Nuevo Peso',
            prefixIcon: const Icon(
              Icons.line_weight_rounded,
              color: AppColors.graph,
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
              backgroundColor: AppColors.graph,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final int pesoEditado = int.tryParse(pesoController.text) ?? 0;
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
        if (conexion.nodoA == conexion.nodoB) {
          final start = nodoA.posicion + const Offset(-12, -24);
          final end = nodoA.posicion + const Offset(12, -24);
          final control1 = nodoA.posicion + const Offset(-40, -70);
          final control2 = nodoA.posicion + const Offset(40, -70);
          for (int i = 0; i <= 10; i++) {
            double t = i / 10.0;
            double u = 1 - t;
            double tt = t * t;
            double uu = u * u;
            double uuu = uu * u;
            double ttt = tt * t;
            Offset point =
                start * uuu +
                control1 * (3 * uu * t) +
                control2 * (3 * u * tt) +
                end * ttt;
            if ((posicion - point).distance < 20) {
              return conexion;
            }
          }
          continue;
        }
        final hayInversa = conexiones.any(
          (c) =>
              c.nodoA == conexion.nodoB &&
              c.nodoB == conexion.nodoA &&
              c.tipo == 'unidireccional',
        );
        final direccion = (nodoB.posicion - nodoA.posicion).normalize();
        final desdeAjustado = nodoA.posicion + direccion * 28;
        final hastaAjustado = nodoB.posicion - direccion * 28;
        if (conexion.tipo == 'unidireccional' && hayInversa) {
          final centro = Offset(
            (desdeAjustado.dx + hastaAjustado.dx) / 2,
            (desdeAjustado.dy + hastaAjustado.dy) / 2,
          );
          final distancia = (hastaAjustado - desdeAjustado).distance;
          final offset = Offset(
            (hastaAjustado.dy - desdeAjustado.dy) / distancia * 35,
            (desdeAjustado.dx - hastaAjustado.dx) / distancia * 35,
          );
          final pControl = centro + offset;
          for (int i = 0; i <= 10; i++) {
            double t = i / 10.0;
            double u = 1 - t;
            double tt = t * t;
            double uu = u * u;
            double uuu = uu * u;
            double ttt = tt * t;
            Offset point =
                desdeAjustado * uuu +
                pControl * (3 * uu * t) +
                pControl * (3 * u * tt) +
                hastaAjustado * ttt;
            if ((posicion - point).distance < 20) {
              return conexion;
            }
          }
        } else {
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
        }
      } catch (_) {}
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlgorithmScaffold(
      accent: AppColors.graph,
      title: 'Redes y Grafos',
      icon: Icons.hub_rounded,
      actions: [
        IconButton(
          onPressed: () {
            setState(() {
              mostrarMatriz = !mostrarMatriz;
            });
          },
          icon: Icon(
            mostrarMatriz ? Icons.close_rounded : Icons.grid_view_rounded,
            color: AppColors.graph,
          ),
          tooltip: mostrarMatriz ? 'Ocultar matriz' : 'Mostrar matriz',
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
                mostrarAyuda();
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
                title: Text('Ayuda'),
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
              accent: AppColors.graph,
              emptyIcon: Icons.hub_outlined,
              emptyTitle: 'Construye tu primera red',
              canvas: Listener(
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
                    final nodo = obtenerNodoEnPosicion(details.localPosition);
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
                    final nodo = obtenerNodoEnPosicion(details.localPosition);
                    if (nodo != null) {
                      mostrarOpcionesNodo(nodo);
                    }
                  },
                  onLongPressStart: (details) {
                    final nodo = obtenerNodoEnPosicion(details.localPosition);
                    if (nodo != null) {
                      mostrarOpcionesNodo(nodo);
                    }
                  },
                  onPanStart: (details) {
                    final nodo = obtenerNodoEnPosicion(details.localPosition);
                    if (nodo != null) {
                      nodoDragging = nodo;
                    }
                  },
                  onPanUpdate: (details) {
                    if (nodoDragging != null) {
                      setState(() {
                        nodoDragging!.posicion += details.delta;
                      });
                    }
                  },
                  onPanEnd: (details) {
                    nodoDragging = null;
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: CustomPaint(
                      painter: GrafoPainter(nodos, conexiones, nodoOrigen),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),
              panel: mostrarMatriz
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
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.analytics_outlined,
                                  color: AppColors.graph,
                                  size: 22,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Matriz de Adyacencia y Grados',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.text,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: nodos.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.hub_outlined,
                                          size: 56,
                                          color: const Color(0xFF94A3B8)
                                              .withValues(alpha: 0.4),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'No hay nodos creados aún',
                                          style: TextStyle(
                                            color: AppColors.textMuted,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : SingleChildScrollView(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: _construirMatrizTabla(),
                                        ),
                                        const SizedBox(height: 24),
                                        _construirPanelGradoMatematicoExacto(),
                                      ],
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    )
                  : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: AlgorithmCanvasControls(
              onClear: () => setState(() {
                nodos.clear();
                conexiones.clear();
                nodoOrigen = null;
              }),
              nodeCount: nodos.length,
              connectionCount: conexiones.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirPanelGradoMatematicoExacto() {
    int n = nodos.length;
    if (n == 0) return const SizedBox.shrink();

    List<List<int>> matriz = List.generate(n, (_) => List.filled(n, 0));
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        int peso = 0;
        for (var c in conexiones) {
          if (c.nodoA == nodos[i].id && c.nodoB == nodos[j].id) {
            peso = c.peso;
            break;
          }
          if (c.tipo == 'sin_direccion' &&
              ((c.nodoA == nodos[i].id && c.nodoB == nodos[j].id) ||
                  (c.nodoA == nodos[j].id && c.nodoB == nodos[i].id))) {
            peso = c.peso;
            break;
          }
        }
        matriz[i][j] = peso;
      }
    }

    List<int> gradosVertices = [];
    List<Widget> detallesList = [];

    for (int i = 0; i < n; i++) {
      int cantConexionesV = 0;
      for (int j = 0; j < n; j++) {
        if (matriz[i][j] != 0) {
          cantConexionesV++;
        }
      }
      gradosVertices.add(cantConexionesV);
      detallesList.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                '• Vértice "${nodos[i].nombre}":',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.graphSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Grado = $cantConexionesV',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.graph,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    int gradoGrafoMax = gradosVertices.isNotEmpty
        ? gradosVertices.reduce(max)
        : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cálculo del Grado del Grafo Δ(G):',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Δ(G) = max{grado(v) : v ∈ V} (basado en aristas)',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppColors.textMuted,
            ),
          ),
          const Divider(height: 20),
          ...detallesList,
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Grado Máximo Δ(G):',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: AppColors.text,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.graph,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$gradoGrafoMax',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.text,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _construirMatrizTabla() {
    int n = nodos.length;
    List<List<int>> matriz = List.generate(n, (_) => List.filled(n, 0));
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        int peso = 0;
        for (var c in conexiones) {
          if (c.nodoA == nodos[i].id && c.nodoB == nodos[j].id) {
            peso = c.peso;
            break;
          }
          if (c.tipo == 'sin_direccion' &&
              c.nodoA == nodos[j].id &&
              c.nodoB == nodos[i].id) {
            peso = c.peso;
            break;
          }
        }
        matriz[i][j] = peso;
      }
    }
    List<TableRow> filas = [];
    List<Widget> cabeceraWidgets = [
      const Padding(
        padding: EdgeInsets.all(10.0),
        child: Text('', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    ];
    for (var node in nodos) {
      cabeceraWidgets.add(
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            node.nombre,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.graph,
            ),
          ),
        ),
      );
    }
    cabeceraWidgets.add(
      const Padding(
        padding: EdgeInsets.all(10.0),
        child: Text(
          'Suma',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text),
        ),
      ),
    );
    cabeceraWidgets.add(
      const Padding(
        padding: EdgeInsets.all(10.0),
        child: Text(
          'Out',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text),
        ),
      ),
    );
    filas.add(TableRow(children: cabeceraWidgets));
    List<int> sumaCols = List.filled(n, 0);
    List<int> cantCols = List.filled(n, 0);
    for (int i = 0; i < n; i++) {
      int sumaFila = 0;
      int cantFila = 0;
      List<Widget> celdas = [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            nodos[i].nombre,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.graph,
            ),
          ),
        ),
      ];
      for (int j = 0; j < n; j++) {
        int val = matriz[i][j];
        sumaFila += val;
        if (val != 0) {
          cantFila++;
          sumaCols[j] += val;
          cantCols[j]++;
        }
        celdas.add(
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Center(
              child: Text(
                val.toString(),
                style: TextStyle(
                  color: val == 0 ? const Color(0xFF94A3B8) : AppColors.text,
                  fontWeight: val == 0 ? FontWeight.normal : FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }
      celdas.add(
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Center(
            child: Text(
              '$sumaFila',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.graph,
              ),
            ),
          ),
        ),
      );
      celdas.add(
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Center(
            child: Text(
              '$cantFila',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.graph,
              ),
            ),
          ),
        ),
      );
      filas.add(TableRow(children: celdas));
    }
    List<Widget> filaSumaCols = [
      const Padding(
        padding: EdgeInsets.all(10.0),
        child: Text(
          'Suma',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text),
        ),
      ),
    ];
    for (int j = 0; j < n; j++) {
      filaSumaCols.add(
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Center(
            child: Text(
              '${sumaCols[j]}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.graph,
              ),
            ),
          ),
        ),
      );
    }
    filaSumaCols.add(
      const Padding(padding: EdgeInsets.all(10.0), child: Text('')),
    );
    filaSumaCols.add(
      const Padding(padding: EdgeInsets.all(10.0), child: Text('')),
    );
    filas.add(TableRow(children: filaSumaCols));
    List<Widget> filaCantCols = [
      const Padding(
        padding: EdgeInsets.all(10.0),
        child: Text(
          'In',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text),
        ),
      ),
    ];
    for (int j = 0; j < n; j++) {
      filaCantCols.add(
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Center(
            child: Text(
              '${cantCols[j]}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.graph,
              ),
            ),
          ),
        ),
      );
    }
    filaCantCols.add(
      const Padding(padding: EdgeInsets.all(10.0), child: Text('')),
    );
    filaCantCols.add(
      const Padding(padding: EdgeInsets.all(10.0), child: Text('')),
    );
    filas.add(TableRow(children: filaCantCols));
    return Table(
      border: TableBorder.all(color: AppColors.border, width: 1),
      defaultColumnWidth: const IntrinsicColumnWidth(),
      children: filas,
    );
  }
}
