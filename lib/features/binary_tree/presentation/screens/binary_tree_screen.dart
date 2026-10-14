import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/features/binary_tree/domain/binary_tree.dart';
import 'package:app_grafos/features/binary_tree/domain/binary_tree_document.dart';
import 'package:app_grafos/features/binary_tree/presentation/widgets/binary_tree_canvas.dart';
import 'package:app_grafos/features/binary_tree/presentation/widgets/binary_tree_help.dart';
import 'package:app_grafos/shared/persistence/graph_file_service.dart';
import 'package:app_grafos/shared/widgets/algorithm_scaffold.dart';
import 'package:app_grafos/shared/widgets/graph_save_dialog.dart';

class BinaryTreeScreen extends StatefulWidget {
  const BinaryTreeScreen({
    super.key,
    this.initialNumbers,
    this.fileService = const GraphFileService(),
  });
  final List<int>? initialNumbers;
  final GraphFileService fileService;
  @override
  State<BinaryTreeScreen> createState() => _BinaryTreeScreenState();
}

class _BinaryTreeScreenState extends State<BinaryTreeScreen> {
  BinaryTree _tree = const BinaryTree(null);
  String _name = 'arbol_binario';
  String _source = 'Árbol binario';
  String? _error;
  String? _notice;
  Map<int, Offset> _positions = {};
  final _panelScroll = ScrollController();
  final _numbers = TextEditingController(text: '8, 3, 10, 1, 6, 14, 4, 7, 13');
  final _minimum = TextEditingController(text: '1');
  final _maximum = TextEditingController(text: '100');
  final _count = TextEditingController(text: '9');
  final _firstOrder = TextEditingController();
  final _secondOrder = TextEditingController();
  TreeTraversalPair _pair = TreeTraversalPair.inPre;

  @override
  void initState() {
    super.initState();
    final numbers = widget.initialNumbers;
    if (numbers != null) {
      _tree = BinaryTree.fromInsertion(numbers);
      _numbers.text = numbers.join(', ');
      _source = 'Árbol de ejemplo · Explora sus recorridos';
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _numbers,
      _minimum,
      _maximum,
      _count,
      _firstOrder,
      _secondOrder,
    ]) {
      controller.dispose();
    }
    _panelScroll.dispose();
    super.dispose();
  }

  void _showError(String error) {
    setState(() => _error = error);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _panelScroll.hasClients) {
        _panelScroll.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _apply(BinaryTree Function() build, String source) {
    try {
      final tree = build();
      setState(() {
        _tree = tree;
        _source = source;
        _error = null;
        _notice = null;
        _positions = {};
      });
    } on FormatException catch (error) {
      _showError(error.message.toString());
    }
  }

  void _generate() => _apply(() {
    final minimum = int.tryParse(_minimum.text.trim());
    final maximum = int.tryParse(_maximum.text.trim());
    final count = int.tryParse(_count.text.trim());
    if (minimum == null || maximum == null || count == null) {
      throw const FormatException(
        'Indica mínimo, máximo y cantidad con números enteros.',
      );
    }
    final values = BinaryTree.randomValues(
      count: count,
      minimum: minimum,
      maximum: maximum,
    );
    final tree = BinaryTree.fromInsertion(values);
    _numbers.text = values.join(', ');
    return tree;
  }, 'Árbol de búsqueda · Números aleatorios');

  void _reconstruct() {
    TreeReconstructionResult? result;
    _apply(() {
      result = BinaryTree.reconstruct(
        firstOrder: BinaryTree.parseNumbers(_firstOrder.text),
        firstTraversal: _pair.first,
        secondOrder: BinaryTree.parseNumbers(_secondOrder.text),
        secondTraversal: _pair.second,
      );
      return result!.tree;
    }, 'Árbol reconstruido · ${_pair.label}');
    if (result != null && result!.isAmbiguous) {
      setState(
        () => _notice =
            'Hay varias soluciones para estos recorridos. '
            'Se muestra un árbol válido colocando los hijos únicos a la izquierda.',
      );
    }
  }

  Future<void> _save() async {
    final document = BinaryTreeDocument(
      name: _name,
      tree: _tree,
      positions: {
        for (final entry in _positions.entries)
          entry.key: TreeNodePosition(entry.value.dx, entry.value.dy),
      },
    );
    final name = await showJsonSaveDialog(
      context,
      initialName: _name,
      jsonBuilder: (name) => document.encode(name: name),
      service: widget.fileService,
    );
    if (name != null && mounted) setState(() => _name = name);
  }

  Future<void> _load() async {
    try {
      final json = await widget.fileService.readJson();
      if (json == null) return;
      final document = BinaryTreeDocument.decode(json);
      if (!mounted) return;
      setState(() {
        _tree = document.tree;
        _name = document.name;
        _source = 'Árbol cargado desde JSON';
        _error = null;
        _notice = null;
        _positions = {
          for (final entry in document.positions.entries)
            entry.key: Offset(entry.value.x, entry.value.y),
        };
        _numbers.text = _tree.traverse(TreeTraversal.preOrder).join(', ');
        _firstOrder.text = _tree.traverse(_pair.first).join(', ');
        _secondOrder.text = _tree.traverse(_pair.second).join(', ');
      });
    } on FormatException catch (error) {
      if (mounted) _showError(error.message.toString());
    } catch (_) {
      if (mounted) {
        _showError(
          'No se pudo leer el archivo. Selecciona un JSON de árboles binarios.',
        );
      }
    }
  }

  void _copyTraversals() {
    _firstOrder.text = _tree.traverse(_pair.first).join(', ');
    _secondOrder.text = _tree.traverse(_pair.second).join(', ');
    setState(() => _error = null);
  }

  TextField _field(
    TextEditingController controller,
    String label, {
    String? hint,
    bool sequence = true,
  }) => TextField(
    controller: controller,
    decoration: InputDecoration(labelText: label, hintText: hint),
    maxLines: sequence ? 2 : 1,
    keyboardType: sequence
        ? TextInputType.text
        : const TextInputType.numberWithOptions(signed: true),
  );

  @override
  Widget build(BuildContext context) => AlgorithmScaffold(
    title: 'Árboles binarios',
    icon: Icons.account_tree_rounded,
    actions: [
      PopupMenuButton<String>(
        tooltip: 'Más opciones',
        onSelected: (value) {
          if (value == 'guardar') _save();
          if (value == 'cargar') _load();
          if (value == 'ayuda') showBinaryTreeHelp(context);
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'guardar',
            enabled: _tree.root != null,
            child: const ListTile(
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
    ],
    body: AlgorithmWorkspace(
      isEmpty: _tree.root == null,
      emptyIcon: Icons.account_tree_outlined,
      emptyTitle: 'Construye tu árbol',
      emptyDescription: 'Introduce números, genera un rango aleatorio o combina dos recorridos.',
      canvas: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              runSpacing: 8,
              children: [
                Text(
                  _source,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${_tree.size} nodos · ${_tree.height} niveles',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                TextButton.icon(
                  onPressed: _tree.root == null
                      ? null
                      : () => setState(() {
                          _tree = const BinaryTree(null);
                          _source = 'Árbol binario';
                          _error = null;
                          _notice = null;
                          _positions = {};
                        }),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Limpiar árbol'),
                ),
              ],
            ),
          ),
          Expanded(
            child: BinaryTreeCanvas(
              tree: _tree,
              positions: _positions,
              onPositionsChanged: (positions) =>
                  setState(() => _positions = positions),
            ),
          ),
        ],
      ),
      panel: SingleChildScrollView(
        controller: _panelScroll,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              Semantics(
                liveRegion: true,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warningSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _error!,
                    key: const ValueKey('tree-error'),
                    style: const TextStyle(
                      color: AppColors.warningText,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            AlgorithmPanelSection(
              title: 'Crear por teclado',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _field(
                    _numbers,
                    'Números de inserción',
                    hint: '8, 3, 10, 1, 6',
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _apply(
                      () => BinaryTree.fromInsertion(
                        BinaryTree.parseNumbers(_numbers.text),
                      ),
                      'Árbol de búsqueda · Inserción por teclado',
                    ),
                    icon: const Icon(Icons.account_tree_rounded),
                    label: const Text('Crear árbol'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AlgorithmPanelSection(
              title: 'Aleatorios por rango',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _field(_minimum, 'Mínimo', sequence: false),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(_maximum, 'Máximo', sequence: false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _field(_count, 'Cantidad de nodos', sequence: false),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _generate,
                    icon: const Icon(Icons.shuffle_rounded),
                    label: const Text('Generar árbol aleatorio'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AlgorithmPanelSection(
              title: 'Reconstruir con dos recorridos',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Las dos listas deben contener los mismos números, sin repetir.',
                    style: TextStyle(color: AppColors.textMuted, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final pair in TreeTraversalPair.values)
                        ChoiceChip(
                          label: Text(pair.label),
                          selected: _pair == pair,
                          onSelected: (_) => setState(() {
                            if (_pair.first != pair.first) _firstOrder.clear();
                            if (_pair.second != pair.second) {
                              _secondOrder.clear();
                            }
                            _pair = pair;
                            _error = null;
                          }),
                        ),
                    ],
                  ),
                  if (_notice != null) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _notice!,
                        key: const ValueKey('tree-ambiguity'),
                        style: const TextStyle(
                          color: AppColors.warningText,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _field(_firstOrder, 'Recorrido ${_pair.first.label}'),
                  const SizedBox(height: 12),
                  _field(_secondOrder, 'Recorrido ${_pair.second.label}'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _reconstruct,
                    child: const Text('Reconstruir árbol'),
                  ),
                  TextButton(
                    onPressed: _tree.root == null ? null : _copyTraversals,
                    child: const Text('Usar recorridos del árbol actual'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (final traversal in TreeTraversal.values) ...[
              AlgorithmPanelSection(
                title: switch (traversal) {
                  TreeTraversal.preOrder =>
                    'Pre-order · Raíz, izquierda, derecha',
                  TreeTraversal.inOrder =>
                    'In-order · Izquierda, raíz, derecha',
                  TreeTraversal.postOrder =>
                    'Post-order · Izquierda, derecha, raíz',
                },
                child: SelectableText(
                  _tree.root == null
                      ? '—'
                      : _tree.traverse(traversal).join(', '),
                  key: ValueKey(traversal),
                  style: const TextStyle(height: 1.6),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    ),
  );
}
