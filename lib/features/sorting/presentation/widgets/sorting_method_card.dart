import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/features/sorting/domain/sorting_algorithm.dart';
import 'package:app_grafos/features/sorting/domain/sorting_order.dart';
import 'package:app_grafos/features/sorting/presentation/screens/sorting_visualization_screen.dart';
import 'package:app_grafos/shared/persistence/graph_file_service.dart';
import 'package:app_grafos/shared/widgets/algorithm_launch_card.dart';

class SortingMethodCard extends StatelessWidget {
  final SortingAlgorithm algorithm;
  final String description;
  final IconData icon;
  final SortingOrder order;
  final GraphFileService fileService;

  const SortingMethodCard({
    super.key,
    required this.algorithm,
    required this.description,
    required this.icon,
    required this.order,
    required this.fileService,
  });

  @override
  Widget build(BuildContext context) => AlgorithmLaunchCard(
    title: algorithm.displayName,
    description: description,
    category: 'Paso a paso',
    icon: icon,
    accent: AppColors.sorting,
    actionLabel: 'Abrir algoritmo',
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SortingVisualizationScreen(
          algorithm: algorithm,
          initialOrder: order,
          fileService: fileService,
          initialArray: const [15, 47, 45, 60, 52, 84, 88, 59, 89, 86, 60],
        ),
      ),
    ),
  );
}
