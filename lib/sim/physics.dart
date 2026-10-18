import 'dart:math' show max, sqrt;

import '../config/physics.dart';
import '../config/weapons.dart';
import 'projectile.dart';
import 'terrain_mask.dart';
import 'trig.dart';
import 'unit.dart';

enum FlightOutcome { flying, hitTerrain, hitUnit, water, outOfBounds, expired }

/// Hand-written projectile physics: semi-implicit Euler at the fixed tick,
/// with per-pixel sub-stepping so fast projectiles can't skip thin ground.
abstract final class ProjectilePhysics {
  static const double _dt = PhysicsConfig.dt;

  /// Velocity for an aim of [angleDeg] (0 = right, 90 = up) and
  /// [powerPercent] (0–100).
  static Projectile launch({
    required int id,
    required WeaponDef weapon,
    required double x,
    required double y,
    required int angleDeg,
    required int powerPercent,
    int? ownerId,
  }) {
    final speed =
        powerPercent.clamp(0, 100) / 100 * PhysicsConfig.maxLaunchSpeed;
    return Projectile(
      id: id,
      ownerId: ownerId,
      weapon: weapon,
      x: x,
      y: y,
      vx: SimTrig.cosDeg(angleDeg) * speed,
      vy: -SimTrig.sinDeg(angleDeg) * speed,
    );
  }

  /// Advances [p] by one tick. On a hit, [p] is left at the impact point.
  /// Reaching [waterLevel] sinks the projectile without exploding.
  static FlightOutcome step(
    Projectile p,
    TerrainMask terrain, {
    required int wind,
    required int waterLevel,
    List<Unit> units = const [],
  }) {
    if (p.weapon.affectedByWind) {
      p.vx += wind * PhysicsConfig.windAccelPerUnit * _dt;
    }
    p.vy += PhysicsConfig.gravity * _dt;

    final x0 = p.x;
    final y0 = p.y;
    final dx = p.vx * _dt;
    final dy = p.vy * _dt;
    final samples = max(1, sqrt(dx * dx + dy * dy).ceil());

    // On the first tick also test the launch point itself.
    for (var i = p.ageTicks == 0 ? 0 : 1; i <= samples; i++) {
      final t = i / samples;
      final sx = x0 + dx * t;
      final sy = y0 + dy * t;
      if (sx < 0 || sx >= terrain.width || sy >= terrain.height) {
        p
          ..x = sx
          ..y = sy;
        return FlightOutcome.outOfBounds;
      }
      if (sy >= waterLevel) {
        p
          ..x = sx
          ..y = sy;
        return FlightOutcome.water;
      }
      if (_hitsUnit(sx, sy, units)) {
        p
          ..x = sx
          ..y = sy;
        return FlightOutcome.hitUnit;
      }
      if (terrain.isSolid(sx.floor(), sy.floor())) {
        p
          ..x = sx
          ..y = sy;
        return FlightOutcome.hitTerrain;
      }
    }

    p
      ..x = x0 + dx
      ..y = y0 + dy
      ..ageTicks += 1;
    return p.ageTicks >= PhysicsConfig.maxProjectileTicks
        ? FlightOutcome.expired
        : FlightOutcome.flying;
  }

  static bool _hitsUnit(double x, double y, List<Unit> units) {
    for (final u in units) {
      if (!u.alive) continue;
      final dx = x - u.centerX;
      final dy = y - u.centerY;
      final r = u.stats.hitRadius;
      if (dx * dx + dy * dy <= r * r) return true;
    }
    return false;
  }

  /// Path a shot would take with no wind, as flat [x0, y0, x1, y1, ...]
  /// (one point per tick, ending at the impact point). Ignores units. Used by
  /// the aim guide.
  static List<double> predict({
    required WeaponDef weapon,
    required double x,
    required double y,
    required int angleDeg,
    required int powerPercent,
    required TerrainMask terrain,
    required int waterLevel,
    int maxTicks = PhysicsConfig.maxProjectileTicks,
  }) {
    final p = launch(
      id: -1,
      weapon: weapon,
      x: x,
      y: y,
      angleDeg: angleDeg,
      powerPercent: powerPercent,
    );
    final points = <double>[x, y];
    for (var i = 0; i < maxTicks; i++) {
      final outcome = step(p, terrain, wind: 0, waterLevel: waterLevel);
      points
        ..add(p.x)
        ..add(p.y);
      if (outcome != FlightOutcome.flying) break;
    }
    return points;
  }
}
