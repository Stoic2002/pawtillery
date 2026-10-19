import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../config/maps.dart';
import '../art/scenery.dart';

/// Background behind the terrain: the theme's sky (moon and stars and
/// bats, a storm with lightning and rain, or a fire-lit dusk with embers),
/// clouds, and the map's scenery layers. Each layer follows the camera at its own speed
/// (parallax), so distant things move less and the scene reads as deep.
class SceneryComponent extends Component {
  SceneryComponent({
    required this.map,
    required this.worldSize,
    required this.cameraPosition,
  }) : super(priority: -9);

  final MapDef map;
  final Vector2 worldSize;
  final Vector2 Function() cameraPosition;

  late final List<SceneryLayer> _layers = Scenery.build(
    map,
    worldSize.x,
    worldSize.y,
  );
  double _time = 0;

  @override
  void update(double dt) => _time += dt;

  /// World offset that makes something drawn at world position p appear to
  /// move at [parallax] times the camera speed (vertical a bit less).
  ui.Offset _shift(double parallax) {
    final cam = cameraPosition();
    final dx = (cam.x - worldSize.x / 2) * (1 - parallax);
    final dy = (cam.y - worldSize.y / 2) * (1 - parallax) * 0.6;
    return ui.Offset(dx, dy);
  }

  @override
  void render(ui.Canvas canvas) {
    switch (map.theme) {
      case MapTheme.castle:
        _stars(canvas);
        _moon(canvas);
        _clouds(canvas, const ui.Color(0xCC2A3050), const ui.Color(0xE0384068));
      case MapTheme.wreck:
        _lightning(canvas);
        _clouds(
          canvas,
          const ui.Color(0xF0262B32),
          const ui.Color(0xF0383E46),
          count: 9,
          speed: 2.2,
          low: true,
        );
      case MapTheme.ruins:
        _sun(canvas);
        _clouds(canvas, const ui.Color(0xB03A2A28), const ui.Color(0xC0503A34));
    }
    for (final layer in _layers) {
      final shift = _shift(layer.parallax);
      canvas
        ..save()
        ..translate(shift.dx, shift.dy)
        ..drawPicture(layer.picture)
        ..restore();
    }
    switch (map.theme) {
      case MapTheme.castle:
        _bats(canvas);
      case MapTheme.wreck:
        _rain(canvas);
      case MapTheme.ruins:
        _embers(canvas);
    }
  }

  // ---------------------------------------------------------------- castle

  void _stars(ui.Canvas canvas) {
    final shift = _shift(0.02);
    for (var i = 0; i < 90; i++) {
      final x = (i * 263.7) % (worldSize.x * 1.4) - worldSize.x * 0.2;
      final y = (i * 97.3) % (worldSize.y * 0.5);
      final twinkle = 0.5 + 0.5 * math.sin(_time * (1 + i % 3) + i);
      _star.color = const ui.Color(
        0xFFFFFFFF,
      ).withValues(alpha: 0.3 + twinkle * 0.6);
      canvas.drawCircle(ui.Offset(x, y) + shift, 1 + (i % 3) * 0.6, _star);
    }
  }

  final ui.Paint _star = ui.Paint();

  void _moon(ui.Canvas canvas) {
    final c = ui.Offset(worldSize.x * 0.72, worldSize.y * 0.16) + _shift(0.04);
    canvas
      ..drawCircle(
        c,
        300,
        ui.Paint()
          ..shader = ui.Gradient.radial(c, 300, [
            const ui.Color(0x66C8D4FF),
            const ui.Color(0x00C8D4FF),
          ]),
      )
      ..drawCircle(c, 70, ui.Paint()..color = const ui.Color(0xFFF2F0DC));
    final crater = ui.Paint()..color = const ui.Color(0x33A0A090);
    for (final (dx, dy, r) in const [
      (-22.0, -14.0, 14.0),
      (18.0, 10.0, 18.0),
      (-8.0, 30.0, 9.0),
      (30.0, -26.0, 8.0),
    ]) {
      canvas.drawCircle(c.translate(dx, dy), r, crater);
    }
  }

  /// A few bats flitting across the moonlit sky.
  void _bats(ui.Canvas canvas) {
    final paint = ui.Paint()..color = const ui.Color(0xFF07080F);
    for (var i = 0; i < 5; i++) {
      final t = _time * (0.05 + i * 0.012) + i * 0.21;
      final x = (t % 1.3 - 0.15) * worldSize.x;
      final y = worldSize.y * (0.12 + 0.05 * i) + math.sin(_time * 2 + i) * 30;
      final flap = math.sin(_time * 14 + i * 2) * 7;
      canvas.drawPath(
        ui.Path()
          ..moveTo(x - 16, y - flap)
          ..quadraticBezierTo(x - 8, y - 2, x, y + 3)
          ..quadraticBezierTo(x + 8, y - 2, x + 16, y - flap)
          ..quadraticBezierTo(x + 6, y + 4, x, y + 7)
          ..quadraticBezierTo(x - 6, y + 4, x - 16, y - flap)
          ..close(),
        paint,
      );
    }
  }

  // ----------------------------------------------------------------- wreck

  /// Every few seconds the storm flashes: the sky lights up for a moment.
  void _lightning(ui.Canvas canvas) {
    final cycle = _time % 7.3;
    if (cycle > 0.5) return;
    final strength = (cycle < 0.08 || (cycle > 0.18 && cycle < 0.26))
        ? 0.45
        : 0.12 * (1 - cycle / 0.5);
    canvas.drawRect(
      ui.Rect.fromLTWH(-worldSize.x, -800, worldSize.x * 3, worldSize.y + 800),
      ui.Paint()
        ..color = const ui.Color(0xFFDDE6FF).withValues(alpha: strength),
    );
    if (cycle < 0.26) {
      // The bolt itself, far off.
      final x = worldSize.x * 0.3 + (_time ~/ 7.3 % 5) * 280;
      final bolt = ui.Path()..moveTo(x, -100);
      var y = -100.0;
      var bx = x;
      var k = 0;
      while (y < worldSize.y * 0.6) {
        y += 50;
        bx += (k.isEven ? 1 : -1) * (14 + (k * 7) % 20);
        bolt.lineTo(bx, y);
        k++;
      }
      canvas.drawPath(
        bolt,
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const ui.Color(0xCCF4F6FF),
      );
    }
  }

  void _rain(ui.Canvas canvas) {
    final paint = ui.Paint()
      ..color = const ui.Color(0x55C8D2DC)
      ..strokeWidth = 1.4;
    for (var i = 0; i < 260; i++) {
      final speed = 900 + (i % 5) * 120;
      final x = (i * 37.9 + _time * 160) % (worldSize.x + 400) - 200;
      final y = (i * 71.3 + _time * speed) % (worldSize.y + 200) - 100;
      canvas.drawLine(ui.Offset(x, y), ui.Offset(x - 6, y + 22), paint);
    }
  }

  // ----------------------------------------------------------------- ruins

  void _sun(ui.Canvas canvas) {
    final c = ui.Offset(worldSize.x * 0.3, worldSize.y * 0.36) + _shift(0.05);
    canvas
      ..drawCircle(
        c,
        320,
        ui.Paint()
          ..shader = ui.Gradient.radial(c, 320, [
            const ui.Color(0x88FF8A3A),
            const ui.Color(0x00FF8A3A),
          ]),
      )
      ..drawCircle(c, 64, ui.Paint()..color = const ui.Color(0xFFFFB46A));
  }

  /// Embers drifting up from the fires.
  void _embers(ui.Canvas canvas) {
    final paint = ui.Paint()..blendMode = ui.BlendMode.plus;
    for (var i = 0; i < 70; i++) {
      final rise = 40 + (i % 6) * 12.0;
      final x = (i * 151.3 + math.sin(_time * 0.9 + i) * 30) % worldSize.x;
      final y = worldSize.y - (i * 83.1 + _time * rise) % worldSize.y;
      final glow = 0.5 + 0.5 * math.sin(_time * 5 + i);
      paint.color = ui.Color.lerp(
        const ui.Color(0xFFFF6A1A),
        const ui.Color(0xFFFFD27A),
        glow,
      )!.withValues(alpha: 0.4 + glow * 0.5);
      canvas.drawCircle(ui.Offset(x, y), 1.4 + (i % 3) * 0.6, paint);
    }
  }

  // ----------------------------------------------------------------- shared

  /// Slow cloud banks in the theme's colours: a darker underside below a
  /// lighter top.
  void _clouds(
    ui.Canvas canvas,
    ui.Color under,
    ui.Color top, {
    int count = 6,
    double speed = 1,
    bool low = false,
  }) {
    final shift = _shift(0.12);
    final span = worldSize.x * 2;
    _shade.color = under;
    _puff.color = top;
    for (var i = 0; i < count; i++) {
      final v = (5 + i * 1.5) * speed;
      final x = ((i * 611.0 + _time * v) % span) - worldSize.x * 0.5;
      final y = (low ? 40.0 : 90.0) + (i * 113) % (low ? 300 : 240);
      final s = (low ? 1.3 : 0.8) + (i % 3) * 0.3;
      final o = ui.Offset(x, y) + shift;
      for (final pass in [0, 1]) {
        for (final (dx, dy, r) in _puffs) {
          canvas.drawCircle(
            o + ui.Offset(dx * s, dy * s + (pass == 0 ? r * s * 0.22 : 0)),
            r * s * (pass == 0 ? 1 : 0.9),
            pass == 0 ? _shade : _puff,
          );
        }
      }
    }
  }

  static const _puffs = [
    (0.0, 0.0, 46.0),
    (-50.0, 14.0, 34.0),
    (52.0, 12.0, 38.0),
    (18.0, -24.0, 34.0),
    (-88.0, 24.0, 22.0),
    (92.0, 24.0, 24.0),
  ];
  final ui.Paint _puff = ui.Paint();
  final ui.Paint _shade = ui.Paint();

  @override
  void onRemove() {
    for (final l in _layers) {
      l.picture.dispose();
    }
    super.onRemove();
  }
}
