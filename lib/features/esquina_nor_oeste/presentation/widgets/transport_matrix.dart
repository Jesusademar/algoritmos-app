import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/features/esquina_nor_oeste/domain/esquina_nor_oeste_problem.dart';
import 'package:app_grafos/shared/domain/mathematical_procedure.dart';

/// Edición estable de las cantidades reales y vista de la matriz balanceada.
class TransportMatrix extends StatefulWidget {
  const TransportMatrix({
    super.key,
    required this.problem,
    required this.formKey,
    required this.onSupplyChanged,
    required this.onDemandChanged,
  });
  final EsquinaNorOesteProblem problem;
  final GlobalKey<FormState> formKey;
  final void Function(String, int?) onSupplyChanged;
  final void Function(String, int?) onDemandChanged;
  @override
  State<TransportMatrix> createState() => _TransportMatrixState();
}

class _TransportMatrixState extends State<TransportMatrix> {
  double _cellWidth = 72;
  final _horizontalScroll = ScrollController();
  final _supplies = <String, TextEditingController>{};
  final _demands = <String, TextEditingController>{};
  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(TransportMatrix oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync(oldWidget.problem);
  }

  void _sync([EsquinaNorOesteProblem? old]) {
    void update(
      Map<String, TextEditingController> controllers,
      String id,
      num value,
      num? previous,
    ) {
      final controller = controllers.putIfAbsent(
        id,
        () => TextEditingController(text: mathNumber(value)),
      );
      if (value != previous && int.tryParse(controller.text) != value) {
        controller.text = mathNumber(value);
      }
    }

    for (final item in widget.problem.origins.where((item) => !item.isDummy)) {
      final previous = old?.origins
          .where((origin) => origin.id == item.id)
          .firstOrNull;
      update(_supplies, item.id, item.supply, previous?.supply);
    }
    for (final item in widget.problem.destinations.where(
      (item) => !item.isDummy,
    )) {
      final previous = old?.destinations
          .where((destination) => destination.id == item.id)
          .firstOrNull;
      update(_demands, item.id, item.demand, previous?.demand);
    }
  }

  @override
  void dispose() {
    _horizontalScroll.dispose();
    for (final controller in [..._supplies.values, ..._demands.values]) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _quantity(EsquinaNorOesteItem item, {required bool supply}) =>
      SizedBox(
        width: _cellWidth,
        child: TextFormField(
          key: ValueKey('${supply ? 'supply' : 'demand'}-${item.id}'),
          controller: (supply ? _supplies : _demands)[item.id],
          keyboardType: TextInputType.number,
          style: TextStyle(
            fontSize: 12,
            color: supply ? AppColors.success : AppColors.text,
            fontWeight: FontWeight.w600,
          ),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (text) {
            final value = int.tryParse(text?.trim() ?? '');
            return value == null || value < 0 ? 'Entero no negativo' : null;
          },
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            labelText: supply ? null : 'Dem',
            labelStyle: const TextStyle(fontSize: 10),
            errorMaxLines: 2,
            errorStyle: const TextStyle(fontSize: 9, height: 1),
          ),
          onChanged: (text) => (supply
              ? widget.onSupplyChanged
              : widget.onDemandChanged)(item.id, int.tryParse(text.trim())),
        ),
      );
  Widget _label(EsquinaNorOesteItem item) => Tooltip(
    message: item.label,
    child: SizedBox(
      width: _cellWidth,
      child: Text(
        item.label,
        maxLines: 2,
        softWrap: true,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: item.isDummy ? AppColors.warningText : AppColors.text,
        ),
      ),
    ),
  );
  String _costText(num? cost) => cost == null ? '—' : mathNumber(cost);
  @override
  Widget build(BuildContext context) {
    final balanced = widget.problem.toBalanced();
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = balanced.destinations.length + 2;
        _cellWidth = ((constraints.maxWidth - 16 - (columns - 1) * 8) / columns)
            .clamp(64.0, 100.0);
        return Form(
          key: widget.formKey,
          child: Scrollbar(
            controller: _horizontalScroll,
            thumbVisibility: true,
            trackVisibility: true,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            child: SingleChildScrollView(
              controller: _horizontalScroll,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 14),
              child: DataTable(
                columnSpacing: 8,
                horizontalMargin: 8,
                headingRowHeight: math.max(
                  96,
                  84 * MediaQuery.textScalerOf(context).scale(1),
                ),
                dataRowMinHeight: 44,
                dataRowMaxHeight: 72,
                headingRowColor: const WidgetStatePropertyAll(
                  AppColors.successSoft,
                ),
                columns: [
                  DataColumn(
                    label: SizedBox(
                      width: _cellWidth,
                      child: const Text(
                        'Origen / destino',
                        maxLines: 2,
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  for (final destination in balanced.destinations)
                    DataColumn(
                      label: SizedBox(
                        width: _cellWidth,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label(destination),
                            const SizedBox(height: 6),
                            if (destination.isDummy)
                              Text(
                                'Dem: ${mathNumber(destination.demand)}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.warningText,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            else
                              _quantity(destination, supply: false),
                          ],
                        ),
                      ),
                    ),
                  DataColumn(
                    label: SizedBox(
                      width: _cellWidth,
                      child: const Text(
                        'Oferta',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
                rows: [
                  for (final origin in balanced.origins)
                    DataRow(
                      color: origin.isDummy
                          ? const WidgetStatePropertyAll(AppColors.warningSoft)
                          : null,
                      cells: [
                        DataCell(_label(origin)),
                        for (final destination in balanced.destinations)
                          DataCell(
                            Text(
                              _costText(
                                balanced.costFor(origin.id, destination.id),
                              ),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: origin.isDummy || destination.isDummy
                                    ? AppColors.warningText
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        DataCell(
                          origin.isDummy
                              ? Text(
                                  mathNumber(origin.supply),
                                  style: const TextStyle(
                                    color: AppColors.warningText,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : _quantity(origin, supply: true),
                        ),
                      ],
                    ),
                  DataRow(
                    cells: [
                      const DataCell(
                        Text(
                          'Demanda',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      for (final destination in balanced.destinations)
                        DataCell(
                          Text(
                            mathNumber(destination.demand),
                            style: TextStyle(
                              color: destination.isDummy
                                  ? AppColors.warningText
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      DataCell(
                        Text(
                          mathNumber(balanced.totalSupply),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
