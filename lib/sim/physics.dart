import 'dart:math' show max, min, sqrt;

import '../config/physics.dart';
import '../config/weapons.dart';
import 'projectile.dart';
import 'terrain_mask.dart';
import 'trig.dart';
import 'unit.dart';

enum FlightOutcome {
  flying,
  hitTerrain,
  hitUnit,
  water,
  outOfBounds,
  expired,

  /// Detonated by its own fuse or finished its job (boomerang returned,
  /// drill done, walker exploded).
  finished,
}

/// Hand-written projectile physics: semi-implicit Euler at the fixed tick,
/// with per-pixel sub-stepping so fast projectiles can't skip thin ground.
abstract final class ProjectilePhysics {
  static const double _dt = PhysicsConfig.dt;

  /// Velocity for an aim of [angleDeg] (0 = right, 90 = up) and
  /// [powerPercent] (0–100), times [speedScale] (e.g. Monyet's strong arm).
  static Projectile launch({
    required int id,
    required WeaponDef weapon,
    required double x,
    required double y,
    required int angleDeg,
    required int powerPercent,
    double speedScale = 1,
    int? ownerId,
    int? fuseTicks,
  }) {
    final speed = powerPercent.clamp(0, 100) /
        100 *
        PhysicsConfig.maxLaunchSpeed *
        speedScale;
    return Projectile(
      id: id,
      ownerId: ownerId,
      weapon: weapon,
      x: x,
      y: y,
      vx: SimTrig.cosDeg(angleDeg) * speed,
      vy: -SimTrig.sinDeg(angleDeg) * speed,
      fuseTicks: fuseTicks,
    );
  }

  /// Advances [p] by one tick of gravity (scaled by the weapon) and wind
  /// (if the weapon is affected). On a hit, [p] is left at the impact point
  /// and [Projectile.freeX]/[Projectile.freeY] at the last free sample.
  /// Reaching [waterLevel] sinks the projectile.
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
    p.vy += PhysicsConfig.gravity *
        PhysicsConfig.gravityScale *
        p.weapon.gravityScale *
        _dt;
    final firstTick = p.ageTicks == 0;
    p.ageTicks++;
    return sweep(p, terrain, p.vx * _dt, p.vy * _dt,
        waterLevel: waterLevel, units: units, includeStart: firstTick);
  }

  /// Moves [p] by (dx, dy) in ≤ 1 px samples, stopping at the first thing
  /// it touches. Used by every flight behaviour.
  static FlightOutcome sweep(
    Projectile p,
    TerrainMask terrain,
    double dx,
    double dy, {
    required int waterLevel,
    List<Unit> units = const [],
    bool includeStart = false,
    bool solidTerrain = true,
  }) {
    final x0 = p.x;
    final y0 = p.y;
    final samples = max(1, sqrt(dx * dx + dy * dy).ceil());
    // Every sample lies in the segment's box: a unit whose hit circle is
    // outside it can't be hit, and on most ticks of a flight none is near,
    // so the per-sample unit check (the bulk of the cost) is skipped.
    final near = _anyUnitNear(units, min(x0, x0 + dx), min(y0, y0 + dy),
        max(x0, x0 + dx), max(y0, y0 + dy));

    for (var i = includeStart ? 0 : 1; i <= samples; i++) {
      final t = i / samples;
      final sx = x0 + dx * t;
      final sy = y0 + dy * t;
      FlightOutcome? hit;
      if (sx < 0 || sx >= terrain.width || sy >= terrain.height) {
        hit = FlightOutcome.outOfBounds;
      } else if (sy >= waterLevel) {
        hit = FlightOutcome.water;
      } else if (near && unitAt(sx, sy, units) != null) {
        hit = FlightOutcome.hitUnit;
      } else if (solidTerrain && terrain.isSolid(sx.floor(), sy.floor())) {
        hit = FlightOutcome.hitTerrain;
      }
      if (hit != null) {
        p
          ..x = sx
          ..y = sy;
        return hit;
      }
      p
        ..freeX = sx
        ..freeY = sy;
    }

    p
      ..x = x0 + dx
      ..y = y0 + dy;
    return p.ageTicks >= PhysicsConfig.maxProjectileTicks
        ? FlightOutcome.expired
        : FlightOutcome.flying;
  }

  static bool _anyUnitNear(
      List<Unit> units, double x0, double y0, double x1, double y1) {
    for (final u in units) {
      if (!u.alive) continue;
      final r = u.stats.hitRadius;
      if (u.centerX + r >= x0 &&
          u.centerX - r <= x1 &&
          u.centerY + r >= y0 &&
          u.centerY - r <= y1) {
        return true;
      }
    }
    return false;
  }

  /// First living unit whose hit circle contains (x, y).
  static Unit? unitAt(double x, double y, List<Unit> units) {
    for (final u in units) {
      if (!u.alive) continue;
      final dx = x - u.centerX;
      final dy = y - u.centerY;
      final r = u.stats.hitRadius;
      if (dx * dx + dy * dy <= r * r) return u;
    }
    return null;
  }

  /// Path a ballistic shot would take with no wind, as flat
  /// [x0, y0, x1, y1, ...] (one point per tick, ending at the first
  /// impact). Ignores units. Used by the aim guide.
  static List<double> predict({
    required WeaponDef weapon,
    required double x,
    required double y,
    required int angleDeg,
    required int powerPercent,
    required TerrainMask terrain,
    required int waterLevel,
    double speedScale = 1,
    int maxTicks = PhysicsConfig.maxProjectileTicks,
  }) {
    final p = launch(
      id: -1,
      weapon: weapon,
      x: x,
      y: y,
      angleDeg: angleDeg,
      powerPercent: powerPercent,
      speedScale: speedScale,
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
