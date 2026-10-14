import 'dart:ui';

/// Vector unitario para dibujar conexiones y calcular sus zonas de selección.
extension OffsetGeometry on Offset {
  Offset normalize() => distance == 0 ? Offset.zero : this / distance;
}
