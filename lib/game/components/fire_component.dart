import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../config/weapons.dart';
import '../../sim/world.dart';

/// Draws fire on the ground: each patch its own uneven cluster of flame
/// tongues standing on the ground under them (not in a row), flickering
/// and licking at different speeds and leaning with the wind, catching
/// quickly when it starts, with flamelets breaking off the tips, sparks,
/// thin smoke and a warm pulsing glow. Lower as it burns out.
class FireComponent extends Component {
  FireComponent(this.sim) : super(priority: 5);

  final SimWorld sim;
  double _time = 0;

  final ui.Paint _paint = ui.Paint();
  final ui.Paint _glow = ui.Paint()..blendMode = ui.BlendMode.plus;
  final ui.Paint _smoke = ui.Paint();

  /// When each patch was first drawn, for catching light.
  final Map<int, double> _born = {};

  /// How far a tongue's base may be from the patch's height, px.
  static const int _baseReach = 8;

  @override
  void update(double dt) {
    _time += dt;
    if (_born.length > sim.fires.length) {
      final live = {for (final f in sim.fires) f.id};
      _born.removeWhere((id, _) => !live.contains(id));
    }
  }

  /// Uneven flicker in about -1..1: a few sines at unrelated speeds.
  static double _flicker(double t) =>
      (math.sin(t) +
          0.5 * math.sin(t * 2.3 + 1.1) +
          0.3 * math.sin(t * 5.7 + 2.3)) /
      1.8;

  /// A steady pseudo-random 0..1 for patch [id], number [n].
  static double _vary(int id, int n) {
    final v = math.sin(id * 12.9898 + n * 78.233) * 43758.5453;
    return v - v.floorToDouble();
  }

  /// The ground's surface near (x, y) for a tongue's base; null if there
  /// is none close by (over a drop).
  double? _surface(int x, int y) {
    final t = sim.terrain;
    if (t.isSolid(x, y - 1)) {
      for (var k = 2; k <= _baseReach; k++) {
        if (!t.isSolid(x, y - k)) return (y - k + 1).toDouble();
      }
      return null;
    }
    for (var k = 0; k <= _baseReach; k++) {
      if (t.isSolid(x, y + k)) return (y + k).toDouble();
    }
    return null;
  }

  @override
  void render(ui.Canvas canvas) {
    final wind = sim.wind.toDouble();
    for (final f in sim.fires) {
      final id = f.id;
      // Catches quickly, smaller as it burns out, and no two the same.
      final caught = ((_time - (_born[id] ??= _time)) / 0.5).clamp(0.0, 1.0);
      final size = 0.8 + 0.5 * _vary(id, 0);
      final life =
          (0.55 + 0.45 * f.turnsLeft / FireConfig.turns) *
          size *
          (0.25 + 0.75 * caught);
      final x = f.x.toDouble();
      final y = f.y.toDouble() + 1;
      final seed = id * 1.7;

      // Smoke rising behind the flames, drifting with the wind.
      for (var i = 0; i < 3; i++) {
        final t = (_time * 0.28 + i / 3 + id * 0.13) % 1;
        final c = ui.Offset(
          x + math.sin(t * 4 + i + seed) * 4 + wind * t * 3,
          y - 16 * life - t * 46,
        );
        final a = (60 * math.sin(t * math.pi) * life).round().clamp(0, 255);
        final r = 6 + t * 16;
        canvas.drawCircle(
          c,
          r,
          // Soft all the way out: a flat disc shows as a disc.
          _smoke
            ..shader = ui.Gradient.radial(c, r, [
              ui.Color.fromARGB(a, 70, 62, 58),
              ui.Color.fromARGB(0, 70, 62, 58),
            ]),
        );
      }

      // Warm glow that pulses with the flames.
      final pulse = 1 + 0.16 * _flicker(_time * 7 + seed);
      final glow = ui.Offset(x, y - 7);
      final gr = 28 * life * pulse;
      canvas.drawCircle(
        glow,
        gr,
        _glow
          // The colour's alpha would scale the shader too.
          ..color = const ui.Color(0xFFFFFFFF)
          ..shader = ui.Gradient.radial(
            glow,
            gr,
            const [
              ui.Color(0x50FF9A3A),
              ui.Color(0x20FF6A1A),
              ui.Color(0x00FF6A1A),
            ],
            const [0, 0.5, 1],
          ),
      );
      _glow.shader = null;

      // Flame tongues on the ground under each, red outside to white-hot
      // at the base.
      final count = 4 + (_vary(id, 1) * 3).floor();
      for (var i = 0; i < count; i++) {
        final k = count == 1 ? 0.5 : i / (count - 1);
        final dx = (k - 0.5) * 22 * size + (_vary(id, 2 + i) - 0.5) * 5;
        final base = _surface((x + dx).round(), f.y);
        if (base == null) continue;
        final bx = x + dx;
        final by = base + 1;
        // Tallest in the middle, but unevenly so.
        final tall =
            (1 - (k - 0.5).abs() * 1.1) * (0.65 + 0.5 * _vary(id, 20 + i));
        final phase = _time * (7 + _vary(id, 40 + i) * 5) + seed + i * 2.1;
        final h = 21 * tall * life * (1 + 0.38 * _flicker(phase));
        final sway = 3 * _flicker(phase * 0.6 + 1) + wind * 0.3;
        final w = (2.8 + tall * 1.8) * life;

        // A glowing spot of ember where it stands.
        final heat = 0.5 + 0.5 * _flicker(phase * 0.4);
        _glow.color = ui.Color.fromARGB(
          (190 * heat).round(),
          255,
          110 + (90 * heat).round(),
          40,
        );
        canvas.drawCircle(ui.Offset(bx, by), 1.4 + w * 0.2, _glow);

        _tongue(canvas, bx, by, h, w, sway, 0xE6D8381A);
        _tongue(canvas, bx, by, h * 0.75, w * 0.75, sway * 0.8, 0xFFFF7A1A);
        _tongue(canvas, bx, by, h * 0.5, w * 0.5, sway * 0.5, 0xFFFFC23A);
        _tongue(canvas, bx, by, h * 0.22, w * 0.3, 0, 0xFFFFF4C8);

        // A flamelet breaks off the tip now and then and burns away.
        final t = (_time * (0.9 + _vary(id, 60 + i)) + _vary(id, 80 + i)) % 1;
        if (t < 0.45) {
          final up = t / 0.45;
          _paint.color = ui.Color.fromARGB(
            (220 * (1 - up)).round(),
            255,
            (170 - 80 * up).round(),
            40,
          );
          canvas.drawOval(
            ui.Rect.fromCenter(
              center: ui.Offset(
                bx + sway * (1 + up) + wind * up * 0.5,
                by - h * (0.9 + up * 0.8),
              ),
              width: w * 0.7 * (1 - up * 0.6),
              height: w * 1.3 * (1 - up * 0.6),
            ),
            _paint,
          );
        }
      }

      // Sparks flicking up and winking out.
      for (var i = 0; i < 4; i++) {
        final t = (_time * 0.75 + i * 0.27 + id * 0.31) % 1;
        final c = ui.Offset(
          x + math.sin(t * 9 + i * 2 + seed) * 7 + wind * t * 2,
          y - 6 - t * 46 * life,
        );
        _glow.color = ui.Color.fromARGB(
          (230 * (1 - t)).round(),
          255,
          i.isEven ? 210 : 150,
          70,
        );
        canvas.drawCircle(c, 1.1, _glow);
      }
    }
  }

  /// One flame tongue [h] tall and [w] wide at its base, tip leaning by
  /// [sway].
  void _tongue(
    ui.Canvas canvas,
    double x,
    double y,
    double h,
    double w,
    double sway,
    int argb,
  ) {
    final path = ui.Path()
      ..moveTo(x - w, y)
      ..cubicTo(
        x - w * 1.2,
        y - h * 0.4,
        x + sway * 0.3 - w * 0.4,
        y - h * 0.75,
        x + sway,
        y - h,
      )
      ..cubicTo(
        x + sway * 0.3 + w * 0.5,
        y - h * 0.7,
        x + w * 1.2,
        y - h * 0.4,
        x + w,
        y,
      )
      ..close();
    _paint.color = ui.Color(argb);
    canvas.drawPath(path, _paint);
  }
}
