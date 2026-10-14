import 'dart:convert';

import 'package:app_grafos/features/binary_tree/domain/binary_tree.dart';

class BinaryTreeDocument {
  BinaryTreeDocument({
    required this.name,
    required this.tree,
    Map<int, TreeNodePosition> positions = const {},
  }) : positions = Map.unmodifiable(positions);
  final String name;
  final BinaryTree tree;
  final Map<int, TreeNodePosition> positions;

  String encode({String? name}) => const JsonEncoder.withIndent('  ').convert({
    'formato': 'logiverse.binary_tree',
    'version': 1,
    'nombreArchivo': name ?? this.name,
    'arbol': tree.root?.toJson(),
    if (positions.isNotEmpty)
      'posiciones': {
        for (final entry in positions.entries)
          '${entry.key}': {'x': entry.value.x, 'y': entry.value.y},
      },
  });

  factory BinaryTreeDocument.decode(String source) {
    final data = jsonDecode(source);
    if (data is! Map ||
        data['formato'] != 'logiverse.binary_tree' ||
        data['version'] != 1 ||
        !data.containsKey('arbol')) {
      throw const FormatException(
        'El archivo no es un documento de árboles binarios compatible.',
      );
    }
    final seen = <int>{};
    BinaryTreeNode? read(dynamic json) {
      if (json == null) return null;
      if (json is! Map ||
          json['valor'] is! int ||
          !json.containsKey('izquierda') ||
          !json.containsKey('derecha')) {
        throw const FormatException('El archivo contiene un nodo inválido.');
      }
      final value = json['valor'] as int;
      if (!seen.add(value)) {
        throw const FormatException('El archivo contiene números repetidos.');
      }
      if (seen.length > BinaryTree.maxNodes ||
          value.abs() > BinaryTree.maxMagnitude) {
        throw const FormatException(
          'El archivo excede el límite de nodos o el rango de números permitido.',
        );
      }
      return BinaryTreeNode(
        value,
        left: read(json['izquierda']),
        right: read(json['derecha']),
      );
    }

    final tree = BinaryTree(read(data['arbol']));
    final positions = <int, TreeNodePosition>{};
    final rawPositions = data['posiciones'];
    if (rawPositions != null) {
      if (rawPositions is! Map) {
        throw const FormatException(
          'Las posiciones de los nodos son inválidas.',
        );
      }
      for (final entry in rawPositions.entries) {
        final value = int.tryParse(entry.key.toString());
        final point = entry.value;
        if (value == null ||
            !seen.contains(value) ||
            point is! Map ||
            point['x'] is! num ||
            point['y'] is! num) {
          throw const FormatException(
            'Las posiciones no corresponden a los nodos del árbol.',
          );
        }
        final x = (point['x'] as num).toDouble();
        final y = (point['y'] as num).toDouble();
        if (!x.isFinite ||
            !y.isFinite ||
            x < 0 ||
            y < 0 ||
            x > 100000 ||
            y > 100000) {
          throw const FormatException(
            'Las coordenadas de los nodos son inválidas.',
          );
        }
        positions[value] = TreeNodePosition(x, y);
      }
    }
    return BinaryTreeDocument(
      positions: positions,
      name: data['nombreArchivo'] is String
          ? data['nombreArchivo']
          : 'arbol_binario',
      tree: tree,
    );
  }
}

class TreeNodePosition {
  const TreeNodePosition(this.x, this.y);
  final double x;
  final double y;
}
