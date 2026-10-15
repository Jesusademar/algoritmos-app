import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/features/sorting/domain/sorting_algorithm.dart';
import 'package:app_grafos/features/sorting/domain/sorting_numbers.dart';
import 'package:app_grafos/features/sorting/domain/sorting_order.dart';
import 'package:app_grafos/features/sorting/presentation/screens/sorting_visualization_screen.dart';
import 'package:app_grafos/features/sorting/presentation/widgets/bowling_pin_widget.dart';
import 'package:app_grafos/features/sorting/presentation/widgets/sorting_input_dialog.dart';
import 'package:app_grafos/features/sorting/presentation/widgets/sorting_visualization_widget.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(1280, 900)]) {
    testWidgets(
      'valida el rango y la repetición y dibuja enteros grandes a ${size.width}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final huge = '9' * 120;
        final upper = (BigInt.parse(huge) + BigInt.one).toString();
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Builder(
              builder: (context) => Scaffold(
                body: FilledButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (context) => SortingInputDialog(
                      onArray: (numbers) =>
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute<void>(
                              builder: (_) => SortingVisualizationScreen(
                                algorithm: SortingAlgorithm.mergeSort,
                                initialArray: numbers,
                              ),
                            ),
                          ),
                    ),
                  ),
                  child: const Text('Abrir entrada'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Abrir entrada'));
        await tester.pumpAndSettle();
        Future<void> enter(String label, String value) async {
          await tester.enterText(find.widgetWithText(TextField, label), value);
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
        }

        Future<void> generate() async {
          await tester.ensureVisible(find.text('Generar aleatorios'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Generar aleatorios'));
          await tester.pumpAndSettle();
        }

        await enter('Cantidad de números', '180');
        await enter('Valor mínimo', upper);
        await enter('Valor máximo', huge);
        await generate();
        expect(
          find.text('El mínimo no puede ser mayor que el máximo.'),
          findsOneWidget,
        );
        await enter('Valor mínimo', huge);
        await enter('Valor máximo', upper);
        await tester.ensureVisible(find.byType(SwitchListTile));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(SwitchListTile));
        await tester.pumpAndSettle();
        await generate();
        expect(
          find.textContaining(
            'El rango no contiene suficientes números distintos.',
          ),
          findsOneWidget,
        );
        await tester.ensureVisible(find.byType(SwitchListTile));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(SwitchListTile));
        await tester.pumpAndSettle();
        await generate();
        final provider = tester
            .widget<SortingVisualizationWidget>(
              find.byType(SortingVisualizationWidget),
            )
            .provider;
        expect(provider.originalArray, hasLength(180));
        expect(
          provider.originalArray.every(
            (value) => value.toString() == huge || value.toString() == upper,
          ),
          isTrue,
        );
        await tester.ensureVisible(find.text('Ver resultado'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ver resultado'));
        await tester.pumpAndSettle();
        expect(provider.isComplete, isTrue);
        await tester.ensureVisible(find.text('Resultado · Big O'));
        await tester.pumpAndSettle();
        expect(find.text('O(n log n)'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'permite definir cantidad y rango sin topes fijos a ${size.width}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: const SortingVisualizationScreen(
              algorithm: SortingAlgorithm.selectionSort,
              initialArray: [4, 2, 9],
              initialOrder: SortingOrder.descending,
            ),
          ),
        );
        await tester.pumpAndSettle();
        Future<void> openInput() async {
          await tester.ensureVisible(find.text('Nuevo ordenamiento'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Nuevo ordenamiento'));
          await tester.pumpAndSettle();
        }

        await openInput();
        final count = find.widgetWithText(TextField, 'Cantidad de números');
        final generate = find.text('Generar aleatorios');
        for (final invalid in ['', '0', '-1', '1.5', 'abc']) {
          await tester.enterText(count, invalid);
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
          await tester.ensureVisible(generate);
          await tester.pumpAndSettle();
          await tester.tap(generate);
          await tester.pumpAndSettle();
          expect(
            find.text('La cantidad debe ser un entero mayor que cero.'),
            findsOneWidget,
          );
          expect(find.byType(AlertDialog), findsOneWidget);
        }
        for (final quantity in [37, 240]) {
          await tester.enterText(
            find.widgetWithText(TextField, 'Valor mínimo'),
            '-5000',
          );
          await tester.enterText(
            find.widgetWithText(TextField, 'Valor máximo'),
            '999999',
          );
          await tester.enterText(count, '$quantity');
          expect(tester.widget<TextField>(count).controller!.text, '$quantity');
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog), findsNothing);
          final provider = tester
              .widget<SortingVisualizationWidget>(
                find.byType(SortingVisualizationWidget),
              )
              .provider;
          expect(provider.originalArray, hasLength(quantity));
          expect(
            provider.originalArray.every(
              (value) =>
                  SortingNumbers.compare(value, -5000) >= 0 &&
                  SortingNumbers.compare(value, 999999) <= 0,
            ),
            isTrue,
          );
          expect(provider.order, SortingOrder.descending);
          expect(
            find.byType(BowlingPinWidget).evaluate().length,
            inInclusiveRange(1, quantity),
          );
          await tester.ensureVisible(find.text('Ver resultado'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Ver resultado'));
          await tester.pumpAndSettle();
          final expected = provider.originalArray.toList()
            ..sort((a, b) => SortingNumbers.compare(b, a));
          expect(provider.currentArray, expected);
          await tester.ensureVisible(find.text('Resultado · Big O'));
          await tester.pumpAndSettle();
          expect(find.text('O(n²)'), findsOneWidget);
          expect(tester.takeException(), isNull);
          if (quantity != 240) await openInput();
        }
      },
    );
  }
}
