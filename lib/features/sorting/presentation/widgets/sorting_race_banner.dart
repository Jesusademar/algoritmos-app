import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/features/sorting/presentation/screens/sorting_race_screen.dart';
import 'package:app_grafos/shared/widgets/futuristic_surface.dart';
import 'package:app_grafos/shared/widgets/neon_icon.dart';

class SortingRaceBanner extends StatelessWidget {
  const SortingRaceBanner({super.key});
  @override
  Widget build(BuildContext context) => FuturisticPanel(
    accent: AppColors.sorting,
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            NeonIcon(
              icon: Icons.sports_score_rounded,
              accent: AppColors.sorting,
              size: 22,
              padding: 10,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cuatro métodos. Una carrera.',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Mismos números, distintas estrategias. Mira cómo ordenan en paralelo y compara sus resultados.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const SortingRaceScreen()),
          ),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Abrir carrera de algoritmos'),
        ),
      ],
    ),
  );
}
