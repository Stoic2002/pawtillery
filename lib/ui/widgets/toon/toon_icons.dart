import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../app/toon_palette.dart';

/// Icons drawn in code as chunky strokes with a dark outline
/// (docs/art_style_guide.md: no Material icons on screen). Each glyph is
/// laid out in a 24 × 24 box.
enum ToonGlyph {
  pause,
  back,
  walkLeft,
  walkRight,
  jump,
  highJump,
  focus,
  dice,
  close,
  bag,
  play,
  replay,
  wind,
  timer,
  gear,
  question,
  info,
  home,
  check,
  plus,
  minus,
  people,
  trophy,
}

class ToonIcon extends StatelessWidget {
  const ToonIcon(
    this.glyph, {
    super.key,
    this.size = 24,
    this.color = ToonPalette.white,
    this.outline = ToonPalette.outline,
  });

  final ToonGlyph glyph;
  final double size;
  final Color color;
  final Color outline;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _ToonIconPainter(glyph, color, outline)),
  );
}

class _ToonIconPainter extends CustomPainter {
  _ToonIconPainter(this.glyph, this.color, this.outline);
  final ToonGlyph glyph;
  final Color color;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    // Outline pass, then the colour pass on top.
    _Glyph(canvas, outline, 2.6 + 2.8).draw(glyph);
    _Glyph(canvas, color, 2.6, outlinePass: false).draw(glyph);
  }

  @override
  bool shouldRepaint(_ToonIconPainter old) =>
      old.glyph != glyph || old.color != color || old.outline != outline;
}

/// Draws one glyph with a given stroke width; the outline pass also
/// strokes solid shapes so they get the same rim.
class _Glyph {
  _Glyph(this.canvas, Color color, double width, {this.outlinePass = true})
    : pen = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
      fill = Paint()..color = color,
      rim = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeJoin = StrokeJoin.round;

  final Canvas canvas;
  final Paint pen;
  final Paint fill;
  final Paint rim;
  final bool outlinePass;

  void line(double x1, double y1, double x2, double y2) =>
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), pen);

  void stroke(Path p) => canvas.drawPath(p, pen);

  void solid(Path p) {
    canvas.drawPath(p, fill);
    if (outlinePass) canvas.drawPath(p, rim);
  }

  void dot(double x, double y, double r) =>
      solid(Path()..addOval(Rect.fromCircle(center: Offset(x, y), radius: r)));

  void draw(ToonGlyph glyph) {
    switch (glyph) {
      case ToonGlyph.pause:
        solid(
          Path()
            ..addRRect(
              RRect.fromLTRBR(6, 5, 10.5, 19, const Radius.circular(1.5)),
            )
            ..addRRect(
              RRect.fromLTRBR(13.5, 5, 18, 19, const Radius.circular(1.5)),
            ),
        );
      case ToonGlyph.back:
        line(19, 12, 6, 12);
        line(11, 6.5, 5.5, 12);
        line(11, 17.5, 5.5, 12);
      case ToonGlyph.walkLeft || ToonGlyph.walkRight:
        final d = glyph == ToonGlyph.walkLeft ? -1.0 : 1.0;
        solid(
          Path()
            ..moveTo(12 - d * 6, 4.5)
            ..lineTo(12 + d * 7, 12)
            ..lineTo(12 - d * 6, 19.5)
            ..close(),
        );
      case ToonGlyph.jump:
        stroke(
          Path()
            ..moveTo(4, 18)
            ..quadraticBezierTo(9, 3, 19, 9),
        );
        line(19, 9, 14, 8);
        line(19, 9, 17, 13.5);
        line(3.5, 20.5, 20.5, 20.5);
      case ToonGlyph.highJump:
        line(12, 19, 12, 5);
        line(7, 10, 12, 5);
        line(17, 10, 12, 5);
        line(7, 15, 12, 10);
        line(17, 15, 12, 10);
        line(5, 21, 19, 21);
      case ToonGlyph.focus:
        canvas.drawCircle(const Offset(12, 12), 6.5, pen);
        dot(12, 12, 2);
        line(12, 2, 12, 5);
        line(12, 19, 12, 22);
        line(2, 12, 5, 12);
        line(19, 12, 22, 12);
      case ToonGlyph.dice:
        solid(
          Path()..addRRect(
            RRect.fromLTRBR(4, 4, 20, 20, const Radius.circular(3.5)),
          ),
        );
        if (!outlinePass) {
          final pip = Paint()..color = ToonPalette.outline;
          for (final (x, y) in const [(8.5, 8.5), (15.5, 15.5), (12.0, 12.0)]) {
            canvas.drawCircle(Offset(x, y), 1.6, pip);
          }
        }
      case ToonGlyph.close:
        line(6.5, 6.5, 17.5, 17.5);
        line(17.5, 6.5, 6.5, 17.5);
      case ToonGlyph.bag:
        stroke(
          Path()
            ..moveTo(8, 9)
            ..quadraticBezierTo(12, 2, 16, 9),
        );
        solid(
          Path()..addRRect(
            RRect.fromLTRBR(3.5, 9, 20.5, 20.5, const Radius.circular(3)),
          ),
        );
        if (!outlinePass) {
          canvas.drawRect(
            const Rect.fromLTWH(10.5, 12, 3, 3.5),
            Paint()..color = ToonPalette.outline,
          );
        }
      case ToonGlyph.play:
        solid(
          Path()
            ..moveTo(7.5, 4.5)
            ..lineTo(19.5, 12)
            ..lineTo(7.5, 19.5)
            ..close(),
        );
      case ToonGlyph.replay:
        canvas.drawArc(
          const Rect.fromLTWH(5, 5, 14, 14),
          -math.pi * 0.35,
          math.pi * 1.7,
          false,
          pen,
        );
        line(16.5, 3.5, 16.8, 8.2);
        line(16.8, 8.2, 12.4, 8.2);
      case ToonGlyph.wind:
        stroke(
          Path()
            ..moveTo(3, 9)
            ..lineTo(15, 9)
            ..quadraticBezierTo(19, 9, 18.5, 6)
            ..quadraticBezierTo(18, 3.5, 15.5, 4.5),
        );
        stroke(
          Path()
            ..moveTo(3, 14)
            ..lineTo(18, 14)
            ..quadraticBezierTo(21.5, 14, 21, 17.5)
            ..quadraticBezierTo(20.5, 20, 17.5, 19),
        );
        line(5, 19, 11, 19);
      case ToonGlyph.timer:
        solid(Path()..addOval(Rect.fromCircle(center: const Offset(12, 13.5), radius: 8)));
        line(9.5, 3, 14.5, 3);
        if (!outlinePass) {
          final hand = Paint()
            ..color = ToonPalette.outline
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round;
          canvas
            ..drawLine(const Offset(12, 13.5), const Offset(12, 8.5), hand)
            ..drawLine(const Offset(12, 13.5), const Offset(15, 15), hand);
        }
      case ToonGlyph.gear:
        final teeth = Path();
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          final c = Offset(12 + math.cos(a) * 8.2, 12 + math.sin(a) * 8.2);
          teeth.addOval(Rect.fromCircle(center: c, radius: 2.4));
        }
        teeth.addOval(Rect.fromCircle(center: const Offset(12, 12), radius: 7.2));
        solid(teeth);
        if (!outlinePass) {
          canvas.drawCircle(
            const Offset(12, 12),
            2.8,
            Paint()..color = ToonPalette.outline,
          );
        }
      case ToonGlyph.question:
        stroke(
          Path()
            ..moveTo(7.5, 8.5)
            ..quadraticBezierTo(7.5, 3.5, 12, 3.5)
            ..quadraticBezierTo(16.5, 3.5, 16.5, 8)
            ..quadraticBezierTo(16.5, 11, 12, 12.5)
            ..lineTo(12, 15),
        );
        dot(12, 19.5, 1.9);
      case ToonGlyph.info:
        dot(12, 5.5, 2.1);
        line(12, 10.5, 12, 19.5);
        line(9.5, 10.5, 12, 10.5);
        line(9, 19.5, 15, 19.5);
      case ToonGlyph.home:
        solid(
          Path()
            ..moveTo(3, 12)
            ..lineTo(12, 3.5)
            ..lineTo(21, 12)
            ..lineTo(18.5, 12)
            ..lineTo(18.5, 20.5)
            ..lineTo(5.5, 20.5)
            ..lineTo(5.5, 12)
            ..close(),
        );
        if (!outlinePass) {
          canvas.drawRRect(
            RRect.fromLTRBR(10, 14, 14, 20.5, const Radius.circular(1)),
            Paint()..color = ToonPalette.outline,
          );
        }
      case ToonGlyph.check:
        stroke(
          Path()
            ..moveTo(4.5, 12.5)
            ..lineTo(10, 18)
            ..lineTo(19.5, 6),
        );
      case ToonGlyph.plus:
        line(12, 5, 12, 19);
        line(5, 12, 19, 12);
      case ToonGlyph.minus:
        line(5, 12, 19, 12);
      case ToonGlyph.people:
        dot(8.5, 7.5, 3.4);
        dot(16, 8.5, 2.9);
        solid(
          Path()
            ..moveTo(2.5, 20)
            ..quadraticBezierTo(2.5, 12.5, 8.5, 12.5)
            ..quadraticBezierTo(14.5, 12.5, 14.5, 20)
            ..close(),
        );
        solid(
          Path()
            ..moveTo(14, 13.5)
            ..quadraticBezierTo(21.5, 12, 21.5, 20)
            ..lineTo(15.8, 20)
            ..quadraticBezierTo(15.8, 15.5, 14, 13.5)
            ..close(),
        );
      case ToonGlyph.trophy:
        solid(
          Path()
            ..moveTo(6, 3.5)
            ..lineTo(18, 3.5)
            ..lineTo(17.5, 9)
            ..quadraticBezierTo(16.5, 14, 12, 14)
            ..quadraticBezierTo(7.5, 14, 6.5, 9)
            ..close(),
        );
        stroke(
          Path()
            ..moveTo(6.2, 5.5)
            ..quadraticBezierTo(2.5, 5.5, 3.5, 8.5)
            ..quadraticBezierTo(4.5, 10.5, 7, 10.5),
        );
        stroke(
          Path()
            ..moveTo(17.8, 5.5)
            ..quadraticBezierTo(21.5, 5.5, 20.5, 8.5)
            ..quadraticBezierTo(19.5, 10.5, 17, 10.5),
        );
        line(12, 14, 12, 17.5);
        solid(
          Path()..addRRect(
            RRect.fromLTRBR(7.5, 17.5, 16.5, 21, const Radius.circular(1)),
          ),
        );
    }
  }
}
