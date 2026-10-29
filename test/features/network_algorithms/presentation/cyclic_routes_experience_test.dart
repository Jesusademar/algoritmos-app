import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/features/network_algorithms/domain/network_algorithm.dart';
import 'package:app_grafos/features/network_algorithms/presentation/screens/network_algorithm_screen.dart';
import 'package:app_grafos/features/network_algorithms/presentation/widgets/network_graph_painter.dart';
import 'package:app_grafos/shared/graph_editor/widgets/graph_canvas_viewport.dart';
import 'package:app_grafos/shared/graph_editor/models/nodo.dart';
import 'package:app_grafos/shared/graph_editor/models/conexion.dart';
import 'package:app_grafos/shared/persistence/graph_document.dart';
import 'package:app_grafos/shared/persistence/graph_document_codec.dart';
import 'package:app_grafos/shared/persistence/graph_file_service.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(1280, 900)]) {
    testWidgets(
      'ciclos: máximo, cambio de destino, procedimiento y archivos a ${size.width}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final document = GraphDocument(
          name: 'con ciclos',
          nodes: [
            Nodo(id: 'a', nombre: 'A', posicion: const Offset(75, 90)),
            Nodo(id: 'b', nombre: 'B', posicion: const Offset(280, 90)),
            Nodo(id: 'c', nombre: 'C', posicion: const Offset(75, 240)),
            Nodo(id: 'd', nombre: 'D', posicion: const Offset(280, 240)),
          ],
          connections: [
            for (final e in [
              ('a', 'b', 1),
              ('a', 'c', 1),
              ('b', 'c', 10),
              ('c', 'b', 10),
              ('b', 'd', 1),
              ('c', 'd', 1),
            ])
              Conexion(
                nodoA: e.$1,
                nodoB: e.$2,
                peso: e.$3,
                tipo: 'unidireccional',
              ),
          ],
          metadata: const {
            'objective': 'maximize',
            'source': 'a',
            'target': 'd',
          },
        );
        String? saved;
        final service = GraphFileService(
          reader: () async =>
              saved ?? const GraphDocumentCodec().encode(document),
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
              algorithm: NetworkAlgorithm.dijkstra,
              initialDocument: document,
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
        await tester.tap(find.byTooltip('Calcular'));
        await tester.pumpAndSettle();
        expect(find.text('Distancia máxima: 12'), findsOneWidget);
        expect(painter().highlighted, {('a', 'b'), ('b', 'c'), ('c', 'd')});
        expect(find.text('Big O: O(V!) · memoria O(V² + E)'), findsOneWidget);
        expect(find.textContaining('libre de ciclos'), findsNothing);
        Future<void> target(String name) async {
          final dropdown = find.byType(DropdownButtonFormField<String>).last;
          await tester.ensureVisible(dropdown);
          await tester.pumpAndSettle();
          await tester.tap(dropdown);
          await tester.pumpAndSettle();
          await tester.tap(find.text(name).last);
          await tester.pumpAndSettle();
        }

        await target('B');
        expect(find.text('Distancia máxima: 11'), findsOneWidget);
        expect(painter().highlighted, {('a', 'c'), ('c', 'b')});
        await target('C');
        expect(find.text('Distancia máxima: 11'), findsOneWidget);
        expect(painter().highlighted, {('a', 'b'), ('b', 'c')});
        await tester.ensureVisible(find.text('Ver procedimiento matemático'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ver procedimiento matemático'));
        await tester.pumpAndSettle();
        expect(
          find.text('Procedimiento matemático · Rutas máximas'),
          findsOneWidget,
        );
        await tester.tap(find.byTooltip('Cerrar procedimiento'));
        await tester.pumpAndSettle();
        Future<void> menu(String label) async {
          await tester.tap(find.byTooltip('Más opciones'));
          await tester.pumpAndSettle();
          await tester.tap(find.text(label));
          await tester.pumpAndSettle();
        }

        await menu('Guardar');
        await tester.tap(find.text('Guardar JSON'));
        await tester.pumpAndSettle();
        expect(const GraphDocumentCodec().decode(saved!).connections.length, 6);
        await menu('Cargar');
        expect(painter().highlighted, isEmpty);
        await tester.tap(find.byTooltip('Calcular'));
        await tester.pumpAndSettle();
        expect(find.text('Distancia máxima: 11'), findsOneWidget);
        await target('D');
        await tester.ensureVisible(find.text('Minimizar'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Minimizar'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Calcular'));
        await tester.pumpAndSettle();
        expect(find.text('Distancia mínima: 2'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'cancelar una búsqueda larga conserva el grafo y no publica resultados parciales',
    (tester) async {
      final document = GraphDocument(
        name: 'densa',
        nodes: [
          for (var i = 0; i < 13; i++)
            Nodo(
              id: '$i',
              nombre: '$i',
              posicion: Offset(60 + i % 4 * 85.0, 80 + i ~/ 4 * 80.0),
            ),
        ],
        connections: [
          for (var a = 0; a < 13; a++)
            for (var b = 0; b < 13; b++)
              if (a != b) Conexion(nodoA: '$a', nodoB: '$b', peso: 1),
        ],
        metadata: const {
          'objective': 'maximize',
          'source': '0',
          'target': '12',
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: NetworkAlgorithmScreen(
            algorithm: NetworkAlgorithm.dijkstra,
            initialDocument: document,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Calcular'));
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      await tester.tap(find.byTooltip('Cancelar cálculo'));
      await tester.pumpAndSettle();
      final canvas = tester.widget<GraphCanvasViewport>(
        find.byType(GraphCanvasViewport),
      );
      expect(canvas.nodes.length, 13);
      expect((canvas.painter as NetworkGraphPainter).highlighted, isEmpty);
      expect(find.textContaining('Distancia máxima:'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      await tester.ensureVisible(find.text('Minimizar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Minimizar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Calcular'));
      await tester.pumpAndSettle();
      expect(find.text('Distancia mínima: 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
