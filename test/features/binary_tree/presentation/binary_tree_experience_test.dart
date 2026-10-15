import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/features/binary_tree/domain/binary_tree.dart';
import 'package:app_grafos/features/binary_tree/domain/binary_tree_document.dart';
import 'package:app_grafos/features/binary_tree/presentation/screens/binary_tree_screen.dart';
import 'package:app_grafos/features/binary_tree/presentation/widgets/binary_tree_canvas.dart';
import 'package:app_grafos/shared/persistence/graph_file_service.dart';
import 'package:app_grafos/shared/widgets/graph_save_dialog.dart';

Finder field(String label) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.labelText == label,
);

void main() {
  for (final size in [const Size(390, 844), const Size(1280, 900)]) {
    testWidgets(
      'árbol: crear, reconstruir, errores, guardar y manual a ${size.width}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        String? exported;
        String? loadSource;
        final service = GraphFileService(
          writer: (name, bytes) async {
            exported = utf8.decode(bytes);
            return '/destino/$name.json';
          },
          reader: () async => loadSource,
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: BinaryTreeScreen(fileService: service),
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(field('Números de inserción'), '8, 3, 10');
        await tester.ensureVisible(find.text('Crear árbol'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Crear árbol'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<SelectableText>(
                find.byKey(const ValueKey(TreeTraversal.inOrder)),
              )
              .data,
          '3, 8, 10',
        );
        final node = find.byKey(const ValueKey('tree-node-8'));
        final sibling = find.byKey(const ValueKey('tree-node-3'));
        final initialNode = tester.getCenter(node);
        final initialSibling = tester.getCenter(sibling);
        final drag = await tester.startGesture(initialNode);
        await drag.moveBy(const Offset(20, 20));
        await tester.pump();
        await drag.moveBy(const Offset(45, 45));
        await tester.pump();
        await drag.up();
        await tester.pumpAndSettle();
        expect(
          (tester.getCenter(node) - initialNode).distance,
          greaterThan(35),
        );
        expect(
          (tester.getCenter(sibling) - initialSibling).distance,
          lessThan(1),
        );
        expect(
          tester
              .widget<BinaryTreeCanvas>(find.byType(BinaryTreeCanvas))
              .tree
              .traverse(TreeTraversal.inOrder),
          [3, 8, 10],
        );
        expect(
          tester
              .widget<BinaryTreeCanvas>(find.byType(BinaryTreeCanvas))
              .positions[8],
          isNotNull,
        );
        await tester.tap(find.byTooltip('Ordenar nodos automáticamente'));
        await tester.pumpAndSettle();
        expect((tester.getCenter(node) - initialNode).distance, lessThan(1));
        await tester.ensureVisible(field('Recorrido In-order'));
        await tester.pumpAndSettle();
        await tester.enterText(field('Recorrido In-order'), '10, 8, 3');
        await tester.ensureVisible(field('Recorrido Pre-order'));
        await tester.pumpAndSettle();
        await tester.enterText(field('Recorrido Pre-order'), '8, 10, 3');
        await tester.ensureVisible(find.text('Reconstruir árbol'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Reconstruir árbol'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<BinaryTreeCanvas>(find.byType(BinaryTreeCanvas))
              .tree
              .root!
              .left!
              .value,
          10,
        );
        await tester.ensureVisible(find.text('In-order + Post-order'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('In-order + Post-order'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(field('Recorrido Post-order'));
        await tester.pumpAndSettle();
        await tester.enterText(field('Recorrido Post-order'), '10, 3, 8');
        await tester.ensureVisible(find.text('Reconstruir árbol'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Reconstruir árbol'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<SelectableText>(
                find.byKey(const ValueKey(TreeTraversal.preOrder)),
              )
              .data,
          '8, 10, 3',
        );
        final before = tester
            .widget<BinaryTreeCanvas>(find.byType(BinaryTreeCanvas))
            .tree;
        await tester.enterText(field('Recorrido Post-order'), '10, 4, 8');
        await tester.tap(find.text('Reconstruir árbol'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('tree-error')), findsOneWidget);
        expect(
          tester.widget<BinaryTreeCanvas>(find.byType(BinaryTreeCanvas)).tree,
          same(before),
        );
        await tester.ensureVisible(field('Mínimo'));
        await tester.pumpAndSettle();
        await tester.enterText(field('Mínimo'), '-1');
        await tester.enterText(field('Máximo'), '1');
        await tester.enterText(field('Cantidad de nodos'), '3');
        await tester.ensureVisible(find.text('Generar árbol aleatorio'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Generar árbol aleatorio'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<SelectableText>(
                find.byKey(const ValueKey(TreeTraversal.inOrder)),
              )
              .data,
          '-1, 0, 1',
        );
        final rootValue = tester
            .widget<BinaryTreeCanvas>(find.byType(BinaryTreeCanvas))
            .tree
            .root!
            .value;
        await tester.drag(
          find.byKey(ValueKey('tree-node-$rootValue')),
          const Offset(30, 30),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Más opciones'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Guardar'));
        await tester.pumpAndSettle();
        expect(find.byType(GraphSaveDialog), findsOneWidget);
        final json = tester
            .widget<SelectableText>(find.byType(SelectableText).last)
            .data!;
        expect(json, contains('logiverse.binary_tree'));
        await tester.tap(find.text('Guardar JSON'));
        await tester.pumpAndSettle();
        expect(
          BinaryTreeDocument.decode(exported!).tree
              .traverse(TreeTraversal.inOrder),
          [-1, 0, 1],
        );
        expect(
          BinaryTreeDocument.decode(exported!).positions[rootValue],
          isNotNull,
        );
        loadSource = BinaryTreeDocument(
          name: 'reconstruido',
          positions: {
            8: const TreeNodePosition(240, 80),
            10: const TreeNodePosition(100, 260),
          },
          tree: BinaryTree.fromTraversals(
            inOrder: [10, 8, 3],
            otherOrder: [8, 10, 3],
            otherTraversal: TreeTraversal.preOrder,
          ),
        ).encode();
        await tester.tap(find.byTooltip('Más opciones'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cargar'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<BinaryTreeCanvas>(find.byType(BinaryTreeCanvas))
              .tree
              .root!
              .left!
              .value,
          10,
        );
        final loaded = tester
            .widget<BinaryTreeCanvas>(find.byType(BinaryTreeCanvas))
            .tree;
        expect(
          tester
              .widget<BinaryTreeCanvas>(find.byType(BinaryTreeCanvas))
              .positions[8],
          const Offset(240, 80),
        );
        loadSource = '{"invalido":true}';
        await tester.tap(find.byTooltip('Más opciones'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cargar'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('tree-error')), findsOneWidget);
        expect(
          tester.widget<BinaryTreeCanvas>(find.byType(BinaryTreeCanvas)).tree,
          same(loaded),
        );
        await tester.tap(find.byTooltip('Más opciones'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Manual de uso'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Guardar y cargar'));
        await tester.pumpAndSettle();
        await tester.pumpAndSettle();
        await tester.tap(find.text('¡Entendido!'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('pre + post y post + pre reconstruyen y muestran ambigüedad', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const BinaryTreeScreen()),
    );
    await tester.pumpAndSettle();
    for (final pair in [TreeTraversalPair.prePost, TreeTraversalPair.postPre]) {
      await tester.ensureVisible(find.text(pair.label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(pair.label));
      await tester.pumpAndSettle();
      await tester.ensureVisible(field('Recorrido Pre-order'));
      await tester.pumpAndSettle();
      await tester.enterText(field('Recorrido Pre-order'), '1, 2, 3');
      await tester.ensureVisible(field('Recorrido Post-order'));
      await tester.pumpAndSettle();
      await tester.enterText(field('Recorrido Post-order'), '3, 2, 1');
      await tester.ensureVisible(find.text('Reconstruir árbol'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reconstruir árbol'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('tree-ambiguity')), findsOneWidget);
      expect(
        tester
            .widget<BinaryTreeCanvas>(find.byType(BinaryTreeCanvas))
            .tree
            .traverse(TreeTraversal.preOrder),
        [1, 2, 3],
      );
      expect(
        tester
            .widget<BinaryTreeCanvas>(find.byType(BinaryTreeCanvas))
            .tree
            .traverse(TreeTraversal.postOrder),
        [3, 2, 1],
      );
    }
    expect(tester.takeException(), isNull);
  });
}
