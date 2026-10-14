import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/features/sorting/domain/sorting_algorithm.dart';
import 'package:app_grafos/features/sorting/presentation/screens/sorting_race_screen.dart';
import 'package:app_grafos/features/sorting/presentation/screens/sorting_visualization_screen.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(1280, 900)]) {
    testWidgets(
      'carrera, validación, pausa, resultados, línea de tiempo y detalle a ${size.width}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
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
            home: const SortingRaceScreen(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Big O:'), findsNothing);
        await tester.enterText(find.byType(TextField), '0, 4');
        await tester.tap(find.text('Aplicar números'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Todos los números deben estar entre'),
          findsOneWidget,
        );
        await tester.enterText(find.byType(TextField), '9, 3, 6, 3');
        await tester.tap(find.text('Aplicar números'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Iniciar carrera'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Iniciar carrera'));
        await tester.pump(const Duration(milliseconds: 330));
        await tester.tap(find.text('Pausar carrera'));
        await tester.pumpAndSettle();
        final turn = tester
            .widget<Text>(find.textContaining(RegExp(r'^Turno ')))
            .data;
        await tester.pump(const Duration(seconds: 1));
        expect(
          tester.widget<Text>(find.textContaining(RegExp(r'^Turno '))).data,
          turn,
        );
        await tester.tap(find.text('Ver resultado'));
        await tester.pumpAndSettle();
        expect(find.text('Comparación completada'), findsOneWidget);
        expect(find.textContaining('Big O:'), findsNWidgets(4));
        for (final method in SortingAlgorithm.values) {
          expect(
            tester
                .widget<Text>(find.byKey(ValueKey('race-array-${method.name}')))
                .data,
            '3 · 3 · 6 · 9',
          );
        }
        final slider = find.byKey(const ValueKey('race-timeline'));
        await tester.ensureVisible(slider);
        await tester.pumpAndSettle();
        await tester.tapAt(tester.getTopLeft(slider) + const Offset(24, 24));
        await tester.pumpAndSettle();
        expect(find.text('Comparación completada'), findsNothing);
        await tester.ensureVisible(find.text('Abrir detalle').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Abrir detalle').first);
        await tester.pumpAndSettle();
        expect(find.byType(SortingVisualizationScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
