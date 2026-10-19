import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../app/toon_palette.dart';

/// The painted farm-meadow scene behind every menu: warm sky, a big sun,
/// soft clouds, layered hills with lollipop trees, and a near hill with
/// grass and flowers. Static (painted once per size) so menus cost
/// nothing; [groundLine] is where the near hill's crest sits, as a
/// fraction of the height, so screens can stand animals on it.
class ToonBackdrop extends StatelessWidget {
  const ToonBackdrop({
    super.key,
    required this.child,
    this.groundLine = 0.8,
    this.dim = 0,
  });

  final Widget child;
  final double groundLine;

  /// Darkens the scene (0–1) behind busy screens so panels stand out.
  final double dim;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      RepaintBoundary(
        child: CustomPaint(painter: _MeadowPainter(groundLine, dim)),
      ),
      child,
    ],
  );
}

class _MeadowPainter extends CustomPainter {
  _MeadowPainter(this.groundLine, this.dim);
  final double groundLine;
  final double dim;

  static const _outline = ToonPalette.outline;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;
    final rng = math.Random(42);

    // Sky.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2E9BE0), Color(0xFF8ED3F5), Color(0xFFFFE7B0)],
          stops: [0, 0.55, 0.85],
        ).createShader(rect),
    );

    // Sun with soft rays.
    final sun = Offset(w * 0.84, h * 0.2);
    final sunR = h * 0.085;
    final rays = Paint()..color = const Color(0x22FFF6C8);
    for (var i = 0; i < 14; i++) {
      final a = i * math.pi / 7;
      canvas.drawPath(
        Path()
          ..moveTo(sun.dx, sun.dy)
          ..lineTo(
            sun.dx + math.cos(a - 0.09) * w,
            sun.dy + math.sin(a - 0.09) * w,
          )
          ..lineTo(
            sun.dx + math.cos(a + 0.09) * w,
            sun.dy + math.sin(a + 0.09) * w,
          )
          ..close(),
        rays,
      );
    }
    canvas
      ..drawCircle(
        sun,
        sunR * 2.4,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFFF3B0).withValues(alpha: 0.75),
              const Color(0x00FFF3B0),
            ],
          ).createShader(Rect.fromCircle(center: sun, radius: sunR * 2.4)),
      )
      ..drawCircle(sun, sunR, Paint()..color = const Color(0xFFFFE066))
      ..drawCircle(
        sun.translate(-sunR * 0.15, -sunR * 0.15),
        sunR * 0.78,
        Paint()..color = const Color(0xFFFFF2A8),
      );

    // Clouds: far ones small and pale.
    for (var i = 0; i < 6; i++) {
      final far = i < 3;
      final c = Offset(
        w * (0.06 + i * 0.17 + rng.nextDouble() * 0.06),
        h * (far ? 0.1 + rng.nextDouble() * 0.12 : 0.2 + rng.nextDouble() * 0.16),
      );
      _cloud(canvas, c, h * (far ? 0.045 : 0.07), far, rng);
    }

    // Distant blue ridge.
    _hill(
      canvas,
      size,
      base: h * 0.6,
      amp: h * 0.08,
      freq: 2.3,
      phase: 0.7,
      fill: const Color(0xFF8CC7E2),
      line: null,
    );
    // Far hills with tiny trees.
    final farHill = _hill(
      canvas,
      size,
      base: h * 0.66,
      amp: h * 0.05,
      freq: 3.1,
      phase: 2.1,
      fill: const Color(0xFF9ED27A),
      line: null,
    );
    for (var i = 0; i < 9; i++) {
      final x = w * (0.04 + i * 0.115 + rng.nextDouble() * 0.04);
      _tree(canvas, Offset(x, farHill(x) + 2), h * 0.022,
          const Color(0xFF6DB255), outlined: false);
    }
    // Middle hills, outlined, with lollipop trees and a fence line.
    final midHill = _hill(
      canvas,
      size,
      base: h * (groundLine - 0.07),
      amp: h * 0.055,
      freq: 2.0,
      phase: 4.0,
      fill: const Color(0xFF6CC04A),
      line: const Color(0xFF2E6B22),
    );
    for (final fx in [0.12, 0.3, 0.58, 0.9]) {
      final x = w * (fx + rng.nextDouble() * 0.04);
      _tree(canvas, Offset(x, midHill(x) + 3), h * 0.04,
          const Color(0xFF4FA83A));
    }
    final post = Paint()..color = const Color(0xFFB98552);
    final postLine = Paint()
      ..color = _outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (var x = w * 0.62; x < w * 0.82; x += h * 0.03) {
      final y = midHill(x);
      final r = Rect.fromLTWH(x, y - h * 0.035, h * 0.008, h * 0.04);
      canvas
        ..drawRect(r, post)
        ..drawRect(r, postLine);
    }
    for (final t in [0.4, 0.75]) {
      final p = Path();
      for (var x = w * 0.62; x <= w * 0.82; x += 4) {
        final y = midHill(x) - h * 0.035 * t;
        x == w * 0.62 ? p.moveTo(x, y) : p.lineTo(x, y);
      }
      canvas.drawPath(
        p,
        Paint()
          ..color = const Color(0xFFB98552)
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * 0.006,
      );
    }

    // Near hill: bright, outlined, with a lit crest.
    final near = _hill(
      canvas,
      size,
      base: h * groundLine,
      amp: h * 0.03,
      freq: 1.4,
      phase: 1.2,
      fill: const Color(0xFF8AD84E),
      line: _outline,
      bottom: const Color(0xFF4C9A2C),
    );
    final tuft = Paint()
      ..color = const Color(0xFF3F8A25)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 70; i++) {
      final x = rng.nextDouble() * w;
      final y = near(x) + 6 + rng.nextDouble() * (h - near(x)) * 0.8;
      for (final d in [-3.0, 0.0, 3.0]) {
        canvas.drawLine(Offset(x, y), Offset(x + d, y - 6 - rng.nextDouble() * 3), tuft);
      }
    }
    final petals = [
      const Color(0xFFFFFFFF),
      const Color(0xFFFFD23F),
      const Color(0xFFFF7EB6),
    ];
    for (var i = 0; i < 22; i++) {
      final x = rng.nextDouble() * w;
      final y = near(x) + 10 + rng.nextDouble() * (h - near(x)) * 0.75;
      final r = 2.2 + rng.nextDouble() * 1.4;
      final petal = Paint()..color = petals[i % petals.length];
      for (var k = 0; k < 5; k++) {
        final a = k * math.pi * 2 / 5;
        canvas.drawCircle(Offset(x + math.cos(a) * r, y + math.sin(a) * r), r * 0.75, petal);
      }
      canvas.drawCircle(Offset(x, y), r * 0.6, Paint()..color = const Color(0xFFE8901A));
    }

    // Soft vignette, plus optional dimming for busy screens.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 1.1,
          colors: [
            const Color(0x00000000),
            const Color(0x00000000),
            const Color(0xFF0B2233).withValues(alpha: 0.35),
          ],
          stops: const [0, 0.65, 1],
        ).createShader(rect),
    );
    if (dim > 0) {
      canvas.drawRect(
        rect,
        Paint()..color = const Color(0xFF0E1A24).withValues(alpha: dim),
      );
    }
  }

  /// Fills a sine-ish hill from [base] down to the bottom; returns its
  /// crest height at any x.
  double Function(double) _hill(
    Canvas canvas,
    Size size, {
    required double base,
    required double amp,
    required double freq,
    required double phase,
    required Color fill,
    required Color? line,
    Color? bottom,
  }) {
    double crest(double x) {
      final t = x / size.width * math.pi * 2;
      return base -
          amp * (math.sin(t * freq + phase) * 0.7 + math.sin(t * freq * 2.3 + phase * 1.7) * 0.3);
    }

    final path = Path()..moveTo(-4, size.height + 4);
    for (var x = -4.0; x <= size.width + 4; x += 6) {
      path.lineTo(x, crest(x));
    }
    path
      ..lineTo(size.width + 4, size.height + 4)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [fill, bottom ?? fill],
        ).createShader(Rect.fromLTRB(0, base - amp, size.width, size.height)),
    );
    if (line != null) {
      // Lit crest just under the outline.
      final crestPath = Path();
      for (var x = -4.0; x <= size.width + 4; x += 6) {
        x == -4 ? crestPath.moveTo(x, crest(x) + 4) : crestPath.lineTo(x, crest(x) + 4);
      }
      canvas
        ..drawPath(
          crestPath,
          Paint()
            ..color = const Color(0x55FFFFFF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        )
        ..drawPath(
          path,
          Paint()
            ..color = line
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeJoin = StrokeJoin.round,
        );
    }
    return crest;
  }

  void _cloud(Canvas canvas, Offset c, double r, bool far, math.Random rng) {
    final puffs = <(Offset, double)>[
      (c, r),
      (c.translate(-r * 1.1, r * 0.3), r * 0.72),
      (c.translate(r * 1.1, r * 0.25), r * 0.8),
      (c.translate(r * 0.4, -r * 0.45), r * 0.75),
      (c.translate(-r * 1.9, r * 0.5), r * 0.45),
      (c.translate(r * 2.0, r * 0.5), r * 0.5),
    ];
    final shade = Paint()
      ..color = far ? const Color(0x99D7EEFA) : const Color(0xFFCFE6F5);
    final body = Paint()
      ..color = far ? const Color(0xCCFFFFFF) : const Color(0xFFFFFFFF);
    for (final (p, pr) in puffs) {
      canvas.drawCircle(p.translate(0, pr * 0.18), pr, shade);
    }
    for (final (p, pr) in puffs) {
      canvas.drawCircle(p.translate(0, -pr * 0.05), pr * 0.92, body);
    }
  }

  void _tree(
    Canvas canvas,
    Offset foot,
    double r,
    Color leaf, {
    bool outlined = true,
  }) {
    final trunk = Rect.fromCenter(
      center: foot.translate(0, -r * 0.7),
      width: r * 0.35,
      height: r * 1.5,
    );
    final crown = foot.translate(0, -r * 1.8);
    final line = Paint()
      ..color = outlined ? _outline : leaf
      ..style = PaintingStyle.stroke
      ..strokeWidth = outlined ? 2 : 0;
    canvas.drawRect(trunk, Paint()..color = const Color(0xFF8A5A33));
    if (outlined) canvas.drawRect(trunk, line);
    canvas.drawCircle(crown, r, Paint()..color = leaf);
    canvas.drawCircle(
      crown.translate(-r * 0.25, -r * 0.3),
      r * 0.55,
      Paint()..color = Color.lerp(leaf, const Color(0xFFFFFFFF), 0.25)!,
    );
    if (outlined) canvas.drawCircle(crown, r, line);
  }

  @override
  bool shouldRepaint(_MeadowPainter old) =>
      old.groundLine != groundLine || old.dim != dim;
}
