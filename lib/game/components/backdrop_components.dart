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

  late final ui.Paint _paint = ui.Paint()..color = ui.Color(map.waterArgb);
  final ui.Paint _surface = ui.Paint()..color = const ui.Color(0x66FFFFFF);

  @override
  void render(ui.Canvas canvas) {
    const side = ControlsConfig.cameraMarginSide;
    final top = level().toDouble();
    canvas
      ..drawRect(
          ui.Rect.fromLTRB(-side, top, worldSize.x + side, worldSize.y), _paint)
      ..drawRect(
          ui.Rect.fromLTRB(-side, top, worldSize.x + side, top + 3), _surface);
  }
}
