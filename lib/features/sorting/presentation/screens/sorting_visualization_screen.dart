import 'dart:async';

import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/features/sorting/domain/sorting_algorithm.dart';
import 'package:app_grafos/features/sorting/domain/sorting_document.dart';
import 'package:app_grafos/features/sorting/domain/sorting_order.dart';
import 'package:app_grafos/features/sorting/presentation/providers/sorting_visualization_provider.dart';
import 'package:app_grafos/features/sorting/presentation/widgets/sorting_help_menu.dart';
import 'package:app_grafos/features/sorting/presentation/widgets/sorting_input_dialog.dart';
import 'package:app_grafos/features/sorting/presentation/widgets/sorting_visualization_widget.dart';
import 'package:app_grafos/shared/persistence/graph_file_service.dart';
import 'package:app_grafos/shared/widgets/algorithm_scaffold.dart';
import 'package:app_grafos/shared/widgets/graph_save_dialog.dart';

/// Main screen for sorting visualization
class SortingVisualizationScreen extends StatefulWidget {
  final SortingAlgorithm algorithm;
  final List<Object> initialArray;
  final SortingOrder initialOrder;
  final double initialSpeed;
  final int initialStepIndex;
  final String initialName;
  final GraphFileService fileService;

  const SortingVisualizationScreen({
    super.key,
    required this.algorithm,
    required this.initialArray,
    this.initialOrder = SortingOrder.ascending,
    this.initialSpeed = 1,
    this.initialStepIndex = 0,
    this.initialName = 'ordenamiento',
    this.fileService = const GraphFileService(),
  });

  @override
  State<SortingVisualizationScreen> createState() =>
      _SortingVisualizationScreenState();
}

class _SortingVisualizationScreenState
    extends State<SortingVisualizationScreen> {
  late SortingVisualizationProvider _provider;
  Timer? _animationTimer;
  double? _animationSpeed;
  late SortingAlgorithm _algorithm;
  late String _name;

  @override
  void initState() {
    super.initState();
    _algorithm = widget.algorithm;
    _name = widget.initialName;
    _provider = _createProvider(
      widget.initialArray,
      widget.initialOrder,
      speed: widget.initialSpeed,
      stepIndex: widget.initialStepIndex,
    );
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _provider.dispose();
    super.dispose();
  }

  void _showInputDialog() {
    _provider.pause();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SortingInputDialog(
        initialQuantity: _provider.hasData
            ? _provider.originalArray.length
            : 10,
        onArray: (array) {
          Navigator.pop(context);
          _resetWithNewArray(array);
        },
      ),
    );
  }

  void _resetWithNewArray(List<Object> array) {
    setState(() {
      _stopAnimation();
      final order = _provider.order;
      final speed = _provider.speed;
      _provider.dispose();
      _provider = _createProvider(array, order)..setSpeed(speed);
    });
  }

  SortingVisualizationProvider _createProvider(
    List<Object> array,
    SortingOrder order, {
    double speed = 1,
    int stepIndex = 0,
  }) {
    return SortingVisualizationProvider(
      array: array,
      algorithm: _algorithm,
      order: order,
      initialSpeed: speed,
      initialStepIndex: stepIndex,
    )..addListener(_syncAnimation);
  }

  Future<void> _save() async {
    _provider.pause();
    final document = SortingDocument(
      name: _name,
      algorithm: _algorithm,
      order: _provider.order,
      originalArray: _provider.originalArray,
      speed: _provider.speed,
      stepIndex: _provider.currentStepIndex,
    );
    final name = await showJsonSaveDialog(
      context,
      initialName: _name,
      jsonBuilder: (name) => document.encode(name: name),
      service: widget.fileService,
    );
    if (name != null && mounted) _name = name;
  }

  Future<void> _load() async {
    _provider.pause();
    try {
      final json = await widget.fileService.readJson();
      if (json == null) return;
      final document = SortingDocument.decode(json);
      if (!mounted) return;
      setState(() {
        _stopAnimation();
        _provider.dispose();
        _algorithm = document.algorithm;
        _name = document.name;
        _provider = _createProvider(
          document.originalArray,
          document.order,
          speed: document.speed,
          stepIndex: document.stepIndex,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ordenamiento cargado en pausa.')),
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

  void _syncAnimation() {
    if (!_provider.isPlaying || _provider.isComplete) {
      _stopAnimation();
      return;
    }
    if (_animationSpeed != _provider.speed) _stopAnimation();
    _startAnimation();
  }

  void _startAnimation() {
    if (_animationTimer != null) return;

    _animationSpeed = _provider.speed;
    final delayMs = (500 / _provider.speed).toInt();
    _animationTimer = Timer.periodic(Duration(milliseconds: delayMs), (_) {
      _provider.advanceStep();
    });
  }

  void _stopAnimation() {
    _animationTimer?.cancel();
    _animationTimer = null;
    _animationSpeed = null;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _provider,
      builder: (context, _) {
        return PopScope(
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) _stopAnimation();
          },
          child: AlgorithmScaffold(
            accent: AppColors.sorting,
            title: _algorithm.displayName,
            icon: Icons.sort_rounded,
            actions: [
              SortingHelpMenu(
                onOpen: _provider.pause,
                onSave: _provider.hasData ? _save : null,
                onLoad: _load,
              ),
            ],
            body: SortingVisualizationWidget(
              provider: _provider,
              onNewSort: _showInputDialog,
            ),
          ),
        );
      },
    );
  }
}
