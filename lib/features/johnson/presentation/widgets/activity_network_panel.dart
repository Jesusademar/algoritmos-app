import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/features/johnson/domain/activity_network_problem.dart';
import 'package:app_grafos/shared/graph_editor/models/nodo.dart';
import 'package:app_grafos/shared/widgets/algorithm_scaffold.dart';

/// Presenta las etiquetas ya calculadas; no ejecuta ni transforma el algoritmo.
class ActivityNetworkPanel extends StatelessWidget {
  const ActivityNetworkPanel({
    super.key,
    required this.nodes,
    required this.startId,
    required this.selectedNode,
    required this.maximizing,
    required this.hasResult,
    required this.total,
    required this.forward,
    required this.backward,
    required this.slacks,
    required this.highlightedEdges,
    required this.onModeChanged,
    required this.onCalculate,
  });
  final List<Nodo> nodes;
  final String? startId;
  final Nodo? selectedNode;
  final bool maximizing;
  final bool hasResult;
  final int total;
  final Map<String, int> forward;
  final Map<String, int> backward;
  final Map<String, int> slacks;
  final int highlightedEdges;
  final ValueChanged<NetworkOptimizationMode> onModeChanged;
  final VoidCallback onCalculate;

  @override
  Widget build(BuildContext context) {
    final start =
        nodes.where((node) => node.id == startId).firstOrNull ??
        nodes.firstOrNull;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Red de actividades',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.johnson,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Conexiones dirigidas · inicio fijo en cero',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Center(
            child: SegmentedButton<NetworkOptimizationMode>(
              segments: const [
                ButtonSegment(
                  value: NetworkOptimizationMode.minimize,
                  label: Text('Minimizar'),
                  icon: Icon(Icons.arrow_downward_rounded, size: 16),
                ),
                ButtonSegment(
                  value: NetworkOptimizationMode.maximize,
                  label: Text('Maximizar'),
                  icon: Icon(Icons.arrow_upward_rounded, size: 16),
                ),
              ],
              selected: {
                maximizing
                    ? NetworkOptimizationMode.maximize
                    : NetworkOptimizationMode.minimize,
              },
              onSelectionChanged: (values) => onModeChanged(values.single),
            ),
          ),
          const SizedBox(height: 16),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Nodo de inicio',
              suffixIcon: Icon(Icons.lock_outline_rounded, size: 18),
            ),
            child: Text(
              start == null
                  ? 'Primer evento creado · 0'
                  : '${start.nombre} · 0',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onCalculate,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Calcular red'),
          ),
          if (selectedNode != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Origen seleccionado: ${selectedNode!.nombre}. Toca otro nodo para conectar.',
                style: const TextStyle(color: AppColors.successText),
              ),
            ),
          if (!hasResult)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                'Define tus actividades y calcula para ver las etiquetas de ida, retorno y holgura.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  height: 1.5,
                  fontSize: 12,
                ),
              ),
            ),
          if (hasResult) ...[
            const SizedBox(height: 20),
            AlgorithmPanelSection(
              title: 'Resultados:',
              highlighted: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Valor Total: $total',
                    style: const TextStyle(
                      fontSize: 19,
                      color: AppColors.successText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tiempo inicial: 0',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$highlightedEdges conexiones resaltadas',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const Divider(height: 24),
                  Text(
                    maximizing
                        ? 'Ida · retorno · holgura'
                        : 'Ida · retorno · exceso',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final node in nodes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${node.nombre}${node.id == start?.id ? ' · Inicio' : ''}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              Text('Ida: ${forward[node.id] ?? '—'}'),
                              Text('Retorno: ${backward[node.id] ?? '—'}'),
                              Text(
                                'H: ${slacks[node.id] ?? '—'}',
                                style: TextStyle(
                                  color: slacks[node.id] == 0
                                      ? AppColors.successText
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          if (!forward.containsKey(node.id))
                            const Text(
                              'Sin ruta desde el inicio',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                        ],
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
