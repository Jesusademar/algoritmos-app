import 'package:app_grafos/features/sorting/presentation/widgets/sorting_race_banner.dart';
import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/app/navigation/algorithm_modules.dart';
import 'package:app_grafos/features/catalog/presentation/widgets/module_illustration.dart';
import 'package:app_grafos/features/catalog/presentation/widgets/catalog_intro.dart';
import 'package:app_grafos/shared/widgets/algorithm_card_grid.dart';
import 'package:app_grafos/shared/widgets/algorithm_launch_card.dart';
import 'package:app_grafos/shared/widgets/algorithm_scaffold.dart';
import 'package:app_grafos/shared/widgets/futuristic_surface.dart';

class MenuPrincipalScreen extends StatefulWidget {
  const MenuPrincipalScreen({super.key});

  @override
  State<MenuPrincipalScreen> createState() => _MenuPrincipalScreenState();
}

class _MenuPrincipalScreenState extends State<MenuPrincipalScreen> {
  String _query = '';

  String _searchText(String value) {
    const accents = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
    };
    return value
        .trim()
        .toLowerCase()
        .split('')
        .map((letter) => accents[letter] ?? letter)
        .join();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchText(_query);
    final modules = algorithmModules.where((module) {
      final text = _searchText(
        '${module.menuTitle} ${module.category} ${module.summary}',
      );
      return text.contains(query);
    }).toList();
    return AlgorithmScaffold(
      title: 'Centro de Módulos Algorítmicos',
      icon: Icons.space_dashboard_outlined,
      body: SingleChildScrollView(
        padding: MediaQuery.sizeOf(context).width < 600
            ? AppLayout.compactPagePadding
            : AppLayout.pagePadding,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppLayout.contentWidth),
            child: FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FuturisticPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CatalogIntro(),
                        const SizedBox(height: 24),
                        FocusTraversalOrder(
                          order: const NumericFocusOrder(100),
                          child: TextField(
                            onChanged: (value) =>
                                setState(() => _query = value),
                            decoration: const InputDecoration(
                              labelText: 'Buscar un algoritmo',
                              hintText: 'Grafos, asignación, árboles…',
                              prefixIcon: Icon(Icons.search_rounded),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SortingRaceBanner(),
                  const SizedBox(height: 24),
                  Text(
                    '${modules.length} módulos${query.isEmpty ? ' disponibles' : ' encontrados'}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (modules.isEmpty)
                    const FuturisticPanel(
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 36,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No encontramos ese algoritmo',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Prueba con el nombre del módulo o su categoría.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    )
                  else
                    AlgorithmCardGrid(
                      children: [
                        for (var index = 0; index < modules.length; index++)
                          FocusTraversalOrder(
                            order: NumericFocusOrder(index.toDouble() + 1),
                            child: AlgorithmLaunchCard(
                              key: ValueKey(modules[index].id),
                              title: modules[index].menuTitle,
                              description: modules[index].summary,
                              category: modules[index].category,
                              icon: modules[index].icon,
                              accent: modules[index].color,
                              preview: ModuleIllustration(
                                id: modules[index].id,
                                accent: modules[index].color,
                              ),
                              onTap: () =>
                                  openAlgorithmModule(context, modules[index]),
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  const Text(
                    'Cada módulo incluye un manual de uso y opciones para guardar y cargar tus datos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
