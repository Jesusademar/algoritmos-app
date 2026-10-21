import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grafos/shared/graph_editor/models/nodo.dart';
import 'package:app_grafos/shared/graph_editor/widgets/graph_canvas_viewport.dart';

class _Dots extends CustomPainter {
  _Dots(this.nodes);
  final List<Nodo> nodes;
  @override
  void paint(Canvas canvas, Size size) {
    for (final node in nodes) {
      canvas.drawCircle(node.posicion, 24, Paint());
    }
  }

  @override
  bool shouldRepaint(_Dots oldDelegate) => true;
}

void main() {
  testWidgets(
    'arrastrar fondo, zoom y editar usan coordenadas de escena sin mover datos',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 500);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final node = Nodo(id: 'a', nombre: 'A', posicion: const Offset(70, 100));
      Offset? tapped;
      Offset? edited;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => GraphCanvasViewport(
                nodes: [node],
                painter: _Dots([node]),
                onTap: (p) => tapped = p,
                onEdit: (p) => edited = p,
                onNodeMoved: (n, p) => setState(() => n.posicion = p),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final state = tester.state<GraphCanvasViewportState>(
        find.byType(GraphCanvasViewport),
      );
      await tester.dragFrom(const Offset(200, 240), const Offset(70, 40));
      await tester.pumpAndSettle();
      expect(node.posicion, const Offset(70, 100));
      expect(state.transform.value.getTranslation().x, isNot(0));
      expect(tapped, isNull);
      expect(find.byType(Dialog), findsNothing);
      await tester.tap(find.byTooltip('Acercar pizarra'));
      await tester.pumpAndSettle();
      expect(state.transform.value.getMaxScaleOnAxis(), closeTo(1.25, 0.001));
      final expected = state.toScene(const Offset(260, 250));
      await tester.tapAt(const Offset(260, 250));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect((tapped! - expected).distance, lessThan(0.01));
      final projected = MatrixUtils.transformPoint(
        state.transform.value,
        node.posicion,
      );
      await tester.dragFrom(projected, const Offset(50, 25));
      await tester.pumpAndSettle();
      expect((node.posicion - const Offset(110, 120)).distance, lessThan(0.1));
      final point = MatrixUtils.transformPoint(
        state.transform.value,
        node.posicion,
      );
      await tester.longPressAt(point);
      await tester.pumpAndSettle();
      expect((edited! - node.posicion).distance, lessThan(0.1));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'ajustar encuadra nodos fuera del área y también coordenadas negativas',
    (tester) async {
      final nodes = [
        Nodo(id: 'a', nombre: 'A', posicion: const Offset(-700, -500)),
        Nodo(id: 'b', nombre: 'B', posicion: const Offset(1500, 1800)),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 350,
              height: 400,
              child: GraphCanvasViewport(
                nodes: nodes,
                painter: _Dots(nodes),
                onTap: (_) {},
                onEdit: (_) {},
                onNodeMoved: (_, _) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Ajustar nodos a la vista'));
      await tester.pumpAndSettle();
      final state = tester.state<GraphCanvasViewportState>(
        find.byType(GraphCanvasViewport),
      );
      for (final node in nodes) {
        final p = MatrixUtils.transformPoint(
          state.transform.value,
          node.posicion,
        );
        expect(p.dx, inInclusiveRange(16, 334));
        expect(p.dy, inInclusiveRange(52, 310));
      }
      expect(nodes.first.posicion, const Offset(-700, -500));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('dos dedos hacen zoom sin crear ni mover nodos', (tester) async {
    var taps = 0;
    var moves = 0;
    final node = Nodo(id: 'a', nombre: 'A', posicion: const Offset(80, 100));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GraphCanvasViewport(
            nodes: [node],
            painter: _Dots([node]),
            onTap: (_) => taps++,
            onEdit: (_) {},
            onNodeMoved: (_, _) => moves++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final state = tester.state<GraphCanvasViewportState>(
      find.byType(GraphCanvasViewport),
    );
    final first = await tester.startGesture(const Offset(230, 200), pointer: 1);
    final second = await tester.startGesture(
      const Offset(330, 200),
      pointer: 2,
    );
    await first.moveTo(const Offset(200, 200));
    await second.moveTo(const Offset(360, 200));
    await tester.pump();
    await first.moveTo(const Offset(170, 200));
    await second.moveTo(const Offset(390, 200));
    await tester.pump();
    expect(state.transform.value.getMaxScaleOnAxis(), greaterThan(1.2));
    await first.up();
    await second.up();
    await tester.pumpAndSettle();
    expect(taps, 0);
    expect(moves, 0);
    expect(node.posicion, const Offset(80, 100));
    expect(tester.takeException(), isNull);
  });
}
