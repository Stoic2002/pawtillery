import 'dart:math' show sqrt;

import '../../config/weapons.dart';
import '../physics.dart';
import '../projectile.dart';
import 'bouncy_behavior.dart' show surfaceNormal;
import 'flight_behavior.dart';
import 'sim_context.dart';

/// Roket Botol: glances off the ground like a skimmed stone, up to
/// [Ricochet.bounces] times, then explodes on the next touch; a pet is hit
/// at once. [Projectile.mode] counts the bounces.
class RicochetBehavior extends FlightBehavior {
  const RicochetBehavior(this.spec);
  final Ricochet spec;

  @override
  FlightOutcome tick(Projectile p, SimContext ctx) {
    final o = ProjectilePhysics.step(p, ctx.terrain,
        wind: ctx.wind, waterLevel: ctx.waterLevel, units: ctx.units);
    switch (o) {
      case FlightOutcome.hitTerrain when p.mode < spec.bounces:
        final (nx, ny) = surfaceNormal(ctx.terrain, p.x, p.y, p.vx, p.vy);
        final dot = p.vx * nx + p.vy * ny;
        if (dot < 0) {
          p
            ..vx -= 2 * dot * nx
            ..vy -= 2 * dot * ny;
        }
        p
          ..vx *= spec.keep
          ..vy *= spec.keep
          ..x = p.freeX
          ..y = p.freeY
          ..mode += 1;
        // Too slow to glance on: it goes off where it is.
        if (sqrt(p.vx * p.vx + p.vy * p.vy) < 60) {
          ctx.explode(p.x, p.y, p.weapon, sourceId: p.ownerId);
          return FlightOutcome.hitTerrain;
        }
        return FlightOutcome.flying;
      case FlightOutcome.hitTerrain || FlightOutcome.hitUnit:
        ctx.explode(p.x, p.y, p.weapon, sourceId: p.ownerId);
        return o;
      default:
        return o;
    }
  }
}
