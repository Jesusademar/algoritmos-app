import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/features/assignment/presentation/screens/asignacion_screen.dart';
import 'package:app_grafos/features/binary_tree/presentation/screens/binary_tree_screen.dart';
import 'package:app_grafos/features/esquina_nor_oeste/presentation/screens/esquina_nor_oeste_screen.dart';
import 'package:app_grafos/features/graph/presentation/screens/grafo_screen.dart';
import 'package:app_grafos/features/johnson/presentation/screens/johnson_screen.dart';
import 'package:app_grafos/features/sorting/presentation/screens/sorting_methods_screen.dart';
import 'package:app_grafos/features/sorting/presentation/screens/sorting_race_screen.dart';
import 'package:app_grafos/shared/help/algorithm_manuals.dart';

void main() {
  final screens = <AlgorithmManual, Widget>{
    AlgorithmManual.graph: const GrafoScreen(),
    AlgorithmManual.assignment: const AsignacionScreen(),
    AlgorithmManual.transport: const EsquinaNorOesteScreen(),
    AlgorithmManual.johnson: const JohnsonScreen(),
    AlgorithmManual.sorting: const SortingMethodsScreen(),
    AlgorithmManual.binaryTree: const BinaryTreeScreen(),
    AlgorithmManual.sortingRace: const SortingRaceScreen(),
  };
  for (final size in [const Size(390, 844), const Size(1280, 900)]) {
    testWidgets(
      'los siete manuales abren desde su pantalla y permiten leer hasta el final a ${size.width}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        for (final entry in screens.entries) {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.dark,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.3),
                  disableAnimations: true,
                ),
                child: child!,
              ),
              home: entry.value,
            ),
          );
          await tester.pumpAndSettle();
          if (entry.key == AlgorithmManual.sortingRace) {
            await tester.tap(find.byTooltip('Cómo comparar'));
          } else {
            await tester.tap(find.byTooltip('Más opciones'));
            await tester.pumpAndSettle();
            await tester.tap(
              find.text(
                entry.key == AlgorithmManual.graph ? 'Ayuda' : 'Manual de uso',
              ),
            );
          }
          await tester.pumpAndSettle();
          expect(
            find.text('Manual de uso · ${entry.key.title}'),
            findsOneWidget,
          );
          for (final section in entry.key.sections) {
            expect(
              find.descendant(
                of: find.byType(AlertDialog),
                matching: find.text(section.title),
              ),
              findsOneWidget,
            );
          }
          await tester.ensureVisible(find.text(entry.key.sections.last.title));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tap(find.text('¡Entendido!'));
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog), findsNothing);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        }
      },
    );
  }
}
