import 'dart:math' show max, sqrt;

import '../../config/physics.dart';
import '../../config/weapons.dart';
import '../physics.dart';
import '../projectile.dart';
import 'flight_behavior.dart';
import 'sim_context.dart';

/// Flies straight for [Projectile.range], turns round, flies back the same
/// distance. Hits each unit (except the thrower) once per leg; passes
/// through terrain.
class BoomerangBehavior extends FlightBehavior {
  const BoomerangBehavior(this.spec);
  final Boomerang spec;

  @override
  FlightOutcome tick(Projectile p, SimContext ctx) {
    p.ageTicks++;
    final speed = sqrt(p.vx * p.vx + p.vy * p.vy);
    if (speed == 0) return FlightOutcome.finished;
    final dirX = p.vx / speed;
    final dirY = p.vy / speed;
    final dist = spec.speed * PhysicsConfig.dt;
    final samples = max(1, dist.ceil());
    final step = dist / samples;

    for (var i = 0; i < samples; i++) {
      p
        ..x += dirX * step
        ..y += dirY * step
        ..traveled += step;
      if (p.x < 0 || p.x >= ctx.terrain.width || p.y >= ctx.terrain.height) {
        return FlightOutcome.outOfBounds;
      }
      if (p.y >= ctx.waterLevel) return FlightOutcome.water;
      for (final u in ctx.units) {
        if (!u.alive || u.id == p.ownerId || p.hitUnits.contains(u.id)) {
          continue;
        }
        if (ProjectilePhysics.unitAt(p.x, p.y, [u]) != null) {
          p.hitUnits.add(u.id);
          ctx.strikeUnit(
              u, p.weapon.maxDamage, dirX, dirY, p.weapon.knockbackScale);
        }
      }
      if (p.traveled >= p.range) {
        if (p.mode == 1) return FlightOutcome.finished;
        p
          ..mode = 1
          ..traveled = 0
          ..vx = -p.vx
          ..vy = -p.vy
          ..hitUnits.clear();
        return FlightOutcome.flying;
      }
    }
    return FlightOutcome.flying;
  }
}
