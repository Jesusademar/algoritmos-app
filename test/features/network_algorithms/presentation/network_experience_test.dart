import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/app/navigation/algorithm_examples.dart';
import 'package:app_grafos/features/network_algorithms/domain/network_algorithm.dart';
import 'package:app_grafos/features/network_algorithms/presentation/screens/network_algorithm_screen.dart';
import 'package:app_grafos/features/network_algorithms/presentation/widgets/network_graph_painter.dart';
import 'package:app_grafos/shared/graph_editor/widgets/graph_canvas_viewport.dart';
import 'package:app_grafos/shared/persistence/graph_document_codec.dart';
import 'package:app_grafos/shared/persistence/graph_file_service.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(1280, 900)]) {
    for (final algorithm in NetworkAlgorithm.values) {
      testWidgets(
        '${algorithm.title}: calcular, editar, guardar y cargar a ${size.width}',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);
          final example = graphExample(algorithm.name);
          String? saved;
          final service = GraphFileService(
            reader: () async => const GraphDocumentCodec().encode(example),
            writer: (name, bytes) async {
              saved = utf8.decode(bytes);
              return '$name.json';
            },
          );
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
              home: NetworkAlgorithmScreen(
                algorithm: algorithm,
                initialDocument: example,
                fileService: service,
              ),
            ),
          );
          await tester.pumpAndSettle();
          NetworkGraphPainter painter() =>
              tester
                      .widget<GraphCanvasViewport>(
                        find.byType(GraphCanvasViewport),
                      )
                      .painter
                  as NetworkGraphPainter;
          final viewport = tester.state<GraphCanvasViewportState>(
            find.byType(GraphCanvasViewport),
          );
          await tester.tap(find.byTooltip('Calcular'));
          await tester.pumpAndSettle();
          expect(
            find.text(
              algorithm == NetworkAlgorithm.kruskal
                  ? 'Costo total: 4'
                  : 'Distancia mínima: 4',
            ),
            findsOneWidget,
          );
          expect(painter().highlighted, {('a', 'c'), ('c', 'b'), ('b', 'd')});
          expect(find.textContaining('Big O:'), findsOneWidget);
          Future<void> objective(String label) async {
            await tester.ensureVisible(find.text(label));
            await tester.pumpAndSettle();
            expect(find.text('Cargar ejemplo'), findsNothing);
            await tester.tap(find.text(label));
            await tester.pumpAndSettle();
            expect(painter().highlighted, isEmpty);
          }

          await objective('Maximizar');
          await tester.tap(find.byTooltip('Calcular'));
          await tester.pumpAndSettle();
          expect(
            find.text(
              algorithm == NetworkAlgorithm.kruskal
                  ? 'Costo total: 11'
                  : 'Distancia máxima: 6',
            ),
            findsOneWidget,
          );
          if (algorithm == NetworkAlgorithm.dijkstra) {
            expect(
              find.text('Big O: O(V + E) · memoria O(V + E)'),
              findsOneWidget,
            );
            expect(painter().highlighted, {('a', 'c'), ('c', 'd')});
          }
          await objective('Minimizar');
          await tester.tap(find.byTooltip('Calcular'));
          await tester.pumpAndSettle();

          final positions = [for (final n in painter().nodes) n.posicion];
          final top = tester.getTopLeft(find.byType(GraphCanvasViewport));
          await tester.dragFrom(
            top + const Offset(180, 180),
            const Offset(-20, 30),
          );
          await tester.pumpAndSettle();
          expect(painter().nodes.map((n) => n.posicion).toList(), positions);
          expect(painter().highlighted.length, 3);
          final edge = painter().edges.firstWhere(
            (e) => e.nodoA == 'a' && e.nodoB == 'c',
          );
          final label = NetworkGraphPainter.edgeLabel(
            edge,
            painter().nodes,
            painter().edges,
            painter().directed,
          );
          await tester.tapAt(
            top + MatrixUtils.transformPoint(viewport.transform.value, label),
          );
          await tester.pump(const Duration(milliseconds: 350));
          await tester.pumpAndSettle();
          expect(find.text('Editar peso'), findsOneWidget);
          if (algorithm == NetworkAlgorithm.dijkstra) {
            await tester.enterText(find.byType(TextField), '-1');
            await tester.tap(find.text('Guardar'));
            await tester.pumpAndSettle();
            expect(
              find.text('Dijkstra no admite pesos negativos.'),
              findsOneWidget,
            );
          }
          await tester.enterText(find.byType(TextField), '10');
          await tester.tap(find.text('Guardar'));
          await tester.pumpAndSettle();
          expect(painter().highlighted, isEmpty);
          await tester.tap(find.byTooltip('Calcular'));
          await tester.pumpAndSettle();
          expect(
            find.text(
              algorithm == NetworkAlgorithm.kruskal
                  ? 'Costo total: 7'
                  : 'Distancia mínima: 5',
            ),
            findsOneWidget,
          );
          Future<void> menu(String label) async {
            await tester.tap(find.byTooltip('Más opciones'));
            await tester.pumpAndSettle();
            expect(find.text('Cargar ejemplo'), findsNothing);
            await tester.tap(find.text(label));
            await tester.pumpAndSettle();
          }

          await objective('Maximizar');
          await menu('Guardar');
          await tester.tap(find.text('Guardar JSON'));
          await tester.pumpAndSettle();
          final restored = const GraphDocumentCodec().decode(saved!);
          expect(restored.metadata['algorithm'], algorithm.name);
          expect(restored.metadata['objective'], 'maximize');
          expect(
            restored.connections
                .firstWhere((e) => e.nodoA == 'a' && e.nodoB == 'c')
                .peso,
            10,
          );
          await menu('Cargar');
          final selected = tester.widget<SegmentedButton<dynamic>>(
            find.byWidgetPredicate((w) => w is SegmentedButton),
          );
          expect(selected.selected.single.toString(), contains('minimize'));
          expect(painter().highlighted, isEmpty);
          expect(
            painter().edges
                .firstWhere((e) => e.nodoA == 'a' && e.nodoB == 'c')
                .peso,
            1,
          );
          await menu('Manual de uso');
          expect(
            find.text('Manual de uso · ${algorithm.title}'),
            findsOneWidget,
          );
          await tester.tap(find.text('¡Entendido!'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Ver procedimiento matemático'));
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('Calcular'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Ver procedimiento matemático'));
          await tester.pumpAndSettle();
          expect(
            find.text('Procedimiento matemático · ${algorithm.title}'),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
