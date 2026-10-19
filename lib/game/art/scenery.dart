import 'dart:math' as math;
import 'dart:ui' as ui;

import '../../config/maps.dart';

/// One background layer: a picture in world-sized coordinates and how fast
/// it follows the camera (0 = fixed to the sky, 1 = moves with the world).
class SceneryLayer {
  const SceneryLayer(this.picture, this.parallax);
  final ui.Picture picture;
  final double parallax;
}

/// Painted-cartoon backdrops per map theme (docs/art_style_guide.md):
/// layered silhouettes that fade towards the sky colour with distance;
/// the nearer layers get a soft outline like the terrain. Visual only;
/// uses its own RNG seeded from the map id.
abstract final class Scenery {
  static List<SceneryLayer> build(MapDef map, double width, double height) {
    final rng = math.Random(_seed(map.id));
    return switch (map.theme) {
      MapTheme.farm => [
        SceneryLayer(
          _ridge(map, rng, width, height, 0.5, 90, 0xFF6E9BC9, 0.55),
          0.15,
        ),
        SceneryLayer(_fields(map, rng, width, height), 0.35),
        SceneryLayer(_trees(map, rng, width, height), 0.6),
      ],
      MapTheme.coast => [
        SceneryLayer(_sea(map, rng, width, height), 0.1),
        SceneryLayer(_islands(map, rng, width, height), 0.25),
        SceneryLayer(_boats(map, rng, width, height), 0.4),
      ],
      MapTheme.snow => [
        SceneryLayer(_peaks(map, rng, width, height, far: true), 0.15),
        SceneryLayer(_peaks(map, rng, width, height, far: false), 0.35),
        SceneryLayer(_pines(map, rng, width, height), 0.6),
      ],
    };
  }

  static int _seed(String id) =>
      id.codeUnits.fold(17, (h, c) => (h * 31 + c) & 0x7FFFFFFF);

  /// Sky-tinted version of [argb]: further = closer to the sky.
  static ui.Color _haze(MapDef map, int argb, double distance) =>
      ui.Color.lerp(ui.Color(argb), ui.Color(map.skyBottomArgb), distance)!;

  static ui.Paint _line(ui.Color c, double w) => ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeJoin = ui.StrokeJoin.round
    ..color = c;

  static ui.Picture _record(void Function(ui.Canvas) draw) {
    final r = ui.PictureRecorder();
    draw(ui.Canvas(r));
    return r.endRecording();
  }

  /// A filled hill line from [base] (fraction of height) to the bottom.
  static ui.Path _hillPath(
    double w,
    double h,
    double base,
    double amp,
    double phase,
    double period,
  ) {
    final path = ui.Path()..moveTo(-w, h);
    for (var x = -w; x <= w * 2; x += 30) {
      path.lineTo(
        x,
        h * base -
            amp * math.sin(x / period + phase) -
            amp * 0.35 * math.sin(x / (period * 0.37) + phase * 2),
      );
    }
    return path
      ..lineTo(w * 2, h)
      ..close();
  }

  static ui.Picture _ridge(
    MapDef map,
    math.Random rng,
    double w,
    double h,
    double base,
    double amp,
    int argb,
    double dist,
  ) => _record((c) {
    final path = _hillPath(w, h, base, amp, rng.nextDouble() * 9, 260);
    c.drawPath(path, ui.Paint()..color = _haze(map, argb, dist));
  });

  // ------------------------------------------------------------------ farm

  static ui.Picture _fields(MapDef map, math.Random rng, double w, double h) =>
      _record((c) {
        const dist = 0.35;
        final path = _hillPath(w, h, 0.6, 55, rng.nextDouble() * 9, 330);
        c
          ..save()
          ..clipPath(path)
          ..drawRect(
            ui.Rect.fromLTWH(-w, 0, w * 3, h),
            ui.Paint()..color = _haze(map, 0xFF7CC64A, dist),
          );
        // Patchwork: tilted strips of crops in alternating greens/golds.
        const crops = [0xFF8ED456, 0xFFE3C45A, 0xFF68B23E, 0xFFB9D35C];
        for (var x = -w; x < w * 2; x += 140 + rng.nextDouble() * 120) {
          final strip = ui.Path()
            ..moveTo(x, h * 0.45)
            ..lineTo(x + 120, h * 0.45)
            ..lineTo(x + 260, h)
            ..lineTo(x + 90, h)
            ..close();
          c.drawPath(
            strip,
            ui.Paint()
              ..color = _haze(map, crops[rng.nextInt(crops.length)], dist),
          );
        }
        c.restore();
        // Silos and barns on the crest.
        for (var i = 0; i < 4; i++) {
          final x = -w * 0.2 + i * w * 0.42 + rng.nextDouble() * 200;
          final ground = h * 0.6 - 40;
          final barn = ui.Rect.fromLTWH(x, ground - 60, 90, 70);
          c
            ..drawRect(barn, ui.Paint()..color = _haze(map, 0xFFC0452E, dist))
            ..drawPath(
              ui.Path()
                ..moveTo(x - 8, ground - 60)
                ..lineTo(x + 45, ground - 100)
                ..lineTo(x + 98, ground - 60)
                ..close(),
              ui.Paint()..color = _haze(map, 0xFF8A2E22, dist),
            )
            ..drawRect(
              ui.Rect.fromLTWH(x + 100, ground - 110, 34, 120),
              ui.Paint()..color = _haze(map, 0xFFD9D2C4, dist),
            )
            ..drawOval(
              ui.Rect.fromLTWH(x + 100, ground - 126, 34, 30),
              ui.Paint()..color = _haze(map, 0xFF9AA4AE, dist),
            );
        }
      });

  static ui.Picture _trees(MapDef map, math.Random rng, double w, double h) =>
      _record((c) {
        const dist = 0.38;
        for (var x = -w * 0.4; x < w * 1.6; x += 160 + rng.nextDouble() * 240) {
          final ground = h * 0.72 + rng.nextDouble() * 40;
          final th = 70 + rng.nextDouble() * 60;
          final trunk = ui.Rect.fromLTWH(x - 8, ground - th, 16, th + 40);
          c.drawRect(trunk, ui.Paint()..color = _haze(map, 0xFF7A4E2C, dist));
          final r = 50 + rng.nextDouble() * 30;
          final crown = ui.Offset(x, ground - th - r * 0.6);
          final leaf = _haze(map, 0xFF4FAE3C, dist);
          c
            ..drawCircle(crown, r, ui.Paint()..color = leaf)
            ..drawCircle(
              crown.translate(-r * 0.25, -r * 0.3),
              r * 0.55,
              ui.Paint()..color = _haze(map, 0xFF7FD25A, dist),
            );
        }
      });

  // ----------------------------------------------------------------- coast

  static ui.Picture _sea(MapDef map, math.Random rng, double w, double h) =>
      _record((c) {
        final horizon = h * 0.62;
        final rect = ui.Rect.fromLTRB(-w, horizon, w * 2, h);
        c.drawRect(
          rect,
          ui.Paint()
            ..shader = ui.Gradient.linear(rect.topCenter, rect.bottomCenter, [
              _haze(map, 0xFF46C3D6, 0.45),
              _haze(map, 0xFF1C8FB0, 0.1),
            ]),
        );
        final sparkle = ui.Paint()..color = const ui.Color(0x88FFFFFF);
        for (var i = 0; i < 160; i++) {
          final x = -w + rng.nextDouble() * w * 3;
          final y =
              horizon + 6 + math.pow(rng.nextDouble(), 1.5) * (h - horizon);
          c.drawRect(
            ui.Rect.fromLTWH(x, y, 10 + rng.nextDouble() * 18, 2),
            sparkle,
          );
        }
      });

  static ui.Picture _islands(MapDef map, math.Random rng, double w, double h) =>
      _record((c) {
        final horizon = h * 0.62;
        for (var x = -w * 0.6; x < w * 1.6; x += 380 + rng.nextDouble() * 420) {
          final iw = 160 + rng.nextDouble() * 260;
          final ih = 40 + rng.nextDouble() * 90;
          final path = ui.Path()
            ..moveTo(x, horizon + 4)
            ..quadraticBezierTo(
              x + iw * 0.2,
              horizon - ih,
              x + iw * 0.5,
              horizon - ih * 0.9,
            )
            ..quadraticBezierTo(
              x + iw * 0.85,
              horizon - ih * 0.8,
              x + iw,
              horizon + 4,
            )
            ..close();
          c.drawPath(path, ui.Paint()..color = _haze(map, 0xFF5E8F6E, 0.5));
          // A palm or two.
          if (rng.nextBool()) {
            final px = x + iw * 0.5;
            final py = horizon - ih * 0.9;
            final palm = _line(_haze(map, 0xFF4E6A4E, 0.45), 4);
            c.drawLine(ui.Offset(px, py), ui.Offset(px + 8, py - 50), palm);
            for (final a in [-2.6, -1.9, -1.2, -0.5]) {
              c.drawLine(
                ui.Offset(px + 8, py - 50),
                ui.Offset(
                  px + 8 + math.cos(a) * 34,
                  py - 50 + math.sin(a) * 18 + 14,
                ),
                palm,
              );
            }
          }
        }
      });

  static ui.Picture _boats(MapDef map, math.Random rng, double w, double h) =>
      _record((c) {
        final ink = _line(_haze(map, 0xFF2A1A12, 0.3), 2.5);
        for (var x = -w * 0.3; x < w * 1.5; x += 520 + rng.nextDouble() * 500) {
          final y = h * 0.66 + rng.nextDouble() * 50;
          final hull = ui.Path()
            ..moveTo(x, y)
            ..lineTo(x + 90, y)
            ..lineTo(x + 74, y + 20)
            ..lineTo(x + 14, y + 20)
            ..close();
          final sail = ui.Path()
            ..moveTo(x + 46, y - 4)
            ..lineTo(x + 46, y - 86)
            ..lineTo(x + 86, y - 8)
            ..close();
          c
            ..drawPath(hull, ui.Paint()..color = _haze(map, 0xFFC0452E, 0.3))
            ..drawPath(hull, ink)
            ..drawPath(sail, ui.Paint()..color = _haze(map, 0xFFFFF6E6, 0.2))
            ..drawPath(sail, ink);
        }
        // Gulls: little "m" strokes.
        final gull = _line(_haze(map, 0xFF2A1A12, 0.45), 3);
        for (var i = 0; i < 9; i++) {
          final g = ui.Offset(
            -w * 0.2 + rng.nextDouble() * w * 1.4,
            h * (0.15 + rng.nextDouble() * 0.25),
          );
          c.drawPath(
            ui.Path()
              ..moveTo(g.dx - 12, g.dy)
              ..quadraticBezierTo(g.dx - 6, g.dy - 8, g.dx, g.dy)
              ..quadraticBezierTo(g.dx + 6, g.dy - 8, g.dx + 12, g.dy),
            gull,
          );
        }
      });

  // ------------------------------------------------------------------ snow

  static ui.Picture _peaks(
    MapDef map,
    math.Random rng,
    double w,
    double h, {
    required bool far,
  }) => _record((c) {
    final dist = far ? 0.6 : 0.38;
    final rock = _haze(map, far ? 0xFF7C8FB8 : 0xFF6A7AA0, dist);
    final snow = _haze(map, 0xFFFFFFFF, dist * 0.4);
    final base = h * (far ? 0.6 : 0.68);
    for (
      var x = -w * 0.8;
      x < w * 1.8;
      x += (far ? 300 : 380) + rng.nextDouble() * 260
    ) {
      final pw = (far ? 380 : 460) + rng.nextDouble() * 260;
      final ph = (far ? 300 : 260) + rng.nextDouble() * 160;
      final apex = ui.Offset(
        x + pw * (0.4 + rng.nextDouble() * 0.2),
        base - ph,
      );
      final peak = ui.Path()
        ..moveTo(x, base + 200)
        ..lineTo(apex.dx, apex.dy)
        ..lineTo(x + pw, base + 200)
        ..close();
      c.drawPath(peak, ui.Paint()..color = rock);
      // Shadow side.
      c.drawPath(
        ui.Path()
          ..moveTo(apex.dx, apex.dy)
          ..lineTo(x + pw, base + 200)
          ..lineTo(apex.dx + pw * 0.05, base + 200)
          ..close(),
        ui.Paint()..color = const ui.Color(0xFF1A2440).withValues(alpha: 0.12),
      );
      // Snow cap with a jagged hem.
      final capY = apex.dy + ph * 0.32;
      final l = apex.dx - (apex.dx - x) * 0.32;
      final r = apex.dx + (x + pw - apex.dx) * 0.32;
      final cap = ui.Path()
        ..moveTo(apex.dx, apex.dy)
        ..lineTo(r, capY);
      for (var k = 1; k < 6; k++) {
        cap.lineTo(r - (r - l) * k / 6, capY + (k.isOdd ? 18 : -4));
      }
      cap
        ..lineTo(l, capY)
        ..close();
      c.drawPath(cap, ui.Paint()..color = snow);
    }
  });

  static ui.Picture _pines(MapDef map, math.Random rng, double w, double h) =>
      _record((c) {
        const dist = 0.25;
        final green = _haze(map, 0xFF2F7A4E, dist);
        final snow = _haze(map, 0xFFFFFFFF, 0.05);
        final ink = _line(_haze(map, 0xFF15301F, dist), 2.5);
        final hill = _hillPath(w, h, 0.76, 30, rng.nextDouble() * 9, 300);
        c
          ..drawPath(hill, ui.Paint()..color = _haze(map, 0xFFEAF2FA, 0.15))
          ..drawPath(hill, _line(_haze(map, 0xFF6A7AA0, dist), 2.5));
        for (var x = -w * 0.5; x < w * 1.6; x += 50 + rng.nextDouble() * 120) {
          final s = 0.6 + rng.nextDouble() * 0.7;
          final ground = h * 0.78 + rng.nextDouble() * 30;
          for (var k = 0; k < 3; k++) {
            final b = ground - k * 34 * s;
            final half = (44 - k * 10) * s;
            final tier = ui.Path()
              ..moveTo(x - half, b)
              ..lineTo(x, b - 56 * s)
              ..lineTo(x + half, b)
              ..close();
            c
              ..drawPath(tier, ui.Paint()..color = green)
              ..drawPath(
                ui.Path()
                  ..moveTo(x - half * 0.45, b - 32 * s)
                  ..lineTo(x, b - 56 * s)
                  ..lineTo(x + half * 0.45, b - 32 * s)
                  ..close(),
                ui.Paint()..color = snow,
              )
              ..drawPath(tier, ink);
          }
        }
      });
}
