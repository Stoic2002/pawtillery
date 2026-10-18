import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../app/field_palette.dart';

/// Icons drawn as pen strokes (docs/art_style_guide.md: no Material icons
/// on screen). Each glyph is drawn in a 24 × 24 box.
enum InkGlyph {
  pause,
  back,
  walkLeft,
  walkRight,
  jump,
  highJump,
  focus,
  dice,
  close,
  satchel,
  play,
  replay,
  wind,
  timer,
}

class InkIcon extends StatelessWidget {
  const InkIcon(
    this.glyph, {
    super.key,
    this.size = 24,
    this.color = FieldPalette.ink,
  });

  final InkGlyph glyph;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _InkPainter(glyph, color)),
  );
}

class _InkPainter extends CustomPainter {
  _InkPainter(this.glyph, this.color);
  final InkGlyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final pen = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;
    void line(double x1, double y1, double x2, double y2) =>
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), pen);

    switch (glyph) {
      case InkGlyph.pause:
        line(9, 6, 9, 18);
        line(15, 6, 15, 18);
      case InkGlyph.back:
        line(19, 12, 5, 12);
        line(10, 7, 5, 12);
        line(10, 17, 5, 12);
      case InkGlyph.walkLeft || InkGlyph.walkRight:
        final dir = glyph == InkGlyph.walkLeft ? -1.0 : 1.0;
        canvas.drawPath(
          Path()
            ..moveTo(12 - dir * 5, 5)
            ..lineTo(12 + dir * 6, 12)
            ..lineTo(12 - dir * 5, 19)
            ..close(),
          fill,
        );
      case InkGlyph.jump:
        canvas.drawPath(
          Path()
            ..moveTo(4, 18)
            ..quadraticBezierTo(10, 3, 19, 10),
          pen,
        );
        line(19, 10, 14.5, 9.5);
        line(19, 10, 17.5, 14.5);
        line(3, 20, 21, 20);
      case InkGlyph.highJump:
        line(12, 19, 12, 5);
        line(7, 10, 12, 5);
        line(17, 10, 12, 5);
        line(7, 15, 12, 10);
        line(17, 15, 12, 10);
        line(5, 21, 19, 21);
      case InkGlyph.focus:
        canvas.drawCircle(const Offset(12, 12), 6.5, pen);
        canvas.drawCircle(const Offset(12, 12), 1.6, fill);
        line(12, 2, 12, 5);
        line(12, 19, 12, 22);
        line(2, 12, 5, 12);
        line(19, 12, 22, 12);
      case InkGlyph.dice:
        canvas.drawRect(const Rect.fromLTWH(5, 5, 14, 14), pen);
        for (final (x, y) in const [(9.0, 9.0), (15.0, 15.0), (12.0, 12.0)]) {
          canvas.drawCircle(Offset(x, y), 1.4, fill);
        }
      case InkGlyph.close:
        line(6, 6, 18, 18);
        line(18, 6, 6, 18);
      case InkGlyph.satchel:
        canvas.drawRect(const Rect.fromLTWH(4, 9, 16, 11), pen);
        canvas.drawPath(
          Path()
            ..moveTo(8, 9)
            ..quadraticBezierTo(12, 2, 16, 9),
          pen,
        );
        line(4, 13, 20, 13);
        canvas.drawRect(const Rect.fromLTWH(10.5, 12, 3, 3), fill);
      case InkGlyph.play:
        canvas.drawPath(
          Path()
            ..moveTo(8, 5)
            ..lineTo(19, 12)
            ..lineTo(8, 19)
            ..close(),
          fill,
        );
      case InkGlyph.replay:
        canvas.drawArc(
          const Rect.fromLTWH(5, 5, 14, 14),
          -math.pi * 0.35,
          math.pi * 1.7,
          false,
          pen,
        );
        line(16.5, 4, 16.8, 8.2);
        line(16.8, 8.2, 12.6, 8.2);
      case InkGlyph.wind:
        canvas.drawPath(
          Path()
            ..moveTo(3, 9)
            ..lineTo(15, 9)
            ..quadraticBezierTo(19, 9, 18.5, 6)
            ..quadraticBezierTo(18, 3.5, 15.5, 4.5),
          pen,
        );
        canvas.drawPath(
          Path()
            ..moveTo(3, 14)
            ..lineTo(18, 14)
            ..quadraticBezierTo(21.5, 14, 21, 17.5)
            ..quadraticBezierTo(20.5, 20, 17.5, 19),
          pen,
        );
        line(6, 19, 12, 19);
      case InkGlyph.timer:
        canvas.drawCircle(const Offset(12, 13), 7.5, pen);
        line(12, 13, 12, 8.5);
        line(12, 13, 15, 14.5);
        line(10, 3, 14, 3);
    }
  }

  @override
  bool shouldRepaint(_InkPainter old) =>
      old.glyph != glyph || old.color != color;
}
