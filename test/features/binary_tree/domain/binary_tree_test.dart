import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:app_grafos/features/binary_tree/domain/binary_tree.dart';
import 'package:app_grafos/features/binary_tree/domain/binary_tree_document.dart';

void main() {
  test('inserción y los tres recorridos coinciden con el árbol esperado', () {
    final tree = BinaryTree.fromInsertion([8, 3, 10, 1, 6, 14, 4, 7, 13]);
    expect(tree.traverse(TreeTraversal.preOrder), [
      8,
      3,
      1,
      6,
      4,
      7,
      10,
      14,
      13,
    ]);
    expect(tree.traverse(TreeTraversal.inOrder), [
      1,
      3,
      4,
      6,
      7,
      8,
      10,
      13,
      14,
    ]);
    expect(tree.traverse(TreeTraversal.postOrder), [
      1,
      4,
      7,
      6,
      3,
      13,
      14,
      10,
      8,
    ]);
    expect(tree.height, 4);
    expect(tree.size, 9);
  });

  test(
    'reconstruye árboles generales sin convertirlos en árboles de búsqueda',
    () {
      for (final order in [TreeTraversal.preOrder, TreeTraversal.postOrder]) {
        final tree = BinaryTree.fromTraversals(
          inOrder: [10, 8, 3],
          otherOrder: order == TreeTraversal.preOrder ? [8, 10, 3] : [10, 3, 8],
          otherTraversal: order,
        );
        expect(tree.root!.value, 8);
        expect(tree.root!.left!.value, 10);
        expect(tree.root!.right!.value, 3);
      }
    },
  );

  test('rechaza diferencias de cantidad/valores, duplicados y órdenes incompatibles', () {
    for (final pair in <(List<int>, List<int>, TreeTraversal)>[
      ([1, 2, 3], [2, 1], TreeTraversal.preOrder),
      ([1, 2, 3], [2, 1, 4], TreeTraversal.preOrder),
      ([1, 1, 2], [1, 2, 1], TreeTraversal.preOrder),
      ([1, 2, 3], [2, 3, 1], TreeTraversal.preOrder),
      ([1, 2, 3], [3, 1, 2], TreeTraversal.postOrder),
      ([], [], TreeTraversal.preOrder),
    ]) {
      expect(
        () => BinaryTree.fromTraversals(
          inOrder: pair.$1,
          otherOrder: pair.$2,
          otherTraversal: pair.$3,
        ),
        throwsFormatException,
      );
    }
  });

  test(
    'aleatorios únicos, inclusivos y acotados, con rangos negativos y grandes',
    () {
      final generator = Random(42);
      for (var count = 1; count <= BinaryTree.maxNodes; count++) {
        final values = BinaryTree.randomValues(
          count: count,
          minimum: -32,
          maximum: 32,
          random: generator,
        );
        expect(values.length, count);
        expect(values.toSet().length, count);
        expect(values.every((v) => v >= -32 && v <= 32), isTrue);
        final tree = BinaryTree.fromInsertion(values);
        for (final order in [TreeTraversal.preOrder, TreeTraversal.postOrder]) {
          final rebuilt = BinaryTree.fromTraversals(
            inOrder: tree.traverse(TreeTraversal.inOrder),
            otherOrder: tree.traverse(order),
            otherTraversal: order,
          );
          expect(rebuilt.root!.toJson(), tree.root!.toJson());
        }
      }
      expect(
        BinaryTree.randomValues(count: 5, minimum: -2, maximum: 2).toSet(),
        {-2, -1, 0, 1, 2},
      );
      expect(
        BinaryTree.randomValues(
          count: 63,
          minimum: -999999999,
          maximum: 999999999,
        ).length,
        63,
      );
      expect(
        () => BinaryTree.randomValues(count: 4, minimum: 1, maximum: 3),
        throwsFormatException,
      );
      expect(
        () => BinaryTree.randomValues(count: 1, minimum: 2, maximum: 1),
        throwsFormatException,
      );
      expect(
        () => BinaryTree.randomValues(count: 64, minimum: 1, maximum: 100),
        throwsFormatException,
      );
    },
  );

  test('lectura por teclado y JSON preservan la estructura reconstruida', () {
    expect(BinaryTree.parseNumbers('-2, 0 4; 7'), [-2, 0, 4, 7]);
    expect(() => BinaryTree.parseNumbers('1, dos'), throwsFormatException);
    expect(() => BinaryTree.parseNumbers('1, 1'), throwsFormatException);
    final tree = BinaryTree.fromTraversals(
      inOrder: [10, 8, 3],
      otherOrder: [8, 10, 3],
      otherTraversal: TreeTraversal.preOrder,
    );
    final document = BinaryTreeDocument(name: 'árbol de prueba', tree: tree);
    final decoded = BinaryTreeDocument.decode(document.encode());
    expect(decoded.name, document.name);
    expect(decoded.tree.root!.toJson(), tree.root!.toJson());
    expect(
      () => BinaryTreeDocument.decode('{"nodos":[]}'),
      throwsFormatException,
    );
    final data = jsonDecode(document.encode()) as Map<String, dynamic>;
    data['arbol']['izquierda']['valor'] = 8;
    expect(
      () => BinaryTreeDocument.decode(jsonEncode(data)),
      throwsFormatException,
    );
    data['arbol']['izquierda']['valor'] = 'texto';
    expect(
      () => BinaryTreeDocument.decode(jsonEncode(data)),
      throwsFormatException,
    );
  });
  test(
    'las seis combinaciones reconstruyen un árbol completo sin ambigüedad',
    () {
      final tree = BinaryTree.fromInsertion([4, 2, 6, 1, 3, 5, 7]);
      for (final pair in TreeTraversalPair.values) {
        final result = BinaryTree.reconstruct(
          firstOrder: tree.traverse(pair.first),
          firstTraversal: pair.first,
          secondOrder: tree.traverse(pair.second),
          secondTraversal: pair.second,
        );
        expect(result.tree.root!.toJson(), tree.root!.toJson());
        expect(result.isAmbiguous, isFalse);
      }
    },
  );

  test(
    'Pre + Post informa hijos únicos y conserva exactamente ambos recorridos',
    () {
      for (final pair in [
        TreeTraversalPair.prePost,
        TreeTraversalPair.postPre,
      ]) {
        final result = BinaryTree.reconstruct(
          firstOrder: pair.first == TreeTraversal.preOrder
              ? [1, 2, 3]
              : [3, 2, 1],
          firstTraversal: pair.first,
          secondOrder: pair.second == TreeTraversal.preOrder
              ? [1, 2, 3]
              : [3, 2, 1],
          secondTraversal: pair.second,
        );
        expect(result.isAmbiguous, isTrue);
        expect(result.tree.root!.left!.value, 2);
        expect(result.tree.traverse(TreeTraversal.preOrder), [1, 2, 3]);
        expect(result.tree.traverse(TreeTraversal.postOrder), [3, 2, 1]);
      }
      final random = Random(18);
      for (var length = 1; length <= 63; length++) {
        final tree = BinaryTree.fromInsertion(
          BinaryTree.randomValues(
            count: length,
            minimum: 1,
            maximum: 100,
            random: random,
          ),
        );
        final result = BinaryTree.reconstruct(
          firstOrder: tree.traverse(TreeTraversal.preOrder),
          firstTraversal: TreeTraversal.preOrder,
          secondOrder: tree.traverse(TreeTraversal.postOrder),
          secondTraversal: TreeTraversal.postOrder,
        );
        expect(
          result.tree.traverse(TreeTraversal.preOrder),
          tree.traverse(TreeTraversal.preOrder),
        );
        expect(
          result.tree.traverse(TreeTraversal.postOrder),
          tree.traverse(TreeTraversal.postOrder),
        );
      }
    },
  );

  test('Pre + Post rechaza raíces, valores y orden incompatibles', () {
    for (final post in [
      [2, 3, 1, 4],
      [4, 2, 3, 1],
      [4, 3, 2, 5],
    ]) {
      expect(
        () => BinaryTree.reconstruct(
          firstOrder: [1, 2, 3, 4],
          firstTraversal: TreeTraversal.preOrder,
          secondOrder: post,
          secondTraversal: TreeTraversal.postOrder,
        ),
        throwsFormatException,
      );
    }
  });

  test(
    'JSON conserva posiciones y admite documentos antiguos sin posiciones',
    () {
      final tree = BinaryTree.fromInsertion([8, 3, 10]);
      final document = BinaryTreeDocument(
        name: 'movido',
        tree: tree,
        positions: {
          8: const TreeNodePosition(250, 80),
          3: const TreeNodePosition(110, 260),
        },
      );
      final loaded = BinaryTreeDocument.decode(document.encode());
      expect(loaded.positions[8]!.x, 250);
      expect(loaded.positions[3]!.y, 260);
      expect(loaded.tree.root!.toJson(), tree.root!.toJson());
      expect(
        BinaryTreeDocument.decode(
          BinaryTreeDocument(name: 'antiguo', tree: tree).encode(),
        ).positions,
        isEmpty,
      );
      final data = jsonDecode(document.encode()) as Map<String, dynamic>;
      data['posiciones']['99'] = {'x': 100, 'y': 100};
      expect(
        () => BinaryTreeDocument.decode(jsonEncode(data)),
        throwsFormatException,
      );
    },
  );
}
