import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/features/sorting/domain/sorting_algorithm.dart';
import 'package:app_grafos/features/sorting/domain/sorting_validator.dart';
import 'package:app_grafos/features/sorting/presentation/providers/sorting_race_controller.dart';
import 'package:app_grafos/features/sorting/presentation/screens/sorting_visualization_screen.dart';
import 'package:app_grafos/features/sorting/presentation/widgets/sorting_order_selector.dart';
import 'package:app_grafos/shared/widgets/algorithm_card_grid.dart';
import 'package:app_grafos/shared/widgets/algorithm_scaffold.dart';
import 'package:app_grafos/shared/widgets/futuristic_surface.dart';
import 'package:app_grafos/shared/widgets/neon_icon.dart';

class SortingRaceScreen extends StatefulWidget {
  const SortingRaceScreen({super.key});
  @override
  State<SortingRaceScreen> createState() => _SortingRaceScreenState();
}

class _SortingRaceScreenState extends State<SortingRaceScreen>
    with WidgetsBindingObserver {
  final _race = SortingRaceController();
  final _numbers = TextEditingController(text: '72, 18, 91, 34, 9, 56, 25, 63');
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _race.pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _race.dispose();
    _numbers.dispose();
    super.dispose();
  }

  void _apply(List<int> numbers) {
    _race.setNumbers(numbers);
    _numbers.text = numbers.join(', ');
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _error = null);
  }

  void _submit() {
    final (numbers, error) = SortingValidator.parseInputString(_numbers.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    _apply(numbers);
  }

  void _details(SortingAlgorithm algorithm) {
    _race.pause();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SortingVisualizationScreen(
          algorithm: algorithm,
          initialArray: _race.numbers,
          initialOrder: _race.order,
          initialStepIndex: _race.stepIndex(algorithm),
        ),
      ),
    );
  }

  void _help() {
    _race.pause();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cómo comparar los métodos'),
        content: const SingleChildScrollView(
          child: Text(
            'Los cuatro métodos reciben los mismos números y el mismo sentido. Puedes reproducir, pausar, avanzar un paso o mover la línea de tiempo.\n\nCada turno muestra un paso de cada método; la carrera visual no mide tiempo real. Al terminar verás sus comparaciones, movimientos y Big O. Las escrituras, desplazamientos e intercambios representan operaciones distintas.\n\nAbre el detalle de un método para seguir explorando, guardar sus datos o consultar su manual.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _race,
    builder: (context, _) => AlgorithmScaffold(
      title: 'Carrera de algoritmos',
      icon: Icons.sports_score_rounded,
      accent: AppColors.sorting,
      actions: [
        IconButton(
          onPressed: _help,
          tooltip: 'Cómo comparar',
          icon: const Icon(Icons.help_outline_rounded),
        ),
      ],
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'MISMA ENTRADA. CUATRO CAMINOS.',
                        style: TextStyle(
                          color: AppColors.sorting,
                          fontSize: 11,
                          letterSpacing: 1.3,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '¿Quién hace menos comparaciones?',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Prueba una lista ordenada, invertida o aleatoria y descubre cómo cambia el trabajo de cada método.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _numbers,
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Números de la carrera',
                          helperText: 'Hasta 20 números entre 1 y 100, separados por comas.',
                          helperMaxLines: 2,
                          errorText: _error,
                          errorMaxLines: 3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: _submit,
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Aplicar números'),
                          ),
                          OutlinedButton(
                            onPressed: () =>
                                _apply(List.generate(8, (i) => (i + 1) * 10)),
                            child: const Text('Lista ordenada'),
                          ),
                          OutlinedButton(
                            onPressed: () =>
                                _apply(List.generate(8, (i) => (8 - i) * 10)),
                            child: const Text('Lista invertida'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _apply(SortingValidator.generateRandomArray(8)),
                            icon: const Icon(Icons.shuffle_rounded, size: 18),
                            label: const Text('Aleatorios'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SortingOrderSelector(
                        order: _race.order,
                        onChanged: _race.setOrder,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FuturisticPanel(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          FilledButton.icon(
                            onPressed: _race.isPlaying
                                ? _race.pause
                                : _race.play,
                            icon: Icon(
                              _race.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                            ),
                            label: Text(
                              _race.isPlaying
                                  ? 'Pausar carrera'
                                  : _race.isComplete
                                  ? 'Repetir carrera'
                                  : 'Iniciar carrera',
                            ),
                          ),
                          OutlinedButton(
                            onPressed: _race.isComplete ? null : _race.next,
                            child: const Text('Un paso'),
                          ),
                          OutlinedButton(
                            onPressed: _race.isComplete ? null : _race.finish,
                            child: const Text('Ver resultado'),
                          ),
                          TextButton(
                            onPressed: _race.reset,
                            child: const Text('Reiniciar'),
                          ),
                          for (final speed in [1, 2, 4])
                            ChoiceChip(
                              label: Text('$speed×'),
                              selected: _race.speed == speed,
                              onSelected: (_) => _race.setSpeed(speed),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Turno ${_race.tick + 1} de ${_race.lastTick + 1} · Ritmo visual',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      Slider(
                        key: const ValueKey('race-timeline'),
                        value: _race.tick.toDouble(),
                        max: _race.lastTick > 0 ? _race.lastTick.toDouble() : 1,
                        onChanged: _race.lastTick == 0
                            ? null
                            : (value) => _race.seek(value.round()),
                      ),
                      const Text(
                        'La carrera muestra pasos visuales; no mide la velocidad real del dispositivo.',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AlgorithmCardGrid(
                  maxColumns: 4,
                  children: [
                    for (final algorithm in SortingAlgorithm.values)
                      _RaceLane(
                        race: _race,
                        algorithm: algorithm,
                        onDetails: () => _details(algorithm),
                      ),
                  ],
                ),
                if (_race.isComplete) ...[
                  const SizedBox(height: 20),
                  FuturisticPanel(
                    accent: AppColors.success,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Comparación completada',
                          style: TextStyle(
                            color: AppColors.successText,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Menos comparaciones en este ejemplo: ${_race.fewestComparisons.map((algorithm) => algorithm.displayName).join(' · ')}.',
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Cambia los datos para comparar de nuevo. Un solo ejemplo no determina qué método conviene para todos los casos.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _RaceLane extends StatelessWidget {
  const _RaceLane({
    required this.race,
    required this.algorithm,
    required this.onDetails,
  });
  final SortingRaceController race;
  final SortingAlgorithm algorithm;
  final VoidCallback onDetails;
  @override
  Widget build(BuildContext context) {
    final accent = switch (algorithm) {
      SortingAlgorithm.selectionSort => AppColors.graph,
      SortingAlgorithm.insertionSort => AppColors.primary,
      SortingAlgorithm.mergeSort => AppColors.sorting,
      SortingAlgorithm.shellSort => AppColors.johnson,
    };
    final step = race.step(algorithm);
    final done = race.completed(algorithm);
    return FuturisticPanel(
      key: ValueKey('race-${algorithm.name}'),
      accent: accent,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              NeonIcon(
                icon: done ? Icons.check_rounded : Icons.equalizer_rounded,
                accent: accent,
                size: 18,
                padding: 8,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  algorithm.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 112,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var index = 0; index < step.array.length; index++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: AnimatedContainer(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 70),
                        height: 12 + step.array[index] * 0.9,
                        decoration: BoxDecoration(
                          color: done
                              ? AppColors.success
                              : (step.comparingIndex1 == index ||
                                    step.comparingIndex2 == index)
                              ? AppColors.comparing
                              : accent.withValues(alpha: 0.65),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(5),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            step.array.join(' · '),
            key: ValueKey('race-array-${algorithm.name}'),
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'Roboto',
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: race.progress(algorithm),
            color: accent,
            borderRadius: BorderRadius.circular(6),
            minHeight: 5,
          ),
          const SizedBox(height: 10),
          Text(
            done
                ? 'Completado'
                : 'Paso ${race.stepIndex(algorithm) + 1} de ${race.result(algorithm).stepCount}',
            style: TextStyle(
              color: done ? AppColors.successText : AppColors.textMuted,
              fontSize: 12,
            ),
          ),
          if (done) ...[
            const SizedBox(height: 10),
            Text(
              '${race.result(algorithm).totalComparisons} comparaciones · ${algorithm.movementLabel}: ${race.result(algorithm).totalSwaps}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Big O: ${race.complexity(algorithm)}',
              style: const TextStyle(
                color: AppColors.successText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onDetails,
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Abrir detalle'),
          ),
        ],
      ),
    );
  }
}
