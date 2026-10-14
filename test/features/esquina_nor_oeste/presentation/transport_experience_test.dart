import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/features/esquina_nor_oeste/presentation/screens/esquina_nor_oeste_screen.dart';
import 'package:app_grafos/shared/graph_editor/models/conexion.dart';
import 'package:app_grafos/shared/graph_editor/models/nodo.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(1280, 900)]) {
    testWidgets('transporte optimiza el modo elegido a ${size.width}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.dark, home: const EsquinaNorOesteScreen()),
      );
      await tester.pumpAndSettle();
      // Seed editor data, then exercise the real matrix and calculate controls.
      final dynamic state = tester.state(find.byType(EsquinaNorOesteScreen));
      state.nodos = <Nodo>[
        Nodo(id: 'a', nombre: 'A', posicion: const Offset(50, 100)),
        Nodo(id: 'b', nombre: 'B', posicion: const Offset(50, 200)),
        Nodo(id: 'x', nombre: 'X', posicion: const Offset(250, 100)),
        Nodo(id: 'y', nombre: 'Y', posicion: const Offset(250, 200)),
      ];
      state.conexiones = <Conexion>[
        for (final pair in <(String, String, int)>[
          ('a', 'x', 1),
          ('a', 'y', 2),
          ('b', 'x', 2),
          ('b', 'y', 100),
        ])
          Conexion(
            nodoA: pair.$1,
            nodoB: pair.$2,
            peso: pair.$3,
            tipo: 'unidireccional',
            color: AppColors.primary,
          ),
      ];
      await tester.tap(find.byTooltip('Mostrar matriz'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Calcular mínimo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Calcular mínimo'));
      await tester.pumpAndSettle();
      expect(find.text('Valor Total: 40'), findsOneWidget);
      expect(
        find.text('A ➔ Y (Cant: 10, Costo Unit: 2)', skipOffstage: false),
        findsNothing,
      );
      expect(find.text('• A ➔ Y (Cant: 10, Costo Unit: 2)'), findsOneWidget);
      await tester.ensureVisible(find.text('Maximizar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Maximizar'));
      await tester.pumpAndSettle();
      expect(find.text('Valor Total: 40'), findsNothing);
      await tester.ensureVisible(find.text('Calcular máximo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Calcular máximo'));
      await tester.pumpAndSettle();
      expect(find.text('Valor Total: 1010'), findsOneWidget);
      expect(find.text('• B ➔ Y (Cant: 10, Costo Unit: 100)'), findsOneWidget);
      // Different totals calculate directly, with residual quantities in the result.
      await tester.ensureVisible(find.byType(TextField).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '9');
      await tester.pumpAndSettle();
      expect(find.text('Valor Total: 1010'), findsNothing);
      await tester.ensureVisible(find.text('Calcular máximo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Calcular máximo'));
      await tester.pumpAndSettle();
      expect(find.text('Valor Total: 1009'), findsOneWidget);
      expect(find.text('Oferta sin utilizar: 1'), findsOneWidget);
      expect(find.textContaining('Equilibra'), findsNothing);
      expect(find.textContaining('Clic izq:'), findsNothing);
      await tester.ensureVisible(find.byType(TextField).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '11');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Calcular máximo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Calcular máximo'));
      await tester.pumpAndSettle();
      expect(find.text('Valor Total: 1010'), findsOneWidget);
      expect(find.text('Demanda pendiente: 1'), findsOneWidget);
      state.conexiones = <Conexion>[];
      await tester.ensureVisible(find.text('Calcular máximo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Calcular máximo'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Las rutas disponibles'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
