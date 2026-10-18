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

/// Translucent water from the current water level (it rises in sudden
/// death) to the bottom of the map and across the side margins, drawn over
/// the terrain.
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
    ..strokeWidth = 2.5
    ..color = const ui.Color(0x88FFFFFF);
  final ui.Paint _glint = ui.Paint()..color = const ui.Color(0x55FFFFFF);
  final ui.Path _wave = ui.Path();
  double _time = 0;

  @override
  void update(double dt) => _time += dt;

  @override
  void render(ui.Canvas canvas) {
    const side = ControlsConfig.cameraMarginSide;
    final top = level().toDouble();
    final left = -side;
    final right = worldSize.x + side;
    _wave.reset();
    _wave.moveTo(left, worldSize.y);
    for (var x = left; x <= right; x += 16) {
      _wave.lineTo(
          x,
          top +
              math.sin(x / 46 + _time * 1.8) * 2.2 +
              math.sin(x / 19 - _time * 2.6) * 1.1);
    }
    _wave
      ..lineTo(right, worldSize.y)
      ..close();
    final base = ui.Color(map.waterArgb);
    _body.shader = ui.Gradient.linear(
      ui.Offset(0, top),
      ui.Offset(0, worldSize.y),
      [
        ui.Color.lerp(base, const ui.Color(0xFFFFFFFF), 0.18)!
            .withValues(alpha: base.a),
        ui.Color.lerp(base, const ui.Color(0xFF00101C), 0.5)!
            .withValues(alpha: (base.a + 0.15).clamp(0, 1)),
      ],
    );
    canvas
      ..drawPath(_wave, _body)
      ..save()
      ..clipRect(ui.Rect.fromLTRB(left, top - 6, right, top + 4))
      ..drawPath(_wave, _crest)
      ..restore();
    // Drifting glints just under the surface.
    for (var i = 0; i < 24; i++) {
      final x = (i * 157.0 + _time * (10 + i % 5 * 4)) % (right - left) + left;
      final y = top + 10 + (i * 37) % 60;
      canvas.drawRect(ui.Rect.fromLTWH(x, y, 14 + (i % 3) * 6, 1.6), _glint);
    }
  }
}
