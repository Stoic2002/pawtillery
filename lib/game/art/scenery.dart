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

/// Painted backdrops per map theme (docs/art_style_guide.md): simple,
/// hazy silhouettes with no outlines, fading towards the sky colour with
/// distance, so the play layer stands out. Visual only; uses its own RNG
/// seeded from the map id.
abstract final class Scenery {
  static List<SceneryLayer> build(MapDef map, double width, double height) {
    final rng = math.Random(_seed(map.id));
    return switch (map.theme) {
      MapTheme.backyard => [
        SceneryLayer(_house(map, rng, width, height), 0.15),
        SceneryLayer(_fenceAndLights(map, rng, width, height), 0.45),
      ],
      MapTheme.castle => [
        SceneryLayer(_mountains(map, rng, width, height), 0.12),
        SceneryLayer(_farCastles(map, rng, width, height), 0.3),
        SceneryLayer(_graveyard(map, rng, width, height), 0.55),
      ],
      MapTheme.wreck => [
        SceneryLayer(_stormSea(map, rng, width, height), 0.08),
        SceneryLayer(_stacksAndGhostShip(map, rng, width, height), 0.25),
        SceneryLayer(_nearRocks(map, rng, width, height), 0.5),
      ],
      MapTheme.ruins => [
        SceneryLayer(_burningCity(map, rng, width, height), 0.12),
        SceneryLayer(_smokeColumns(map, rng, width, height), 0.25),
        SceneryLayer(_brokenWalls(map, rng, width, height), 0.55),
      ],
    };
  }

  static int _seed(String id) =>
      id.codeUnits.fold(17, (h, c) => (h * 31 + c) & 0x7FFFFFFF);

  /// Sky-tinted version of [argb]: further = closer to the sky.
  static ui.Color _haze(MapDef map, int argb, double distance) =>
      ui.Color.lerp(ui.Color(argb), ui.Color(map.skyBottomArgb), distance)!;

  static ui.Paint _fill(ui.Color c) => ui.Paint()..color = c;

  static ui.Picture _record(void Function(ui.Canvas) draw) {
    final r = ui.PictureRecorder();
    draw(ui.Canvas(r));
    return r.endRecording();
  }

  /// A hill line from [base] (fraction of height) down past the bottom.
  static ui.Path _hillPath(
    double w,
    double h,
    double base,
    double amp,
    double phase,
    double period,
  ) {
    final path = ui.Path()..moveTo(-w, h * 1.5);
    for (var x = -w; x <= w * 2; x += 30) {
      path.lineTo(
        x,
        h * base -
            amp * math.sin(x / period + phase) -
            amp * 0.35 * math.sin(x / (period * 0.37) + phase * 2),
      );
    }
    return path
      ..lineTo(w * 2, h * 1.5)
      ..close();
  }

  /// A soft horizontal band of fog.
  static void _fog(ui.Canvas c, double w, double y, double h, ui.Color color) {
    final rect = ui.Rect.fromLTWH(-w, y - h / 2, w * 3, h);
    c.drawRect(
      rect,
      ui.Paint()
        ..shader = ui.Gradient.linear(
          rect.topCenter,
          rect.bottomCenter,
          [color.withValues(alpha: 0), color, color.withValues(alpha: 0)],
          const [0, 0.5, 1],
        ),
    );
  }

  // -------------------------------------------------------------- backyard

  /// A house and trees in silhouette with warm windows, behind a haze.
  static ui.Picture _house(
    MapDef map,
    math.Random rng,
    double w,
    double h,
  ) => _record((c) {
    final ground = h * 0.66;
    final soft = ui.Paint()..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3);
    // Trees.
    for (var x = -w * 0.5; x < w * 1.6; x += 260 + rng.nextDouble() * 260) {
      final r = 90 + rng.nextDouble() * 70;
      for (final (dx, dy, k) in [(-0.6, 0.2, 0.7), (0.5, 0.15, 0.75), (0.0, -0.3, 1.0)]) {
        c.drawCircle(
          ui.Offset(x + dx * r, ground - r * 0.9 + dy * r),
          r * k,
          ui.Paint()
            ..color = const ui.Color(0xFF33243D)
            ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4),
        );
      }
      c.drawCircle(
        ui.Offset(x - r * 0.3, ground - r * 1.3),
        r * 0.35,
        ui.Paint()
          ..color = const ui.Color(0x8C6E4A60)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8),
      );
    }
    // The house: walls, a pitched roof, siding, lit windows.
    for (final hx in [w * 0.12, w * 0.68]) {
      const hw = 420.0;
      const hh = 230.0;
      final body = ui.Rect.fromLTWH(hx, ground - hh, hw, hh + 60);
      c
        ..drawRect(body, soft..color = const ui.Color(0xFF3F2A48))
        ..drawPath(
          ui.Path()
            ..moveTo(hx - 30, ground - hh)
            ..lineTo(hx + hw / 2, ground - hh - 130)
            ..lineTo(hx + hw + 30, ground - hh)
            ..close(),
          soft..color = const ui.Color(0xFF34223C),
        );
      final siding = ui.Paint()
        ..color = const ui.Color(0x802A1C33)
        ..strokeWidth = 1.2;
      for (var y = ground - hh + 12; y < ground + 40; y += 14) {
        c.drawLine(ui.Offset(hx, y), ui.Offset(hx + hw, y), siding);
      }
      for (final (wx, wy) in [(40.0, 50.0), (170.0, 50.0), (300.0, 50.0), (40.0, 140.0), (300.0, 140.0)]) {
        final win = ui.Rect.fromLTWH(hx + wx, ground - hh + wy, 70, 56);
        c
          ..drawRect(
            win.inflate(10),
            ui.Paint()
              ..color = const ui.Color(0x55FFC982)
              ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 10),
          )
          ..drawRect(win, ui.Paint()..color = const ui.Color(0x99FFC982))
          ..drawLine(win.topCenter, win.bottomCenter, ui.Paint()..color = const ui.Color(0xFF3F2A48)..strokeWidth = 4)
          ..drawLine(win.centerLeft, win.centerRight, ui.Paint()..color = const ui.Color(0xFF3F2A48)..strokeWidth = 4);
      }
    }
    _fog(c, w, h * 0.66, 170, const ui.Color(0x55F2A877));
  });

  /// A wooden fence along the yard with a wire of warm fairy lights and
  /// soft bokeh, as in the redesign's arena.
  static ui.Picture _fenceAndLights(
    MapDef map,
    math.Random rng,
    double w,
    double h,
  ) => _record((c) {
    final top = h * 0.5;
    final bottom = h * 0.78;
    final rail = ui.Paint()..color = const ui.Color(0xFF3A2638);
    c
      ..drawRect(ui.Rect.fromLTRB(-w, top + 40, w * 2, top + 58), rail)
      ..drawRect(ui.Rect.fromLTRB(-w, bottom - 60, w * 2, bottom - 42), rail);
    for (var x = -w; x < w * 2; x += 46) {
      final plankTop = top + (rng.nextDouble() * 10);
      final plank = ui.Path()
        ..moveTo(x + 2, bottom)
        ..lineTo(x + 2, plankTop + 10)
        ..lineTo(x + 21, plankTop)
        ..lineTo(x + 40, plankTop + 10)
        ..lineTo(x + 40, bottom)
        ..close();
      c
        ..drawPath(
          plank,
          ui.Paint()
            ..shader = ui.Gradient.linear(
              ui.Offset(x, plankTop),
              ui.Offset(x + 40, plankTop),
              [const ui.Color(0xFF7A5470), const ui.Color(0xFF5E3E56)],
            ),
        )
        ..drawRect(
          ui.Rect.fromLTRB(x + 32, plankTop + 8, x + 40, bottom),
          ui.Paint()..color = const ui.Color(0x40000000),
        );
      for (var g = plankTop + 20; g < bottom; g += 9 + rng.nextDouble() * 8) {
        c.drawLine(
          ui.Offset(x + 6 + rng.nextDouble() * 28, g),
          ui.Offset(x + 6 + rng.nextDouble() * 28, g + 6),
          ui.Paint()
            ..color = const ui.Color(0x26000000)
            ..strokeWidth = 1,
        );
      }
    }
    // The light wire: sagging arcs with bulbs.
    final wire = ui.Path();
    final bulbs = <ui.Offset>[];
    const span = 300.0;
    for (var x = -w; x < w * 2; x += span) {
      final y0 = top - 40;
      wire.moveTo(x, y0);
      wire.quadraticBezierTo(x + span / 2, y0 + 70, x + span, y0);
      for (var t = 0.1; t < 1; t += 0.2) {
        final bx = x + span * t;
        final by = y0 + 70 * 2 * t * (1 - t) + 6;
        bulbs.add(ui.Offset(bx, by));
      }
    }
    c.drawPath(
      wire,
      ui.Paint()
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const ui.Color(0xCC24162A),
    );
    for (final b in bulbs) {
      c
        ..drawCircle(
          b,
          14,
          ui.Paint()
            ..color = const ui.Color(0xAAFFC064)
            ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8),
        )
        ..drawCircle(b, 4, ui.Paint()..color = const ui.Color(0xFFFFF2C9));
    }
    for (var i = 0; i < 14; i++) {
      c.drawCircle(
        ui.Offset(-w * 0.2 + rng.nextDouble() * w * 1.4, top - 140 + rng.nextDouble() * 180),
        16 + rng.nextDouble() * 22,
        ui.Paint()
          ..color = const ui.Color(0x40FFB86B)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 16),
      );
    }
  });

  // ---------------------------------------------------------------- castle

  static ui.Picture _mountains(
    MapDef map,
    math.Random rng,
    double w,
    double h,
  ) => _record((c) {
    for (final (base, dist) in [(0.5, 0.55), (0.58, 0.4)]) {
      final path = ui.Path()..moveTo(-w, h * 1.5);
      var x = -w;
      while (x < w * 2) {
        path.lineTo(x, h * base + rng.nextDouble() * 60);
        x += 80 + rng.nextDouble() * 120;
        path.lineTo(x, h * base - 120 - rng.nextDouble() * 160);
        x += 80 + rng.nextDouble() * 120;
      }
      path
        ..lineTo(w * 2, h * 1.5)
        ..close();
      c.drawPath(path, _fill(_haze(map, 0xFF1A1E3A, dist)));
    }
    _fog(
      c,
      w,
      h * 0.62,
      120,
      _haze(map, 0xFF8A93C0, 0.2).withValues(alpha: 0.35),
    );
  });

  static ui.Picture _farCastles(
    MapDef map,
    math.Random rng,
    double w,
    double h,
  ) => _record((c) {
    const dist = 0.3;
    final stone = _fill(_haze(map, 0xFF141830, dist));
    final lit = _fill(const ui.Color(0xFFFFC46A));
    c.drawPath(_hillPath(w, h, 0.68, 40, rng.nextDouble() * 9, 300), stone);
    for (var i = 0; i < 3; i++) {
      final x = -w * 0.3 + i * w * 0.75 + rng.nextDouble() * 300;
      final base = h * 0.66;
      // A crag with a little castle on top.
      c.drawPath(
        ui.Path()
          ..moveTo(x - 160, base + 60)
          ..lineTo(x - 60, base - 120)
          ..lineTo(x + 70, base - 130)
          ..lineTo(x + 170, base + 60)
          ..close(),
        stone,
      );
      for (final (dx, tw, th) in [(-50.0, 34.0, 110.0), (30.0, 40.0, 150.0)]) {
        c
          ..drawRect(ui.Rect.fromLTWH(x + dx, base - 130 - th, tw, th), stone)
          ..drawPath(
            ui.Path()
              ..moveTo(x + dx - 6, base - 130 - th)
              ..lineTo(x + dx + tw / 2, base - 130 - th - 44)
              ..lineTo(x + dx + tw + 6, base - 130 - th)
              ..close(),
            stone,
          );
        if (rng.nextBool()) {
          c.drawRect(
            ui.Rect.fromLTWH(x + dx + tw / 2 - 4, base - 130 - th + 26, 8, 12),
            lit,
          );
        }
      }
      c.drawRect(ui.Rect.fromLTWH(x - 40, base - 190, 90, 60), stone);
    }
    _fog(
      c,
      w,
      h * 0.72,
      90,
      _haze(map, 0xFF9AA4D0, 0.1).withValues(alpha: 0.3),
    );
  });

  static ui.Picture _graveyard(
    MapDef map,
    math.Random rng,
    double w,
    double h,
  ) => _record((c) {
    const dist = 0.18;
    final dark = _fill(_haze(map, 0xFF0C0F1E, dist));
    c.drawPath(_hillPath(w, h, 0.78, 30, rng.nextDouble() * 9, 260), dark);
    final branch = ui.Paint()
      ..color = dark.color
      ..strokeCap = ui.StrokeCap.round;
    for (var x = -w * 0.5; x < w * 1.6; x += 120 + rng.nextDouble() * 200) {
      final ground = h * 0.78 - 10;
      if (rng.nextDouble() < 0.4) {
        // Bare tree.
        final th = 120 + rng.nextDouble() * 80;
        c.drawLine(
          ui.Offset(x, ground + 20),
          ui.Offset(x, ground - th),
          branch..strokeWidth = 12,
        );
        for (var k = 0; k < 4; k++) {
          final y = ground - th * (0.4 + k * 0.15);
          final side = k.isEven ? 1 : -1;
          c.drawLine(
            ui.Offset(x, y),
            ui.Offset(x + side * (40 + rng.nextDouble() * 40), y - 40),
            branch..strokeWidth = 5,
          );
        }
      } else {
        // Leaning gravestones.
        final gw = 22 + rng.nextDouble() * 14;
        final gh = 30 + rng.nextDouble() * 30;
        c
          ..save()
          ..translate(x, ground + 6)
          ..rotate((rng.nextDouble() - 0.5) * 0.3)
          ..drawRRect(
            ui.RRect.fromRectAndCorners(
              ui.Rect.fromLTWH(-gw / 2, -gh, gw, gh + 10),
              topLeft: ui.Radius.circular(gw / 2),
              topRight: ui.Radius.circular(gw / 2),
            ),
            dark,
          )
          ..restore();
      }
    }
    _fog(c, w, h * 0.82, 70, const ui.Color(0x557A84B4));
  });

  // ----------------------------------------------------------------- wreck

  static ui.Picture _stormSea(
    MapDef map,
    math.Random rng,
    double w,
    double h,
  ) => _record((c) {
    final horizon = h * 0.62;
    final rect = ui.Rect.fromLTRB(-w, horizon, w * 2, h * 1.5);
    c.drawRect(
      rect,
      ui.Paint()
        ..shader = ui.Gradient.linear(
          rect.topCenter,
          ui.Offset(rect.left, h),
          [_haze(map, 0xFF2C5A62, 0.45), _haze(map, 0xFF0E2A32, 0.05)],
        ),
    );
    final cap = _fill(const ui.Color(0x55E6EEF0));
    for (var i = 0; i < 140; i++) {
      final x = -w + rng.nextDouble() * w * 3;
      final y =
          horizon + 4 + math.pow(rng.nextDouble(), 1.6) * (h - horizon);
      c.drawRect(ui.Rect.fromLTWH(x, y, 8 + rng.nextDouble() * 22, 1.6), cap);
    }
  });

  static ui.Picture _stacksAndGhostShip(
    MapDef map,
    math.Random rng,
    double w,
    double h,
  ) => _record((c) {
    final horizon = h * 0.62;
    final rock = _fill(_haze(map, 0xFF1C2228, 0.58));
    for (var x = -w * 0.6; x < w * 1.6; x += 300 + rng.nextDouble() * 400) {
      final sw = 50 + rng.nextDouble() * 90;
      final sh = 80 + rng.nextDouble() * 160;
      c.drawPath(
        ui.Path()
          ..moveTo(x, horizon + 6)
          ..lineTo(x + sw * 0.2, horizon - sh)
          ..lineTo(x + sw * 0.7, horizon - sh * 0.9)
          ..lineTo(x + sw, horizon + 6)
          ..close(),
        rock,
      );
    }
    // A ghost ship with torn sails on the horizon.
    final ship = _fill(_haze(map, 0xFF1A1E24, 0.35));
    final sail = _fill(_haze(map, 0xFF8C8A80, 0.45));
    final sx = w * 0.62;
    c.drawPath(
      ui.Path()
        ..moveTo(sx - 120, horizon - 20)
        ..lineTo(sx + 120, horizon - 26)
        ..lineTo(sx + 96, horizon + 6)
        ..lineTo(sx - 100, horizon + 6)
        ..close(),
      ship,
    );
    for (final (dx, mh) in [(-50.0, 150.0), (30.0, 180.0)]) {
      c
        ..drawRect(ui.Rect.fromLTWH(sx + dx, horizon - 20 - mh, 5, mh), ship)
        ..drawPath(
          ui.Path()
            ..moveTo(sx + dx + 5, horizon - mh)
            ..lineTo(sx + dx + 60, horizon - mh + 20)
            ..lineTo(sx + dx + 48, horizon - mh * 0.55)
            ..lineTo(sx + dx + 30, horizon - mh * 0.6)
            ..lineTo(sx + dx + 5, horizon - mh * 0.4)
            ..close(),
          sail,
        );
    }
  });

  static ui.Picture _nearRocks(
    MapDef map,
    math.Random rng,
    double w,
    double h,
  ) => _record((c) {
    final rock = _fill(_haze(map, 0xFF12171C, 0.2));
    for (var x = -w * 0.5; x < w * 1.6; x += 420 + rng.nextDouble() * 500) {
      final rw = 120 + rng.nextDouble() * 160;
      final rh = 60 + rng.nextDouble() * 120;
      final base = h * 0.72;
      c.drawPath(
        ui.Path()
          ..moveTo(x, base + 200)
          ..lineTo(x + rw * 0.15, base - rh * 0.6)
          ..lineTo(x + rw * 0.4, base - rh)
          ..lineTo(x + rw * 0.75, base - rh * 0.7)
          ..lineTo(x + rw, base + 200)
          ..close(),
        rock,
      );
    }
    _fog(c, w, h * 0.7, 110, const ui.Color(0x4A9AA2A6));
  });

  // ----------------------------------------------------------------- ruins

  static ui.Picture _burningCity(
    MapDef map,
    math.Random rng,
    double w,
    double h,
  ) => _record((c) {
    final base = h * 0.64;
    // Fire glow along the horizon.
    final glow = ui.Rect.fromLTRB(-w, base - 160, w * 2, base + 40);
    c.drawRect(
      glow,
      ui.Paint()
        ..shader = ui.Gradient.linear(
          glow.topCenter,
          glow.bottomCenter,
          [const ui.Color(0x00FF7A2A), const ui.Color(0x88FF6A20)],
        ),
    );
    final building = _fill(_haze(map, 0xFF2A1A1A, 0.35));
    final window = _fill(const ui.Color(0xCCFFB050));
    for (var x = -w * 0.5; x < w * 1.6; x += 60 + rng.nextDouble() * 70) {
      final bw = 50 + rng.nextDouble() * 70;
      final bh = 60 + rng.nextDouble() * 200;
      // Broken tops: a jagged roofline.
      final top = ui.Path()
        ..moveTo(x, base + 200)
        ..lineTo(x, base - bh);
      for (var k = 1; k <= 4; k++) {
        top.lineTo(
          x + bw * k / 4,
          base - bh + (k.isOdd ? rng.nextDouble() * 40 : 0),
        );
      }
      top
        ..lineTo(x + bw, base + 200)
        ..close();
      c.drawPath(top, building);
      for (var wy = base - bh + 30; wy < base - 16; wy += 26) {
        for (var wx = x + 10; wx < x + bw - 14; wx += 20) {
          if (rng.nextDouble() < 0.18) {
            c.drawRect(ui.Rect.fromLTWH(wx, wy, 7, 9), window);
          }
        }
      }
    }
  });

  static ui.Picture _smokeColumns(
    MapDef map,
    math.Random rng,
    double w,
    double h,
  ) => _record((c) {
    // Billowing columns: many soft, overlapping puffs that widen and lean
    // with the wind as they rise.
    for (var x = -w * 0.3; x < w * 1.5; x += 380 + rng.nextDouble() * 400) {
      for (var k = 0; k < 26; k++) {
        final t = k / 25;
        final r = 26 + t * 90 + rng.nextDouble() * 20;
        final p = ui.Offset(
          x + t * t * 260 + (rng.nextDouble() - 0.5) * r * 0.8,
          h * 0.64 - t * h * 0.55 + (rng.nextDouble() - 0.5) * 30,
        );
        final color = _haze(map, 0xFF2E2628, 0.25 + t * 0.35);
        c.drawCircle(
          p,
          r,
          ui.Paint()
            ..shader = ui.Gradient.radial(p, r, [
              color.withValues(alpha: 0.32 * (1 - t * 0.5)),
              color.withValues(alpha: 0),
            ]),
        );
      }
    }
  });

  static ui.Picture _brokenWalls(
    MapDef map,
    math.Random rng,
    double w,
    double h,
  ) => _record((c) {
    final dark = _fill(_haze(map, 0xFF1A1210, 0.15));
    final hole = _fill(_haze(map, 0xFFB86A40, 0.2));
    c.drawPath(_hillPath(w, h, 0.76, 24, rng.nextDouble() * 9, 240), dark);
    for (var x = -w * 0.5; x < w * 1.6; x += 200 + rng.nextDouble() * 260) {
      final ww = 70 + rng.nextDouble() * 110;
      final wh = 70 + rng.nextDouble() * 120;
      final base = h * 0.76;
      final wall = ui.Path()
        ..moveTo(x, base + 30)
        ..lineTo(x, base - wh);
      for (var k = 1; k <= 5; k++) {
        wall.lineTo(x + ww * k / 5, base - wh + rng.nextDouble() * wh * 0.6);
      }
      wall
        ..lineTo(x + ww, base + 30)
        ..close();
      c
        ..drawPath(wall, dark)
        ..drawRect(
          ui.Rect.fromLTWH(x + ww * 0.3, base - wh * 0.5, ww * 0.2, wh * 0.22),
          hole,
        );
    }
    _fog(c, w, h * 0.8, 80, const ui.Color(0x44C08060));
  });
}
