import 'package:flutter/material.dart';
import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/features/network_algorithms/domain/network_algorithm.dart';
import 'package:app_grafos/features/network_algorithms/domain/network_objective.dart';
import 'package:app_grafos/features/network_algorithms/domain/longest_path_solver.dart';
import 'package:app_grafos/features/network_algorithms/domain/weighted_network.dart';
import 'package:app_grafos/features/network_algorithms/domain/kruskal_solver.dart';
import 'package:app_grafos/features/network_algorithms/domain/dijkstra_solver.dart';
import 'package:app_grafos/features/network_algorithms/presentation/widgets/network_graph_painter.dart';
import 'package:app_grafos/shared/graph_editor/models/conexion.dart';
import 'package:app_grafos/shared/graph_editor/models/nodo.dart';
import 'package:app_grafos/shared/graph_editor/widgets/graph_canvas_viewport.dart';
import 'package:app_grafos/shared/help/algorithm_manuals.dart';
import 'package:app_grafos/shared/persistence/graph_document.dart';
import 'package:app_grafos/shared/persistence/graph_document_codec.dart';
import 'package:app_grafos/shared/persistence/graph_file_service.dart';
import 'package:app_grafos/shared/widgets/algorithm_scaffold.dart';
import 'package:app_grafos/shared/widgets/algorithm_manual_dialog.dart';
import 'package:app_grafos/shared/widgets/graph_save_dialog.dart';
import 'package:app_grafos/shared/widgets/mathematical_procedure_dialog.dart';

class NetworkAlgorithmScreen extends StatefulWidget {
  const NetworkAlgorithmScreen({
    super.key,
    required this.algorithm,
    this.initialDocument,
    this.fileService = const GraphFileService(),
  });
  final NetworkAlgorithm algorithm;
  final GraphDocument? initialDocument;
  final GraphFileService fileService;
  @override
  State<NetworkAlgorithmScreen> createState() => _NetworkAlgorithmScreenState();
}

class _NetworkAlgorithmScreenState extends State<NetworkAlgorithmScreen> {
  List<Nodo> _nodes = [];
  List<Conexion> _edges = [];
  String? _selected;
  String? _source;
  String? _target;
  String? _error;
  String _name = 'red';
  KruskalResult? _kruskal;
  NetworkPathResult? _dijkstra;
  NetworkObjective _objective = NetworkObjective.minimize;
  bool get _maximizing => _objective == NetworkObjective.maximize;
  int _sequence = 0;
  bool get _directed => widget.algorithm == NetworkAlgorithm.dijkstra;
  Color get _accent => _directed ? AppColors.graph : AppColors.sorting;
  String _label(String id) => _nodes.firstWhere((n) => n.id == id).nombre;

  @override
  void initState() {
    super.initState();
    if (widget.initialDocument != null) {
      _apply(
        const GraphDocumentCodec().decode(
          const GraphDocumentCodec().encode(widget.initialDocument!),
        ),
      );
    }
  }

  WeightedNetwork _network([GraphDocument? document]) => WeightedNetwork(
    nodes: (document?.nodes ?? _nodes).map((n) => n.id),
    labels: {for (final n in document?.nodes ?? _nodes) n.id: n.nombre},
    edges: (document?.connections ?? _edges).map(
      (e) => WeightedEdge(e.nodoA, e.nodoB, e.peso),
    ),
  );

  void _invalidate() {
    _kruskal = null;
    _dijkstra = null;
    _error = null;
  }

  void _change(VoidCallback change) => setState(() {
    change();
    _invalidate();
  });

  void _apply(GraphDocument document) {
    if (document.nodes.isNotEmpty || document.connections.isNotEmpty) {
      _network(document).validate(nonNegative: _directed);
    }
    final names = document.nodes.map((n) => n.nombre.trim()).toList();
    if (names.any((n) => n.isEmpty) ||
        names.toSet().length != names.length ||
        document.nodes.any(
          (n) => !n.posicion.dx.isFinite || !n.posicion.dy.isFinite,
        )) {
      throw const FormatException(
        'Las etiquetas deben ser únicas y las posiciones válidas.',
      );
    }
    final pairs = <(String, String)>{};
    for (final edge in document.connections) {
      final key = !_directed && edge.nodoA.compareTo(edge.nodoB) > 0
          ? (edge.nodoB, edge.nodoA)
          : (edge.nodoA, edge.nodoB);
      if (!pairs.add(key)) {
        throw const FormatException(
          'Hay conexiones repetidas entre la misma pareja de nodos.',
        );
      }
    }
    final mode = document.metadata['objective'];
    if (mode != null &&
        !NetworkObjective.values.any((value) => value.name == mode)) {
      throw const FormatException('El objetivo debe ser minimize o maximize.');
    }
    _objective = mode == 'maximize'
        ? NetworkObjective.maximize
        : NetworkObjective.minimize;
    _nodes = document.nodes.toList();
    _edges = document.connections.toList();
    _name = document.name;
    final source = document.metadata['source'];
    final target = document.metadata['target'];
    _source = _nodes.any((n) => n.id == source)
        ? source as String
        : _nodes.firstOrNull?.id;
    _target = _nodes.any((n) => n.id == target)
        ? target as String
        : _nodes.lastOrNull?.id;
    _selected = null;
    _invalidate();
  }

  Future<void> _load() async {
    try {
      final json = await widget.fileService.readJson();
      if (json == null || !mounted) return;
      final document = const GraphDocumentCodec().decode(json);
      setState(() => _apply(document));
    } catch (error) {
      if (mounted) {
        setState(
          () => _error =
              'No se pudo cargar: ${error is ArgumentError ? error.message : error}',
        );
      }
    }
  }

  Future<void> _save() async {
    final name = await showGraphSaveDialog(
      context,
      GraphDocument(
        name: _name,
        nodes: _nodes,
        connections: _edges,
        metadata: {
          'algorithm': widget.algorithm.name,
          'objective': _objective.name,
          'source': _source,
          'target': _target,
        },
      ),
      service: widget.fileService,
    );
    if (name != null && mounted) setState(() => _name = name);
  }

  Future<void> _editNode(Offset position, [Nodo? node]) async {
    var text = node?.nombre ?? '';
    final form = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(node == null ? 'Crear nodo' : 'Editar nodo'),
        content: Form(
          key: form,
          child: TextFormField(
            initialValue: text,
            onChanged: (value) => text = value,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nombre del nodo'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Escribe un nombre.'
                : _nodes.any((n) => n != node && n.nombre == value.trim())
                ? 'Ese nombre ya existe.'
                : null,
          ),
        ),
        actions: [
          if (node != null)
            TextButton(
              onPressed: () {
                _change(() {
                  _nodes.remove(node);
                  _edges.removeWhere(
                    (e) => e.nodoA == node.id || e.nodoB == node.id,
                  );
                  if (_source == node.id) _source = _nodes.firstOrNull?.id;
                  if (_target == node.id) _target = _nodes.lastOrNull?.id;
                  _selected = null;
                });
                Navigator.pop(context);
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(color: AppColors.warningText),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (!form.currentState!.validate()) return;
              _change(() {
                if (node != null) {
                  node.nombre = text.trim();
                } else {
                  var id = '';
                  do {
                    id =
                        'n${DateTime.now().microsecondsSinceEpoch}_${_sequence++}';
                  } while (_nodes.any((n) => n.id == id));
                  _nodes.add(
                    Nodo(id: id, nombre: text.trim(), posicion: position),
                  );
                  _source ??= id;
                  _target = id;
                }
              });
              Navigator.pop(context);
            },
            child: Text(node == null ? 'Crear' : 'Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _editEdge(Nodo from, Nodo to, [Conexion? existing]) async {
    if (from == to) {
      setState(() {
        _selected = null;
        _error = 'No se permiten bucles en un nodo.';
      });
      return;
    }
    var text = existing?.peso.toString() ?? '';
    final form = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(existing == null ? 'Conectar nodos' : 'Editar peso'),
        content: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${from.nombre} ${_directed ? '→' : '—'} ${to.nombre}',
                style: TextStyle(color: _accent),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: text,
                onChanged: (value) => text = value,
                autofocus: true,
                keyboardType: TextInputType.numberWithOptions(
                  signed: !_directed,
                ),
                decoration: const InputDecoration(labelText: 'Peso'),
                validator: (value) {
                  final weight = int.tryParse(value?.trim() ?? '');
                  return weight == null
                      ? 'Ingresa un número entero.'
                      : _directed && weight < 0
                      ? 'Dijkstra no admite pesos negativos.'
                      : null;
                },
              ),
            ],
          ),
        ),
        actions: [
          if (existing != null)
            TextButton(
              onPressed: () {
                _change(() => _edges.remove(existing));
                Navigator.pop(context);
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(color: AppColors.warningText),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (!form.currentState!.validate()) return;
              _change(() {
                if (existing != null) _edges.remove(existing);
                _edges.add(
                  Conexion(
                    nodoA: from.id,
                    nodoB: to.id,
                    peso: int.parse(text.trim()),
                    tipo: _directed ? 'unidireccional' : 'sin_direccion',
                    color: _accent,
                  ),
                );
              });
              Navigator.pop(context);
            },
            child: Text(existing == null ? 'Conectar' : 'Guardar'),
          ),
        ],
      ),
    );
  }

  Nodo? _nodeAt(Offset point) =>
      _nodes.where((n) => (n.posicion - point).distance < 30).firstOrNull;
  Conexion? _edgeAt(Offset point) => _edges
      .where(
        (e) =>
            (NetworkGraphPainter.edgeLabel(e, _nodes, _edges, _directed) -
                    point)
                .distance <
            24,
      )
      .firstOrNull;
  void _editAt(Offset point) {
    final node = _nodeAt(point);
    final edge = _edgeAt(point);
    if (node != null) {
      _editNode(point, node);
    } else if (edge != null) {
      _editEdge(
        _nodes.firstWhere((n) => n.id == edge.nodoA),
        _nodes.firstWhere((n) => n.id == edge.nodoB),
        edge,
      );
    }
  }

  void _tap(Offset point) {
    final node = _nodeAt(point);
    if (node == null) {
      if (_edgeAt(point) != null) {
        _editAt(point);
      } else {
        _editNode(point);
      }
      setState(() => _selected = null);
    } else if (_selected == null) {
      setState(() => _selected = node.id);
    } else {
      final from = _nodes.firstWhere((n) => n.id == _selected);
      final existing = _edges
          .where(
            (e) =>
                (e.nodoA == from.id && e.nodoB == node.id) ||
                (!_directed && e.nodoB == from.id && e.nodoA == node.id),
          )
          .firstOrNull;
      setState(() => _selected = null);
      _editEdge(from, node, existing);
    }
  }

  void _calculate() {
    try {
      final network = _network();
      if (_directed) {
        final result = _maximizing
            ? const LongestPathSolver().solve(network, _source ?? '')
            : const DijkstraSolver().solve(network, _source ?? '');
        setState(() {
          _dijkstra = result;
          _kruskal = null;
          _error = null;
        });
      } else {
        final result = const KruskalSolver().solve(
          network,
          objective: _objective,
        );
        setState(() {
          _kruskal = result;
          _dijkstra = null;
          _error = null;
        });
      }
    } on ArgumentError catch (error) {
      setState(() {
        _invalidate();
        _error = error.message.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = _dijkstra != null && _target != null
        ? _dijkstra!.pathTo(_target!)
        : null;
    final highlighted = {
      for (final e in _kruskal?.edges ?? path ?? <WeightedEdge>[]) e.id,
    };
    final procedure = _kruskal?.procedure ?? _dijkstra?.procedure;
    return AlgorithmScaffold(
      title: 'Algoritmo de ${widget.algorithm.title}',
      icon: _directed ? Icons.route_rounded : Icons.device_hub_rounded,
      accent: _accent,
      actions: [
        IconButton(
          tooltip: 'Calcular',
          onPressed: _calculate,
          icon: const Icon(Icons.play_arrow_rounded),
        ),
        PopupMenuButton<String>(
          tooltip: 'Más opciones',
          onSelected: (value) {
            switch (value) {
              case 'save':
                _save();
              case 'load':
                _load();
              case 'help':
                showAlgorithmManual(
                  context,
                  _directed
                      ? AlgorithmManual.dijkstra
                      : AlgorithmManual.kruskal,
                  accent: _accent,
                );
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'save', child: Text('Guardar')),
            PopupMenuItem(value: 'load', child: Text('Cargar')),
            PopupMenuItem(value: 'help', child: Text('Manual de uso')),
          ],
        ),
      ],
      body: AlgorithmWorkspace(
        accent: _accent,
        isEmpty: _nodes.isEmpty,
        emptyTitle: _directed ? 'Traza tu primera ruta' : 'Conecta tu red',
        emptyDescription: 'Toca para crear. Selecciona dos nodos para conectar. Arrastra el fondo para navegar.',
        canvas: Stack(
          children: [
            Positioned.fill(
              child: GraphCanvasViewport(
                nodes: _nodes,
                painter: NetworkGraphPainter(
                  nodes: _nodes,
                  edges: _edges,
                  directed: _directed,
                  accent: _accent,
                  selected: _selected,
                  source: _directed ? _source : null,
                  target: _directed ? _target : null,
                  highlighted: highlighted,
                  distances: _dijkstra?.distances,
                  maximizing: _maximizing,
                ),
                onTap: _tap,
                onEdit: _editAt,
                onNodeMoved: (node, position) =>
                    setState(() => node.posicion = position),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: AlgorithmCanvasControls(
                nodeCount: _nodes.length,
                connectionCount: _edges.length,
                onClear: () => _change(() {
                  _nodes.clear();
                  _edges.clear();
                  _source = null;
                  _target = null;
                  _selected = null;
                }),
              ),
            ),
          ],
        ),
        panel: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _directed
                    ? (_maximizing
                          ? 'Rutas más largas · red sin ciclos'
                          : 'Rutas más cortas · Dijkstra')
                    : (_maximizing
                          ? 'Árbol de expansión máxima'
                          : 'Árbol de expansión mínima'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _accent,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _directed
                    ? 'Conexiones dirigidas · pesos ≥ 0'
                    : 'Conexiones sin dirección · se permiten pesos negativos',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: SegmentedButton<NetworkObjective>(
                  segments: const [
                    ButtonSegment(
                      value: NetworkObjective.minimize,
                      label: Text('Minimizar'),
                      icon: Icon(Icons.arrow_downward_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: NetworkObjective.maximize,
                      label: Text('Maximizar'),
                      icon: Icon(Icons.arrow_upward_rounded, size: 16),
                    ),
                  ],
                  selected: {_objective},
                  onSelectionChanged: (values) =>
                      _change(() => _objective = values.single),
                ),
              ),
              const SizedBox(height: 16),
              if (_directed && _maximizing) ...[
                const Text(
                  'Método: orden topológico. Maximizar requiere una red dirigida sin ciclos.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (_directed && _nodes.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  key: ValueKey('source-$_source'),
                  initialValue: _source,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Nodo de inicio',
                  ),
                  items: [
                    for (final n in _nodes)
                      DropdownMenuItem(value: n.id, child: Text(n.nombre)),
                  ],
                  onChanged: (value) => _change(() => _source = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey('target-$_target'),
                  initialValue: _target,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Nodo de destino',
                  ),
                  items: [
                    for (final n in _nodes)
                      DropdownMenuItem(value: n.id, child: Text(n.nombre)),
                  ],
                  onChanged: (value) => setState(() => _target = value),
                ),
                const SizedBox(height: 16),
              ],
              FilledButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  _directed
                      ? 'Calcular rutas'
                      : (_maximizing
                            ? 'Calcular árbol máximo'
                            : 'Calcular árbol mínimo'),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: procedure == null
                    ? null
                    : () => showMathematicalProcedure(
                        context,
                        procedure,
                        accent: _accent,
                      ),
                icon: const Icon(Icons.functions_rounded),
                label: const Text('Ver procedimiento matemático'),
              ),
              if (_selected != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Origen seleccionado: ${_label(_selected!)}. Toca otro nodo para conectar.',
                    style: const TextStyle(color: AppColors.successText),
                  ),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.warningText),
                  ),
                ),
              if (_kruskal != null) ...[
                const SizedBox(height: 20),
                AlgorithmPanelSection(
                  title: _kruskal!.components == 1
                      ? (_maximizing
                            ? 'Árbol de expansión máxima'
                            : 'Árbol de expansión mínima')
                      : 'Bosque ${_maximizing ? 'máximo' : 'mínimo'} · ${_kruskal!.components} componentes',
                  highlighted: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Costo total: ${_kruskal!.total}',
                        style: const TextStyle(
                          fontSize: 19,
                          color: AppColors.successText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_kruskal!.components > 1)
                        const Text(
                          'La red no es conexa: faltan conexiones entre componentes.',
                          style: TextStyle(color: AppColors.warningText),
                        ),
                      for (final e in _kruskal!.edges)
                        Text(
                          '${_label(e.from)} — ${_label(e.to)} · ${e.weight}',
                        ),
                      const SizedBox(height: 12),
                      const Text(
                        'Big O: O(E log E) · memoria O(V + E)',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_dijkstra != null) ...[
                const SizedBox(height: 20),
                AlgorithmPanelSection(
                  title: 'Resultado desde ${_label(_source!)}',
                  highlighted: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _target == null || path == null
                            ? 'Sin ruta al destino'
                            : 'Distancia ${_maximizing ? 'máxima' : 'mínima'}: ${_dijkstra!.distances[_target]}',
                        style: const TextStyle(
                          fontSize: 19,
                          color: AppColors.successText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (path != null)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(_label(_source!)),
                            for (final edge in path) ...[
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: AppColors.success,
                              ),
                              Text(_label(edge.to)),
                            ],
                          ],
                        ),
                      const SizedBox(height: 12),
                      for (final n in _nodes)
                        Text(
                          '${n.nombre}: ${_dijkstra!.distances[n.id] ?? (_maximizing ? '−∞ · inalcanzable' : '∞ · inalcanzable')}',
                        ),
                      const SizedBox(height: 12),
                      Text(
                        _maximizing
                            ? 'Big O: O(V + E) · memoria O(V + E)'
                            : 'Big O: O(V² + E) · memoria O(V + E)',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
