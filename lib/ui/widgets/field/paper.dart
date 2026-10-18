import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show PointMode;

import 'package:flutter/widgets.dart';

import '../../../app/field_palette.dart';

/// A sheet of field-journal paper behind [child]: paper colour, fibres and
/// specks, and a warm darkening towards the edges. Static (drawn once per
/// size) so menus cost nothing.
class PaperAtmosphere extends StatelessWidget {
  const PaperAtmosphere({super.key, required this.child, this.vignette = 0.5});

  final Widget child;

  /// Edge darkening, 0–1.
  final double vignette;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      RepaintBoundary(child: CustomPaint(painter: _PaperPainter(vignette))),
      child,
    ],
  );
}

class _PaperPainter extends CustomPainter {
  _PaperPainter(this.vignette);
  final double vignette;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = FieldPalette.paper);
    // Fixed seed: the same paper every frame.
    final rng = math.Random(1859);
    final fibre = Paint()
      ..strokeWidth = 0.6
      ..strokeCap = StrokeCap.round;
    final fibres = (size.width * size.height / 900).round().clamp(0, 4000);
    for (var i = 0; i < fibres; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final a = rng.nextDouble() * math.pi;
      final l = 2 + rng.nextDouble() * 6;
      fibre.color =
          (rng.nextBool() ? FieldPalette.paperEdge : const Color(0xFFFFFBF0))
              .withValues(alpha: 0.35);
      canvas.drawLine(
        Offset(x, y),
        Offset(x + math.cos(a) * l, y + math.sin(a) * l),
        fibre,
      );
    }
    final count = (size.width * size.height / 160).round().clamp(0, 30000);
    final specks = Float32List(count * 2);
    for (var i = 0; i < count * 2; i += 2) {
      specks[i] = rng.nextDouble() * size.width;
      specks[i + 1] = rng.nextDouble() * size.height;
    }
    canvas.drawRawPoints(
      PointMode.points,
      specks,
      Paint()
        ..strokeWidth = 1
        ..color = FieldPalette.inkSoft.withValues(alpha: 0.05),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 0.95,
          colors: [
            const Color(0x00000000),
            const Color(0x00000000),
            const Color(0xFF8A6A3A).withValues(alpha: 0.35 * vignette),
          ],
          stops: const [0, 0.6, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_PaperPainter old) => old.vignette != vignette;
}

/// A piece of paper laid on top of whatever is behind it: optional tilt,
/// tape at the top, hairline or double-rule frame.
class PaperPanel extends StatelessWidget {
  const PaperPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    this.tilt = 0,
    this.tape = false,
    this.frame = PanelFrame.hairline,
    this.color = FieldPalette.paper,
    this.accent,
  });

  final Widget child;
  final EdgeInsets padding;

  /// Degrees; keep within ±1.
  final double tilt;
  final bool tape;
  final PanelFrame frame;
  final Color color;

  /// Colours the frame (e.g. the active team's ink).
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final line = accent ?? FieldPalette.ink;
    Widget panel = DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        border: frame == PanelFrame.none
            ? null
            : Border.all(color: line, width: accent == null ? 1 : 1.6),
        boxShadow: const [
          // Paper's own thin contact shadow, nothing more.
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 1.5,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: frame == PanelFrame.double
          ? Padding(
              padding: const EdgeInsets.all(2.5),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: line.withValues(alpha: 0.7),
                    width: 0.6,
                  ),
                ),
                child: Padding(padding: padding, child: child),
              ),
            )
          : Padding(padding: padding, child: child),
    );
    if (tape) {
      panel = Stack(
        clipBehavior: Clip.none,
        children: [
          panel,
          Positioned(
            top: -7,
            left: 0,
            right: 0,
            child: Center(
              child: Transform.rotate(
                angle: -0.05,
                child: Container(
                  width: 46,
                  height: 14,
                  color: FieldPalette.tape,
                ),
              ),
            ),
          ),
        ],
      );
    }
    return tilt == 0
        ? panel
        : Transform.rotate(angle: tilt * math.pi / 180, child: panel);
  }
}

enum PanelFrame { none, hairline, double }

/// A hairline rule with a small engraved leaf in the middle.
class LeafRule extends StatelessWidget {
  const LeafRule({super.key, this.width = 220, this.color = FieldPalette.ink});

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: 14,
    child: CustomPaint(painter: _LeafRulePainter(color)),
  );
}

class _LeafRulePainter extends CustomPainter {
  _LeafRulePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.center(Offset.zero);
    final line = Paint()
      ..color = color
      ..strokeWidth = 0.8;
    canvas
      ..drawLine(Offset(0, mid.dy), Offset(mid.dx - 16, mid.dy), line)
      ..drawLine(Offset(mid.dx + 16, mid.dy), Offset(size.width, mid.dy), line);
    // A leaf on its stem, lying along the rule.
    final leaf = Path()
      ..moveTo(mid.dx - 11, mid.dy)
      ..quadraticBezierTo(mid.dx, mid.dy - 7, mid.dx + 11, mid.dy)
      ..quadraticBezierTo(mid.dx, mid.dy + 7, mid.dx - 11, mid.dy)
      ..close();
    canvas
      ..drawPath(leaf, Paint()..color = color)
      ..drawLine(
        Offset(mid.dx - 9, mid.dy),
        Offset(mid.dx + 9, mid.dy),
        Paint()
          ..color = FieldPalette.paper
          ..strokeWidth = 0.8,
      );
  }

  @override
  bool shouldRepaint(_LeafRulePainter old) => old.color != color;
}

/// Title in spaced capitals, the face's stand-in for small caps.
class SpacedTitle extends StatelessWidget {
  const SpacedTitle(
    this.text, {
    super.key,
    this.size = 18,
    this.spacing = 3,
    this.color = FieldPalette.ink,
  });

  final String text;
  final double size;
  final double spacing;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    textAlign: TextAlign.center,
    style: TextStyle(fontSize: size, letterSpacing: spacing, color: color),
  );
}
