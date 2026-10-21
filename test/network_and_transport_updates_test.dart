import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/app/navigation/algorithm_examples.dart';
import 'package:app_grafos/features/esquina_nor_oeste/presentation/screens/esquina_nor_oeste_screen.dart';
import 'package:app_grafos/features/johnson/presentation/screens/johnson_screen.dart';
import 'package:app_grafos/shared/graph_editor/models/conexion.dart';

void main() {
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
      'Johnson recalcula ambos modos al editar y eliminar pesos a ${size.width}',
      (tester) async {
        viewport(tester);
        await tester.pumpWidget(
          app(JohnsonScreen(initialDocument: graphExample('johnson'))),
        );
        await tester.pumpAndSettle();
        final dynamic state = tester.state(find.byType(JohnsonScreen));
        await tester.tap(find.byTooltip('Calcular'));
        await tester.pumpAndSettle();
        expect(state.proyectoDuracionTotal, 10);
        Future<void> mode(String label) async {
          await tester.ensureVisible(find.text(label));
          await tester.pumpAndSettle();
          await tester.tap(find.text(label));
          await tester.pumpAndSettle();
        }

        await mode('Minimizar');
        expect(state.proyectoDuracionTotal, 7);
        expect(state.aristasCriticas, {'a-b', 'b-d'});
        Conexion edge() => (state.conexiones as List<Conexion>).firstWhere(
          (c) => c.nodoA == 'a' && c.nodoB == 'b',
        );
        state.editarConexion(edge());
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '12');
        await tester.tap(find.text('Guardar'));
        await tester.pumpAndSettle();
        expect(edge().peso, 12);
        expect(state.proyectoDuracionTotal, 10);
        expect(state.aristasCriticas, {'a-c', 'c-d'});
        await mode('Maximizar');
        expect(state.proyectoDuracionTotal, 15);
        expect(state.aristasCriticas, {'a-b', 'b-d'});
        state.editarConexion(edge());
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'abc');
        await tester.tap(find.text('Guardar'));
        await tester.pumpAndSettle();
        expect(find.text('Ingresa un peso entero válido.'), findsOneWidget);
        expect(edge().peso, 12);
        expect(state.proyectoDuracionTotal, 15);
        await tester.tap(find.text('Eliminar Línea'));
        await tester.pumpAndSettle();
        expect(state.proyectoDuracionTotal, 10);
        expect((state.tiemposTempranos as Map).containsKey('b'), isFalse);
        expect(state.aristasCriticas, {'a-c', 'c-d'});
        // Replacing an existing connection via the creation dialog also refreshes.
        state.crearConexion(
          state.nodos.firstWhere((n) => n.id == 'c'),
          state.nodos.firstWhere((n) => n.id == 'd'),
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '20');
        await tester.tap(find.text('Conectar'));
        await tester.pumpAndSettle();
        expect(state.proyectoDuracionTotal, 22);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'Noroeste muestra y actualiza fila o columna ficticia a ${size.width}',
      (tester) async {
        viewport(tester);
        await tester.pumpWidget(
          app(
            EsquinaNorOesteScreen(initialDocument: graphExample('transport')),
          ),
        );
        await tester.pumpAndSettle();
        final dynamic state = tester.state(find.byType(EsquinaNorOesteScreen));
        expect(find.byType(DataTable), findsOneWidget);
        expect(find.text('Origen ficticio'), findsNothing);
        expect(find.text('Destino ficticio'), findsNothing);
        Future<void> quantity(String key, String text) async {
          final field = find.descendant(
            of: find.byKey(ValueKey(key)),
            matching: find.byType(TextField),
          );
          await tester.ensureVisible(field);
          await tester.pumpAndSettle();
          await tester.enterText(field, text);
          await tester.pumpAndSettle();
        }

        await quantity('demand-c', '15');
        var table = tester.widget<DataTable>(find.byType(DataTable));
        expect(find.text('Origen ficticio'), findsOneWidget);
        expect(table.rows.length, 4); // Dos reales, ficticio y demanda.
        expect((table.rows[2].cells[1].child as Text).data, '0');
        expect((table.rows[2].cells[2].child as Text).data, '0');
        expect((table.rows[2].cells.last.child as Text).data, '5');
        expect(find.byType(TextFormField), findsNWidgets(4));
        await quantity('supply-b', '25');
        table = tester.widget<DataTable>(find.byType(DataTable));
        expect(find.text('Origen ficticio'), findsNothing);
        expect(find.text('Destino ficticio'), findsOneWidget);
        expect(find.text('Dem: 10'), findsOneWidget);
        expect(table.columns.length, 5);
        expect((table.rows[0].cells[3].child as Text).data, '0');
        expect((table.rows[1].cells[3].child as Text).data, '0');
        expect(state.nodos.length, 4);
        await quantity('supply-b', '15');
        expect(find.text('Destino ficticio'), findsNothing);
        expect(find.text('Origen ficticio'), findsNothing);
        expect(
          tester.widget<DataTable>(find.byType(DataTable)).columns.length,
          4,
        );
        await quantity('demand-c', '-1');
        await tester.ensureVisible(find.text('Calcular mínimo'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Calcular mínimo'));
        await tester.pumpAndSettle();
        expect(find.text('Entero no negativo'), findsOneWidget);
        expect(state.ultimoCostoTotal, isNull);
        await quantity('demand-c', '15');
        await tester.ensureVisible(find.text('Calcular mínimo'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Calcular mínimo'));
        await tester.pumpAndSettle();
        expect(state.ultimoCostoTotal, isNotNull);
        expect(find.text('Entero no negativo'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
