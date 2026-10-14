import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/features/sorting/domain/sorting_algorithm.dart';
import 'package:app_grafos/features/sorting/domain/sorting_document.dart';
import 'package:app_grafos/features/sorting/domain/sorting_order.dart';
import 'package:app_grafos/features/sorting/presentation/screens/sorting_visualization_screen.dart';
import 'package:app_grafos/features/sorting/presentation/widgets/sorting_help_menu.dart';
import 'package:app_grafos/features/sorting/presentation/widgets/sorting_method_card.dart';
import 'package:app_grafos/features/sorting/presentation/widgets/sorting_order_selector.dart';
import 'package:app_grafos/shared/persistence/graph_file_service.dart';
import 'package:app_grafos/shared/widgets/algorithm_card_grid.dart';
import 'package:app_grafos/shared/widgets/algorithm_scaffold.dart';
import 'package:app_grafos/shared/widgets/futuristic_surface.dart';
import 'package:app_grafos/shared/widgets/graph_save_dialog.dart';

class SortingMethodsScreen extends StatefulWidget {
  const SortingMethodsScreen({
    super.key,
    this.fileService = const GraphFileService(),
  });
  final GraphFileService fileService;

  @override
  State<SortingMethodsScreen> createState() => _SortingMethodsScreenState();
}

class _SortingMethodsScreenState extends State<SortingMethodsScreen> {
  SortingOrder _order = SortingOrder.ascending;

  Future<void> _save() async {
    var method = SortingAlgorithm.selectionSort;
    final algorithm = await showDialog<SortingAlgorithm>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elige el método del ejemplo'),
        content: DropdownButtonFormField<SortingAlgorithm>(
          initialValue: method,
          items: [
            for (final value in SortingAlgorithm.values)
              DropdownMenuItem(value: value, child: Text(value.displayName)),
          ],
          onChanged: (value) {
            if (value != null) method = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, method),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    if (algorithm == null || !mounted) return;
    final document = SortingDocument(
      name: 'ordenamiento',
      algorithm: algorithm,
      order: _order,
      originalArray: const [15, 47, 45, 60, 52, 84, 88, 59, 89, 86, 60],
    );
    await showJsonSaveDialog(
      context,
      initialName: document.name,
      jsonBuilder: (name) => document.encode(name: name),
      service: widget.fileService,
    );
  }

  Future<void> _load() async {
    try {
      final json = await widget.fileService.readJson();
      if (json == null) return;
      final document = SortingDocument.decode(json);
      if (!mounted) return;
      setState(() => _order = document.order);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SortingVisualizationScreen(
            algorithm: document.algorithm,
            initialArray: document.originalArray,
            initialOrder: document.order,
            initialSpeed: document.speed,
            initialStepIndex: document.stepIndex,
            initialName: document.name,
            fileService: widget.fileService,
          ),
        ),
      );
    } on FormatException catch (error) {
      if (mounted) _showFileError(error.message.toString());
    } catch (_) {
      if (mounted) {
        _showFileError('No se pudo leer el archivo de ordenamiento.');
      }
    }
  }

  void _showFileError(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AlgorithmScaffold(
      accent: AppColors.sorting,
      title: 'Métodos de Ordenamiento',
      icon: Icons.sort_rounded,
      actions: [SortingHelpMenu(onSave: _save, onLoad: _load)],
      body: SingleChildScrollView(
        padding: MediaQuery.sizeOf(context).width < 600
            ? AppLayout.compactPagePadding
            : AppLayout.pagePadding,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppLayout.contentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FuturisticPanel(
                  accent: AppColors.sorting,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LABORATORIO DE ORDENAMIENTO',
                        style: TextStyle(
                          color: AppColors.sorting,
                          fontSize: 12,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Selecciona un método de ordenamiento',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Observa cada comparación, controla la ejecución '
                        'y descubre cómo crece el trabajo de cada algoritmo.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Sentido del ordenamiento',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      SortingOrderSelector(
                        order: _order,
                        onChanged: (order) => setState(() => _order = order),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AlgorithmCardGrid(
                  maxColumns: 2,
                  children: [
                    SortingMethodCard(
                      algorithm: SortingAlgorithm.selectionSort,
                      order: _order,
                      description: 'Selecciona el menor o el mayor de la porción pendiente y lo coloca en su posición definitiva.',
                      icon: Icons.filter_list_rounded,
                      fileService: widget.fileService,
                    ),
                    SortingMethodCard(
                      algorithm: SortingAlgorithm.insertionSort,
                      order: _order,
                      description: 'Inserta cada elemento en su posición correcta dentro de la porción ordenada.',
                      icon: Icons.input_rounded,
                      fileService: widget.fileService,
                    ),
                    SortingMethodCard(
                      algorithm: SortingAlgorithm.mergeSort,
                      order: _order,
                      description: 'Divide el arreglo en mitades y combina sus elementos en orden.',
                      icon: Icons.call_merge_rounded,
                      fileService: widget.fileService,
                    ),
                    SortingMethodCard(
                      algorithm: SortingAlgorithm.shellSort,
                      order: _order,
                      description: 'Ordena grupos de elementos separados por saltos cada vez más pequeños.',
                      icon: Icons.stairs_rounded,
                      fileService: widget.fileService,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
