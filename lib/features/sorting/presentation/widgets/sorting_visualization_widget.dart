import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/features/sorting/presentation/providers/sorting_visualization_provider.dart';
import 'package:app_grafos/features/sorting/presentation/widgets/bowling_pin_widget.dart';
import 'package:app_grafos/features/sorting/presentation/widgets/sorting_complexity_widget.dart';
import 'package:app_grafos/features/sorting/presentation/widgets/sorting_order_selector.dart';
import 'package:app_grafos/shared/widgets/algorithm_scaffold.dart';

class SortingVisualizationWidget extends StatelessWidget {
  final SortingVisualizationProvider provider;
  final VoidCallback onNewSort;

  const SortingVisualizationWidget({
    super.key,
    required this.provider,
    required this.onNewSort,
  });

  @override
  Widget build(BuildContext context) {
    return AlgorithmWorkspace(
      canvas: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                provider.order.description,
                style: const TextStyle(
                  color: AppColors.sorting,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${provider.currentArray.length} elementos · ${provider.algorithm.displayName}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted),
              ),
              if (provider.isComplete) ...[
                const SizedBox(height: 12),
                Text(
                  'Ordenamiento completado · Big O: ${provider.executionComplexity}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.successText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              Wrap(
                spacing: 24,
                runSpacing: 32,
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: List.generate(
                  provider.currentArray.length,
                  (index) => SizedBox(
                    width: 75,
                    height: 155,
                    child: BowlingPinWidget(
                      value: provider.currentArray[index],
                      maxValue: 100,
                      color: provider.getColorForIndex(index),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      panel: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.tune_rounded, color: AppColors.sorting, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Proceso y controles',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AlgorithmPanelSection(
              title: 'Sentido del ordenamiento',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SortingOrderSelector(
                    order: provider.order,
                    onChanged: provider.setOrder,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Al cambiar el sentido, se reinician los pasos con los mismos datos.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AlgorithmPanelSection(
              title: 'Estado del arreglo',
              child: Text(
                provider.currentArray.join(' | '),
                style: const TextStyle(fontFamily: 'monospace', height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
            AlgorithmPanelSection(
              title:
                  'Paso ${provider.currentStepIndex + 1} de ${provider.totalSteps}',
              highlighted: true,
              child: Text(
                provider.description,
                style: const TextStyle(height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              provider.isComplete
                  ? 'Ordenamiento completado'
                  : 'Progreso del ordenamiento',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: provider.totalSteps > 0
                  ? (provider.currentStepIndex + 1) / provider.totalSteps
                  : 0,
              minHeight: 6,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: provider.currentStepIndex > 0
                      ? provider.previousStep
                      : null,
                  icon: const Icon(Icons.skip_previous_rounded, size: 18),
                  label: const Text('Anterior'),
                ),
                FilledButton.icon(
                  onPressed: provider.isComplete
                      ? null
                      : provider.togglePlayPause,
                  icon: Icon(
                    provider.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 18,
                  ),
                  label: Text(provider.isPlaying ? 'Pausar' : 'Reproducir'),
                ),
                OutlinedButton.icon(
                  onPressed: provider.isComplete ? null : provider.nextStep,
                  icon: const Icon(Icons.skip_next_rounded, size: 18),
                  label: const Text('Siguiente'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: provider.reset,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Reiniciar'),
                ),
                FilledButton.icon(
                  onPressed: onNewSort,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Nuevo ordenamiento'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AlgorithmPanelSection(
              title: 'Velocidad: ${provider.speed.toStringAsFixed(1)}×',
              child: Slider(
                value: provider.speed,
                min: 0.5,
                max: 2.0,
                divisions: 3,
                label: '${provider.speed.toStringAsFixed(1)}×',
                onChanged: provider.setSpeed,
              ),
            ),
            if (provider.isComplete) ...[
              const SizedBox(height: 16),
              AlgorithmPanelSection(
                title: 'Resultado · Big O',
                highlighted: true,
                child: SortingComplexityWidget(
                  algorithm: provider.algorithm,
                  complexity: provider.executionComplexity,
                  elementCount: provider.currentArray.length,
                  comparisons: provider.totalComparisons,
                  movements: provider.totalSwaps,
                  calculationDuration: provider.calculationDuration,
                ),
              ),
            ],
            const SizedBox(height: 16),
            const AlgorithmPanelSection(
              title: 'Leyenda de colores',
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _ColorLegendItem(
                    color: AppColors.unsorted,
                    label: 'Sin ordenar',
                  ),
                  _ColorLegendItem(
                    color: AppColors.comparing,
                    label: 'Comparando',
                  ),
                  _ColorLegendItem(color: AppColors.moving, label: 'Moviendo'),
                  _ColorLegendItem(color: AppColors.success, label: 'Ordenado'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorLegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _ColorLegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
