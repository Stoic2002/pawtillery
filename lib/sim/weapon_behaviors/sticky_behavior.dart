import '../physics.dart';
import '../projectile.dart';
import 'flight_behavior.dart';
import 'sim_context.dart';

/// Bom Lengket: a normal arc until it touches something, then it sticks:
/// to a unit (it rides on top of it, wherever it is knocked or walks) or
/// to the ground. It explodes when its fuse runs out, wherever it is.
class StickyBehavior extends FlightBehavior {
  const StickyBehavior();

  @override
  FlightOutcome tick(Projectile p, SimContext ctx) {
    if (tickFuse(p)) {
      ctx.explode(p.x, p.y, p.weapon, sourceId: p.ownerId);
      return FlightOutcome.finished;
    }
    final stuck = p.stuckTo;
    if (stuck != null) {
      if (stuck >= 0) {
        final u = ctx.units[stuck];
        if (u.alive) {
          p
            ..x = u.centerX
            ..y = u.centerY - u.stats.hitRadius * 0.6;
        } else {
          p.stuckTo = -1;
        }
      }
      if (p.y >= ctx.waterLevel) return FlightOutcome.water;
      return FlightOutcome.flying;
    }
    final o = ProjectilePhysics.step(
      p,
      ctx.terrain,
      wind: ctx.wind,
      waterLevel: ctx.waterLevel,
      units: ctx.units,
    );
    switch (o) {
      case FlightOutcome.hitUnit:
        final u = ProjectilePhysics.unitAt(p.x, p.y, ctx.units);
        p.stuckTo = u?.id ?? -1;
        if (u == null) {
          p
            ..x = p.freeX
            ..y = p.freeY;
        }
        return FlightOutcome.flying;
      case FlightOutcome.hitTerrain:
        p
          ..stuckTo = -1
          ..x = p.freeX
          ..y = p.freeY;
        return FlightOutcome.flying;
      default:
        return o;
    }
  }
}
