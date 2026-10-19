import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../app/toon_palette.dart';
import 'toon_text.dart';

/// The game's wordmark: bouncing sun-yellow letters with a thick outline,
/// led by a paw-print badge. Read by screen readers as plain [title].
class ToonLogo extends StatelessWidget {
  const ToonLogo({super.key, required this.title, this.size = 60});

  final String title;
  final double size;

  @override
  Widget build(BuildContext context) {
    final letters = title.toUpperCase().split('');
    return Semantics(
      label: title,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Transform.rotate(
            angle: -0.2,
            child: SizedBox.square(
              dimension: size * 0.95,
              child: const CustomPaint(painter: PawBadgePainter()),
            ),
          ),
          SizedBox(width: size * 0.12),
          for (final (i, l) in letters.indexed)
            Transform.translate(
              offset: Offset(0, math.sin(i * 1.3) * size * 0.06),
              child: Transform.rotate(
                angle: math.sin(i * 2.1 + 0.4) * 0.07,
                child: ToonText(
                  l,
                  size: size,
                  color: i.isEven ? ToonPalette.sun : const Color(0xFFFFDE5C),
                  outlineWidth: size * 0.085,
                  drop: size * 0.09,
                  letterSpacing: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A paw print in a round orange badge.
class PawBadgePainter extends CustomPainter {
  const PawBadgePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = size.center(Offset.zero);
    final line = Paint()
      ..color = ToonPalette.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.07;
    final r = s * 0.44;
    canvas
      ..drawCircle(c.translate(0, s * 0.06), r, Paint()..color = ToonPalette.outline)
      ..drawCircle(
        c,
        r,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ToonPalette.tomato, ToonPalette.tomatoDeep],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      )
      ..drawCircle(c, r, line);
    final paw = Paint()..color = ToonPalette.white;
    final pawLine = Paint()
      ..color = ToonPalette.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.04;
    final pad = Rect.fromCenter(
      center: c.translate(0, s * 0.1),
      width: s * 0.36,
      height: s * 0.28,
    );
    final toes = [
      for (final (dx, dy) in const [(-0.17, -0.07), (-0.06, -0.16), (0.06, -0.16), (0.17, -0.07)])
        Rect.fromCircle(center: c.translate(dx * s, dy * s), radius: s * 0.065),
    ];
    for (final t in toes) {
      canvas
        ..drawOval(t, paw)
        ..drawOval(t, pawLine);
    }
    canvas
      ..drawOval(pad, paw)
      ..drawOval(pad, pawLine);
  }

  @override
  bool shouldRepaint(PawBadgePainter old) => false;
}
