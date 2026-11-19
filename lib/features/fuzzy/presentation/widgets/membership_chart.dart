import 'package:flutter/material.dart';
import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/features/fuzzy/domain/fuzzy_system.dart';

const membershipColors = [
  AppColors.sorting,
  AppColors.johnson,
  AppColors.graph,
  AppColors.success,
  AppColors.primary,
];

class MembershipChart extends StatelessWidget {
  const MembershipChart({super.key, required this.variable});
  final FuzzyVariable variable;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Semantics(
        label:
            'Grado de pertenencia de ${variable.name}, de ${variable.min} a ${variable.max}. ${variable.functions.map((mf) => '${mf.name}: ${mf.type.label}, ${mf.parameters.join(', ')}').join('. ')}',
        child: SizedBox(
          height: 180,
          child: CustomPaint(painter: _MembershipPainter(variable)),
        ),
      ),
      Wrap(
        spacing: 16,
        runSpacing: 6,
        children: [
          for (var i = 0; i < variable.functions.length; i++)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: membershipColors[i % membershipColors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    variable.functions[i].name,
                    style: TextStyle(
                      color: membershipColors[i % membershipColors.length],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    ],
  );
}

class _MembershipPainter extends CustomPainter {
  const _MembershipPainter(this.variable);
  final FuzzyVariable variable;

  void label(
    Canvas canvas,
    String text,
    Offset position, {
    bool right = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, position - Offset(right ? painter.width : 0, 0));
    painter.dispose();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final area = Rect.fromLTRB(32, 12, size.width - 12, size.height - 28);
    final grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (final fraction in [0.0, 0.5, 1.0]) {
      final y = area.bottom - fraction * area.height;
      canvas.drawLine(Offset(area.left, y), Offset(area.right, y), grid);
      label(canvas, '$fraction', Offset(0, y - 6));
    }
    label(
      canvas,
      variable.min.toStringAsPrecision(4),
      Offset(area.left, area.bottom + 8),
    );
    label(
      canvas,
      variable.max.toStringAsPrecision(4),
      Offset(area.right, area.bottom + 8),
      right: true,
    );
    canvas.save();
    canvas.clipRect(area.inflate(1));
    for (var i = 0; i < variable.functions.length; i++) {
      final mf = variable.functions[i];
      if (mf.validate() != null) continue;
      // Include breakpoints in addition to samples, preserving narrow triangles.
      final samples = <double>[
        for (var j = 0; j <= 240; j++)
          variable.min + (variable.max - variable.min) * (j / 240),
        if (mf.type != MembershipType.gaussian)
          ...mf.parameters.where((p) => p >= variable.min && p <= variable.max),
        if (mf.type == MembershipType.gaussian &&
            mf.parameters[1] >= variable.min &&
            mf.parameters[1] <= variable.max)
          mf.parameters[1],
      ]..sort();
      final path = Path();
      for (var j = 0; j < samples.length; j++) {
        final x =
            area.left +
            (samples[j] - variable.min) /
                (variable.max - variable.min) *
                area.width;
        final y = area.bottom - mf.membership(samples[j]) * area.height;
        if (!x.isFinite || !y.isFinite) continue;
        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = membershipColors[i % membershipColors.length]
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MembershipPainter oldDelegate) =>
      oldDelegate.variable != variable;
}
