import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/features/assignment/presentation/screens/asignacion_screen.dart';
import 'package:app_grafos/features/binary_tree/presentation/screens/binary_tree_screen.dart';
import 'package:app_grafos/features/esquina_nor_oeste/presentation/screens/esquina_nor_oeste_screen.dart';
import 'package:app_grafos/features/graph/presentation/screens/grafo_screen.dart';
import 'package:app_grafos/features/johnson/presentation/screens/johnson_screen.dart';
import 'package:app_grafos/features/sorting/domain/sorting_algorithm.dart';
import 'package:app_grafos/features/sorting/presentation/screens/sorting_methods_screen.dart';
import 'package:app_grafos/features/sorting/presentation/screens/sorting_visualization_screen.dart';
import 'package:app_grafos/shared/widgets/algorithm_scaffold.dart';

void main() {
  final screens = <String, Widget>{
    'grafos': const GrafoScreen(),
    'árboles': const BinaryTreeScreen(),
    'asignación': const AsignacionScreen(),
    'Johnson': const JohnsonScreen(),
    'transporte': const EsquinaNorOesteScreen(),
    'métodos': const SortingMethodsScreen(),
    'Selection Sort': const SortingVisualizationScreen(
      algorithm: SortingAlgorithm.selectionSort,
      initialArray: [8, 3, 5, 1],
    ),
    'Merge Sort': const SortingVisualizationScreen(
      algorithm: SortingAlgorithm.mergeSort,
      initialArray: [8, 3, 5, 1],
    ),
    'Shell Sort': const SortingVisualizationScreen(
      algorithm: SortingAlgorithm.shellSort,
      initialArray: [8, 3, 5, 1],
    ),
    'Insertion Sort': const SortingVisualizationScreen(
      algorithm: SortingAlgorithm.insertionSort,
      initialArray: [8, 3, 5, 1],
    ),
  };

  for (final size in [
    const Size(390, 844),
    const Size(800, 900),
    const Size(1280, 800),
  ]) {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} sin desbordamiento a ${size.width}', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.dark, home: entry.value),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Open optional matrix panels through their actual screen controls.
        if (entry.key == 'grafos' ||
            entry.key == 'asignación' ||
            entry.key == 'transporte') {
          await tester.tap(find.byTooltip('Mostrar matriz'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        if (entry.key == 'métodos' ||
            entry.key == 'Selection Sort' ||
            entry.key == 'Insertion Sort' ||
            entry.key == 'Merge Sort' ||
            entry.key == 'Shell Sort') {
          await tester.tap(find.byTooltip('Más opciones'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Manual de uso'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(find.text('Vuelve a experimentar'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tap(find.text('¡Entendido!'));
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog), findsNothing);
        }
        if (entry.key == 'Johnson') {
          final canvas = find.byType(AlgorithmWorkspace);
          await tester.tapAt(
            tester.getTopLeft(canvas) + const Offset(100, 100),
          );
          await tester.pump(const Duration(milliseconds: 350));
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextField).first, 'Inicio');
          await tester.tap(find.widgetWithText(FilledButton, 'Crear'));
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('Calcular'));
          await tester.pumpAndSettle();
          expect(find.text('Resultados:'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      });
    }
  }

  testWidgets('ordenamiento permite avanzar y cambiar los datos en móvil', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: screens['Selection Sort']),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Siguiente'));
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Paso 2 de'), findsOneWidget);
    await tester.ensureVisible(find.text('Nuevo ordenamiento'));
    await tester.tap(find.text('Nuevo ordenamiento'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.enterText(find.byType(TextField), '9, 2, 6');
    await tester.ensureVisible(find.text('Usar estos números'));
    await tester.tap(find.text('Usar estos números'));
    await tester.pumpAndSettle();
    expect(find.text('9 | 2 | 6'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
