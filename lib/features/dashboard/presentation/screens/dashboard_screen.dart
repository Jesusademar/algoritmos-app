import 'package:app_grafos/features/sorting/presentation/widgets/sorting_race_banner.dart';
import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/app/navigation/algorithm_modules.dart';
import 'package:app_grafos/features/catalog/presentation/screens/menu_principal_screen.dart';
import 'package:app_grafos/features/dashboard/presentation/widgets/dashboard_sections.dart';
import 'package:app_grafos/shared/widgets/algorithm_card_grid.dart';
import 'package:app_grafos/shared/widgets/futuristic_surface.dart';
import 'package:app_grafos/shared/widgets/neon_icon.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ambient;
  late final AnimationController _entrance;
  final _workflowKey = GlobalKey();
  int _selectedModule = 0;
  bool _demoOrdered = false;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _ambient.stop();
      _entrance.value = 1;
    } else if (!_ambient.isAnimating) {
      _ambient.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ambient.dispose();
    _entrance.dispose();
    super.dispose();
  }

  void _open(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final module = algorithmModules[_selectedModule];
    return Scaffold(
      body: AnimatedBuilder(
        animation: _ambient,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: MediaQuery.sizeOf(context).width < 600
                ? AppLayout.compactPagePadding
                : AppLayout.pagePadding,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppLayout.contentWidth,
                ),
                child: FadeTransition(
                  opacity: _entrance,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 40),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final intro = _buildIntro();
                          final preview = _buildPreview();
                          if (constraints.maxWidth >= 850) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(flex: 6, child: intro),
                                const SizedBox(width: 40),
                                Expanded(flex: 5, child: preview),
                              ],
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              intro,
                              const SizedBox(height: 28),
                              preview,
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                      const AlgorithmCardGrid(
                        children: [
                          Metric(
                            icon: Icons.apps_rounded,
                            title: '6 módulos',
                            subtitle: 'Grafos, optimización y ordenamiento',
                          ),
                          Metric(
                            icon: Icons.sort_rounded,
                            title: '4 métodos de ordenamiento',
                            subtitle:
                                'Selection, Insertion, Merge y Shell Sort',
                          ),
                          Metric(
                            icon: Icons.touch_app_rounded,
                            title: 'Aprendizaje interactivo',
                            subtitle: 'Construye, ejecuta y compara',
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                      const SortingRaceBanner(),
                      const SizedBox(height: 40),
                      const SectionHeading(
                        eyebrow: 'CONOCE EL LABORATORIO',
                        title: 'Un problema, distintas formas de resolverlo',
                        description: 'Selecciona un módulo para conocer qué datos necesita y qué puedes aprender con él.',
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (
                            var index = 0;
                            index < algorithmModules.length;
                            index++
                          )
                            ChoiceChip(
                              avatar: Icon(
                                algorithmModules[index].icon,
                                size: 18,
                                color: algorithmModules[index].color,
                              ),
                              label: Text(algorithmModules[index].label),
                              selected: _selectedModule == index,
                              showCheckmark: false,
                              selectedColor: algorithmModules[index].color
                                  .withValues(alpha: 0.15),
                              side: BorderSide(
                                color: _selectedModule == index
                                    ? algorithmModules[index].color
                                    : AppColors.border,
                              ),
                              onSelected: (_) =>
                                  setState(() => _selectedModule = index),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      AnimatedSwitcher(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 250),
                        child: _buildModuleDetails(module),
                      ),
                      const SizedBox(height: 48),
                      const SectionHeading(
                        eyebrow: 'MÁS ALLÁ DEL RESULTADO',
                        title: '¿Qué hace bueno a un algoritmo?',
                        description: 'Entender el proceso te permite elegir una solución adecuada para cada problema.',
                      ),
                      const SizedBox(height: 20),
                      const AlgorithmCardGrid(
                        children: [
                          KnowledgeCard(
                            icon: Icons.verified_outlined,
                            color: AppColors.success,
                            title: 'Corrección',
                            body: 'Un algoritmo debe producir una respuesta válida para los datos de entrada. Revisa restricciones, casos límite y el significado del resultado.',
                          ),
                          KnowledgeCard(
                            icon: Icons.speed_rounded,
                            color: AppColors.sorting,
                            title: 'Eficiencia',
                            body: 'El tiempo y la memoria necesarios pueden crecer con el tamaño del problema. La notación O grande describe ese crecimiento, no una duración exacta.',
                          ),
                          KnowledgeCard(
                            icon: Icons.visibility_outlined,
                            color: AppColors.graph,
                            title: 'Interpretación',
                            body: 'Visualizar nodos, matrices o comparaciones ayuda a entender las decisiones del algoritmo y a explicar por qué una solución es útil.',
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                      SectionHeading(
                        key: _workflowKey,
                        eyebrow: 'TU PRIMER EXPERIMENTO',
                        title: 'Del problema a la solución',
                        description: 'Sigue este recorrido y observa cómo cada dato afecta el resultado.',
                      ),
                      const SizedBox(height: 20),
                      const AlgorithmCardGrid(
                        maxColumns: 2,
                        children: [
                          WorkflowStep(
                            number: '01',
                            title: 'Define el problema',
                            body: 'Decide si necesitas representar una red, asignar recursos, distribuir una oferta u ordenar números.',
                          ),
                          WorkflowStep(
                            number: '02',
                            title: 'Construye tus datos',
                            body: 'Agrega nodos y conexiones, completa los costos o escribe los valores que quieres ordenar.',
                          ),
                          WorkflowStep(
                            number: '03',
                            title: 'Ejecuta y observa',
                            body: 'Consulta la matriz, calcula una solución o avanza por los pasos de un ordenamiento.',
                          ),
                          WorkflowStep(
                            number: '04',
                            title: 'Compara y aprende',
                            body: 'Cambia una entrada, vuelve a ejecutar y explica cómo y por qué cambió el resultado.',
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                      const SectionHeading(
                        eyebrow: 'DETRÁS DE LOGIVERSE',
                        title: 'Equipo de desarrollo',
                        description: 'Un proyecto académico para aprender algoritmos a través de la visualización y la experimentación.',
                      ),
                      const SizedBox(height: 20),
                      const AlgorithmCardGrid(
                        children: [
                          DeveloperCard(
                            name: 'Jesus Canqui',
                            initials: 'JC',
                            color: AppColors.primary,
                          ),
                          DeveloperCard(
                            name: 'Miguel Sanchez',
                            initials: 'MS',
                            color: AppColors.sorting,
                          ),
                          DeveloperCard(
                            name: 'Jenny Quispe',
                            initials: 'JQ',
                            color: AppColors.graph,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'LogiVerse Core · Laboratorio de algoritmos e investigación de operaciones',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        builder: (context, child) => FuturisticBackground(
          accent: Color.lerp(
            AppColors.primary,
            AppColors.graph,
            _ambient.value * 0.45,
          )!,
          child: child!,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const NeonIcon(icon: Icons.hub_rounded, size: 26),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LogiVerse Core',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Laboratorio de algoritmos',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.25),
            ),
          ),
          child: const Text(
            'EXPLORA · VISUALIZA · APRENDE',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text.rich(
          const TextSpan(
            children: [
              TextSpan(text: 'Análisis de\n'),
              TextSpan(
                text: 'Algoritmos',
                style: TextStyle(
                  color: AppColors.primary,
                  shadows: [Shadow(color: Color(0x447F5EFF), blurRadius: 26)],
                ),
              ),
            ],
          ),
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w800,
            height: 1.1,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Tu próxima idea empieza aquí.',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        const Text(
          'Crea redes, ordena números y explora árboles. Prueba tus ideas paso a paso y descubre cómo cada algoritmo llega a su resultado.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: () => _open(const MenuPrincipalScreen()),
              icon: const Icon(Icons.rocket_launch_rounded, size: 20),
              label: const Text('Explorar Algoritmos'),
            ),
            OutlinedButton.icon(
              onPressed: () => Scrollable.ensureVisible(
                _workflowKey.currentContext!,
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 500),
              ),
              icon: const Icon(Icons.auto_stories_outlined, size: 20),
              label: const Text('¿Cómo funciona?'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreview() {
    final values = _demoOrdered ? [2, 3, 5, 7, 9] : [7, 3, 9, 2, 5];
    return FuturisticPanel(
      accent: AppColors.sorting,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.equalizer_rounded, color: AppColors.sorting, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'De datos a orden',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Un ejemplo de ordenamiento ascendente',
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 190,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var index = 0; index < values.length; index++) ...[
                  if (index > 0) const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${values[index]}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.sorting,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedContainer(
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 450),
                          curve: Curves.easeInOutCubic,
                          height: values[index] * 13.0 + 18,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.sorting.withValues(alpha: 0.9),
                                AppColors.primary.withValues(alpha: 0.25),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.sorting.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _demoOrdered
                ? 'Resultado: 2, 3, 5, 7, 9'
                : 'Entrada: 7, 3, 9, 2, 5',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => setState(() => _demoOrdered = !_demoOrdered),
            icon: Icon(
              _demoOrdered ? Icons.refresh_rounded : Icons.sort_rounded,
            ),
            label: Text(_demoOrdered ? 'Reiniciar ejemplo' : 'Ordenar ejemplo'),
          ),
          const SizedBox(height: 10),
          const Text(
            'Para ver las comparaciones paso a paso, abre el módulo de ordenamiento.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleDetails(AlgorithmModule module) {
    return FuturisticPanel(
      key: ValueKey(module.label),
      accent: module.color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(module.icon, color: module.color, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  module.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            module.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.6,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 20),
          AlgorithmCardGrid(
            maxColumns: 2,
            children: [
              DataFact(
                title: 'Datos de entrada',
                text: module.input,
                icon: Icons.input_rounded,
              ),
              DataFact(
                title: 'Qué puedes observar',
                text: module.output,
                icon: Icons.insights_rounded,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(module.tip, style: TextStyle(color: module.color, height: 1.5)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: () => openAlgorithmModule(context, module),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Abrir este módulo'),
              ),
              OutlinedButton.icon(
                onPressed: () => openAlgorithmExample(context, module),
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('Probar ejemplo listo'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
