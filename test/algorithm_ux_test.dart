import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/features/catalog/presentation/screens/menu_principal_screen.dart';
import 'package:app_grafos/features/graph/presentation/screens/grafo_screen.dart';
import 'package:app_grafos/features/sorting/domain/sorting_algorithm.dart';
import 'package:app_grafos/features/sorting/presentation/screens/sorting_visualization_screen.dart';
import 'package:app_grafos/shared/widgets/algorithm_card_grid.dart';
import 'package:app_grafos/shared/widgets/algorithm_scaffold.dart';

void main() {
  for (final size in [
    const Size(390, 844),
    const Size(800, 900),
    const Size(1280, 900),
  ]) {
    testWidgets('menú legible y navegable a ${size.width}', (tester) async {
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
          home: const MenuPrincipalScreen(),
        ),
      );
      // Verify pointer navigation on compact layouts and keyboard activation on desktop.
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      final cards = find.descendant(
        of: find.byType(AlgorithmCardGrid),
        matching: find.byType(InkWell),
      );
      expect(cards, findsNWidgets(6));
      if (size.width >= 1000) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      } else {
        await tester.ensureVisible(find.text('Redes y Grafos'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Redes y Grafos'));
      }
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(GrafoScreen), findsOneWidget);
      expect(find.byType(AlgorithmScaffold), findsOneWidget);
      expect(find.text('Redes y Grafos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'la velocidad cambia y el manual y el diálogo pausan la reproducción',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const SortingVisualizationScreen(
            algorithm: SortingAlgorithm.selectionSort,
            initialArray: [9, 8, 7, 6, 5, 4, 3, 2, 1],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reproducir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('Paso 2 de'), findsOneWidget);
      final speed = find.byType(Slider);
      await tester.ensureVisible(speed);
      await tester.tapAt(tester.getTopRight(speed) - const Offset(24, -24));
      await tester.pump();
      expect(find.text('Velocidad: 2.0×'), findsOneWidget);
      final stepBefore = tester
          .widget<Text>(find.textContaining(RegExp(r'^Paso \d+ de')))
          .data;
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        tester.widget<Text>(find.textContaining(RegExp(r'^Paso \d+ de'))).data,
        isNot(stepBefore),
      );
      await tester.tap(find.byTooltip('Más opciones'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Manual de uso'));
      await tester.pumpAndSettle();
      final helpStep = tester
          .widget<Text>(find.textContaining(RegExp(r'^Paso \d+ de')))
          .data;
      await tester.pump(const Duration(seconds: 2));
      expect(
        tester.widget<Text>(find.textContaining(RegExp(r'^Paso \d+ de'))).data,
        helpStep,
      );
      await tester.tap(find.text('¡Entendido!'));
      await tester.pumpAndSettle();
      expect(find.text('Reproducir'), findsOneWidget);
      await tester.ensureVisible(find.text('Reproducir'));
      await tester.tap(find.text('Reproducir'));
      await tester.pump();
      await tester.ensureVisible(find.text('Nuevo ordenamiento'));
      await tester.tap(find.text('Nuevo ordenamiento'));
      await tester.pumpAndSettle();
      final pausedStep = tester
          .widget<Text>(find.textContaining(RegExp(r'^Paso \d+ de')))
          .data;
      await tester.pump(const Duration(seconds: 2));
      expect(
        tester.widget<Text>(find.textContaining(RegExp(r'^Paso \d+ de'))).data,
        pausedStep,
      );
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('Reproducir'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('el formulario muestra errores y acepta números con Enter', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const SortingVisualizationScreen(
          algorithm: SortingAlgorithm.insertionSort,
          initialArray: [5, 3, 8],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Nuevo ordenamiento'));
    await tester.tap(find.text('Nuevo ordenamiento'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '0, 101');
    await tester.ensureVisible(find.text('Usar estos números'));
    await tester.tap(find.text('Usar estos números'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).decoration!.errorText,
      isNotNull,
    );
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.enterText(find.byType(TextField), '9, 2, 6');
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).decoration!.errorText,
      isNull,
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('9 | 2 | 6'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
