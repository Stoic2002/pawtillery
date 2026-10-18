import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../config/maps.dart';
import '../art/scenery.dart';

/// Background behind the terrain: sun, drifting clouds and the map's
/// scenery layers. Each layer follows the camera at its own speed
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

  late final List<SceneryLayer> _layers =
      Scenery.build(map, worldSize.x, worldSize.y);
  double _time = 0;

  bool get _outdoor => map.theme != MapTheme.warehouse;

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
    if (_outdoor) {
      _sun(canvas);
      _clouds(canvas);
    }
    for (final layer in _layers) {
      final shift = _shift(layer.parallax);
      canvas
        ..save()
        ..translate(shift.dx, shift.dy)
        ..drawPicture(layer.picture)
        ..restore();
    }
  }

  void _sun(ui.Canvas canvas) {
    final shift = _shift(0.05);
    final evening = map.theme == MapTheme.park;
    final center = ui.Offset(
            worldSize.x * (evening ? 0.22 : 0.8), worldSize.y * (evening ? 0.42 : 0.12)) +
        shift;
    final core = evening ? const ui.Color(0xFFFFC27A) : const ui.Color(0xFFFFF4C8);
    canvas
      ..drawCircle(
          center,
          260,
          ui.Paint()
            ..shader = ui.Gradient.radial(center, 260,
                [core.withValues(alpha: 0.45), core.withValues(alpha: 0)]))
      ..drawCircle(center, 46, ui.Paint()..color = core);
  }

  /// Soft, layered cloud banks: many translucent puffs that fade at the
  /// edges, flatter at the bottom, drifting slowly.
  void _clouds(ui.Canvas canvas) {
    final shift = _shift(0.12);
    final span = worldSize.x * 2;
    for (var i = 0; i < 6; i++) {
      final speed = 5 + i * 1.5;
      final x = ((i * 611.0 + _time * speed) % span) - worldSize.x * 0.5;
      final y = 70.0 + (i * 113) % 240;
      final s = 0.8 + (i % 3) * 0.3;
      final o = ui.Offset(x, y) + shift;
      for (var k = 0; k < 9; k++) {
        final dx = (k - 4) * 26.0 * s;
        final dy = -((4 - (k - 4).abs()) * 7.0 + (k * 37 % 11)) * s;
        final r = (34 + (k * 53 % 17)) * s;
        final c = o + ui.Offset(dx, dy);
        _puff.shader = ui.Gradient.radial(c, r, const [
          ui.Color(0x99FFFFFF),
          ui.Color(0x55F4F8FC),
          ui.Color(0x00F4F8FC),
        ], const [
          0,
          0.6,
          1,
        ]);
        canvas.drawCircle(c, r, _puff);
      }
    }
  }

  final ui.Paint _puff = ui.Paint();

  @override
  void onRemove() {
    for (final l in _layers) {
      l.picture.dispose();
    }
    super.onRemove();
  }
}

