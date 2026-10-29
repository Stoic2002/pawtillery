import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The sky behind menus: a painted meadow at golden hour. A soft sun, a
/// few fluffy clouds, hazy mountains and a tree line in the distance, and
/// grassy hills in front, all without outlines and fading towards the sky
/// with distance, so the cards and buttons on top stay the loudest thing.
/// [hills] picks the front hills' layout: the menu's (a light hill to the
/// right, a green one to the left that the pets stand on), the splash's,
/// or none (only low, faint hills on the horizon).
///
/// The main menu ([PawHills.menu]) shows the painted meadow from
/// `assets/menu/background.webp` instead, once [PawBackdrop.load] has
/// read it (tool/art/convert_art.py); without it, the code-drawn one.
enum PawHills { menu, splash, none }

class PawBackdrop extends StatelessWidget {
  const PawBackdrop({
    super.key,
    required this.child,
    this.hills = PawHills.none,
    this.clouds = true,
  });

  final Widget child;
  final PawHills hills;
  final bool clouds;

  static ui.Image? _painting;

  /// Reads the main menu's painting, once, before the first frame (so it
  /// never pops in over the code-drawn meadow).
  static Future<void> load() async {
    try {
      final data = await rootBundle.load('assets/menu/background.webp');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      _painting = (await codec.getNextFrame()).image;
      codec.dispose();
    } on Object catch (e) {
      debugPrint('Menu background not loaded: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final painting = hills == PawHills.menu ? _painting : null;
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: painting != null
              // The hill the pets stand on is at its left: keep that edge.
              ? RawImage(
                  image: painting,
                  fit: BoxFit.cover,
                  alignment: Alignment.centerLeft,
                  filterQuality: FilterQuality.medium,
                )
              : CustomPaint(painter: _MeadowPainter(hills, clouds)),
        ),
        child,
      ],
    );
  }
}

class _MeadowPainter extends CustomPainter {
  _MeadowPainter(this.hills, this.clouds);

  final PawHills hills;
  final bool clouds;

  // Palette: sky, haze and grass, warm towards the horizon.
  static const _skyTop = Color(0xFF5FB0EC);
  static const _skyMid = Color(0xFFA6D7F4);
  static const _skyLow = Color(0xFFF7E9D2);
  static const _mountain = Color(0xFFB4CBE3);
  static const _mountainShade = Color(0xFFA3BCD9);
  static const _treeLine = Color(0xFF9CC7A4);
  static const _backTop = Color(0xFFB2DC8A);
  static const _backBottom = Color(0xFF8BC66A);
  static const _frontTop = Color(0xFF93D370);
  static const _frontBottom = Color(0xFF63AE4A);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;
    final horizon = switch (hills) {
      PawHills.menu => 0.6 * h,
      PawHills.splash => 0.64 * h,
      PawHills.none => 0.84 * h,
    };

    _sky(canvas, size, horizon);
    if (clouds) _clouds(canvas, w, h);
    _mountains(canvas, w, h, horizon);
    _trees(canvas, w, h, horizon);
    switch (hills) {
      case PawHills.menu:
        _hill(
          canvas,
          Rect.fromLTWH(w * 0.28, h * 0.66, w * 0.95, h),
          back: true,
        );
        _hill(
          canvas,
          Rect.fromLTWH(-w * 0.12, h * 0.63, w * 0.72, h * 0.95),
          back: false,
        );
      case PawHills.splash:
        _hill(
          canvas,
          Rect.fromLTWH(w * 0.4, h * 0.74, w * 0.72, h),
          back: true,
        );
        _hill(
          canvas,
          Rect.fromLTWH(-w * 0.1, h * 0.7, w * 0.7, h),
          back: false,
        );
      case PawHills.none:
        _meadowStrip(canvas, w, h, horizon);
    }
  }

  void _sky(Canvas canvas, Size size, double horizon) {
    final h = size.height;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [_skyTop, _skyMid, _skyLow],
          stops: [0, (horizon / h) * 0.7, horizon / h],
        ).createShader(rect),
    );
    // A soft sun high in the middle, its warmth spreading over the sky.
    final sun = Offset(size.width * 0.56, h * 0.14);
    canvas
      ..drawCircle(
        sun,
        h * 0.75,
        Paint()
          ..shader = RadialGradient(
            colors: const [Color(0x55FFF4D6), Color(0x00FFF4D6)],
          ).createShader(Rect.fromCircle(center: sun, radius: h * 0.75)),
      )
      ..drawCircle(
        sun,
        h * 0.16,
        Paint()
          ..shader = RadialGradient(
            colors: const [Color(0xCCFFFBEF), Color(0x00FFFBEF)],
          ).createShader(Rect.fromCircle(center: sun, radius: h * 0.16)),
      )
      ..drawCircle(sun, h * 0.045, Paint()..color = const Color(0xF2FFFCF2));
  }

  void _clouds(Canvas canvas, double w, double h) {
    final s = h / 400;
    _cloud(canvas, Offset(w * 0.15, h * 0.13), 46 * s, 0.95);
    _cloud(canvas, Offset(w * 0.42, h * 0.28), 30 * s, 0.75);
    _cloud(canvas, Offset(w * 0.86, h * 0.1), 40 * s, 0.9);
    _cloud(canvas, Offset(w * 0.7, h * 0.36), 22 * s, 0.55);
  }

  /// A fluffy cumulus: overlapping puffs on a flat base, white on top and
  /// a cool grey-blue underneath. [r] is the biggest puff's radius.
  void _cloud(Canvas canvas, Offset c, double r, double opacity) {
    final puffs = Path()
      ..addOval(
        Rect.fromCircle(
          center: c + Offset(-1.25 * r, 0.25 * r),
          radius: 0.55 * r,
        ),
      )
      ..addOval(
        Rect.fromCircle(
          center: c + Offset(-0.6 * r, -0.2 * r),
          radius: 0.75 * r,
        ),
      )
      ..addOval(
        Rect.fromCircle(center: c + Offset(0.2 * r, -0.35 * r), radius: r),
      )
      ..addOval(
        Rect.fromCircle(
          center: c + Offset(1.05 * r, 0.05 * r),
          radius: 0.68 * r,
        ),
      )
      ..addOval(
        Rect.fromCircle(
          center: c + Offset(1.6 * r, 0.35 * r),
          radius: 0.42 * r,
        ),
      )
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(c.dx - 1.7 * r, c.dy, c.dx + 1.95 * r, c.dy + 0.8 * r),
          Radius.circular(0.4 * r),
        ),
      );
    final bounds = puffs.getBounds();
    canvas
      ..saveLayer(
        bounds.inflate(4),
        Paint()..color = Color.fromRGBO(0, 0, 0, opacity),
      )
      ..drawPath(
        puffs,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const [Colors.white, Color(0xFFFBFDFF), Color(0xFFDCE8F4)],
            stops: const [0, 0.55, 1],
          ).createShader(bounds),
      )
      ..restore();
  }

  /// Two ranges of hazy mountains on the horizon, the far one paler.
  void _mountains(Canvas canvas, double w, double h, double horizon) {
    final far = hills == PawHills.none ? 0.1 * h : 0.2 * h;
    void range(double base, double height, int seed, Color color) {
      final rnd = math.Random(seed);
      final path = Path()..moveTo(0, base);
      var x = 0.0;
      var y = base - height * (0.4 + rnd.nextDouble() * 0.4);
      path.lineTo(0, y);
      while (x < w) {
        final step = w * (0.08 + rnd.nextDouble() * 0.1);
        final peak = base - height * (0.45 + rnd.nextDouble() * 0.55);
        final mid = x + step / 2;
        path.quadraticBezierTo(mid - step * 0.15, peak, mid, peak);
        x += step;
        y = base - height * (0.25 + rnd.nextDouble() * 0.35);
        path.quadraticBezierTo(mid + step * 0.15, peak, x, y);
      }
      path
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }

    range(horizon, far, 3, _mountain.withValues(alpha: 0.75));
    range(
      horizon + far * 0.15,
      far * 0.65,
      11,
      _mountainShade.withValues(alpha: 0.7),
    );
    // Haze settling at the foot of the mountains.
    final fog = Rect.fromLTWH(0, horizon - far * 0.45, w, far * 0.7);
    canvas.drawRect(
      fog,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00F7E9D2), Color(0x99F7E9D2), Color(0x00F7E9D2)],
        ).createShader(fog),
    );
  }

  /// A gentle rolling ridge of rounded trees just below the horizon.
  void _trees(Canvas canvas, double w, double h, double horizon) {
    final base = horizon + h * 0.02;
    final paint = Paint()..color = _treeLine;
    final ridge = Path()..moveTo(0, base);
    for (var x = 0.0; x <= w; x += 8) {
      ridge.lineTo(x, base - math.sin(x / w * math.pi * 3) * h * 0.012);
    }
    ridge
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(ridge, paint);
    final rnd = math.Random(5);
    final r0 = h * 0.022;
    for (var x = -r0; x < w + r0;) {
      final r = r0 * (0.6 + rnd.nextDouble() * 0.7);
      final y = base - math.sin(x / w * math.pi * 3) * h * 0.012;
      canvas.drawCircle(Offset(x, y - r * 0.4), r, paint);
      x += r * (1.1 + rnd.nextDouble() * 1.4);
    }
  }

  /// A grassy hill: an ellipse lit from above with a pale rim on its
  /// crest, the near one with grass tufts and a few flowers.
  void _hill(Canvas canvas, Rect r, {required bool back}) {
    final oval = Path()..addOval(r);
    final top = back ? _backTop : _frontTop;
    final bottom = back ? _backBottom : _frontBottom;
    final lit = Rect.fromLTWH(r.left, r.top, r.width, r.height * 0.4);
    canvas
      // Contact shadow on whatever is behind.
      ..drawPath(
        oval.shift(const Offset(0, -3)),
        Paint()
          ..color = const Color(0x22355E2A)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      )
      ..drawPath(
        oval,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [top, bottom],
          ).createShader(lit),
      )
      ..save()
      ..clipPath(oval)
      ..drawOval(
        r.deflate(2).shift(const Offset(0, 4)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..color = const Color(0x55F4FFE0)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      )
      ..restore();
    if (back) return;

    // Grass tufts along the crest, and flowers dotted below it.
    final cx = r.center.dx;
    final cy = r.center.dy;
    final a = r.width / 2;
    final b = r.height / 2;
    double crest(double x) {
      final t = ((x - cx) / a).clamp(-1.0, 1.0);
      return cy - b * math.sqrt(1 - t * t);
    }

    final rnd = math.Random(9);
    final blade = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;
    for (
      var x = r.left + a * 0.15;
      x < r.right - a * 0.15;
      x += 9 + rnd.nextDouble() * 10
    ) {
      final y = crest(x) + 1.5;
      final tall = 4 + rnd.nextDouble() * 5;
      blade.color = rnd.nextBool()
          ? const Color(0xFF6CB651)
          : const Color(0xFFA9E07F);
      for (final lean in const [-0.5, 0.0, 0.5]) {
        canvas.drawLine(
          Offset(x + lean * 3, y),
          Offset(x + lean * 6, y - tall * (lean == 0 ? 1.2 : 0.85)),
          blade,
        );
      }
    }
    const petals = [Color(0xFFFFFFFF), Color(0xFFFFE07A), Color(0xFFFFB3C1)];
    for (var i = 0; i < 26; i++) {
      final x = r.left + a * 0.3 + rnd.nextDouble() * a * 1.4;
      final y = crest(x) + 14 + rnd.nextDouble() * r.height * 0.3;
      final s = 1.6 + rnd.nextDouble() * 1.4;
      canvas
        ..drawCircle(
          Offset(x, y),
          s,
          Paint()..color = petals[i % petals.length],
        )
        ..drawCircle(
          Offset(x, y),
          s * 0.4,
          Paint()..color = const Color(0xFFF5B700),
        );
    }
  }

  /// Without front hills: a low, soft meadow along the bottom edge.
  void _meadowStrip(Canvas canvas, double w, double h, double horizon) {
    final base = horizon + h * 0.05;
    final path = Path()..moveTo(0, base);
    for (var x = 0.0; x <= w; x += 8) {
      path.lineTo(x, base - math.sin(x / w * math.pi * 2 + 0.6) * h * 0.02);
    }
    path
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    final rect = Rect.fromLTWH(0, base - h * 0.03, w, h - base + h * 0.03);
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_backTop, _backBottom],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_MeadowPainter old) =>
      old.hills != hills || old.clouds != clouds;
}
