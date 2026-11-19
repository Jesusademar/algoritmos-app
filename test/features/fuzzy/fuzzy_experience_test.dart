import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/features/fuzzy/data/fis_file_service.dart';
import 'package:app_grafos/features/fuzzy/domain/fuzzy_codecs.dart';
import 'package:app_grafos/features/fuzzy/domain/fuzzy_system.dart';
import 'package:app_grafos/features/fuzzy/presentation/screens/fuzzy_screen.dart';
import 'package:app_grafos/features/fuzzy/presentation/widgets/membership_chart.dart';
import 'package:app_grafos/shared/persistence/graph_file_service.dart';

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

Future<void> openScreen(
  WidgetTester tester,
  Widget screen, {
  Size size = const Size(1280, 900),
  double scale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: screen,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final size in [const Size(320, 700), const Size(1280, 900)]) {
    testWidgets(
      'crea trapezoides en entradas y salidas y los exporta en reglas a ${size.width}',
      (tester) async {
        String? fis;
        String? json;
        await openScreen(
          tester,
          FuzzyScreen(
            initialSystem: FuzzySystem.ventilationExample(),
            fisService: FisFileService(
              writer: (_, bytes) async {
                fis = utf8.decode(bytes);
                return 'ventilacion.fis';
              },
            ),
            documentService: GraphFileService(
              writer: (_, bytes) async {
                json = utf8.decode(bytes);
                return 'diseno.json';
              },
            ),
          ),
          size: size,
          scale: 1.3,
        );
        expect(find.text('Añadir trapezoide'), findsNothing);
        for (final input in [true, false]) {
          final add = input
              ? find.text('Editar variable').first
              : find.text('Editar variable').last;
          await tester.ensureVisible(add);
          await tester.pumpAndSettle();
          await tester.tap(add);
          await tester.pumpAndSettle();
          await tapText(tester, 'Añadir conjunto');
          await tester.tap(
            find.byType(DropdownButtonFormField<MembershipType>),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('Trapezoidal (trapmf)').last);
          await tester.pumpAndSettle();
          expect(find.text('Trapezoidal (trapmf)'), findsOneWidget);
          final dialogName = find
              .descendant(
                of: find.byType(AlertDialog).last,
                matching: find.byType(TextField),
              )
              .first;
          await tester.enterText(
            dialogName,
            input ? 'templado_trap' : 'velocidad_trap',
          );
          final parameters = input
              ? ['0', '10', '25', '40']
              : ['0', '20', '60', '100'];
          for (var i = 0; i < 4; i++) {
            await tester.enterText(
              find.byKey(Key('trapezoid-parameter-${['a', 'b', 'c', 'd'][i]}')),
              parameters[i],
            );
          }
          // Reject reversed shoulders and a blank parameter independently.
          await tester.enterText(
            find.byKey(const Key('trapezoid-parameter-b')),
            input ? '30' : '70',
          );
          await tapText(tester, 'Guardar conjunto');
          expect(find.byType(AlertDialog), findsNWidgets(2));
          await tester.enterText(
            find.byKey(const Key('trapezoid-parameter-b')),
            parameters[1],
          );
          await tester.enterText(
            find.byKey(const Key('trapezoid-parameter-c')),
            '',
          );
          await tapText(tester, 'Guardar conjunto');
          expect(find.byType(AlertDialog), findsNWidgets(2));
          await tester.enterText(
            find.byKey(const Key('trapezoid-parameter-c')),
            parameters[2],
          );
          await tapText(tester, 'Guardar conjunto');
          expect(find.byType(AlertDialog), findsOneWidget);
          await tapText(tester, 'Guardar variable');
          expect(find.byType(AlertDialog), findsNothing);
        }
        await tester.ensureVisible(find.text('Editar regla').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Editar regla').first);
        await tester.pumpAndSettle();
        final selectors = find.byType(DropdownButtonFormField<int>);
        await tester.tap(selectors.first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('templado_trap').last);
        await tester.pumpAndSettle();
        await tester.ensureVisible(selectors.last);
        await tester.pumpAndSettle();
        await tester.tap(selectors.last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('velocidad_trap').last);
        await tester.pumpAndSettle();
        await tapText(tester, 'Guardar regla');
        expect(
          find.text(
            'Si temperatura es templado_trap, entonces ventilacion es velocidad_trap.',
          ),
          findsOneWidget,
        );
        await tapText(tester, 'Guardar diseño JSON');
        final restored = const FuzzyDocumentCodec().decode(json!);
        expect(
          restored.inputs.first.functions.last.type,
          MembershipType.trapezoidal,
        );
        expect(restored.inputs.first.functions.last.parameters, [
          0,
          10,
          25,
          40,
        ]);
        expect(restored.outputs.first.functions.last.parameters, [
          0,
          20,
          60,
          100,
        ]);
        expect(restored.rules.first.inputs, [4, 0]);
        expect(restored.rules.first.outputs, [4]);
        await tapText(tester, 'Exportar .fis');
        await tapText(tester, 'Guardar .fis');
        expect(
          fis,
          contains("MF4='templado_trap':'trapmf',[0.0 10.0 25.0 40.0]"),
        );
        expect(
          fis,
          contains("MF4='velocidad_trap':'trapmf',[0.0 20.0 60.0 100.0]"),
        );
        expect(fis, contains('4 0, 4 (1.0) : 1'));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'editar la forma desde la variable conserva las reglas y cancelar descarta los cambios',
    (tester) async {
      String? saved;
      final original = FuzzySystem.ventilationExample();
      await openScreen(
        tester,
        FuzzyScreen(
          initialSystem: original,
          documentService: GraphFileService(
            writer: (_, bytes) async {
              saved = utf8.decode(bytes);
              return 'diseno.json';
            },
          ),
        ),
      );
      for (final apply in [false, true]) {
        await tester.ensureVisible(find.text('Editar variable').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Editar variable').first);
        await tester.pumpAndSettle();
        final edit = find.byTooltip('Editar conjunto bajo').last;
        await tester.ensureVisible(edit);
        await tester.pumpAndSettle();
        await tester.tap(edit);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(DropdownButtonFormField<MembershipType>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Trapezoidal (trapmf)').last);
        await tester.pumpAndSettle();
        await tapText(tester, 'Guardar conjunto');
        await tapText(tester, apply ? 'Guardar variable' : 'Cancelar');
        final variable = tester
            .widgetList<MembershipChart>(find.byType(MembershipChart))
            .first
            .variable;
        expect(
          variable.functions.first.type,
          apply ? MembershipType.trapezoidal : MembershipType.triangular,
        );
      }
      await tapText(tester, 'Guardar diseño JSON');
      final restored = const FuzzyDocumentCodec().decode(saved!);
      expect(
        restored.inputs.first.functions.first.type,
        MembershipType.trapezoidal,
      );
      expect(
        restored.rules.map((r) => r.inputs),
        original.rules.map((r) => r.inputs),
      );
      expect(
        restored.rules.map((r) => r.outputs),
        original.rules.map((r) => r.outputs),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'el ejemplo trapezoidal se carga con curvas y exportación listas',
    (tester) async {
      String? fis;
      await openScreen(
        tester,
        FuzzyScreen(
          fisService: FisFileService(
            writer: (_, bytes) async {
              fis = utf8.decode(bytes);
              return 'ejemplo.fis';
            },
          ),
        ),
      );
      await tapText(tester, 'Ejemplo trapezoidal');
      expect(find.byType(MembershipChart), findsNWidgets(3));
      expect(find.textContaining('Trapezoidal ['), findsNWidgets(9));
      await tapText(tester, 'Exportar .fis');
      await tapText(tester, 'Guardar .fis');
      expect(fis, const FisCodec().encode(FuzzySystem.trapezoidExample()));
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(320, 700),
    const Size(390, 844),
    const Size(1280, 900),
  ]) {
    testWidgets('curvas, formularios y exportación legibles a ${size.width}', (
      tester,
    ) async {
      String? saved;
      await openScreen(
        tester,
        FuzzyScreen(
          initialSystem: FuzzySystem.ventilationExample(),
          fisService: FisFileService(
            writer: (name, bytes) async {
              saved = utf8.decode(bytes);
              return '$name.fis';
            },
          ),
        ),
        size: size,
        scale: 1.3,
      );
      expect(find.byType(MembershipChart), findsNWidgets(3));
      await tapText(tester, 'Exportar .fis');
      expect(
        find.textContaining('fis = readfis("ventilacion.fis")'),
        findsOneWidget,
      );
      await tapText(tester, 'Guardar .fis');
      expect(saved, const FisCodec().encode(FuzzySystem.ventilationExample()));
      expect(find.byType(AlertDialog), findsNothing);
      await tester.ensureVisible(find.byTooltip('Guía de lógica difusa'));
      await tester.tap(find.byTooltip('Guía de lógica difusa'));
      await tester.pumpAndSettle();
      await tapText(tester, 'Entendido');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'construye un sistema y recupera su JSON sin perderlo por archivos inválidos',
    (tester) async {
      String? json;
      String? nextLoad;
      final service = GraphFileService(
        writer: (name, bytes) async {
          json = utf8.decode(bytes);
          return '$name.json';
        },
        reader: () async => nextLoad,
      );
      await openScreen(
        tester,
        FuzzyScreen(documentService: service),
        size: const Size(390, 844),
      );
      await tester.enterText(
        find.byKey(const Key('fuzzy-system-name')),
        'mi_control',
      );
      for (final input in [true, false]) {
        await tapText(tester, input ? 'Añadir entrada' : 'Añadir salida');
        final fields = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        );
        await tester.enterText(
          fields.at(0),
          input ? 'temperatura' : 'velocidad',
        );
        await tester.enterText(fields.at(1), '0');
        await tester.enterText(fields.at(2), '100');
        await tapText(tester, 'Guardar variable');
      }
      await tapText(tester, 'Añadir regla');
      final weight = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(weight, '2');
      await tapText(tester, 'Guardar regla');
      expect(
        find.text('El peso debe ser un número entre 0 y 1.'),
        findsOneWidget,
      );
      await tester.enterText(weight, '0.8');
      await tapText(tester, 'Guardar regla');
      expect(
        find.text('Si temperatura es bajo, entonces velocidad es bajo.'),
        findsOneWidget,
      );
      await tapText(tester, 'Guardar diseño JSON');
      expect(const FuzzyDocumentCodec().decode(json!).rules.single.weight, 0.8);
      await tester.ensureVisible(find.byKey(const Key('fuzzy-system-name')));
      await tester.enterText(
        find.byKey(const Key('fuzzy-system-name')),
        'otro',
      );
      nextLoad = json;
      await tapText(tester, 'Cargar diseño JSON');
      expect(find.text('Reemplazar el diseño'), findsOneWidget);
      await tapText(tester, 'Cancelar');
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('fuzzy-system-name')))
            .controller!
            .text,
        'otro',
      );
      await tapText(tester, 'Cargar diseño JSON');
      await tapText(tester, 'Continuar');
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('fuzzy-system-name')))
            .controller!
            .text,
        'mi_control',
      );
      nextLoad = '{}';
      await tapText(tester, 'Cargar diseño JSON');
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('fuzzy-system-name')))
            .controller!
            .text,
        'mi_control',
      );
      expect(
        find.text('Si temperatura es bajo, entonces velocidad es bajo.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'edita curvas con validación y mantiene reglas al borrar un conjunto sin uso',
    (tester) async {
      await openScreen(
        tester,
        FuzzyScreen(initialSystem: FuzzySystem.ventilationExample()),
        size: const Size(390, 844),
      );
      final edit = find.byTooltip('Editar conjunto bajo').first;
      await tester.ensureVisible(edit);
      await tester.tap(edit);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<MembershipType>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gaussiana (gaussmf)').last);
      await tester.pumpAndSettle();
      final fields = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(fields.last, '0 10');
      await tapText(tester, 'Guardar conjunto');
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.enterText(fields.last, '4 10');
      await tapText(tester, 'Guardar conjunto');
      expect(find.textContaining('Gaussiana [4.0 10.0]'), findsOneWidget);
      await tapText(tester, 'Añadir conjunto');
      await tapText(tester, 'Guardar conjunto');
      final delete = find.byTooltip('Eliminar conjunto conjunto_1');
      await tester.ensureVisible(delete);
      await tester.tap(delete);
      await tester.pumpAndSettle();
      expect(
        find.text('Se eliminará este conjunto y 0 regla(s) que lo utilizan.'),
        findsOneWidget,
      );
      await tapText(tester, 'Continuar');
      expect(find.text('Regla 3 · Peso 1.0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('cancelar o fallar la exportación permite volver a intentar', (
    tester,
  ) async {
    var calls = 0;
    final service = FisFileService(
      writer: (_, _) async {
        calls++;
        if (calls == 1) throw Exception('sin acceso');
        return calls == 2 ? null : 'ventilacion.fis';
      },
    );
    await openScreen(
      tester,
      FuzzyScreen(
        initialSystem: FuzzySystem.ventilationExample(),
        fisService: service,
      ),
    );
    await tapText(tester, 'Exportar .fis');
    await tapText(tester, 'Guardar .fis');
    expect(
      find.text('No se pudo guardar el .fis. Intenta elegir otra ubicación.'),
      findsOneWidget,
    );
    await tapText(tester, 'Guardar .fis');
    expect(find.byType(AlertDialog), findsOneWidget);
    await tapText(tester, 'Guardar .fis');
    expect(find.byType(AlertDialog), findsNothing);
    expect(calls, 3);
    expect(tester.takeException(), isNull);
  });
}
