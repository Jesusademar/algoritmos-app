import 'dart:ui';

class Nodo {
  final String id;
  String nombre;
  Offset posicion;
  int valorInicial;

  Nodo({
    required this.id,
    required this.nombre,
    required this.posicion,
    this.valorInicial = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'x': posicion.dx,
    'y': posicion.dy,
    'valorInicial': valorInicial,
  };

  factory Nodo.fromJson(Map<String, dynamic> json) => Nodo(
    id: json['id'],
    nombre: json['nombre'],
    posicion: Offset(
      (json['x'] as num).toDouble(),
      (json['y'] as num).toDouble(),
    ),
    valorInicial: json['valorInicial'] ?? 0,
  );
}
