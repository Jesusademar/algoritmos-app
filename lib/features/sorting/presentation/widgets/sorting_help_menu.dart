import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';

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
        showDialog<void>(
          context: context,
          builder: (_) => const _SortingHelpDialog(),
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

class _SortingHelpDialog extends StatelessWidget {
  const _SortingHelpDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(
        children: [
          Icon(Icons.help_outline_rounded, color: AppColors.sorting),
          SizedBox(width: 12),
          Expanded(child: Text('Manual de uso · Ordenamiento')),
        ],
      ),
      content: const SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HelpStep(
              number: '1',
              title: 'Elige un método',
              description:
                  'Selection Sort selecciona el siguiente elemento de la '
                  'porción pendiente. Insertion Sort inserta cada elemento en su '
                  'posición dentro de la porción ordenada. Merge Sort divide y combina '
                  'mitades. Shell Sort ordena con saltos cada vez más pequeños.',
            ),
            _HelpStep(
              number: '2',
              title: 'Selecciona el sentido',
              description:
                  'Ascendente ordena de menor a mayor; Descendente, de '
                  'mayor a menor. Puedes cambiar el sentido durante la visualización: '
                  'los pasos se reinician con los mismos números.',
            ),
            _HelpStep(
              number: '3',
              title: 'Ingresa tus números',
              description:
                  'Pulsa Nuevo ordenamiento. Genera números aleatorios '
                  'o escribe una lista separada por comas, por ejemplo: 9, 2, 6. '
                  'Puedes usar hasta 20 números, con valores entre 1 y 100.',
            ),
            _HelpStep(
              number: '4',
              title: 'Controla la ejecución',
              description:
                  'Reproducir avanza automáticamente y Pausar detiene '
                  'la animación. Usa Anterior y Siguiente para revisar cada paso '
                  'y su explicación. Abrir este manual pausa la reproducción.',
            ),
            _HelpStep(
              number: '5',
              title: 'Ajusta la velocidad',
              description:
                  'Mueve el control de velocidad entre 0.5× y 2.0×. '
                  'Puedes ajustarlo mientras se reproduce el ordenamiento.',
            ),
            _HelpStep(
              number: '6',
              title: 'Interpreta los colores',
              description:
                  'Gris: sin ordenar. Amarillo: comparación. Naranja: '
                  'movimiento. Verde: posición ordenada. El arreglo y la explicación '
                  'muestran lo que ocurre en cada paso.',
            ),
            _HelpStep(
              number: '7',
              title: 'Consulta el resultado y Big O',
              description:
                  'Al terminar aparece el arreglo ordenado y el informe '
                  'Big O, con la cantidad de elementos, comparaciones, intercambios '
                  'desplazamientos o escrituras y tiempo de cálculo. Big O describe cómo crece '
                  'el trabajo; el tiempo mostrado excluye la animación.',
            ),
            _HelpStep(
              number: '8',
              title: 'Vuelve a experimentar',
              description:
                  'Reiniciar vuelve al primer paso con los mismos datos. '
                  'Nuevo ordenamiento permite probar otros números y conserva '
                  'el sentido y la velocidad elegidos.',
            ),
            _HelpStep(
              number: '9',
              title: 'Guardar y cargar',
              description:
                  'En Más opciones, Guardar exporta un JSON con los números originales, '
                  'el método, el sentido, la velocidad y el paso actual. Cargar recupera '
                  'el proceso en pausa. También puedes cargarlo desde el catálogo; '
                  'allí Guardar permite elegir el método del ejemplo que se exportará. '
                  'Un archivo inválido no reemplaza la sesión actual.',
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('¡Entendido!'),
        ),
      ],
    );
  }
}

class _HelpStep extends StatelessWidget {
  const _HelpStep({
    required this.number,
    required this.title,
    required this.description,
  });

  final String number;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.sorting.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: AppColors.sorting,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
