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
/// - thrown weapons: a crosshair in the team's colour at the aim angle with
///   a ring that fills with power, the first ~25 % of the no-wind path
///   (PRD), and the angle/power readout next to the unit;
/// - boomerang: its straight line to the turning point;
/// - direction weapons: an arrow;
/// - target weapons: a crosshair (green if allowed, red if not).
class AimGuideComponent extends Component {
  AimGuideComponent({
    required this.sim,
    required this.aim,
    required this.showPath,
    required this.teamColors,
  }) : super(priority: 6);

  final SimWorld sim;

  /// Colour (0xAARRGGBB) of each sim team, for the crosshair.
  final List<int> teamColors;
  final AimState Function() aim;

  /// Settings switch for the predicted path.
  final bool Function() showPath;

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

  final ui.Paint _ink = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeCap = ui.StrokeCap.round
    ..color = const ui.Color(0xFF2A1A12);
  final ui.Paint _tint = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeCap = ui.StrokeCap.round;

  // Numbers and units only, so no ARB entry is needed.
  final TextPaint _readout = TextPaint(
    style: const TextStyle(
      fontFamily: 'LilitaOne',
      fontSize: 11,
      color: ui.Color(0xFFFFFFFF),
      shadows: [
        Shadow(color: ui.Color(0xFF2A1A12), offset: ui.Offset(1, 0)),
        Shadow(color: ui.Color(0xFF2A1A12), offset: ui.Offset(-1, 0)),
        Shadow(color: ui.Color(0xFF2A1A12), offset: ui.Offset(0, 1)),
        Shadow(color: ui.Color(0xFF2A1A12), offset: ui.Offset(0, -1)),
        Shadow(color: ui.Color(0xFF2A1A12), offset: ui.Offset(0, 2)),
      ],
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
    if (!a.active || unit == null || !unit.alive || !thrown || !showPath()) {
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
    _crosshair(
      canvas,
      center + dir * (unit.stats.hitRadius + 34),
      ui.Color(teamColors[unit.team]),
      weapon.aim == AimMode.angleAndPower ? a.power / 100 : null,
    );
    if (weapon.aim == AimMode.direction) {
      final start = center + dir * (unit.stats.hitRadius + 6);
      canvas.drawLine(start, start + dir * 40, _line);
    } else if (flight is Boomerang && showPath()) {
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

  /// A team-coloured reticle: ring, four ticks and a centre dot, each with
  /// a dark outline; [power] (0–1) fills an arc around it.
  void _crosshair(ui.Canvas canvas, ui.Offset c, ui.Color team, double? power) {
    const r = 8.0;
    void both(void Function(ui.Paint) draw, double width) {
      draw(_ink..strokeWidth = width + 2.6);
      draw(_tint..strokeWidth = width);
    }

    _tint.color = ui.Color.lerp(team, const ui.Color(0xFFFFFFFF), 0.15)!;
    both((p) => canvas.drawCircle(c, r, p), 2.2);
    for (final (dx, dy) in const [(1.0, 0.0), (-1.0, 0.0), (0.0, 1.0), (0.0, -1.0)]) {
      final d = ui.Offset(dx, dy);
      both((p) => canvas.drawLine(c + d * (r - 3), c + d * (r + 5), p), 2.2);
    }
    canvas
      ..drawCircle(c, 2.4, ui.Paint()..color = const ui.Color(0xFF2A1A12))
      ..drawCircle(c, 1.4, ui.Paint()..color = _tint.color);
    if (power == null || power <= 0) return;
    final ring = ui.Rect.fromCircle(center: c, radius: r + 9);
    final sweep = power * math.pi * 2;
    canvas.drawArc(ring, -math.pi / 2, sweep, false, _ink..strokeWidth = 6);
    _tint.color = ui.Color.lerp(
      const ui.Color(0xFFFFC928),
      const ui.Color(0xFFFF4A2A),
      power,
    )!;
    canvas.drawArc(ring, -math.pi / 2, sweep, false, _tint..strokeWidth = 3.4);
  }
}
