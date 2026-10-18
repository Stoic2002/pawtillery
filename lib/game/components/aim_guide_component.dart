import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../config/controls.dart';
import '../../config/weapons.dart';
import '../../sim/physics.dart';
import '../../sim/world.dart';

/// Aim guide for the active unit: the first ~25 % of the no-wind path,
/// shown only while aiming. Recomputed when the aim, the unit's position or
/// the terrain changes.
class AimGuideComponent extends Component {
  AimGuideComponent({
    required this.sim,
    required this.isAiming,
    required this.angle,
    required this.power,
  }) : super(priority: 6);

  final SimWorld sim;
  final bool Function() isAiming;
  final int Function() angle;
  final int Function() power;

  final ui.Paint _dot = ui.Paint()..color = const ui.Color(0xE6FFFFFF);
  final ui.Paint _dotEdge = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..color = const ui.Color(0x99000000);

  // Numbers and units only, so no ARB entry is needed.
  final TextPaint _readout = TextPaint(
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w800,
      color: ui.Color(0xFFFFFFFF),
      shadows: [Shadow(color: ui.Color(0xFF000000), blurRadius: 3)],
    ),
  );

  List<double> _visible = const [];
  (int, int, double, double)? _cacheKey;
  bool _dirty = true;

  /// Call after the terrain changes; the path may now end elsewhere.
  void invalidate() => _dirty = true;

  @override
  void update(double dt) {
    final unit = sim.activeUnit;
    if (!isAiming() || unit == null || !unit.alive) {
      _visible = const [];
      return;
    }
    final key = (angle(), power(), unit.x, unit.y);
    if (!_dirty && key == _cacheKey) return;
    _cacheKey = key;
    _dirty = false;

    final (x, y) = SimWorld.launchOrigin(unit, key.$1);
    final path = ProjectilePhysics.predict(
      weapon: Weapons.rock,
      x: x,
      y: y,
      angleDeg: key.$1,
      powerPercent: key.$2,
      terrain: sim.terrain,
      waterLevel: sim.waterLevel,
    );
    final points = path.length ~/ 2;
    final keep = math.max(1, (points * ControlsConfig.aimGuideFraction).ceil());
    _visible = path.sublist(0, keep * 2);
  }

  @override
  void render(ui.Canvas canvas) {
    if (_visible.isEmpty) return;
    final unit = sim.activeUnit;
    if (unit != null) {
      // Angle and power beside the unit, on the side away from the shot.
      final side = (angle() > 90 && angle() < 270) ? 1 : -1;
      _readout.render(
        canvas,
        '${angle()}°  ${power()}%',
        Vector2(unit.centerX + side * (unit.stats.hitRadius + 8),
            unit.centerY + 4),
        anchor: side > 0 ? Anchor.centerLeft : Anchor.centerRight,
      );
    }
    // Every 3rd tick so the dots read as a dotted line.
    for (var i = 0; i < _visible.length; i += 6) {
      final o = ui.Offset(_visible[i], _visible[i + 1]);
      canvas
        ..drawCircle(o, 4, _dot)
        ..drawCircle(o, 4, _dotEdge);
    }
  }
}
