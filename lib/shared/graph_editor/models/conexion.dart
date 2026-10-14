import 'dart:ui';

class Conexion {
  final String nodoA;
  final String nodoB;
  final int peso;
  final String tipo;
  final Color color;

  Conexion({
    required this.nodoA,
    required this.nodoB,
    required this.peso,
    this.tipo =
        'normal', // Valor por defecto por si otros algoritmos no lo envían
    this.color = const Color(0xFF6366F1), // Valor por defecto
  });

  Map<String, dynamic> toJson() => {
    'nodoA': nodoA,
    'nodoB': nodoB,
    'peso': peso,
    'tipo': tipo,
    'color': color.toARGB32(),
  };

  factory Conexion.fromJson(Map<String, dynamic> json) => Conexion(
    nodoA: json['nodoA'],
    nodoB: json['nodoB'],
    peso: json['peso'],
    tipo: json['tipo'] ?? 'normal',
    color: json['color'] != null
        ? Color(json['color'])
        : const Color(0xFF6366F1),
  );
}
