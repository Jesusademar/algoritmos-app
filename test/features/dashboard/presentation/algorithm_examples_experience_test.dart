import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/app/navigation/algorithm_modules.dart';
import 'package:app_grafos/features/assignment/presentation/screens/asignacion_screen.dart';
import 'package:app_grafos/features/binary_tree/presentation/widgets/binary_tree_canvas.dart';
import 'package:app_grafos/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:app_grafos/features/esquina_nor_oeste/presentation/screens/esquina_nor_oeste_screen.dart';
import 'package:app_grafos/features/johnson/presentation/screens/johnson_screen.dart';
import 'package:app_grafos/features/sorting/presentation/screens/sorting_visualization_screen.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(1280, 900)]) {
    testWidgets(
      'los seis ejemplos abren datos listos y calculan a ${size.width}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: const DashboardScreen(),
          ),
        );
        await tester.pumpAndSettle();
        for (final module in algorithmModules) {
          final choice = find.widgetWithText(ChoiceChip, module.label);
          await tester.ensureVisible(choice);
          await tester.pumpAndSettle();
          await tester.tap(choice);
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Probar ejemplo listo'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Probar ejemplo listo'));
          await tester.pumpAndSettle();
          if (module.id == 'assignment') {
            await tester.ensureVisible(find.text('Calcular Asignación Óptima'));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Calcular Asignación Óptima'));
            await tester.pumpAndSettle();
            final dynamic state = tester.state(find.byType(AsignacionScreen));
            expect(state.ultimoCostoOptimo, 4);
          } else if (module.id == 'transport') {
            await tester.ensureVisible(find.text('Calcular mínimo'));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Calcular mínimo'));
            await tester.pumpAndSettle();
            final dynamic state = tester.state(
              find.byType(EsquinaNorOesteScreen),
            );
            expect(state.ultimoCostoTotal, 40);
          } else if (module.id == 'johnson') {
            await tester.tap(find.byTooltip('Calcular'));
            await tester.pumpAndSettle();
            final dynamic state = tester.state(find.byType(JohnsonScreen));
            expect(state.proyectoDuracionTotal, 10);
          } else if (module.id == 'binary-tree') {
            expect(
              tester
                  .widget<BinaryTreeCanvas>(find.byType(BinaryTreeCanvas))
                  .tree
                  .size,
              9,
            );
          } else if (module.id == 'sorting') {
            expect(find.byType(SortingVisualizationScreen), findsOneWidget);
          }
          expect(tester.takeException(), isNull);
          Navigator.of(tester.element(find.byType(Scaffold).last)).pop();
          await tester.pumpAndSettle();
        }
      },
    );
  }
}
