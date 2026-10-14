import 'dart:math';

enum TreeTraversal { preOrder, inOrder, postOrder }

extension TreeTraversalLabel on TreeTraversal {
  String get label => switch (this) {
    TreeTraversal.preOrder => 'Pre-order',
    TreeTraversal.inOrder => 'In-order',
    TreeTraversal.postOrder => 'Post-order',
  };
}

enum TreeTraversalPair {
  inPre(TreeTraversal.inOrder, TreeTraversal.preOrder),
  inPost(TreeTraversal.inOrder, TreeTraversal.postOrder),
  preIn(TreeTraversal.preOrder, TreeTraversal.inOrder),
  postIn(TreeTraversal.postOrder, TreeTraversal.inOrder),
  prePost(TreeTraversal.preOrder, TreeTraversal.postOrder),
  postPre(TreeTraversal.postOrder, TreeTraversal.preOrder);

  const TreeTraversalPair(this.first, this.second);
  final TreeTraversal first;
  final TreeTraversal second;
  String get label => '${first.label} + ${second.label}';
}

class BinaryTreeNode {
  const BinaryTreeNode(this.value, {this.left, this.right});
  final int value;
  final BinaryTreeNode? left;
  final BinaryTreeNode? right;

  int get height => 1 + max(left?.height ?? 0, right?.height ?? 0);
  Map<String, dynamic> toJson() => {
    'valor': value,
    'izquierda': left?.toJson(),
    'derecha': right?.toJson(),
  };
}

class BinaryTree {
  const BinaryTree(this.root);
  final BinaryTreeNode? root;
  static const maxNodes = 63;
  static const maxMagnitude = 999999999;

  List<int> traverse(TreeTraversal order) {
    final values = <int>[];
    void visit(BinaryTreeNode? node) {
      if (node == null) return;
      if (order == TreeTraversal.preOrder) values.add(node.value);
      visit(node.left);
      if (order == TreeTraversal.inOrder) values.add(node.value);
      visit(node.right);
      if (order == TreeTraversal.postOrder) values.add(node.value);
    }

    visit(root);
    return List<int>.unmodifiable(values);
  }

  int get size => traverse(TreeTraversal.inOrder).length;
  int get height => root?.height ?? 0;

  static void validateValues(List<int> values, {bool allowEmpty = false}) {
    if (!allowEmpty && values.isEmpty) {
      throw const FormatException('Ingresa al menos un número.');
    }
    if (values.length > maxNodes) {
      throw const FormatException('Puedes usar hasta 63 números.');
    }
    if (values.any((v) => v.abs() > maxMagnitude)) {
      throw const FormatException('Usa números entre -999999999 y 999999999.');
    }
    if (values.toSet().length != values.length) {
      throw const FormatException(
        'No se permiten números repetidos: cada nodo debe ser único.',
      );
    }
  }

  static List<int> parseNumbers(String input) {
    if (input.trim().isEmpty) {
      throw const FormatException('Ingresa una lista de números.');
    }
    final parts = input.trim().split(RegExp(r'[,;\s]+'));
    final values = <int>[];
    for (final part in parts) {
      final value = int.tryParse(part);
      if (value == null) {
        throw const FormatException(
          'Usa solo números enteros separados por comas o espacios.',
        );
      }
      values.add(value);
    }
    validateValues(values);
    return List<int>.unmodifiable(values);
  }

  factory BinaryTree.fromInsertion(List<int> values) {
    validateValues(values);
    BinaryTreeNode insert(BinaryTreeNode? node, int value) {
      if (node == null) return BinaryTreeNode(value);
      return value < node.value
          ? BinaryTreeNode(
              node.value,
              left: insert(node.left, value),
              right: node.right,
            )
          : BinaryTreeNode(
              node.value,
              left: node.left,
              right: insert(node.right, value),
            );
    }

    BinaryTreeNode? root;
    for (final value in values) {
      root = insert(root, value);
    }
    return BinaryTree(root);
  }

  factory BinaryTree.fromTraversals({
    required List<int> inOrder,
    required List<int> otherOrder,
    required TreeTraversal otherTraversal,
  }) {
    if (otherTraversal == TreeTraversal.inOrder) {
      throw const FormatException(
        'Combina In-order con Pre-order o Post-order.',
      );
    }
    validateValues(inOrder);
    validateValues(otherOrder);
    if (inOrder.length != otherOrder.length ||
        !inOrder.toSet().containsAll(otherOrder)) {
      throw const FormatException(
        'Los dos recorridos deben tener la misma cantidad y exactamente los mismos números.',
      );
    }
    final positions = {for (var i = 0; i < inOrder.length; i++) inOrder[i]: i};
    final isPre = otherTraversal == TreeTraversal.preOrder;
    var cursor = isPre ? 0 : otherOrder.length - 1;
    BinaryTreeNode? build(int start, int end) {
      if (start >= end) return null;
      if (cursor < 0 || cursor >= otherOrder.length) {
        throw const FormatException(
          'Los recorridos no describen un árbol válido.',
        );
      }
      final value = otherOrder[cursor];
      cursor += isPre ? 1 : -1;
      final split = positions[value]!;
      if (split < start || split >= end) {
        throw const FormatException(
          'Los números coinciden, pero el orden de los recorridos es incompatible.',
        );
      }
      if (isPre) {
        final left = build(start, split);
        final right = build(split + 1, end);
        return BinaryTreeNode(value, left: left, right: right);
      }
      final right = build(split + 1, end);
      final left = build(start, split);
      return BinaryTreeNode(value, left: left, right: right);
    }

    return BinaryTree(build(0, inOrder.length));
  }

  static TreeReconstructionResult reconstruct({
    required List<int> firstOrder,
    required TreeTraversal firstTraversal,
    required List<int> secondOrder,
    required TreeTraversal secondTraversal,
  }) {
    if (firstTraversal == secondTraversal) {
      throw const FormatException('Elige dos recorridos diferentes.');
    }
    validateValues(firstOrder);
    validateValues(secondOrder);
    if (firstOrder.length != secondOrder.length ||
        !firstOrder.toSet().containsAll(secondOrder)) {
      throw const FormatException(
        'Los dos recorridos deben tener la misma cantidad y exactamente los mismos números.',
      );
    }
    if (firstTraversal == TreeTraversal.inOrder ||
        secondTraversal == TreeTraversal.inOrder) {
      final firstIsIn = firstTraversal == TreeTraversal.inOrder;
      return TreeReconstructionResult(
        BinaryTree.fromTraversals(
          inOrder: firstIsIn ? firstOrder : secondOrder,
          otherOrder: firstIsIn ? secondOrder : firstOrder,
          otherTraversal: firstIsIn ? secondTraversal : firstTraversal,
        ),
        isAmbiguous: false,
      );
    }
    final pre = firstTraversal == TreeTraversal.preOrder
        ? firstOrder
        : secondOrder;
    final post = firstTraversal == TreeTraversal.postOrder
        ? firstOrder
        : secondOrder;
    final postPositions = {for (var i = 0; i < post.length; i++) post[i]: i};
    var ambiguous = false;
    BinaryTreeNode build(int preStart, int postStart, int length) {
      final value = pre[preStart];
      if (value != post[postStart + length - 1]) {
        throw const FormatException(
          'El orden de Pre-order y Post-order es incompatible.',
        );
      }
      if (length == 1) return BinaryTreeNode(value);
      final childEnd = postPositions[pre[preStart + 1]]!;
      if (childEnd < postStart || childEnd >= postStart + length - 1) {
        throw const FormatException(
          'El orden de Pre-order y Post-order es incompatible.',
        );
      }
      final leftSize = childEnd - postStart + 1;
      final left = build(preStart + 1, postStart, leftSize);
      if (leftSize == length - 1) {
        // Traversals do not specify the side of an only child. Choose left
        // consistently and report that another tree can fit the same inputs.
        ambiguous = true;
        return BinaryTreeNode(value, left: left);
      }
      return BinaryTreeNode(
        value,
        left: left,
        right: build(
          preStart + leftSize + 1,
          postStart + leftSize,
          length - leftSize - 1,
        ),
      );
    }

    final tree = BinaryTree(build(0, 0, pre.length));
    return TreeReconstructionResult(tree, isAmbiguous: ambiguous);
  }

  static List<int> randomValues({
    required int count,
    required int minimum,
    required int maximum,
    Random? random,
  }) {
    if (count < 1 || count > maxNodes) {
      throw const FormatException('La cantidad debe estar entre 1 y 63.');
    }
    if (minimum > maximum) {
      throw const FormatException(
        'El mínimo no puede ser mayor que el máximo.',
      );
    }
    if (minimum.abs() > maxMagnitude || maximum.abs() > maxMagnitude) {
      throw const FormatException(
        'El rango permitido es de -999999999 a 999999999.',
      );
    }
    final range = maximum - minimum + 1;
    if (count > range) {
      throw const FormatException(
        'El rango no tiene suficientes números distintos para esa cantidad.',
      );
    }
    // Floyd sampling stays bounded even when every value of a range is needed.
    final generator = random ?? Random();
    final selected = <int>{};
    for (var j = range - count; j < range; j++) {
      final pick = generator.nextInt(j + 1);
      selected.add(selected.contains(pick) ? j : pick);
    }
    return selected.map((v) => v + minimum).toList()..shuffle(generator);
  }
}

class TreeReconstructionResult {
  const TreeReconstructionResult(this.tree, {required this.isAmbiguous});
  final BinaryTree tree;
  final bool isAmbiguous;
}
