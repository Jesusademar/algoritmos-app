import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/features/sorting/domain/sorting_numbers.dart';
import 'package:app_grafos/features/sorting/domain/sorting_validator.dart';

/// Entrada compartida por la visualización y la carrera de métodos.
class SortingInputDialog extends StatefulWidget {
  const SortingInputDialog({
    super.key,
    required this.onArray,
    this.initialQuantity = 10,
  });
  final ValueChanged<List<Object>> onArray;
  final int initialQuantity;
  @override
  State<SortingInputDialog> createState() => _SortingInputDialogState();
}

class _SortingInputDialogState extends State<SortingInputDialog> {
  late final _quantity = TextEditingController(
    text: '${widget.initialQuantity}',
  );
  final _minimum = TextEditingController(text: '1');
  final _maximum = TextEditingController(text: '100');
  final _manual = TextEditingController();
  String? _randomError;
  String? _manualError;
  bool _unique = false;
  @override
  void dispose() {
    for (final controller in [_quantity, _minimum, _maximum, _manual]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _clearRandomError(String _) {
    if (_randomError != null) setState(() => _randomError = null);
  }

  void _generate() {
    final quantity = int.tryParse(_quantity.text.trim());
    if (quantity == null || quantity <= 0) {
      setState(
        () => _randomError = 'La cantidad debe ser un entero mayor que cero.',
      );
      return;
    }
    try {
      final minimum = SortingNumbers.parse(_minimum.text);
      final maximum = SortingNumbers.parse(_maximum.text);
      final numbers = SortingValidator.generateRandomArray(
        quantity,
        minimum: minimum,
        maximum: maximum,
        unique: _unique,
      );
      widget.onArray(numbers);
    } on FormatException {
      setState(
        () => _randomError = 'Escribe un mínimo y un máximo enteros válidos.',
      );
    } on ArgumentError catch (error) {
      setState(() => _randomError = error.message.toString());
    }
  }

  void _submitManual() {
    final (numbers, error) = SortingValidator.parseInputString(_manual.text);
    if (error != null) {
      setState(() => _manualError = error);
      return;
    }
    widget.onArray(numbers);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Ingresa los números para ordenar'),
    content: SizedBox(
      width: 520,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tú eliges la cantidad y las cifras. Se admiten enteros positivos, negativos y cero.',
              style: TextStyle(color: AppColors.textMuted, height: 1.5),
            ),
            const SizedBox(height: 20),
            const Text(
              'Opción 1: Números aleatorios',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _quantity,
              keyboardType: TextInputType.number,
              onChanged: _clearRandomError,
              onSubmitted: (_) => _generate(),
              decoration: const InputDecoration(
                labelText: 'Cantidad de números',
                hintText: 'Ej: 1000',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _minimum,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              onChanged: _clearRandomError,
              onSubmitted: (_) => _generate(),
              decoration: const InputDecoration(
                labelText: 'Valor mínimo',
                hintText: 'Ej: -5000',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _maximum,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              onChanged: _clearRandomError,
              onSubmitted: (_) => _generate(),
              decoration: const InputDecoration(
                labelText: 'Valor máximo',
                hintText: 'Ej: 1000000',
                helperText: 'Se incluyen ambos extremos del rango.',
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sin repetir'),
              subtitle: const Text(
                'Desactivado: se permiten valores repetidos.',
              ),
              value: _unique,
              onChanged: (value) => setState(() {
                _unique = value;
                _randomError = null;
              }),
            ),
            if (_randomError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _randomError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ElevatedButton(
              onPressed: _generate,
              child: const Text('Generar aleatorios'),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            const Text(
              'Opción 2: Ingresar manualmente',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _manual,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submitManual(),
              onChanged: (_) {
                if (_manualError != null) setState(() => _manualError = null);
              },
              decoration: InputDecoration(
                labelText: 'Números a ordenar',
                hintText: 'Ej: -2500, 0, 99999999999999999999',
                helperText:
                    'Enteros separados por comas. Puedes repetir valores.',
                helperMaxLines: 2,
                errorText: _manualError,
                errorMaxLines: 3,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _submitManual,
              child: const Text('Usar estos números'),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
    ],
  );
}
