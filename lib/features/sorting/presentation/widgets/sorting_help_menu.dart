import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/shared/help/algorithm_manuals.dart';
import 'package:app_grafos/shared/widgets/algorithm_manual_dialog.dart';

/// El mismo manual está disponible desde el catálogo y la visualización.
class SortingHelpMenu extends StatelessWidget {
  const SortingHelpMenu({super.key, this.onOpen, this.onSave, this.onLoad});

  final VoidCallback? onOpen;
  final VoidCallback? onSave;
  final VoidCallback? onLoad;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Más opciones',
      onSelected: (value) {
        onOpen?.call();
        if (value == 'guardar') {
          onSave?.call();
          return;
        }
        if (value == 'cargar') {
          onLoad?.call();
          return;
        }
        showAlgorithmManual(
          context,
          AlgorithmManual.sorting,
          accent: AppColors.sorting,
        );
      },
      itemBuilder: (_) => [
        if (onSave != null)
          const PopupMenuItem(
            value: 'guardar',
            child: ListTile(
              leading: Icon(Icons.save_alt_rounded),
              title: Text('Guardar'),
            ),
          ),
        if (onLoad != null)
          const PopupMenuItem(
            value: 'cargar',
            child: ListTile(
              leading: Icon(Icons.folder_open_rounded),
              title: Text('Cargar'),
            ),
          ),
        const PopupMenuItem(
          value: 'ayuda',
          child: ListTile(
            leading: Icon(Icons.help_outline_rounded),
            title: Text('Manual de uso'),
          ),
        ),
      ],
    );
  }
}
