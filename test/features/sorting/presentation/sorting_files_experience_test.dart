import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/features/sorting/domain/sorting_algorithm.dart';
import 'package:app_grafos/features/sorting/domain/sorting_document.dart';
import 'package:app_grafos/features/sorting/domain/sorting_order.dart';
import 'package:app_grafos/features/sorting/presentation/screens/sorting_methods_screen.dart';
import 'package:app_grafos/features/sorting/presentation/screens/sorting_visualization_screen.dart';
import 'package:app_grafos/features/sorting/presentation/widgets/sorting_visualization_widget.dart';
import 'package:app_grafos/shared/persistence/graph_file_service.dart';
import 'package:app_grafos/shared/widgets/graph_save_dialog.dart';

Future<void> menu(WidgetTester tester, String action) async {
  await tester.tap(find.byTooltip('Más opciones'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.text(action));
  await tester.pumpAndSettle();
}

void main() {
  for (final size in [const Size(390, 844), const Size(1280, 900)]) {
    testWidgets(
      'ordenamiento guarda entrada y carga sesión en pausa a ${size.width}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        String? saved;
        String? source;
        final service = GraphFileService(
          writer: (_, bytes) async {
            saved = utf8.decode(bytes);
            return '/destino/ordenamiento.json';
          },
          reader: () async => source,
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: SortingVisualizationScreen(
              algorithm: SortingAlgorithm.insertionSort,
              initialArray: const [9, 3, 6, 3],
              initialOrder: SortingOrder.descending,
              fileService: service,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final provider = tester
            .widget<SortingVisualizationWidget>(
              find.byType(SortingVisualizationWidget),
            )
            .provider;
        provider.setSpeed(2);
        provider.play();
        await tester.pump(const Duration(milliseconds: 500));
        await menu(tester, 'Guardar');
        final pausedStep = provider.currentStepIndex;
        await tester.pump(const Duration(seconds: 1));
        expect(provider.currentStepIndex, pausedStep);
        expect(provider.isPlaying, isFalse);
        await tester.enterText(find.byType(TextField), 'sesion_prueba');
        await tester.tap(find.text('Guardar JSON'));
        await tester.pumpAndSettle();
        final exported = SortingDocument.decode(saved!);
        expect(exported.name, 'sesion_prueba');
        expect(exported.originalArray, [9, 3, 6, 3]);
        expect(exported.order, SortingOrder.descending);
        expect(exported.speed, 2);
        expect(exported.stepIndex, pausedStep);
        source = SortingDocument(
          name: 'sesion_merge',
          algorithm: SortingAlgorithm.mergeSort,
          order: SortingOrder.ascending,
          originalArray: [8, 2, 4],
          speed: 0.5,
          stepIndex: 2,
        ).encode();
        await menu(tester, 'Cargar');
        final loaded = tester
            .widget<SortingVisualizationWidget>(
              find.byType(SortingVisualizationWidget),
            )
            .provider;
        expect(loaded.algorithm, SortingAlgorithm.mergeSort);
        expect(loaded.originalArray, [8, 2, 4]);
        expect(loaded.speed, 0.5);
        expect(loaded.currentStepIndex, 2);
        expect(loaded.isPlaying, isFalse);
        expect(find.text('Merge Sort'), findsOneWidget);
        source = null;
        await menu(tester, 'Cargar');
        expect(
          tester
              .widget<SortingVisualizationWidget>(
                find.byType(SortingVisualizationWidget),
              )
              .provider,
          same(loaded),
        );
        source = '{"formato":"otro"}';
        await menu(tester, 'Cargar');
        expect(
          find.textContaining('no es un documento de ordenamiento'),
          findsOneWidget,
        );
        expect(
          tester
              .widget<SortingVisualizationWidget>(
                find.byType(SortingVisualizationWidget),
              )
              .provider,
          same(loaded),
        );
        await menu(tester, 'Guardar');
        await tester.tap(find.text('Guardar JSON'));
        await tester.pumpAndSettle();
        expect(SortingDocument.decode(saved!).name, 'sesion_merge');
        expect(
          SortingDocument.decode(saved!).algorithm,
          SortingAlgorithm.mergeSort,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'el catálogo exporta el ejemplo elegido y abre el método del archivo cargado',
    (tester) async {
      String? saved;
      String? source;
      final service = GraphFileService(
        writer: (_, bytes) async {
          saved = utf8.decode(bytes);
          return '/destino/ejemplo.json';
        },
        reader: () async => source,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: SortingMethodsScreen(fileService: service),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Descendente'));
      await tester.pumpAndSettle();
      await menu(tester, 'Guardar');
      await tester.tap(find.byType(DropdownButtonFormField<SortingAlgorithm>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Shell Sort').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.byType(GraphSaveDialog), findsOneWidget);
      await tester.tap(find.text('Guardar JSON'));
      await tester.pumpAndSettle();
      final exported = SortingDocument.decode(saved!);
      expect(exported.algorithm, SortingAlgorithm.shellSort);
      expect(exported.order, SortingOrder.descending);
      source = exported.encode();
      await menu(tester, 'Cargar');
      expect(find.byType(SortingVisualizationScreen), findsOneWidget);
      final provider = tester
          .widget<SortingVisualizationWidget>(
            find.byType(SortingVisualizationWidget),
          )
          .provider;
      expect(provider.algorithm, SortingAlgorithm.shellSort);
      expect(provider.originalArray, exported.originalArray);
      expect(provider.isPlaying, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
