import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/shared/widgets/futuristic_surface.dart';
import 'package:app_grafos/shared/widgets/neon_icon.dart';

/// Encabezado y superficie comunes a todos los módulos de algoritmos.
class AlgorithmScaffold extends StatelessWidget {
  const AlgorithmScaffold({
    super.key,
    required this.title,
    required this.icon,
    required this.body,
    this.actions = const [],
    this.accent = AppColors.primary,
  });

  final String title;
  final IconData icon;
  final Widget body;
  final List<Widget> actions;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 700;
    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          primary: accent,
          onPrimary: AppColors.background,
        ),
        progressIndicatorTheme: theme.progressIndicatorTheme.copyWith(
          color: accent,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: wide ? 76 : 64,
          titleSpacing: 12,
          title: Row(
            children: [
              NeonIcon(icon: icon, accent: accent, size: 22, padding: 8),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (wide) ...[
                      const Text(
                        'LOGIVERSE / EXPLORA Y CREA',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 5),
                    ],
                    Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: actions,
          actionsPadding: const EdgeInsets.only(right: 12),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withValues(alpha: 0.65),
                    AppColors.sorting.withValues(alpha: 0.20),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        body: FuturisticBackground(
          accent: accent,
          child: SafeArea(child: body),
        ),
      ),
    );
  }
}

/// Conserva el lienzo a la izquierda en escritorio y apila el panel en móvil.
/// Ambos hijos reciben límites de altura para sus listas y visualizaciones.
class AlgorithmWorkspace extends StatelessWidget {
  const AlgorithmWorkspace({
    super.key,
    required this.canvas,
    this.panel,
    this.isEmpty = false,
    this.emptyIcon = Icons.hub_outlined,
    this.emptyTitle = 'Construye tu primera red',
    this.emptyDescription = 'Haz clic en el lienzo para crear un nodo. Selecciona dos nodos para conectarlos.',
    this.accent = AppColors.primary,
  });

  final Widget canvas;
  final Widget? panel;
  final bool isEmpty;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyDescription;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasArea = Stack(
          fit: StackFit.expand,
          children: [
            canvas,
            if (isEmpty)
              IgnorePointer(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            emptyIcon,
                            color: accent.withValues(alpha: 0.7),
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            emptyTitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            emptyDescription,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
        final canvasSurface = ClipRRect(
          borderRadius: BorderRadius.circular(AppLayout.radius),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.5),
              ),
              borderRadius: BorderRadius.circular(AppLayout.radius),
            ),
            child: canvasArea,
          ),
        );
        if (panel == null) return canvasSurface;
        final panelSurface = Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppLayout.radius),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: panel!,
        );
        if (constraints.maxWidth >= AppLayout.workspaceBreakpoint) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: canvasSurface),
              SizedBox(width: AppLayout.panelWidth + 24, child: panelSurface),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: canvasSurface),
            Expanded(child: panelSurface),
          ],
        );
      },
    );
  }
}

class AlgorithmPanelSection extends StatelessWidget {
  const AlgorithmPanelSection({
    super.key,
    required this.title,
    required this.child,
    this.highlighted = false,
  });

  final String title;
  final Widget child;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlighted
            ? Color.alphaBlend(
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                AppColors.background,
              )
            : AppColors.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.35)
              : AppColors.border.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Acciones del lienzo con espacio para envolver el contenido en pantallas pequeñas.
class AlgorithmCanvasControls extends StatelessWidget {
  const AlgorithmCanvasControls({
    super.key,
    required this.onClear,
    required this.nodeCount,
    required this.connectionCount,
  });

  final VoidCallback onClear;
  final int nodeCount;
  final int connectionCount;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Limpiar lienzo'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Nodos: $nodeCount • Conexiones: $connectionCount',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
