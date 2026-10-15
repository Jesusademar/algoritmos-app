import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/shared/domain/mathematical_procedure.dart';

Future<void> showMathematicalProcedure(
  BuildContext context,
  MathematicalProcedure procedure, {
  Color accent = AppColors.primary,
}) => showDialog<void>(
  context: context,
  builder: (context) => Dialog(
    insetPadding: EdgeInsets.all(
      MediaQuery.sizeOf(context).width < 600 ? 12 : 24,
    ),
    child: SizedBox(
      width: 960,
      height: MediaQuery.sizeOf(context).height * 0.88,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
            child: Row(
              children: [
                Icon(Icons.functions_rounded, color: accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    procedure.title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar procedimiento',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: procedure.steps.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      procedure.description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  );
                }
                final step = procedure.steps[index - 1];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: accent.withValues(
                        alpha: index == procedure.steps.length ? 0.55 : 0.22,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '$index. ${step.title}',
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        step.description,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                      if (step.table != null) ...[
                        const SizedBox(height: 14),
                        _ProcedureTable(table: step.table!),
                      ],
                      for (final expression in step.expressions) ...[
                        const SizedBox(height: 12),
                        SelectableText(
                          expression,
                          style: const TextStyle(fontSize: 14, height: 1.7),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  ),
);

class _ProcedureTable extends StatefulWidget {
  const _ProcedureTable({required this.table});
  final MathematicalTable table;
  @override
  State<_ProcedureTable> createState() => _ProcedureTableState();
}

class _ProcedureTableState extends State<_ProcedureTable> {
  final _scroll = ScrollController();
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scrollbar(
    controller: _scroll,
    thumbVisibility: true,
    child: SingleChildScrollView(
      controller: _scroll,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 12),
      child: DataTable(
        columnSpacing: 16,
        horizontalMargin: 12,
        dataRowMinHeight: 48,
        dataRowMaxHeight: math.max(
          72,
          56 * MediaQuery.textScalerOf(context).scale(1),
        ),
        columns: [
          for (final label in widget.table.columns)
            DataColumn(label: _label(label, heading: true)),
        ],
        rows: [
          for (final row in widget.table.rows)
            DataRow(cells: [for (final cell in row) DataCell(_label(cell))]),
        ],
      ),
    ),
  );
  Widget _label(String label, {bool heading = false}) => SizedBox(
    width: 108,
    child: Tooltip(
      message: label,
      child: Text(
        label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: heading ? const TextStyle(fontWeight: FontWeight.w600) : null,
      ),
    ),
  );
}
