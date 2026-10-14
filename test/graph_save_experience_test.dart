import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/shared/persistence/graph_document.dart';
import 'package:app_grafos/shared/persistence/graph_file_service.dart';
import 'package:app_grafos/shared/widgets/graph_save_dialog.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(1280, 900)]) {
    testWidgets(
      'guardar actualiza nombre, evita duplicados y cierra solo tras éxito a ${size.width}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final pending = Completer<String?>();
        var writes = 0;
        final service = GraphFileService(
          writer: (name, bytes) {
            writes++;
            expect(name, 'des_prue');
            expect(jsonDecode(utf8.decode(bytes))['nombreArchivo'], 'des_prue');
            return pending.future;
          },
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showGraphSaveDialog(
                    context,
                    GraphDocument(
                      name: 'asignacion_proyecto',
                      nodes: [],
                      connections: [],
                    ),
                    service: service,
                  ),
                  child: const Text('Abrir guardado'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Abrir guardado'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'des_prue.json');
        await tester.pumpAndSettle();
        expect(
          tester.widget<SelectableText>(find.byType(SelectableText)).data,
          contains('"nombreArchivo": "des_prue"'),
        );
        await tester.tap(find.text('Guardar JSON'));
        await tester.pump();
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );
        expect(
          tester
              .widget<TextButton>(find.widgetWithText(TextButton, 'Cancelar'))
              .onPressed,
          isNull,
        );
        expect(writes, 1);
        pending.complete('/destino/des_prue.json');
        await tester.pumpAndSettle();
        expect(find.byType(GraphSaveDialog), findsNothing);
        expect(find.text('Archivo guardado: des_prue.json'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'cancelación y fallo mantienen el formulario y permiten reintentar',
    (tester) async {
      var writes = 0;
      final service = GraphFileService(
        writer: (_, _) async {
          writes++;
          if (writes == 1) return null;
          if (writes == 2) throw Exception('Sin acceso');
          return '/destino/prueba.json';
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showGraphSaveDialog(
                  context,
                  GraphDocument(name: 'prueba', nodes: [], connections: []),
                  service: service,
                ),
                child: const Text('Abrir guardado'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir guardado'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar JSON'));
      await tester.pumpAndSettle();
      expect(find.byType(GraphSaveDialog), findsOneWidget);
      expect(find.textContaining('Archivo guardado:'), findsNothing);
      await tester.tap(find.text('Guardar JSON'));
      await tester.pumpAndSettle();
      expect(find.textContaining('No se pudo guardar'), findsOneWidget);
      await tester.tap(find.text('Guardar JSON'));
      await tester.pumpAndSettle();
      expect(find.byType(GraphSaveDialog), findsNothing);
      expect(writes, 3);
    },
  );
}
