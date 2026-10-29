import 'dart:math' show sqrt;

import '../../config/weapons.dart';
import '../physics.dart';
import '../projectile.dart';
import '../terrain_mask.dart';
import 'flight_behavior.dart';
import 'sim_context.dart';

/// Bounces off ground and units, losing speed each time, and comes to rest
/// on flat ground. Explodes only when its fuse runs out. With
/// [Bouncy.armOnImpact], [Projectile.mode] 0 = not yet touched (the fuse
/// waits), 1 = armed.
class BouncyBehavior extends FlightBehavior {
  const BouncyBehavior(this.spec);
  final Bouncy spec;

  /// Below this speed (px/s) on a floor, it stops bouncing and rests.
  static const double restSpeed = 40;

  @override
  FlightOutcome tick(Projectile p, SimContext ctx) {
    final armed = !spec.armOnImpact || p.mode == 1;
    if (armed && tickFuse(p)) {
      ctx.explode(p.x, p.y, p.weapon, sourceId: p.ownerId);
      return FlightOutcome.finished;
    }
    if (p.resting) {
      if (ctx.terrain.isSolid(p.x.floor(), p.y.floor() + 1)) {
        p.ageTicks++;
        return FlightOutcome.flying;
      }
      p.resting = false;
    }
    final o = ProjectilePhysics.step(p, ctx.terrain,
        wind: ctx.wind, waterLevel: ctx.waterLevel, units: ctx.units);
    if (spec.armOnImpact &&
        (o == FlightOutcome.hitTerrain || o == FlightOutcome.hitUnit)) {
      p.mode = 1;
    }
    switch (o) {
      case FlightOutcome.hitTerrain:
        final (nx, ny) = surfaceNormal(ctx.terrain, p.x, p.y, p.vx, p.vy);
        _bounce(p, nx, ny);
        if (ny < -0.5 && _speed(p) < restSpeed) {
          p
            ..vx = 0
            ..vy = 0
            ..resting = true;
        }
        return FlightOutcome.flying;
      case FlightOutcome.hitUnit:
        final u = ProjectilePhysics.unitAt(p.x, p.y, ctx.units)!;
        final dx = p.x - u.centerX;
        final dy = p.y - u.centerY;
        final len = sqrt(dx * dx + dy * dy);
        _bounce(p, len == 0 ? 0 : dx / len, len == 0 ? -1 : dy / len);
        return FlightOutcome.flying;
      default:
        return o;
    }
  }

  void _bounce(Projectile p, double nx, double ny) {
    final dot = p.vx * nx + p.vy * ny;
    if (dot < 0) {
      p
        ..vx -= 2 * dot * nx
        ..vy -= 2 * dot * ny;
    }
    p
      ..vx *= spec.restitution
      ..vy *= spec.restitution
      ..x = p.freeX
      ..y = p.freeY;
  }

  static double _speed(Projectile p) => sqrt(p.vx * p.vx + p.vy * p.vy);
}

/// Outward surface normal at (x, y), estimated from the ground pixels in a
/// small disc around it. Falls back to the reverse of the velocity.
(double, double) surfaceNormal(
    TerrainMask t, double x, double y, double vx, double vy) {
  final ix = x.floor();
  final iy = y.floor();
  var sx = 0;
  var sy = 0;
  for (var dy = -3; dy <= 3; dy++) {
    for (var dx = -3; dx <= 3; dx++) {
      if (dx * dx + dy * dy > 9) continue;
      if (t.isSolid(ix + dx, iy + dy)) {
        sx += dx;
        sy += dy;
      }
    }
  }
  var nx = -sx.toDouble();
  var ny = -sy.toDouble();
  var len = sqrt(nx * nx + ny * ny);
  if (len == 0) {
    nx = -vx;
    ny = -vy;
    len = sqrt(nx * nx + ny * ny);
    if (len == 0) return (0, -1);
  }
  return (nx / len, ny / len);
}
