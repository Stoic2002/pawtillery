import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../config/controls.dart';
import '../../config/weapons.dart';
import '../../sim/physics.dart';
import '../../sim/world.dart';
import '../hud_state.dart';

/// Aiming visuals for the active unit, depending on the weapon:
/// - thrown weapons: the first ~25 % of the no-wind path (PRD), plus the
///   angle/power readout next to the unit;
/// - boomerang: its straight line to the turning point;
/// - direction weapons: an arrow;
/// - target weapons: a crosshair (green if allowed, red if not).
class AimGuideComponent extends Component {
  AimGuideComponent({required this.sim, required this.aim})
      : super(priority: 6);

  final SimWorld sim;
  final AimState Function() aim;

  final ui.Paint _dot = ui.Paint()..color = const ui.Color(0xE6FFFFFF);
  final ui.Paint _dotEdge = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..color = const ui.Color(0x99000000);
  final ui.Paint _line = ui.Paint()
    ..strokeWidth = 4
    ..strokeCap = ui.StrokeCap.round
    ..color = const ui.Color(0xCCFFFFFF);
  final ui.Paint _cross = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 3;

  // Numbers and units only, so no ARB entry is needed.
  final TextPaint _readout = TextPaint(
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w800,
      color: ui.Color(0xFFFFFFFF),
      shadows: [Shadow(color: ui.Color(0xFF000000), blurRadius: 3)],
    ),
  );

  List<double> _path = const [];
  Object? _cacheKey;
  bool _dirty = true;

  /// Call after the terrain changes; the path may now end elsewhere.
  void invalidate() => _dirty = true;

  @override
  void update(double dt) {
    final a = aim();
    final unit = sim.activeUnit;
    final weapon = Weapons.byId(a.weaponId);
    final thrown = weapon.aim == AimMode.angleAndPower &&
        weapon.flight is! Boomerang;
    if (!a.active || unit == null || !unit.alive || !thrown) {
      _path = const [];
      return;
    }
    final key = (a.weaponId, a.angle, a.power, unit.x, unit.y);
    if (!_dirty && key == _cacheKey) return;
    _cacheKey = key;
    _dirty = false;

    final (x, y) = SimWorld.launchOrigin(unit, a.angle);
    final path = ProjectilePhysics.predict(
      weapon: weapon,
      x: x,
      y: y,
      angleDeg: a.angle,
      powerPercent: a.power,
      terrain: sim.terrain,
      waterLevel: sim.waterLevel,
      speedScale: unit.stats.firePowerScale,
    );
    final points = path.length ~/ 2;
    final keep = math.max(1, (points * ControlsConfig.aimGuideFraction).ceil());
    _path = path.sublist(0, keep * 2);
  }

  @override
  void render(ui.Canvas canvas) {
    final a = aim();
    final unit = sim.activeUnit;
    if (unit == null || !unit.alive) return;
    final weapon = Weapons.byId(a.weaponId);

    if (weapon.aim == AimMode.target) {
      final tx = a.targetX;
      final ty = a.targetY;
      if (tx == null || ty == null) return;
      _cross.color = a.targetValid
          ? const ui.Color(0xFF00E676)
          : const ui.Color(0xFFFF1744);
      final c = ui.Offset(tx.toDouble(), ty.toDouble());
      canvas
        ..drawCircle(c, 14, _cross)
        ..drawLine(c - const ui.Offset(22, 0), c + const ui.Offset(22, 0), _cross)
        ..drawLine(c - const ui.Offset(0, 22), c + const ui.Offset(0, 22), _cross);
      if (weapon.delivery is AirStrike) {
        canvas.drawLine(ui.Offset(c.dx, 0), ui.Offset(c.dx, c.dy - 22), _cross);
      }
      return;
    }
    if (!a.active) return;

    final rad = a.angle * math.pi / 180;
    final dir = ui.Offset(math.cos(rad), -math.sin(rad));
    final center = ui.Offset(unit.centerX, unit.centerY);
    final flight = weapon.flight;
    if (weapon.aim == AimMode.direction) {
      final start = center + dir * (unit.stats.hitRadius + 6);
      canvas.drawLine(start, start + dir * 40, _line);
    } else if (flight is Boomerang) {
      final range = flight.minRange +
          (flight.maxRange - flight.minRange) * a.power / 100;
      final start = center + dir * (unit.stats.hitRadius + 6);
      for (var d = 0.0; d < range * ControlsConfig.aimGuideFraction * 2;
          d += 18) {
        canvas.drawCircle(start + dir * d, 4, _dot);
      }
    }

    // Every 3rd tick so the dots read as a dotted line.
    for (var i = 0; i < _path.length; i += 6) {
      final o = ui.Offset(_path[i], _path[i + 1]);
      canvas
        ..drawCircle(o, 4, _dot)
        ..drawCircle(o, 4, _dotEdge);
    }

    if (weapon.aim == AimMode.angleAndPower || weapon.aim == AimMode.direction) {
      // Readout beside the unit, on the side away from the shot.
      final side = dir.dx < 0 ? 1 : -1;
      final text = weapon.aim == AimMode.direction
          ? '${a.angle}°'
          : '${a.angle}°  ${a.power}%';
      _readout.render(
        canvas,
        text,
        Vector2(unit.centerX + side * (unit.stats.hitRadius + 8),
            unit.centerY + 4),
        anchor: side > 0 ? Anchor.centerLeft : Anchor.centerRight,
      );
    }
  }
}
