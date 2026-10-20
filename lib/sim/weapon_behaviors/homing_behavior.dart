import 'dart:math' show sqrt;

import '../../config/physics.dart';
import '../../config/weapons.dart';
import '../physics.dart';
import '../projectile.dart';
import '../unit.dart';
import 'flight_behavior.dart';
import 'sim_context.dart';

/// Roket Pelacak and Rudal Pemburu: a normal arc for [Homing.delayTicks]
/// (mode 0), then a motor at constant speed (mode 1) that bends its
/// heading towards the quarry each tick: the nearest enemy, or the point
/// the player chose. With fuel, it burns out (mode 2) and falls like a
/// normal shot. Only sqrt and arithmetic, so it stays deterministic
/// across devices.
class HomingBehavior extends FlightBehavior {
  const HomingBehavior(this.spec);
  final Homing spec;

  @override
  FlightOutcome tick(Projectile p, SimContext ctx) {
    final FlightOutcome o;
    final fuel = spec.fuelTicks;
    if (p.mode != 1) {
      o = ProjectilePhysics.step(p, ctx.terrain,
          wind: ctx.wind, waterLevel: ctx.waterLevel, units: ctx.units);
      if (p.mode == 0 &&
          o == FlightOutcome.flying &&
          p.ageTicks >= spec.delayTicks) {
        p.mode = 1;
      }
    } else {
      p.ageTicks++;
      if (fuel != null && p.ageTicks >= spec.delayTicks + fuel) p.mode = 2;
      _steer(p, ctx.units);
      o = ProjectilePhysics.sweep(p, ctx.terrain, p.vx * PhysicsConfig.dt,
          p.vy * PhysicsConfig.dt,
          waterLevel: ctx.waterLevel, units: ctx.units);
    }
    if (o == FlightOutcome.hitTerrain || o == FlightOutcome.hitUnit) {
      ctx.explode(p.x, p.y, p.weapon, sourceId: p.ownerId);
    }
    return o;
  }

  void _steer(Projectile p, List<Unit> units) {
    final speed = sqrt(p.vx * p.vx + p.vy * p.vy);
    var dirX = speed == 0 ? 0.0 : p.vx / speed;
    var dirY = speed == 0 ? -1.0 : p.vy / speed;
    final double? qx;
    final double? qy;
    if (p.targetX != null && p.targetY != null) {
      qx = p.targetX;
      qy = p.targetY;
    } else {
      final target = nearestEnemy(p, units);
      qx = target?.centerX;
      qy = target?.centerY;
    }
    if (qx != null && qy != null) {
      final tx = qx - p.x;
      final ty = qy - p.y;
      final d = sqrt(tx * tx + ty * ty);
      if (d > 0) {
        dirX += tx / d * spec.steer;
        dirY += ty / d * spec.steer;
        final len = sqrt(dirX * dirX + dirY * dirY);
        if (len > 0) {
          dirX /= len;
          dirY /= len;
        }
      }
    }
    p
      ..vx = dirX * spec.speed
      ..vy = dirY * spec.speed;
  }

  /// The closest living unit not on the shooter's team (ties: lowest id).
  static Unit? nearestEnemy(Projectile p, List<Unit> units) {
    final owner = p.ownerId;
    final team = owner == null ? null : units[owner].team;
    Unit? best;
    var bestD = double.infinity;
    for (final u in units) {
      if (!u.alive || u.team == team) continue;
      final dx = u.centerX - p.x;
      final dy = u.centerY - p.y;
      final d = dx * dx + dy * dy;
      if (d < bestD) {
        bestD = d;
        best = u;
      }
    }
    return best;
  }
}
