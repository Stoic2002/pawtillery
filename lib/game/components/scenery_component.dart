import 'dart:math' as math;
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
    _sun(canvas);
    _clouds(canvas);
    for (final layer in _layers) {
      final shift = _shift(layer.parallax);
      canvas
        ..save()
        ..translate(shift.dx, shift.dy)
        ..drawPicture(layer.picture)
        ..restore();
    }
    if (map.theme == MapTheme.snow) _snowfall(canvas);
  }

  void _sun(ui.Canvas canvas) {
    final shift = _shift(0.05);
    final morning = map.theme == MapTheme.snow;
    final center =
        ui.Offset(
          worldSize.x * (morning ? 0.25 : 0.8),
          worldSize.y * (morning ? 0.2 : 0.12),
        ) +
        shift;
    final core = morning
        ? const ui.Color(0xFFFFE0B8)
        : const ui.Color(0xFFFFE066);
    canvas
      ..drawCircle(
        center,
        280,
        ui.Paint()
          ..shader = ui.Gradient.radial(center, 280, [
            core.withValues(alpha: 0.5),
            core.withValues(alpha: 0),
          ]),
      )
      ..drawCircle(center, 58, ui.Paint()..color = core)
      ..drawCircle(
        center.translate(-8, -8),
        44,
        ui.Paint()..color = const ui.Color(0x66FFFFFF),
      );
  }

  /// Puffy cartoon clouds (as on the menus): white puffs over a cool
  /// shaded underside, drifting slowly.
  void _clouds(ui.Canvas canvas) {
    final shift = _shift(0.12);
    final span = worldSize.x * 2;
    for (var i = 0; i < 6; i++) {
      final speed = 5 + i * 1.5;
      final x = ((i * 611.0 + _time * speed) % span) - worldSize.x * 0.5;
      final y = 90.0 + (i * 113) % 240;
      final s = 0.8 + (i % 3) * 0.3;
      final o = ui.Offset(x, y) + shift;
      for (final pass in [0, 1]) {
        for (final (dx, dy, r) in _puffs) {
          canvas.drawCircle(
            o + ui.Offset(dx * s, dy * s + (pass == 0 ? r * s * 0.18 : 0)),
            r * s * (pass == 0 ? 1 : 0.92),
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
  final ui.Paint _puff = ui.Paint()..color = const ui.Color(0xF2FFFFFF);
  final ui.Paint _shade = ui.Paint()..color = const ui.Color(0xCCCFE3F2);

  /// Gentle snowfall over the backdrop.
  void _snowfall(ui.Canvas canvas) {
    for (var i = 0; i < 140; i++) {
      final fall = 30 + (i % 7) * 6.0;
      final x = (i * 97.3 + math.sin(_time * 0.8 + i) * 14) % worldSize.x;
      final y = (i * 53.7 + _time * fall) % worldSize.y;
      canvas.drawCircle(ui.Offset(x, y), 1.5 + (i % 3), _flake);
    }
  }

  final ui.Paint _flake = ui.Paint()..color = const ui.Color(0xCCFFFFFF);

  @override
  void onRemove() {
    for (final l in _layers) {
      l.picture.dispose();
    }
    super.onRemove();
  }
}

