import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/app/navigation/algorithm_examples.dart';
import 'package:app_grafos/features/assignment/presentation/screens/asignacion_screen.dart';
import 'package:app_grafos/features/esquina_nor_oeste/presentation/screens/esquina_nor_oeste_screen.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(1280, 900)]) {
    for (final assignment in [true, false]) {
      testWidgets(
        '${assignment ? 'asignación' : 'transporte'} muestra el procedimiento y lo invalida al cambiar el objetivo a ${size.width}',
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
                  disableAnimations: true,
                  textScaler: const TextScaler.linear(1.3),
                ),
                child: child!,
              ),
              home: assignment
                  ? AsignacionScreen(
                      initialDocument: graphExample('assignment'),
                    )
                  : EsquinaNorOesteScreen(
                      initialDocument: graphExample('transport'),
                    ),
            ),
          );
          await tester.pumpAndSettle();
          final procedureButton = find.widgetWithText(
            OutlinedButton,
            'Ver procedimiento matemático',
          );
          final panelScroll = find
              .descendant(
                of: find.byType(ListView).last,
                matching: find.byType(Scrollable),
              )
              .first;
          Future<void> showControl(Finder control) async {
            tester.state<ScrollableState>(panelScroll).position.jumpTo(0);
            await tester.pumpAndSettle();
            await tester.scrollUntilVisible(
              control,
              250,
              scrollable: panelScroll,
            );
            await tester.pumpAndSettle();
          }

          await showControl(procedureButton);
          expect(
            tester.widget<OutlinedButton>(procedureButton).onPressed,
            isNull,
          );

          Future<void> calculate(String label) async {
            await showControl(find.text(label));
            await tester.tap(find.text(label));
            await tester.pumpAndSettle();
          }

          Future<void> readProcedure(int total) async {
            await showControl(procedureButton);
            expect(
              tester.widget<OutlinedButton>(procedureButton).onPressed,
              isNotNull,
            );
            await tester.tap(procedureButton);
            await tester.pumpAndSettle();
            expect(
              find.textContaining('Procedimiento matemático ·'),
              findsOneWidget,
            );
            final verticalScroll = find
                .descendant(
                  of: find.byType(Dialog),
                  matching: find.byWidgetPredicate(
                    (widget) =>
                        widget is Scrollable &&
                        widget.axisDirection == AxisDirection.down,
                  ),
                )
                .first;
            final finalStep = find.textContaining(
              assignment
                  ? 'Asignaciones y resultado final'
                  : 'Costo y resultado final',
            );
            await tester.scrollUntilVisible(
              finalStep,
              450,
              scrollable: verticalScroll,
            );
            await tester.pumpAndSettle();
            final equation = find.byWidgetPredicate(
              (widget) =>
                  widget is SelectableText &&
                  RegExp('^Z = .*= $total\$').hasMatch(widget.data ?? ''),
            );
            await tester.scrollUntilVisible(
              equation,
              250,
              scrollable: verticalScroll,
            );
            await tester.pumpAndSettle();
            expect(equation, findsOneWidget);
            expect(tester.takeException(), isNull);
            await tester.tap(find.byTooltip('Cerrar procedimiento'));
            await tester.pumpAndSettle();
            expect(find.byType(Dialog), findsNothing);
          }

          await calculate(
            assignment ? 'Calcular Asignación Óptima' : 'Calcular mínimo',
          );
          await readProcedure(assignment ? 4 : 40);
          if (assignment) {
            await tester.ensureVisible(find.byType(DropdownButton<String>));
            await tester.pumpAndSettle();
            await tester.tap(find.byType(DropdownButton<String>));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Maximizar').last);
          } else {
            await showControl(find.text('Maximizar'));
            await tester.tap(find.text('Maximizar'));
          }
          await tester.pumpAndSettle();
          expect(
            tester.widget<OutlinedButton>(procedureButton).onPressed,
            isNull,
          );
          await calculate(
            assignment ? 'Calcular Asignación Óptima' : 'Calcular máximo',
          );
          await readProcedure(assignment ? 101 : 1010);
        },
      );
    }
  }
}
