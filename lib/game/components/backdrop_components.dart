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

/// Translucent water from [MapDef.waterLevel] to the bottom of the map
/// (and across the side margins), drawn over the terrain.
class WaterComponent extends PositionComponent {
  WaterComponent({required this.map, required Vector2 worldSize})
      : super(
          position: Vector2(-ControlsConfig.cameraMarginSide,
              map.waterLevel.toDouble()),
          size: Vector2(worldSize.x + ControlsConfig.cameraMarginSide * 2,
              worldSize.y - map.waterLevel),
          priority: 10,
        );

  final MapDef map;
  late final ui.Paint _paint = ui.Paint()..color = ui.Color(map.waterArgb);

  @override
  void render(ui.Canvas canvas) => canvas.drawRect(size.toRect(), _paint);
}
