import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/features/assignment/presentation/screens/asignacion_screen.dart';
import 'package:app_grafos/features/johnson/presentation/screens/johnson_screen.dart';
import 'package:app_grafos/shared/graph_editor/models/conexion.dart';
import 'package:app_grafos/shared/graph_editor/models/nodo.dart';
import 'package:app_grafos/shared/widgets/algorithm_scaffold.dart';

void main() {
  for (final moreOrigins in [false, true]) {
    testWidgets(
      'asignación muestra ${moreOrigins ? 'columna' : 'fila'} ficticia y resultado',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(1280, 900);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.dark, home: const AsignacionScreen()),
        );
        final dynamic state = tester.state(find.byType(AsignacionScreen));
        final origins = List.generate(
          moreOrigins ? 3 : 2,
          (i) => Nodo(
            id: 'o$i',
            nombre: 'O$i',
            posicion: Offset(50, 100 + i * 100),
          ),
        );
        final destinations = List.generate(
          moreOrigins ? 2 : 3,
          (i) => Nodo(
            id: 'd$i',
            nombre: 'D$i',
            posicion: Offset(250, 100 + i * 100),
          ),
        );
        state.nodos = <Nodo>[...origins, ...destinations];
        state.conexiones = <Conexion>[
          for (var i = 0; i < origins.length; i++)
            for (var j = 0; j < destinations.length; j++)
              Conexion(
                nodoA: origins[i].id,
                nodoB: destinations[j].id,
                peso: i * 2 + j + 2,
              ),
        ];
        final countBefore = (state.conexiones as List<Conexion>).length;
        state.nodoOrigen = origins.first;
        state.conectarNodos(origins.first);
        await tester.pumpAndSettle();
        expect(
          find.text('No se permiten bucles en un mismo nodo.'),
          findsOneWidget,
        );
        expect(find.byType(Dialog), findsNothing);
        expect((state.conexiones as List<Conexion>).length, countBefore);
        await tester.tap(find.byTooltip('Mostrar matriz'));
        await tester.pumpAndSettle();
        final table = tester.widget<DataTable>(find.byType(DataTable));
        expect(table.rows.length, 3);
        expect(
          table.columns.length,
          4,
        ); // Three cost columns plus the row label.
        expect(
          find.text(moreOrigins ? 'Destino ficticio 1' : 'Origen ficticio 1'),
          findsOneWidget,
        );
        state.calcularSolucionOptima();
        await tester.pumpAndSettle();
        final details = state.detalleAsignaciones as List<String>;
        expect(details.length, 3);
        expect(
          details.where((detail) => detail.contains('ficticio')).length,
          1,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Johnson conecta A→B, bloquea B→A y bucles, y permite actualizar A→B',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.dark, home: const JohnsonScreen()),
      );
      final dynamic state = tester.state(find.byType(JohnsonScreen));
      final a = Nodo(id: 'a', nombre: 'A', posicion: const Offset(100, 100));
      final b = Nodo(id: 'b', nombre: 'B', posicion: const Offset(300, 100));
      state.nodos = <Nodo>[a, b];
      // Rebuild the editor through its existing stateful API.
      state.crearConexion(a, b);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '5');
      await tester.tap(find.text('Conectar'));
      await tester.pumpAndSettle();
      expect((state.conexiones as List<Conexion>).single.peso, 5);
      final canvas = tester.getTopLeft(find.byType(AlgorithmWorkspace));
      await tester.tapAt(canvas + b.posicion);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      await tester.tapAt(canvas + a.posicion);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(find.textContaining('conexión inversa'), findsOneWidget);
      expect(find.text('Conectar'), findsNothing);
      expect((state.conexiones as List<Conexion>).length, 1);
      await tester.tapAt(canvas + a.posicion);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      await tester.tapAt(canvas + a.posicion);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(find.textContaining('No se permiten bucles'), findsOneWidget);
      expect((state.conexiones as List<Conexion>).length, 1);
      state.crearConexion(a, b);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '7');
      await tester.tap(find.text('Conectar'));
      await tester.pumpAndSettle();
      expect((state.conexiones as List<Conexion>).single.peso, 7);
      expect(tester.takeException(), isNull);
    },
  );
}
