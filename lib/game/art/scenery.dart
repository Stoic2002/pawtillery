import 'dart:math' as math;
import 'dart:ui' as ui;

import '../../config/maps.dart';
import 'paint_kit.dart';

/// One background layer: a picture in world-sized coordinates and how fast
/// it follows the camera (0 = fixed to the sky, 1 = moves with the world).
class SceneryLayer {
  const SceneryLayer(this.picture, this.parallax);
  final ui.Picture picture;
  final double parallax;
}

/// Procedural backdrops per map theme: far and near silhouettes that fade
/// towards the sky colour with distance (atmospheric perspective).
/// Visual only; uses its own RNG seeded from the map id.
abstract final class Scenery {
  static List<SceneryLayer> build(MapDef map, double width, double height) {
    final rng = math.Random(map.id.hashCode);
    return switch (map.theme) {
      MapTheme.backyard => [
          SceneryLayer(_hills(map, rng, width, height, far: true), 0.25),
          SceneryLayer(_houses(map, rng, width, height), 0.4),
          SceneryLayer(_trees(map, rng, width, height, near: false), 0.6),
        ],
      MapTheme.park => [
          SceneryLayer(_skyline(map, rng, width, height), 0.25),
          SceneryLayer(_hills(map, rng, width, height, far: false), 0.45),
          SceneryLayer(_trees(map, rng, width, height, near: true), 0.65),
        ],
      MapTheme.warehouse => [
          SceneryLayer(_backWall(map, rng, width, height), 0.2),
          SceneryLayer(_trusses(map, width, height), 0.45),
          SceneryLayer(_shelves(map, rng, width, height), 0.6),
        ],
    };
  }

  /// Sky-tinted version of [argb]: further = closer to the sky.
  static ui.Color _haze(MapDef map, int argb, double distance) =>
      ui.Color.lerp(ui.Color(argb), ui.Color(map.skyBottomArgb), distance)!;

  static ui.Picture _record(void Function(ui.Canvas) draw) {
    final r = ui.PictureRecorder();
    draw(ui.Canvas(r));
    return r.endRecording();
  }

  static ui.Picture _hills(MapDef map, math.Random rng, double w, double h,
      {required bool far}) {
    return _record((c) {
      for (final (base, amp, dist) in far
          ? [(0.52, 70.0, 0.7), (0.6, 50.0, 0.55)]
          : [(0.58, 60.0, 0.5)]) {
        final path = ui.Path()..moveTo(-w, h);
        final phase = rng.nextDouble() * 10;
        for (var x = -w; x <= w * 2; x += 40) {
          final y = h * base -
              amp * math.sin(x / 380 + phase) -
              amp * 0.4 * math.sin(x / 140 + phase * 2);
          path.lineTo(x, y);
        }
        path
          ..lineTo(w * 2, h)
          ..close();
        final color = _haze(map, map.grassArgb, dist);
        c.drawPath(
            path,
            ui.Paint()
              ..shader = ui.Gradient.linear(ui.Offset(0, h * 0.35),
                  ui.Offset(0, h), [color, _haze(map, map.dirtArgb, dist)]));
      }
    });
  }

  static ui.Picture _houses(MapDef map, math.Random rng, double w, double h) {
    return _record((c) {
      final wall = _haze(map, 0xFFC9B8A0, 0.55);
      final roof = _haze(map, 0xFF8E4A3A, 0.55);
      final window = _haze(map, 0xFFFFE6A8, 0.35);
      for (var x = -w * 0.5; x < w * 1.6; x += 260 + rng.nextDouble() * 220) {
        final hw = 120 + rng.nextDouble() * 90;
        final hh = 80 + rng.nextDouble() * 60;
        final ground = h * 0.62 + rng.nextDouble() * 30;
        final body = ui.Rect.fromLTWH(x, ground - hh, hw, hh);
        c.drawRect(body, ui.Paint()..color = wall);
        c.drawPath(
            ui.Path()
              ..moveTo(x - 12, ground - hh)
              ..lineTo(x + hw / 2, ground - hh - 55 - rng.nextDouble() * 25)
              ..lineTo(x + hw + 12, ground - hh)
              ..close(),
            ui.Paint()..color = roof);
        for (var i = 0; i < 2; i++) {
          c.drawRect(
              ui.Rect.fromLTWH(x + 18 + i * (hw - 52), ground - hh + 22, 22, 22),
              ui.Paint()..color = window);
        }
      }
    });
  }

  static ui.Picture _trees(MapDef map, math.Random rng, double w, double h,
      {required bool near}) {
    final dist = near ? 0.3 : 0.4;
    return _record((c) {
      final trunk = _haze(map, 0xFF5A3E2A, dist);
      final leaf = _haze(map, PaintKit.toneArgb(map.grassArgb, -0.35), dist);
      final leafLight = _haze(map, map.grassArgb, dist);
      for (var x = -w * 0.4; x < w * 1.6; x += 150 + rng.nextDouble() * 260) {
        final ground = h * (near ? 0.7 : 0.66) + rng.nextDouble() * 40;
        final th = 90 + rng.nextDouble() * 90;
        c.drawRect(ui.Rect.fromLTWH(x - 7, ground - th, 14, th),
            ui.Paint()..color = trunk);
        final r = 55 + rng.nextDouble() * 40;
        for (final (dx, dy, k) in [(-0.5, 0.1, 0.8), (0.5, 0.15, 0.75), (0.0, -0.3, 1.0)]) {
          final center = ui.Offset(x + dx * r, ground - th + dy * r);
          c.drawCircle(
              center,
              r * k,
              ui.Paint()
                ..shader = ui.Gradient.radial(
                    center - ui.Offset(r * 0.3, r * 0.3), r * k * 1.4,
                    [leafLight, leaf]));
        }
      }
    });
  }

  static ui.Picture _skyline(MapDef map, math.Random rng, double w, double h) {
    return _record((c) {
      final building = _haze(map, 0xFF5C5470, 0.55);
      final lit = _haze(map, 0xFFFFD58A, 0.25);
      for (var x = -w * 0.5; x < w * 1.6; x += 70 + rng.nextDouble() * 60) {
        final bw = 60 + rng.nextDouble() * 70;
        final bh = 120 + rng.nextDouble() * 260;
        final ground = h * 0.66;
        c.drawRect(ui.Rect.fromLTWH(x, ground - bh, bw, bh),
            ui.Paint()..color = building);
        for (var wy = ground - bh + 14; wy < ground - 20; wy += 22) {
          for (var wx = x + 10; wx < x + bw - 12; wx += 18) {
            if (rng.nextDouble() < 0.35) {
              c.drawRect(ui.Rect.fromLTWH(wx, wy, 8, 10), ui.Paint()..color = lit);
            }
          }
        }
      }
    });
  }

  static ui.Picture _backWall(MapDef map, math.Random rng, double w, double h) {
    return _record((c) {
      c.drawRect(ui.Rect.fromLTWH(-w, 0, w * 3, h),
          ui.Paint()..color = _haze(map, 0xFF4A4038, 0.35));
      final mortar = ui.Paint()
        ..color = _haze(map, 0xFF332B25, 0.35)
        ..strokeWidth = 2;
      for (var y = 0.0; y < h; y += 28) {
        c.drawLine(ui.Offset(-w, y), ui.Offset(w * 2, y), mortar);
      }
      // Tall windows letting in daylight, with light shafts.
      for (var x = -w * 0.3; x < w * 1.5; x += 520) {
        final win = ui.Rect.fromLTWH(x, h * 0.12, 160, 260);
        c.drawRect(win, ui.Paint()..color = const ui.Color(0xFFDDEBF2));
        final bar = ui.Paint()
          ..color = const ui.Color(0xFF2A2420)
          ..strokeWidth = 6;
        c
          ..drawLine(win.topCenter, win.bottomCenter, bar)
          ..drawLine(win.centerLeft, win.centerRight, bar);
        c.drawPath(
            ui.Path()
              ..moveTo(win.left, win.top)
              ..lineTo(win.right, win.top)
              ..lineTo(win.right + 260, h)
              ..lineTo(win.left + 140, h)
              ..close(),
            ui.Paint()..color = const ui.Color(0x1AFFF4D6));
      }
    });
  }

  static ui.Picture _trusses(MapDef map, double w, double h) {
    return _record((c) {
      final steel = ui.Paint()
        ..color = _haze(map, 0xFF2E3338, 0.25)
        ..strokeWidth = 8;
      final thin = ui.Paint()
        ..color = _haze(map, 0xFF2E3338, 0.25)
        ..strokeWidth = 4;
      final top = h * 0.06;
      final bottom = h * 0.16;
      c
        ..drawLine(ui.Offset(-w, top), ui.Offset(w * 2, top), steel)
        ..drawLine(ui.Offset(-w, bottom), ui.Offset(w * 2, bottom), steel);
      for (var x = -w; x < w * 2; x += 120) {
        c.drawLine(ui.Offset(x, bottom), ui.Offset(x + 60, top), thin);
        c.drawLine(ui.Offset(x + 60, top), ui.Offset(x + 120, bottom), thin);
      }
      // Hanging lamps.
      for (var x = -w * 0.2; x < w * 1.4; x += 420) {
        c.drawLine(ui.Offset(x, bottom), ui.Offset(x, bottom + 90), thin);
        c.drawPath(
            ui.Path()
              ..moveTo(x - 26, bottom + 110)
              ..lineTo(x - 10, bottom + 90)
              ..lineTo(x + 10, bottom + 90)
              ..lineTo(x + 26, bottom + 110)
              ..close(),
            ui.Paint()..color = _haze(map, 0xFF3C4A3E, 0.2));
        c.drawCircle(ui.Offset(x, bottom + 112), 8,
            ui.Paint()..color = const ui.Color(0xFFFFE9A8));
      }
    });
  }

  static ui.Picture _shelves(MapDef map, math.Random rng, double w, double h) {
    return _record((c) {
      final frame = _haze(map, 0xFF3A4048, 0.3);
      final box = [0xFF9C7A50, 0xFF8A6A44, 0xFFB08C5E];
      for (var x = -w * 0.4; x < w * 1.5; x += 380 + rng.nextDouble() * 200) {
        final sw = 220.0;
        final floor = h * 0.78;
        for (final post in [x, x + sw]) {
          c.drawRect(ui.Rect.fromLTWH(post, floor - 330, 10, 330),
              ui.Paint()..color = frame);
        }
        for (var level = 0; level < 3; level++) {
          final y = floor - 100 - level * 110;
          c.drawRect(ui.Rect.fromLTWH(x, y, sw + 10, 8), ui.Paint()..color = frame);
          for (var bx = x + 14; bx < x + sw - 40; bx += 50 + rng.nextDouble() * 20) {
            final bh = 40 + rng.nextDouble() * 50;
            c.drawRect(
                ui.Rect.fromLTWH(bx, y - bh, 44, bh),
                ui.Paint()
                  ..color = _haze(map, box[rng.nextInt(box.length)], 0.35));
          }
        }
      }
    });
  }
}
