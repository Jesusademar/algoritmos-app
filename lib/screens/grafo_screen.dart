import 'dart:math';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_selector/file_selector.dart';

import '../models/nodo.dart';
import '../models/conexion.dart';
import '../shared/persistence/graph_document.dart';
import '../shared/persistence/graph_document_codec.dart';

class GrafoScreen extends StatefulWidget {
  const GrafoScreen({super.key});

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
  final jsonController = TextEditingController();
  final nombreArchivoController = TextEditingController(text: 'grafo_proyecto');
  String tipoConexion = 'unidireccional';

  Future<void> guardarEnDescargas() async {
    try {
      final nombre = nombreArchivoController.text.isNotEmpty
          ? nombreArchivoController.text
          : 'grafo';
      final jsonString = _documentCodec.encode(
        GraphDocument(name: nombre, nodes: nodos, connections: conexiones),
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
            : 'grafo',
        nodes: nodos,
        connections: conexiones,
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
              'Guardar Estructura del Grafo',
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
                decoration: InputDecoration(
                  hintText: 'ej. grafo_red_social',
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
                'Estructura JSON generada:',
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
              'Descargar Archivo JSON',
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
        nodos = document.nodes.toList();
        conexiones = document.connections.toList();
        nodoOrigen = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✨ ¡Grafo cargado exitosamente al lienzo!'),
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

  void mostrarAyuda() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(
              Icons.auto_stories_rounded,
              color: Color(0xFF6366F1),
              size: 28,
            ),
            SizedBox(width: 14),
            Text(
              'Manual y Guía de Uso del Sistema',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color(0xFF1E293B),
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
              backgroundColor: const Color(0xFF6366F1),
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
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF6366F1), size: 22),
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
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                descripcion,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF475569),
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
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.add_circle_outline_rounded, color: Color(0xFF6366F1)),
            SizedBox(width: 10),
            Text(
              'Nuevo Vértice',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
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
        content: const Text(
          'Selecciona una opción de gestión para este elemento:',
          style: TextStyle(color: Color(0xFF475569)),
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
        backgroundColor: Colors.white,
        title: const Text(
          'Editar Nombre del Nodo',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        content: TextField(
          controller: nombreController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Nuevo Nombre',
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
                      color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.4),
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
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
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
                  color: Colors.white,
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
                  color: Colors.white,
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
                      color: Color(0xFF6366F1),
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
                          activeColor: Color(0xFF6366F1),
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
                          activeColor: Color(0xFF6366F1),
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

  void borrarNodo(Nodo nodo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: const Text(
          'Eliminar Vértice',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        content: Text(
          '¿Deseas eliminar el nodo "${nodo.nombre}" y todas sus conexiones asociadas?',
          style: const TextStyle(color: Color(0xFF475569)),
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
        backgroundColor: Colors.white,
        title: const Text(
          'Eliminar Conexión',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        content: const Text(
          '¿Estás seguro de que deseas eliminar esta arista?',
          style: TextStyle(color: Color(0xFF475569)),
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
        backgroundColor: Colors.white,
        title: const Text(
          'Editar Conexión',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        content: TextField(
          controller: pesoController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Nuevo Peso',
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.hub_rounded,
                color: Color(0xFF6366F1),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                'Editor de Grafos Pro',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
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
              setState(() {
                mostrarMatriz = !mostrarMatriz;
              });
            },
            icon: Icon(
              mostrarMatriz ? Icons.close_rounded : Icons.grid_view_rounded,
              color: const Color(0xFF6366F1),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Listener(
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
                ),
                if (mostrarMatriz) ...[
                  Container(width: 1, color: const Color(0xFFE2E8F0)),
                  SizedBox(
                    width: 440,
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.analytics_outlined,
                                  color: Color(0xFF6366F1),
                                  size: 22,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Matriz de Adyacencia y Grados',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
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
                                            color: Color(0xFF64748B),
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
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: () => setState(() {
                    nodos.clear();
                    conexiones.clear();
                    nodoOrigen = null;
                  }),
                  icon: const Icon(
                    Icons.delete_sweep_rounded,
                    size: 18,
                    color: Color(0xFF64748B),
                  ),
                  label: const Text(
                    'Limpiar lienzo',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Nodos: ${nodos.length}   •   Conexiones: ${conexiones.length}',
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '• Vértice "${nodos[i].nombre}":',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF334155),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Grado = $cantConexionesV',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1),
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
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cálculo del Grado del Grafo Δ(G):',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Δ(G) = max{grado(v) : v ∈ V} (basado en aristas)',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Color(0xFF64748B),
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
                  color: Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$gradoGrafoMax',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
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
              color: Color(0xFF6366F1),
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
    );
    cabeceraWidgets.add(
      const Padding(
        padding: EdgeInsets.all(10.0),
        child: Text(
          'Out',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
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
              color: Color(0xFF6366F1),
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
                  color: val == 0
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF0F172A),
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
                color: Color(0xFF6366F1),
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
                color: Color(0xFF6366F1),
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
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
                color: Color(0xFF6366F1),
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
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
                color: Color(0xFF6366F1),
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
      border: TableBorder.all(color: const Color(0xFFE2E8F0), width: 1),
      defaultColumnWidth: const IntrinsicColumnWidth(),
      children: filas,
    );
  }
}

class GrafoPainter extends CustomPainter {
  final List<Nodo> nodos;
  final List<Conexion> conexiones;
  final Nodo? nodoOrigen;

  GrafoPainter(this.nodos, this.conexiones, this.nodoOrigen);

  void dibujarFlecha(Canvas canvas, Offset desde, Offset hasta, Color color) {
    final direccion = (hasta - desde).normalize();
    final desdeAjustado = desde + direccion * 28;
    final hastaAjustado = hasta - direccion * 28;
    canvas.drawLine(
      desdeAjustado,
      hastaAjustado,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    final base = hastaAjustado - direccion * 14;
    final perp = Offset(-direccion.dy, direccion.dx) * 8;
    canvas.drawPath(
      Path()
        ..moveTo(base.dx + perp.dx, base.dy + perp.dy)
        ..lineTo(hastaAjustado.dx, hastaAjustado.dy)
        ..lineTo(base.dx - perp.dx, base.dy - perp.dy)
        ..close(),
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  void dibujarFlechaCurva(
    Canvas canvas,
    Offset desde,
    Offset hasta,
    Color color,
  ) {
    final direccion = (hasta - desde).normalize();
    final desdeAjustado = desde + direccion * 28;
    final hastaAjustado = hasta - direccion * 28;
    final centro = Offset(
      (desdeAjustado.dx + hastaAjustado.dx) / 2,
      (desdeAjustado.dy + hastaAjustado.dy) / 2,
    );
    final distancia = (hastaAjustado - desdeAjustado).distance;
    final offset = Offset(
      (hastaAjustado.dy - desdeAjustado.dy) / distancia * 35,
      (desdeAjustado.dx - hastaAjustado.dx) / distancia * 35,
    );
    final path = Path();
    path.moveTo(desdeAjustado.dx, desdeAjustado.dy);
    path.quadraticBezierTo(
      centro.dx + offset.dx,
      centro.dy + offset.dy,
      hastaAjustado.dx,
      hastaAjustado.dy,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    final dirFinal =
        (hastaAjustado - Offset(centro.dx + offset.dx, centro.dy + offset.dy))
            .normalize();
    final base = hastaAjustado - dirFinal * 14;
    final perp = Offset(-dirFinal.dy, dirFinal.dx) * 8;
    canvas.drawPath(
      Path()
        ..moveTo(base.dx + perp.dx, base.dy + perp.dy)
        ..lineTo(hastaAjustado.dx, hastaAjustado.dy)
        ..lineTo(base.dx - perp.dx, base.dy - perp.dy)
        ..close(),
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  void dibujarBucle(Canvas canvas, Offset pos, Color color) {
    final start = pos + const Offset(-12, -24);
    final end = pos + const Offset(12, -24);
    final control1 = pos + const Offset(-40, -70);
    final control2 = pos + const Offset(40, -70);
    final path = Path();
    path.moveTo(start.dx, start.dy);
    path.cubicTo(
      control1.dx,
      control1.dy,
      control2.dx,
      control2.dy,
      end.dx,
      end.dy,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    final dirFinal = (end - control2).normalize();
    final base = end - dirFinal * 12;
    final perp = Offset(-dirFinal.dy, dirFinal.dx) * 7;
    canvas.drawPath(
      Path()
        ..moveTo(base.dx + perp.dx, base.dy + perp.dy)
        ..lineTo(end.dx, end.dy)
        ..lineTo(base.dx - perp.dx, base.dy - perp.dy)
        ..close(),
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (var conexion in conexiones) {
      final nodoA = nodos.firstWhere((n) => n.id == conexion.nodoA);
      final nodoB = nodos.firstWhere((n) => n.id == conexion.nodoB);
      Offset medio;
      final Color colorActual = conexion.color;
      if (conexion.nodoA == conexion.nodoB) {
        dibujarBucle(canvas, nodoA.posicion, colorActual);
        medio = nodoA.posicion + const Offset(0, -60);
      } else {
        final hayInversa = conexiones.any(
          (c) =>
              c.nodoA == conexion.nodoB &&
              c.nodoB == conexion.nodoA &&
              c.tipo == 'unidireccional',
        );
        if (conexion.tipo == 'sin_direccion') {
          canvas.drawLine(
            nodoA.posicion,
            nodoB.posicion,
            Paint()
              ..color = colorActual
              ..strokeWidth = 2.5
              ..strokeCap = StrokeCap.round,
          );
        } else {
          if (hayInversa) {
            dibujarFlechaCurva(
              canvas,
              nodoA.posicion,
              nodoB.posicion,
              colorActual,
            );
          } else {
            dibujarFlecha(canvas, nodoA.posicion, nodoB.posicion, colorActual);
          }
        }
        if (conexion.tipo == 'unidireccional' && hayInversa) {
          final direccion = (nodoB.posicion - nodoA.posicion).normalize();
          final desdeAjustado = nodoA.posicion + direccion * 28;
          final hastaAjustado = nodoB.posicion - direccion * 28;
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
          medio = desdeAjustado * 0.25 + pControl * 0.5 + hastaAjustado * 0.25;
        } else {
          medio = Offset(
            (nodoA.posicion.dx + nodoB.posicion.dx) / 2,
            (nodoA.posicion.dy + nodoB.posicion.dy) / 2,
          );
        }
      }
      final textPainter = TextPainter(
        text: TextSpan(
          text: ' ${conexion.peso} ',
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final bgRect = Rect.fromCenter(
        center: medio,
        width: textPainter.width + 10,
        height: textPainter.height + 6,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bgRect, const Radius.circular(8)),
        Paint()..color = Colors.white,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bgRect, const Radius.circular(8)),
        Paint()
          ..color = const Color(0xFFCBD5E1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      textPainter.paint(
        canvas,
        medio - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
    for (var nodo in nodos) {
      final esOrigen = nodo.id == nodoOrigen?.id;
      canvas.drawCircle(
        nodo.posicion + const Offset(0, 4),
        26,
        Paint()..color = Colors.black.withValues(alpha: 0.08),
      );
      canvas.drawCircle(
        nodo.posicion,
        26,
        Paint()..color = esOrigen ? const Color(0xFFEEF2FF) : Colors.white,
      );
      canvas.drawCircle(
        nodo.posicion,
        26,
        Paint()
          ..color = esOrigen ? const Color(0xFF6366F1) : const Color(0xFFCBD5E1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = esOrigen ? 3 : 1.5,
      );
      final textPainter = TextPainter(
        text: TextSpan(
          text: nodo.nombre,
          style: TextStyle(
            color: esOrigen ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        nodo.posicion - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(GrafoPainter oldDelegate) => true;
}

extension on Offset {
  Offset normalize() {
    final distance = this.distance;
    if (distance == 0) return Offset.zero;
    return Offset(dx / distance, dy / distance);
  }
}
