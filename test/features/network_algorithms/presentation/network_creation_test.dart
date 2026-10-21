import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/features/network_algorithms/domain/network_algorithm.dart';
import 'package:app_grafos/features/network_algorithms/presentation/screens/network_algorithm_screen.dart';
import 'package:app_grafos/features/network_algorithms/presentation/widgets/network_graph_painter.dart';
import 'package:app_grafos/shared/graph_editor/widgets/graph_canvas_viewport.dart';

void main() {
  testWidgets(
    'crear por teclado, conectar con cero, elegir destino y borrar un nodo',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const NetworkAlgorithmScreen(
            algorithm: NetworkAlgorithm.dijkstra,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final top = tester.getTopLeft(find.byType(GraphCanvasViewport));
      Future<void> tapScene(Offset point) async {
        final state = tester.state<GraphCanvasViewportState>(
          find.byType(GraphCanvasViewport),
        );
        await tester.tapAt(
          top + MatrixUtils.transformPoint(state.transform.value, point),
        );
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();
      }

      NetworkGraphPainter painter() =>
          tester
                  .widget<GraphCanvasViewport>(find.byType(GraphCanvasViewport))
                  .painter
              as NetworkGraphPainter;
      for (final entry in [
        ('A', const Offset(80, 90)),
        ('B', const Offset(280, 180)),
      ]) {
        await tapScene(entry.$2);
        expect(find.text('Crear nodo'), findsOneWidget);
        await tester.enterText(find.byType(TextField), entry.$1);
        await tester.tap(find.text('Crear'));
        await tester.pumpAndSettle();
      }
      expect(painter().nodes.length, 2);
      await tapScene(const Offset(80, 90));
      await tapScene(const Offset(280, 180));
      expect(find.text('Conectar nodos'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '0');
      await tester.tap(find.text('Conectar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Calcular'));
      await tester.pumpAndSettle();
      expect(find.text('Distancia mínima: 0'), findsOneWidget);
      expect(painter().highlighted.length, 1);
      final target = find.byType(DropdownButtonFormField<String>).last;
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
      await tester.tap(find.text('A').last);
      await tester.pumpAndSettle();
      expect(painter().highlighted, isEmpty);
      expect(find.text('Distancia mínima: 0'), findsOneWidget);
      await tester.longPressAt(top + const Offset(280, 180));
      await tester.pumpAndSettle();
      expect(find.text('Editar nodo'), findsOneWidget);
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
      expect(painter().nodes.length, 1);
      expect(painter().edges, isEmpty);
      expect(painter().distances, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
