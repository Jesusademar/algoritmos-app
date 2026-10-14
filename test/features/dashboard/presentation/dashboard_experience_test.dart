import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:app_grafos/features/sorting/presentation/screens/sorting_methods_screen.dart';

void main() {
  for (final size in [
    const Size(390, 844),
    const Size(800, 900),
    const Size(1440, 1000),
  ]) {
    testWidgets('dashboard interactivo con texto ampliado a ${size.width}', (
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
            data: MediaQuery.of(context).copyWith(
              disableAnimations: true,
              textScaler: const TextScaler.linear(1.3),
            ),
            child: child!,
          ),
          home: const DashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (final developer in [
        'Jesus Canqui',
        'Miguel Sanchez',
        'Jenny Quispe',
      ]) {
        expect(find.text(developer), findsOneWidget);
      }
      await tester.ensureVisible(find.text('Ordenar ejemplo'));
      await tester.tap(find.text('Ordenar ejemplo'));
      await tester.pumpAndSettle();
      expect(find.text('Resultado: 2, 3, 5, 7, 9'), findsOneWidget);
      await tester.tap(find.text('Reiniciar ejemplo'));
      await tester.pumpAndSettle();
      expect(find.text('Entrada: 7, 3, 9, 2, 5'), findsOneWidget);
      final sorting = find.widgetWithText(ChoiceChip, 'Ordenamiento');
      await tester.ensureVisible(sorting);
      await tester.tap(sorting);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('Ordenamiento')),
          matching: find.text('Selection, Insertion, Merge y Shell Sort'),
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Abrir este módulo'));
      await tester.tap(find.text('Abrir este módulo'));
      await tester.pumpAndSettle();
      expect(find.byType(SortingMethodsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
