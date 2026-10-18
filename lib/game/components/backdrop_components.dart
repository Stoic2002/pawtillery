import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../config/maps.dart';

/// Sky gradient behind the whole map.
class SkyComponent extends PositionComponent {
  SkyComponent({required this.map, required Vector2 worldSize})
      : super(size: worldSize, priority: -10);

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

/// Translucent water from [MapDef.waterLevel] to the bottom of the map,
/// drawn over the terrain.
class WaterComponent extends PositionComponent {
  WaterComponent({required this.map, required Vector2 worldSize})
      : super(
          position: Vector2(0, map.waterLevel.toDouble()),
          size: Vector2(worldSize.x, worldSize.y - map.waterLevel),
          priority: 10,
        );

  final MapDef map;
  late final ui.Paint _paint = ui.Paint()..color = ui.Color(map.waterArgb);

  @override
  void render(ui.Canvas canvas) => canvas.drawRect(size.toRect(), _paint);
}
