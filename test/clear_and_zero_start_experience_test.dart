import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/features/catalog/presentation/screens/menu_principal_screen.dart';
import 'package:app_grafos/features/johnson/presentation/screens/johnson_screen.dart';
import 'package:app_grafos/features/sorting/domain/sorting_algorithm.dart';
import 'package:app_grafos/features/sorting/domain/sorting_document.dart';
import 'package:app_grafos/features/sorting/domain/sorting_order.dart';
import 'package:app_grafos/features/sorting/presentation/providers/sorting_race_controller.dart';
import 'package:app_grafos/features/sorting/presentation/providers/sorting_visualization_provider.dart';
import 'package:app_grafos/features/sorting/presentation/screens/sorting_race_screen.dart';
import 'package:app_grafos/features/sorting/presentation/screens/sorting_visualization_screen.dart';
import 'package:app_grafos/features/sorting/presentation/widgets/bowling_pin_widget.dart';
import 'package:app_grafos/features/sorting/presentation/widgets/sorting_visualization_widget.dart';
import 'package:app_grafos/shared/graph_editor/models/conexion.dart';
import 'package:app_grafos/shared/graph_editor/models/nodo.dart';
import 'package:app_grafos/shared/persistence/graph_document.dart';
import 'package:app_grafos/shared/persistence/graph_document_codec.dart';
import 'package:app_grafos/shared/persistence/graph_file_service.dart';

Future<void> menu(WidgetTester tester, String option) async {
  await tester.tap(find.byTooltip('Más opciones'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(option));
  await tester.pumpAndSettle();
}

void main() {
  test('Limpiar vacía los estados y detiene la reproducción sin confundirlo con Reiniciar', () {
    for (final algorithm in SortingAlgorithm.values) {
      final provider = SortingVisualizationProvider(
        array: [8, 1, 3],
        algorithm: algorithm,
        order: SortingOrder.descending,
      );
      provider.finish();
      provider.reset();
      expect(provider.originalArray, [8, 1, 3]);
      provider.play();
      provider.clear();
      expect(provider.hasData, isFalse);
      expect(provider.originalArray, isEmpty);
      expect(provider.currentArray, isEmpty);
      expect(provider.finalArray, isEmpty);
      expect(provider.sortedIndices, isEmpty);
      expect(provider.totalComparisons, 0);
      expect(provider.totalSwaps, 0);
      expect(provider.totalSteps, 0);
      expect(provider.currentStepIndex, 0);
      expect(provider.isComplete, isFalse);
      expect(provider.isPlaying, isFalse);
      expect(provider.order, SortingOrder.descending);
      provider.play();
      provider.nextStep();
      provider.finish();
      expect(provider.isPlaying, isFalse);
      expect(provider.currentStepIndex, 0);
      provider.dispose();
    }
  });
  testWidgets(
    'Limpiar cancela el reloj de la carrera y permite ingresar otra lista',
    (tester) async {
      final race = SortingRaceController();
      race.play();
      await tester.pump(const Duration(milliseconds: 300));
      race.clear();
      await tester.pump(const Duration(seconds: 1));
      expect(race.hasData, isFalse);
      expect(race.isPlaying, isFalse);
      expect(race.tick, 0);
      expect(race.lastTick, 0);
      expect(race.fewestComparisons, isEmpty);
      for (final algorithm in SortingAlgorithm.values) {
        expect(race.result(algorithm).totalComparisons, 0);
        expect(race.step(algorithm).array, isEmpty);
        expect(race.completed(algorithm), isFalse);
        expect(race.progress(algorithm), 0);
      }
      race.play();
      expect(race.isPlaying, isFalse);
      race.setNumbers([3, 1]);
      race.finish();
      expect(race.step(SortingAlgorithm.mergeSort).array, [1, 3]);
      race.dispose();
    },
  );

  for (final size in [const Size(390, 844), const Size(1280, 900)]) {
    void viewport(WidgetTester tester) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    Widget app(Widget home) => MaterialApp(
      theme: AppTheme.dark,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: true,
          textScaler: const TextScaler.linear(1.3),
        ),
        child: child!,
      ),
      home: home,
    );

    testWidgets(
      'los cuatro métodos limpian resultado y permiten cargar nuevos números a ${size.width}',
      (tester) async {
        viewport(tester);
        for (final algorithm in SortingAlgorithm.values) {
          final source = SortingDocument(
            name: 'nueva lista',
            algorithm: algorithm,
            order: SortingOrder.ascending,
            originalArray: [5, 2],
          ).encode();
          await tester.pumpWidget(
            app(
              SortingVisualizationScreen(
                algorithm: algorithm,
                initialArray: const [9, 1, 3],
                fileService: GraphFileService(reader: () async => source),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final provider = tester
              .widget<SortingVisualizationWidget>(
                find.byType(SortingVisualizationWidget),
              )
              .provider;
          provider.finish();
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Limpiar'));
          await tester.pumpAndSettle();
          provider.reset();
          provider.play();
          await tester.pump(const Duration(milliseconds: 100));
          expect(provider.isPlaying, isTrue);
          await tester.tap(find.text('Limpiar'));
          await tester.pumpAndSettle();
          await tester.pump(const Duration(seconds: 1));
          expect(find.byType(BowlingPinWidget), findsNothing);
          expect(find.text('Aún no hay números'), findsOneWidget);
          expect(find.textContaining('Big O'), findsNothing);
          expect(provider.isPlaying, isFalse);
          await tester.ensureVisible(find.text('Nuevo ordenamiento'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Nuevo ordenamiento'));
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<TextField>(
                  find.widgetWithText(TextField, 'Cantidad de números'),
                )
                .controller!
                .text,
            '10',
          );
          await tester.tap(find.text('Cancelar'));
          await tester.pumpAndSettle();
          await menu(tester, 'Cargar');
          final loaded = tester
              .widget<SortingVisualizationWidget>(
                find.byType(SortingVisualizationWidget),
              )
              .provider;
          expect(loaded.originalArray, [5, 2]);
          expect(loaded.isPlaying, isFalse);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        }
      },
    );
    testWidgets(
      'la carrera muestra un estado vacío y se puede reutilizar a ${size.width}',
      (tester) async {
        viewport(tester);
        await tester.pumpWidget(app(const SortingRaceScreen()));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Ver resultado'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ver resultado'));
        await tester.pumpAndSettle();
        expect(find.text('Comparación completada'), findsOneWidget);
        await tester.tap(find.text('Limpiar'));
        await tester.pumpAndSettle();
        expect(find.text('Comparación completada'), findsNothing);
        expect(find.textContaining('Big O:'), findsNothing);
        expect(find.text('Sin datos para comparar'), findsOneWidget);
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          isEmpty,
        );
        await tester.ensureVisible(find.text('Lista ordenada'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Lista ordenada'));
        await tester.pumpAndSettle();
        expect(find.text('Sin datos para comparar'), findsNothing);
        expect(find.text('Abrir detalle'), findsNWidgets(4));
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'Johnson crea, carga y guarda siempre con inicio cero a ${size.width}',
      (tester) async {
        viewport(tester);
        const codec = GraphDocumentCodec();
        final old = GraphDocument(
          name: 'inicio anterior',
          nodes: [
            Nodo(
              id: 'a',
              nombre: 'A',
              posicion: const Offset(100, 100),
              valorInicial: 99,
            ),
            Nodo(
              id: 'b',
              nombre: 'B',
              posicion: const Offset(260, 100),
              valorInicial: 77,
            ),
          ],
          connections: [Conexion(nodoA: 'a', nodoB: 'b', peso: 5)],
          metadata: const {
            'valorInicialNodo': '99',
            'nodoInicialSeleccionadoId': 'a',
          },
        );
        String? saved;
        final service = GraphFileService(
          reader: () async => codec.encode(old),
          writer: (_, bytes) async {
            saved = utf8.decode(bytes);
            return '/destino/johnson.json';
          },
        );
        await tester.pumpWidget(app(JohnsonScreen(fileService: service)));
        await tester.pumpAndSettle();
        final dynamic state = tester.state(find.byType(JohnsonScreen));
        state.agregarNodo(const Offset(100, 100));
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Tiempo inicial: 0'), findsOneWidget);
        expect(find.text('Insertar valor inicial'), findsNothing);
        await tester.enterText(find.byType(TextField), 'Inicio');
        await tester.tap(find.text('Crear'));
        await tester.pumpAndSettle();
        expect((state.nodos as List<Nodo>).single.valorInicial, 0);
        await menu(tester, 'Cargar');
        expect(
          (state.nodos as List<Nodo>).every((node) => node.valorInicial == 0),
          isTrue,
        );
        await tester.tap(find.byTooltip('Calcular'));
        await tester.pumpAndSettle();
        expect((state.tiemposTempranos as Map<String, int>)['a'], 0);
        expect(state.proyectoDuracionTotal, 5);
        expect(find.byType(TextField), findsNothing);
        expect(find.text('Tiempo inicial: 0'), findsOneWidget);
        await menu(tester, 'Guardar');
        await tester.tap(find.text('Guardar JSON'));
        await tester.pumpAndSettle();
        final restored = codec.decode(saved!);
        expect(restored.metadata['valorInicialNodo'], 0);
        expect(restored.nodes.every((node) => node.valorInicial == 0), isTrue);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'el menú hereda letras claras y los botones mantienen contraste a ${size.width}',
      (tester) async {
        viewport(tester);
        await tester.pumpWidget(app(const MenuPrincipalScreen()));
        await tester.pumpAndSettle();
        for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
          final color = rich.text.style?.color;
          if (color == null || rich.text.toPlainText().trim().isEmpty) continue;
          expect(
            color.computeLuminance(),
            greaterThan(0.1),
            reason: rich.text.toPlainText(),
          );
        }
        for (final accent in [
          AppColors.primary,
          AppColors.graph,
          AppColors.johnson,
          AppColors.sorting,
          AppColors.success,
        ]) {
          final contrast =
              (AppColors.text.computeLuminance() + 0.05) /
              (AppColors.buttonFill(accent).computeLuminance() + 0.05);
          expect(contrast, greaterThanOrEqualTo(4.5));
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
