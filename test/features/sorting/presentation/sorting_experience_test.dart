import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/features/sorting/domain/sorting_algorithm.dart';
import 'package:app_grafos/features/sorting/domain/sorting_order.dart';
import 'package:app_grafos/features/sorting/presentation/screens/sorting_methods_screen.dart';
import 'package:app_grafos/features/sorting/presentation/screens/sorting_visualization_screen.dart';
import 'package:app_grafos/features/sorting/presentation/widgets/sorting_visualization_widget.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(1280, 900)]) {
    testWidgets('orden descendente, Big O y nuevos datos a ${size.width}', (
      tester,
    ) async {
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
          home: const SortingMethodsScreen(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Descendente'));
      await tester.tap(find.text('Descendente'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Big O'), findsNothing);
      expect(find.text('O(n)'), findsNothing);
      await tester.ensureVisible(find.text('Insertion Sort'));
      await tester.tap(find.text('Insertion Sort'));
      await tester.pumpAndSettle();
      final provider = tester
          .widget<SortingVisualizationWidget>(
            find.byType(SortingVisualizationWidget),
          )
          .provider;
      expect(provider.order, SortingOrder.descending);
      expect(provider.algorithm, SortingAlgorithm.insertionSort);
      expect(find.textContaining('Big O'), findsNothing);
      await tester.ensureVisible(find.text('Reproducir'));
      await tester.tap(find.text('Reproducir'));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.ensureVisible(find.text('Ascendente'));
      await tester.tap(find.text('Ascendente'));
      await tester.pumpAndSettle();
      expect(provider.order, SortingOrder.ascending);
      expect(provider.currentStepIndex, 0);
      expect(provider.isPlaying, isFalse);
      await tester.tap(find.text('Descendente'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Nuevo ordenamiento'));
      await tester.tap(find.text('Nuevo ordenamiento'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '3, 9, 1, 3');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      final updated = tester
          .widget<SortingVisualizationWidget>(
            find.byType(SortingVisualizationWidget),
          )
          .provider;
      expect(updated.order, SortingOrder.descending);
      expect(updated.finalArray, [9, 3, 3, 1]);
      while (!updated.isComplete) {
        updated.nextStep();
      }
      await tester.pumpAndSettle();
      expect(find.text('9 | 3 | 3 | 1'), findsOneWidget);
      await tester.ensureVisible(find.text('Resultado · Big O'));
      await tester.pumpAndSettle();
      expect(find.text('O(n²)'), findsOneWidget);
      expect(
        find.text('Comparaciones: ${updated.totalComparisons}'),
        findsOneWidget,
      );
      expect(find.textContaining('Cálculo de los pasos:'), findsOneWidget);
      updated.reset();
      await tester.pumpAndSettle();
      expect(find.textContaining('Big O'), findsNothing);
      updated.setOrder(SortingOrder.ascending);
      expect(find.textContaining('Big O'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Big O lineal aparece al terminar una entrada ya ordenada', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const SortingVisualizationScreen(
          algorithm: SortingAlgorithm.insertionSort,
          initialArray: [1, 2, 3],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Big O'), findsNothing);
    await tester.ensureVisible(find.text('Reproducir'));
    await tester.tap(find.text('Reproducir'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Big O'), findsNothing);
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Resultado · Big O'));
    expect(find.text('O(n)'), findsOneWidget);
    expect(find.text('Comparaciones: 2'), findsOneWidget);
    expect(find.text('Desplazamientos: 0'), findsOneWidget);
    expect(find.text('Mejor caso'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  for (final algorithm in [
    SortingAlgorithm.mergeSort,
    SortingAlgorithm.shellSort,
  ]) {
    testWidgets(
      '${algorithm.displayName} se abre, ordena descendente y muestra Big O al finalizar',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.dark, home: const SortingMethodsScreen()),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Descendente'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(algorithm.displayName));
        await tester.tap(find.text(algorithm.displayName));
        await tester.pumpAndSettle();
        final provider = tester
            .widget<SortingVisualizationWidget>(
              find.byType(SortingVisualizationWidget),
            )
            .provider;
        expect(provider.algorithm, algorithm);
        expect(provider.order, SortingOrder.descending);
        expect(find.textContaining('Big O'), findsNothing);
        await tester.ensureVisible(find.text('Reproducir'));
        await tester.tap(find.text('Reproducir'));
        await tester.pump(const Duration(seconds: 2));
        expect(provider.currentStepIndex, greaterThan(0));
        expect(find.textContaining('Big O'), findsNothing);
        final expected = [15, 47, 45, 60, 52, 84, 88, 59, 89, 86, 60]
          ..sort((a, b) => b.compareTo(a));
        await tester.pump(const Duration(minutes: 2));
        await tester.pumpAndSettle();
        expect(provider.currentArray, expected);
        await tester.ensureVisible(find.text('Resultado · Big O'));
        expect(find.text(algorithm.worstCase), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
