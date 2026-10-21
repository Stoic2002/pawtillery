import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../config/controls.dart';
import '../../config/weapons.dart';
import '../../sim/physics.dart';
import '../../sim/unit.dart';
import '../../sim/world.dart';
import '../hud_state.dart';

/// Aiming visuals for the active unit, depending on the weapon:
/// - thrown weapons: the redesign's dashed aim circle around the unit, the
///   first ~25 % of the no-wind path as cream dots (PRD), and an
///   "angle · power" pill above the unit;
/// - boomerang: its straight line to the turning point;
/// - direction weapons: an arrow;
/// - target weapons: a round marker (orange if allowed, grey if not).
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

  final ui.Paint _dot = ui.Paint()..color = const ui.Color(0xFFFFF6E6);
  final ui.Paint _dotEdge = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1.2
    ..color = const ui.Color(0xFF2B2118);
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
      fontFamily: 'Baloo2',
      fontVariations: [ui.FontVariation('wght', 800)],
      fontWeight: FontWeight.w700,
      fontSize: 10.5,
      height: 1,
      color: ui.Color(0xFFFFF6E6),
    ),
  );
  final ui.Paint _pill = ui.Paint()..color = const ui.Color(0xFF2B2118);
  final ui.Paint _beam = ui.Paint()
    ..strokeWidth = 2
    ..strokeCap = ui.StrokeCap.round
    ..color = const ui.Color(0x99E5484D);
  final ui.Paint _dash = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1.4
    ..color = const ui.Color(0x662B2118);

  /// The dashed aim ring around (0, 0), built once (measuring and cutting
  /// the dashes every frame allocated dozens of paths while aiming).
  static final ui.Path _dashedRing = () {
    const ring = 52.0;
    final circle = ui.Path()
      ..addOval(ui.Rect.fromCircle(center: ui.Offset.zero, radius: ring));
    final dashes = ui.Path();
    for (final m in circle.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 9) {
        dashes.addPath(m.extractPath(d, d + 5), ui.Offset.zero);
      }
    }
    return dashes;
  }();

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
    final thrown =
        weapon.aim == AimMode.angleAndPower && weapon.flight is! Boomerang;
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
      speedScale: unit.stats.firePowerScale * weapon.launchSpeedScale,
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
      if (tx != null && ty != null) _targetMarker(canvas, weapon, a, tx, ty);
      return;
    }
    if (!a.active) return;
    _aimRing(canvas, unit, weapon, a);
  }

  /// The prototype's target: an ink ring with an orange wash (grey when the
  /// spot is not allowed) and a centre dot; a dashed drop line for things
  /// that come from the sky.
  void _targetMarker(
    ui.Canvas canvas,
    WeaponDef weapon,
    AimState a,
    int tx,
    int ty,
  ) {
    final c = ui.Offset(tx.toDouble(), ty.toDouble());
    _cross.color = const ui.Color(0xFF2B2118);
    canvas
      ..drawCircle(
        c,
        16,
        ui.Paint()
          ..color = a.targetValid
              ? const ui.Color(0x59FF8A3D)
              : const ui.Color(0x59CFC4B3),
      )
      ..drawCircle(c, 16, _cross)
      ..drawCircle(c, 3, ui.Paint()..color = const ui.Color(0xFF2B2118));
    final delivery = weapon.delivery;
    if (delivery is AirStrike ||
        delivery is Lightning ||
        delivery is OrbitalStrike ||
        delivery is AirRaid) {
      canvas.drawLine(
        ui.Offset(c.dx, 0),
        ui.Offset(c.dx, c.dy - 16),
        _dash..strokeWidth = 2,
      );
    }
  }

  /// The slingshot's dashed ring, aim line or path, and the readout.
  void _aimRing(ui.Canvas canvas, Unit unit, WeaponDef weapon, AimState a) {
    final rad = a.angle * math.pi / 180;
    final dir = ui.Offset(math.cos(rad), -math.sin(rad));
    final center = ui.Offset(unit.centerX, unit.centerY);
    final flight = weapon.flight;
    // The aim circle: a dashed ring around the unit, as in the prototype.
    canvas.drawPath(_dashedRing.shift(center), _dash..strokeWidth = 1.4);
    final delivery = weapon.delivery;
    if ((delivery is Beam || delivery is Shotgun) && showPath()) {
      // Laser and shotgun: a faint red line over the part of the shot the
      // guide shows.
      final length = switch (delivery) {
        Beam(:final length) || Shotgun(range: final length) => length,
        _ => 0,
      };
      final start = center + dir * (unit.stats.hitRadius + 2);
      canvas.drawLine(
        start,
        start + dir * (length * ControlsConfig.aimGuideFraction * 2),
        _beam,
      );
    } else if (delivery is Grapple) {
      // Grappling hook: the rope's full reach, and where it would catch.
      final (x, y, hooked) = SimWorld.grappleReach(
        sim.terrain,
        sim.waterLevel,
        unit,
        a.angle,
        delivery.length,
      );
      final start = center + dir * (unit.stats.hitRadius + 2);
      final end = ui.Offset(x, y);
      final length = (end - start).distance;
      for (var d = 0.0; d < length; d += 10) {
        canvas.drawLine(
          start + dir * d,
          start + dir * math.min(d + 5, length),
          _line,
        );
      }
      if (hooked) {
        canvas
          ..drawCircle(end, 7, _dot)
          ..drawCircle(end, 7, _dotEdge);
      } else {
        canvas
          ..drawLine(
            end + const ui.Offset(-5, -5),
            end + const ui.Offset(5, 5),
            _beam,
          )
          ..drawLine(
            end + const ui.Offset(-5, 5),
            end + const ui.Offset(5, -5),
            _beam,
          );
      }
    } else if (weapon.aim == AimMode.direction) {
      final start = center + dir * (unit.stats.hitRadius + 6);
      canvas.drawLine(start, start + dir * 40, _line);
    } else if (flight is Boomerang && showPath()) {
      final range =
          flight.minRange + (flight.maxRange - flight.minRange) * a.power / 100;
      final start = center + dir * (unit.stats.hitRadius + 6);
      for (
        var d = 0.0;
        d < range * ControlsConfig.aimGuideFraction * 2;
        d += 18
      ) {
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

    if (weapon.aim == AimMode.angleAndPower ||
        weapon.aim == AimMode.direction) {
      // "45° · 60%" on a dark pill above the unit.
      final text = weapon.aim == AimMode.direction
          ? '${a.angle}°'
          : '${a.angle}° · ${a.power}%';
      final w = _readout.getLineMetrics(text).width + 12;
      final top = unit.y - 66;
      canvas.drawRRect(
        ui.RRect.fromLTRBR(
          unit.centerX - w / 2,
          top,
          unit.centerX + w / 2,
          top + 15,
          const ui.Radius.circular(8),
        ),
        _pill,
      );
      _readout.render(
        canvas,
        text,
        Vector2(unit.centerX, top + 7.8),
        anchor: Anchor.center,
      );
    }
  }
}
