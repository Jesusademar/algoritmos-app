import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/features/sorting/domain/sorting_order.dart';

class SortingOrderSelector extends StatelessWidget {
  const SortingOrderSelector({
    super.key,
    required this.order,
    required this.onChanged,
  });

  final SortingOrder order;
  final ValueChanged<SortingOrder> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: SortingOrder.values
              .map(
                (value) => ChoiceChip(
                  label: Text(value.label),
                  selected: order == value,
                  showCheckmark: false,
                  avatar: Icon(
                    value == SortingOrder.ascending
                        ? Icons.north_rounded
                        : Icons.south_rounded,
                    size: 18,
                  ),
                  onSelected: (_) => onChanged(value),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
        Text(
          order.description,
          style: const TextStyle(color: AppColors.textMuted),
        ),
      ],
    );
  }
}
