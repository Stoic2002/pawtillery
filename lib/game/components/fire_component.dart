import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../config/weapons.dart';
import '../../sim/world.dart';

/// Draws napalm fire on the ground: each patch a cluster of flame tongues
/// that flicker unevenly and lean with the wind over a glowing ember bed,
/// with sparks rising, a thin smoke trail and a warm pulsing glow. Lower
/// as it burns out.
class FireComponent extends Component {
  FireComponent(this.sim) : super(priority: 5);

  final SimWorld sim;
  double _time = 0;

  final ui.Paint _paint = ui.Paint();
  final ui.Paint _glow = ui.Paint()..blendMode = ui.BlendMode.plus;
  final ui.Paint _smoke = ui.Paint();

  /// Tongues of one patch, left to right: offset (px) and height.
  static const _tongues = [
    (-8.0, 0.55),
    (-4.0, 0.85),
    (0.0, 1.0),
    (4.0, 0.8),
    (8.0, 0.5),
  ];

  @override
  void update(double dt) => _time += dt;

  /// Uneven flicker in about -1..1: a few sines at unrelated speeds.
  static double _flicker(double t) =>
      (math.sin(t) +
          0.5 * math.sin(t * 2.3 + 1.1) +
          0.3 * math.sin(t * 5.7 + 2.3)) /
      1.8;

  @override
  void render(ui.Canvas canvas) {
    final wind = sim.wind.toDouble();
    for (final f in sim.fires) {
      // Smaller as it burns out.
      final life = 0.55 + 0.45 * f.turnsLeft / FireConfig.turns;
      final x = f.x.toDouble();
      final y = f.y.toDouble() + 1;
      final seed = f.id * 1.7;

      // Smoke rising behind the flames, drifting with the wind.
      for (var i = 0; i < 3; i++) {
        final t = (_time * 0.32 + i / 3 + f.id * 0.13) % 1;
        final c = ui.Offset(
          x + math.sin(t * 4 + i + seed) * 3 + wind * t * 2.2,
          y - 16 * life - t * 40,
        );
        _smoke.color = ui.Color.fromARGB(
          (38 * math.sin(t * math.pi) * life).round(),
          70,
          62,
          58,
        );
        canvas.drawCircle(c, 4 + t * 13, _smoke);
      }

      // Warm glow that pulses with the flames.
      final pulse = 1 + 0.12 * _flicker(_time * 6 + seed);
      final glow = ui.Offset(x, y - 7);
      final gr = 30 * life * pulse;
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

      // Ember bed: dark char with spots glowing on and off.
      _paint.color = const ui.Color(0xFF5A1C10);
      canvas.drawOval(
        ui.Rect.fromCenter(center: ui.Offset(x, y), width: 24, height: 6),
        _paint,
      );
      for (var i = 0; i < 4; i++) {
        final heat = 0.5 + 0.5 * _flicker(_time * 3 + i * 2.1 + seed);
        _glow.color = ui.Color.fromARGB(
          (200 * heat).round(),
          255,
          120 + (80 * heat).round(),
          40,
        );
        canvas.drawCircle(ui.Offset(x - 8 + i * 5.3, y), 1.6, _glow);
      }

      // Flame tongues, red outside to white-hot at the base.
      for (var i = 0; i < _tongues.length; i++) {
        final (dx, tall) = _tongues[i];
        final phase = _time * (6 + i * 1.3) + seed + i * 2.1;
        final h = 20 * tall * life * (1 + 0.28 * _flicker(phase));
        final sway = 2.4 * _flicker(phase * 0.7 + 1) + wind * 0.25;
        final w = (3.6 + tall * 1.6) * life;
        final bx = x + dx;
        _tongue(canvas, bx, y, h, w, sway, 0xE6D8381A);
        _tongue(canvas, bx, y, h * 0.75, w * 0.75, sway * 0.8, 0xFFFF7A1A);
        _tongue(canvas, bx, y, h * 0.5, w * 0.5, sway * 0.5, 0xFFFFC23A);
        _tongue(canvas, bx, y, h * 0.22, w * 0.3, 0, 0xFFFFF4C8);
      }

      // Sparks flicking up and winking out.
      for (var i = 0; i < 4; i++) {
        final t = (_time * 0.75 + i * 0.27 + f.id * 0.31) % 1;
        final c = ui.Offset(
          x + math.sin(t * 9 + i * 2 + seed) * 6 + wind * t * 1.5,
          y - 6 - t * 42 * life,
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
