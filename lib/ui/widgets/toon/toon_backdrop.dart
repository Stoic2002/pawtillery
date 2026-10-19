import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The painted scene behind every menu: a battlefield at dusk. A deep blue
/// sky burning orange at the horizon, a rising moon, stars, a ruined castle
/// on a far crag, smoke from distant fires, layered dark hills with bare
/// trees, fog, and a near hill with a moonlit rim for the animals to stand
/// on. Static (painted once per size) so menus cost nothing; [groundLine]
/// is where the near hill's crest sits, as a fraction of the height.
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
        child: CustomPaint(painter: _DuskPainter(groundLine, dim)),
      ),
      child,
    ],
  );
}

class _DuskPainter extends CustomPainter {
  _DuskPainter(this.groundLine, this.dim);
  final double groundLine;
  final double dim;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;
    final rng = math.Random(7);

    // Sky: night blue overhead, violet, then a burning horizon.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0B1024),
            Color(0xFF2A2350),
            Color(0xFF7A3A4A),
            Color(0xFFD2703C),
          ],
          stops: [0, 0.45, 0.68, 0.82],
        ).createShader(rect),
    );

    // Stars in the upper sky.
    final star = Paint();
    for (var i = 0; i < 70; i++) {
      final p = Offset(rng.nextDouble() * w, rng.nextDouble() * h * 0.45);
      star.color = const Color(
        0xFFFFFFFF,
      ).withValues(alpha: 0.25 + rng.nextDouble() * 0.6);
      canvas.drawCircle(p, 0.6 + rng.nextDouble() * 1.1, star);
    }

    // Moon with a cold glow.
    final moon = Offset(w * 0.8, h * 0.2);
    final mr = h * 0.075;
    canvas
      ..drawCircle(
        moon,
        mr * 4,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFBFCBFF).withValues(alpha: 0.4),
              const Color(0x00BFCBFF),
            ],
          ).createShader(Rect.fromCircle(center: moon, radius: mr * 4)),
      )
      ..drawCircle(moon, mr, Paint()..color = const Color(0xFFF1EED8));
    final crater = Paint()..color = const Color(0x22808070);
    for (final (dx, dy, r) in const [
      (-0.3, -0.2, 0.22),
      (0.25, 0.15, 0.28),
      (-0.05, 0.45, 0.14),
    ]) {
      canvas.drawCircle(moon.translate(dx * mr, dy * mr), r * mr, crater);
    }

    // Distant ridge with a ruined castle on a crag.
    _hill(
      canvas,
      size,
      base: h * 0.6,
      amp: h * 0.07,
      freq: 2.2,
      phase: 0.6,
      color: const Color(0xFF3A2A4A),
    );
    _castle(
      canvas,
      Offset(w * 0.56, h * 0.56),
      h * 0.28,
      const Color(0xFF2A1F3A),
    );

    // Smoke rising from fires beyond the hills.
    for (final fx in [0.18, 0.42, 0.7]) {
      for (var k = 0; k < 14; k++) {
        final t = k / 13;
        final r = h * (0.03 + t * 0.09);
        final p = Offset(w * fx + t * t * w * 0.08, h * (0.62 - t * 0.5));
        canvas.drawCircle(
          p,
          r,
          Paint()
            ..shader = RadialGradient(
              colors: [
                const Color(0xFF241C2A).withValues(alpha: 0.34 * (1 - t * 0.5)),
                const Color(0x00241C2A),
              ],
            ).createShader(Rect.fromCircle(center: p, radius: r)),
        );
      }
    }

    // Fog band over the far valley.
    _fog(canvas, size, h * 0.66, h * 0.14, const Color(0x55C8A0B4));

    // Middle hills with bare trees and gravestones, in silhouette.
    final mid = _hill(
      canvas,
      size,
      base: h * (groundLine - 0.08),
      amp: h * 0.05,
      freq: 1.8,
      phase: 3.6,
      color: const Color(0xFF1E1830),
    );
    for (final fx in [0.08, 0.33, 0.9]) {
      final x = w * (fx + rng.nextDouble() * 0.04);
      _bareTree(
        canvas,
        Offset(x, mid(x) + 4),
        h * 0.16,
        const Color(0xFF1E1830),
      );
    }
    final stone = Paint()..color = const Color(0xFF1E1830);
    for (var i = 0; i < 6; i++) {
      final x = w * (0.6 + i * 0.045);
      final gh = h * (0.03 + rng.nextDouble() * 0.02);
      canvas
        ..save()
        ..translate(x, mid(x) + 3)
        ..rotate((rng.nextDouble() - 0.5) * 0.3)
        ..drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(-gh * 0.35, -gh, gh * 0.7, gh + 4),
            topLeft: Radius.circular(gh * 0.35),
            topRight: Radius.circular(gh * 0.35),
          ),
          stone,
        )
        ..restore();
    }

    // Near hill: dark ground with a moonlit rim and grass blades.
    final near = _hill(
      canvas,
      size,
      base: h * groundLine,
      amp: h * 0.025,
      freq: 1.3,
      phase: 1.1,
      color: const Color(0xFF14101E),
      bottom: const Color(0xFF0A0812),
    );
    final rim = Path();
    for (var x = 0.0; x <= w; x += 4) {
      x == 0 ? rim.moveTo(x, near(x) + 1) : rim.lineTo(x, near(x) + 1);
    }
    canvas.drawPath(
      rim,
      Paint()
        ..color = const Color(0xFF6E6AA0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    final blade = Paint()
      ..color = const Color(0xFF2E2A48)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 160; i++) {
      final x = rng.nextDouble() * w;
      final y = near(x) + 1;
      canvas.drawLine(
        Offset(x, y),
        Offset(x + (rng.nextDouble() - 0.5) * 5, y - 3 - rng.nextDouble() * 7),
        blade,
      );
    }

    // Embers drifting up.
    final ember = Paint()..blendMode = BlendMode.plus;
    for (var i = 0; i < 40; i++) {
      ember.color =
          (i.isEven ? const Color(0xFFFF8A3A) : const Color(0xFFFFC46A))
              .withValues(alpha: 0.3 + rng.nextDouble() * 0.5);
      canvas.drawCircle(
        Offset(rng.nextDouble() * w, h * (0.35 + rng.nextDouble() * 0.5)),
        0.8 + rng.nextDouble() * 1.4,
        ember,
      );
    }

    // Vignette, plus optional dimming for busy screens.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 1.05,
          colors: [
            const Color(0x00000000),
            const Color(0x00000000),
            const Color(0xFF05040A).withValues(alpha: 0.55),
          ],
          stops: const [0, 0.6, 1],
        ).createShader(rect),
    );
    if (dim > 0) {
      canvas.drawRect(
        rect,
        Paint()..color = const Color(0xFF07060E).withValues(alpha: dim),
      );
    }
  }

  /// Fills a wavy hill from [base] down; returns its crest at any x.
  double Function(double) _hill(
    Canvas canvas,
    Size size, {
    required double base,
    required double amp,
    required double freq,
    required double phase,
    required Color color,
    Color? bottom,
  }) {
    double crest(double x) {
      final t = x / size.width * math.pi * 2;
      return base -
          amp *
              (math.sin(t * freq + phase) * 0.7 +
                  math.sin(t * freq * 2.3 + phase * 1.7) * 0.3);
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
          colors: [color, bottom ?? color],
        ).createShader(Rect.fromLTRB(0, base - amp, size.width, size.height)),
    );
    return crest;
  }

  void _fog(Canvas canvas, Size size, double y, double h, Color color) {
    final r = Rect.fromLTWH(0, y - h / 2, size.width, h);
    canvas.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0),
            color,
            color.withValues(alpha: 0),
          ],
        ).createShader(r),
    );
  }

  /// A crag topped by a broken castle: keep, two towers, one lit window.
  void _castle(Canvas canvas, Offset foot, double s, Color color) {
    final p = Paint()..color = color;
    canvas.drawPath(
      Path()
        ..moveTo(foot.dx - s * 0.7, foot.dy + s * 0.2)
        ..lineTo(foot.dx - s * 0.25, foot.dy - s * 0.25)
        ..lineTo(foot.dx + s * 0.3, foot.dy - s * 0.28)
        ..lineTo(foot.dx + s * 0.75, foot.dy + s * 0.2)
        ..close(),
      p,
    );
    final base = foot.dy - s * 0.26;
    for (final (dx, tw, th, broken) in [
      (-0.32, 0.14, 0.5, false),
      (-0.1, 0.32, 0.36, false),
      (0.24, 0.13, 0.58, true),
    ]) {
      final r = Rect.fromLTWH(foot.dx + dx * s, base - th * s, tw * s, th * s);
      canvas.drawRect(r, p);
      if (broken) {
        canvas.drawPath(
          Path()
            ..moveTo(r.left, r.top)
            ..lineTo(r.left + r.width * 0.3, r.top - s * 0.06)
            ..lineTo(r.left + r.width * 0.55, r.top + s * 0.02)
            ..lineTo(r.right, r.top - s * 0.04)
            ..lineTo(r.right, r.top)
            ..close(),
          p,
        );
      } else {
        for (var k = 0; k < 3; k++) {
          canvas.drawRect(
            Rect.fromLTWH(
              r.left + k * r.width / 2.5,
              r.top - s * 0.035,
              r.width / 5,
              s * 0.035,
            ),
            p,
          );
        }
      }
    }
    canvas.drawRect(
      Rect.fromLTWH(foot.dx + 0.02 * s, base - 0.24 * s, 0.035 * s, 0.05 * s),
      Paint()..color = const Color(0xFFFFB45A),
    );
  }

  void _bareTree(Canvas canvas, Offset foot, double h, Color color) {
    final branch = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      foot,
      foot.translate(0, -h),
      branch..strokeWidth = h * 0.07,
    );
    for (var k = 0; k < 4; k++) {
      final y = foot.dy - h * (0.4 + k * 0.15);
      final side = k.isEven ? 1 : -1;
      canvas.drawLine(
        Offset(foot.dx, y),
        Offset(foot.dx + side * h * 0.35 * (1 - k * 0.15), y - h * 0.2),
        branch..strokeWidth = h * 0.03,
      );
    }
  }

  @override
  bool shouldRepaint(_DuskPainter old) =>
      old.groundLine != groundLine || old.dim != dim;
}
