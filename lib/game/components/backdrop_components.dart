import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../config/controls.dart';
import '../../config/maps.dart';

/// Sky gradient behind the whole map, extended over the area the camera
/// may show past the map edges.
class SkyComponent extends PositionComponent {
  SkyComponent({required this.map, required Vector2 worldSize})
      : super(
          position: Vector2(-_side, -_top),
          size: worldSize + Vector2(_side * 2, _top),
          priority: -10,
        );

  static const double _side = ControlsConfig.cameraMarginSide;
  static const double _top = ControlsConfig.cameraMarginTop;

  final MapDef map;
  late final ui.Paint _paint = ui.Paint()
    ..shader = ui.Gradient.linear(
      ui.Offset.zero,
      ui.Offset(0, size.y),
      [ui.Color(map.skyTopArgb), ui.Color(map.skyBottomArgb)],
    );

  @override
  void render(ui.Canvas canvas) => canvas.drawRect(size.toRect(), _paint);
}

/// The sea behind the terrain: a darker swell a little above the water
/// line, so islands sit *in* the water with sea visible behind them, the
/// way a painted horizon does.
class WaterBackComponent extends Component {
  WaterBackComponent({
    required this.map,
    required this.worldSize,
    required this.level,
  }) : super(priority: -1);

  final MapDef map;
  final Vector2 worldSize;
  final int Function() level;

  final ui.Paint _body = ui.Paint();
  final ui.Path _wave = ui.Path();
  double _time = 0;

  @override
  void update(double dt) => _time += dt;

  @override
  void render(ui.Canvas canvas) {
    const side = ControlsConfig.cameraMarginSide;
    final top = level() - 14.0;
    final left = -side;
    final right = worldSize.x + side;
    _wave
      ..reset()
      ..moveTo(left, worldSize.y + 400);
    for (var x = left; x <= right; x += 12) {
      _wave.lineTo(
        x,
        top +
            math.sin(x / 70 + _time * 0.9) * 3.5 +
            math.sin(x / 27 - _time * 1.4) * 1.6,
      );
    }
    _wave
      ..lineTo(right, worldSize.y + 400)
      ..close();
    final base = ui.Color(map.waterArgb).withValues(alpha: 1);
    _body.shader = ui.Gradient.linear(
      ui.Offset(0, top),
      ui.Offset(0, top + 160),
      [
        ui.Color.lerp(base, ui.Color(map.skyBottomArgb), 0.35)!,
        ui.Color.lerp(base, const ui.Color(0xFF02070C), 0.55)!,
      ],
    );
    canvas.drawPath(_wave, _body);
  }
}

/// The water in front of everything from the current water level (it
/// rises in sudden death) down: translucent near the surface and deep
/// and dark below, with a rolling surface, a lit crest and its shadowed
/// trough, broken foam, and caustic ripples drifting under the surface.
class WaterComponent extends Component {
  WaterComponent({
    required this.map,
    required this.worldSize,
    required this.level,
  }) : super(priority: 10);

  final MapDef map;
  final Vector2 worldSize;
  final int Function() level;

  final ui.Paint _body = ui.Paint();
  final ui.Paint _crest = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = ui.StrokeCap.round;
  final ui.Paint _trough = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 5;
  final ui.Paint _foam = ui.Paint()..strokeCap = ui.StrokeCap.round;
  final ui.Paint _caustic = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1.4
    ..strokeCap = ui.StrokeCap.round;
  final ui.Path _wave = ui.Path();
  final ui.Path _surface = ui.Path();
  double _time = 0;

  @override
  void update(double dt) => _time += dt;

  double _height(double x) =>
      math.sin(x / 52 + _time * 1.5) * 2.6 +
      math.sin(x / 23 - _time * 2.3) * 1.3 +
      math.sin(x / 9 + _time * 3.1) * 0.5;

  @override
  void render(ui.Canvas canvas) {
    const side = ControlsConfig.cameraMarginSide;
    final top = level().toDouble();
    final left = -side;
    final right = worldSize.x + side;
    final bottom = worldSize.y + 400;
    _wave
      ..reset()
      ..moveTo(left, bottom);
    _surface.reset();
    for (var x = left; x <= right; x += 8) {
      final y = top + _height(x);
      _wave.lineTo(x, y);
      x == left ? _surface.moveTo(x, y) : _surface.lineTo(x, y);
    }
    _wave
      ..lineTo(right, bottom)
      ..close();

    final base = ui.Color(map.waterArgb).withValues(alpha: 1);
    final shallow = ui.Color.lerp(base, ui.Color(map.skyBottomArgb), 0.25)!;
    final deep = ui.Color.lerp(base, const ui.Color(0xFF01060B), 0.7)!;
    _body.shader = ui.Gradient.linear(
      ui.Offset(0, top),
      ui.Offset(0, top + 120),
      [
        shallow.withValues(alpha: 0.55),
        base.withValues(alpha: 0.78),
        deep.withValues(alpha: 0.96),
      ],
      const [0, 0.35, 1],
    );
    canvas.drawPath(_wave, _body);

    // Caustic ripples just under the surface.
    _caustic.color = const ui.Color(0x2EFFFFFF);
    for (var row = 0; row < 4; row++) {
      final y0 = top + 14 + row * 15;
      for (var i = 0; i < 18; i++) {
        final x0 =
            left +
            ((i * 211.0 + row * 97 + _time * (14 + row * 5)) %
                (right - left));
        final len = 22.0 + (i * 13 % 20);
        final p = ui.Path()..moveTo(x0, y0);
        for (var t = 4.0; t <= len; t += 4) {
          p.lineTo(x0 + t, y0 + math.sin((x0 + t) / 7 + _time * 2) * 1.6);
        }
        canvas.drawPath(p, _caustic);
      }
    }

    // Shadowed trough under the crest, then the lit crest line.
    _trough.color = deep.withValues(alpha: 0.35);
    canvas
      ..save()
      ..translate(0, 4)
      ..drawPath(_surface, _trough)
      ..restore();
    _crest.color = ui.Color.lerp(
      shallow,
      const ui.Color(0xFFFFFFFF),
      0.55,
    )!.withValues(alpha: 0.85);
    canvas.drawPath(_surface, _crest);

    // Broken foam caps where the waves peak.
    for (var x = left; x <= right; x += 6) {
      final h = _height(x);
      if (h > -2.2) continue;
      final flicker = math.sin(x * 0.37 + _time * 4) * 0.5 + 0.5;
      _foam
        ..color = const ui.Color(0xFFFFFFFF).withValues(alpha: 0.35 + flicker * 0.4)
        ..strokeWidth = 1.6 + flicker * 1.4;
      canvas.drawLine(
        ui.Offset(x, top + h - 0.5),
        ui.Offset(x + 4, top + _height(x + 4) - 0.5),
        _foam,
      );
    }
  }
}
