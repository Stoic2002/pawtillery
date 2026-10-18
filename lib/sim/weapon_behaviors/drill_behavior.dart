import 'dart:math' show max, sqrt;

import '../../config/physics.dart';
import '../../config/weapons.dart';
import '../physics.dart';
import '../projectile.dart';
import 'sim_context.dart';
import 'flight_behavior.dart';

/// Arcs like a normal shot until it touches ground, then tunnels straight
/// on for [Drill.length] px and explodes. Touching a unit at any point
/// explodes it at once.
class DrillBehavior extends FlightBehavior {
  const DrillBehavior(this.spec);
  final Drill spec;

  @override
  FlightOutcome tick(Projectile p, SimContext ctx) {
    if (p.mode == 0) {
      final o = ProjectilePhysics.step(p, ctx.terrain,
          wind: ctx.wind, waterLevel: ctx.waterLevel, units: ctx.units);
      if (o == FlightOutcome.hitUnit) ctx.explode(p.x, p.y, p.weapon, sourceId: p.ownerId);
      if (o != FlightOutcome.hitTerrain) return o;
      final speed = sqrt(p.vx * p.vx + p.vy * p.vy);
      final scale = speed == 0 ? 0.0 : spec.speed / speed;
      p
        ..mode = 1
        ..traveled = 0
        ..vx = speed == 0 ? 0 : p.vx * scale
        ..vy = speed == 0 ? spec.speed : p.vy * scale;
      return FlightOutcome.flying;
    }

    p.ageTicks++;
    final dist = spec.speed * PhysicsConfig.dt;
    final samples = max(1, dist.ceil());
    final step = dist / samples;
    final dirX = p.vx / spec.speed;
    final dirY = p.vy / spec.speed;
    for (var i = 0; i < samples; i++) {
      p
        ..x += dirX * step
        ..y += dirY * step
        ..traveled += step;
      if (p.x < 0 || p.x >= ctx.terrain.width || p.y >= ctx.terrain.height) {
        return FlightOutcome.outOfBounds;
      }
      if (p.y >= ctx.waterLevel) return FlightOutcome.water;
      if (ProjectilePhysics.unitAt(p.x, p.y, ctx.units) != null) {
        ctx.explode(p.x, p.y, p.weapon, sourceId: p.ownerId);
        return FlightOutcome.hitUnit;
      }
    }
    ctx.carveTunnel(p.x.round(), p.y.round(), spec.tunnelRadius);
    if (p.traveled >= spec.length) {
      ctx.explode(p.x, p.y, p.weapon, sourceId: p.ownerId);
      return FlightOutcome.finished;
    }
    return FlightOutcome.flying;
  }
}
