import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';

Future<void> showBinaryTreeHelp(BuildContext context) => showDialog<void>(
  context: context,
  builder: (_) => AlertDialog(
    scrollable: true,
    title: const Text('Manual de uso · Árboles binarios'),
    content: const SizedBox(
      width: 520,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Step(
            '1. Crear con números',
            'Escribe enteros separados por comas o espacios. Se insertan en el orden indicado: menores a la izquierda y mayores a la derecha. La primera cifra es la raíz.',
          ),
          _Step(
            '2. Generar por rango',
            'Indica mínimo, máximo y cantidad. Los extremos están incluidos. El rango debe contener suficientes números distintos. Se admiten hasta 63 nodos, con valores entre -999999999 y 999999999.',
          ),
          _Step(
            '3. Leer los recorridos',
            'Pre-order: raíz, izquierda, derecha. In-order: izquierda, raíz, derecha. Post-order: izquierda, derecha, raíz. Los tres resultados se actualizan con el árbol.',
          ),
          _Step(
            '4. Reconstruir con dos recorridos',
            'Elige dos recorridos diferentes entre Pre-order, In-order y Post-order. Están disponibles las seis combinaciones, en ambos órdenes. Deben tener igual cantidad, los mismos valores y ningún número repetido. Pre-order + Post-order puede tener varias soluciones si hay hijos únicos; se muestra una solución válida colocándolos a la izquierda y se indica la ambigüedad. El orden también debe ser compatible; de lo contrario aparece un error sin reemplazar el árbol actual.',
          ),
          _Step(
            '5. Explorar el dibujo',
            'Arrastra un nodo para acomodarlo sin cambiar los recorridos. Arrastra el fondo para desplazar la vista; usa el gesto de zoom o la rueda del ratón. Ordenar nodos automáticamente recupera la distribución inicial. Ajustar árbol a la vista permite volver a ver todos los nodos.',
          ),
          _Step(
            '6. Guardar y cargar',
            'En Más opciones puedes guardar un JSON o cargarlo. El archivo conserva la forma exacta del árbol y las posiciones de los nodos, incluso si se reconstruyó con recorridos. Un archivo inválido no reemplaza el árbol actual.',
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
  ),
);

class _Step extends StatelessWidget {
  const _Step(this.title, this.body);
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(body, style: const TextStyle(height: 1.5)),
      ],
    ),
  );
}
