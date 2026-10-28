import '../../config/weapons.dart';
import '../physics.dart';
import '../projectile.dart';
import '../unit.dart';
import 'flight_behavior.dart';
import 'sim_context.dart';

/// Kelapa Jatuh: a heavy arc; where it lands it starts rolling the way it
/// was going, with the units' walking code, over small bumps but not up
/// slopes or walls. It explodes when it touches a pet, comes to a stop, or
/// has rolled for [Roll.ticks]. A direct hit on a pet explodes at once.
/// [Projectile.mode]: 0 flying, 1 rolling.
class RollBehavior extends FlightBehavior {
  const RollBehavior(this.spec);
  final Roll spec;

  @override
  FlightOutcome tick(Projectile p, SimContext ctx) {
    if (p.mode == 0) {
      final o = ProjectilePhysics.step(p, ctx.terrain,
          wind: ctx.wind, waterLevel: ctx.waterLevel, units: ctx.units);
      switch (o) {
        case FlightOutcome.hitUnit:
          ctx.explode(p.x, p.y, p.weapon, sourceId: p.ownerId);
          return o;
        case FlightOutcome.hitTerrain:
          var foot = p.freeY.floor();
          while (!ctx.terrain.isSolid(p.freeX.floor(), foot + 1) &&
              foot < ctx.waterLevel) {
            foot++;
          }
          p
            ..mode = 1
            ..fuseTicks = spec.ticks
            ..body = (Unit(
              id: -1,
              team: -1,
              x: p.freeX.floorToDouble(),
              y: (foot + 1).toDouble(),
              stats: UnitStats(
                maxHp: 1,
                bodyHeight: 10,
                hitRadius: 5,
                walkSpeed: spec.speed,
                maxClimb: spec.climb,
              ),
            )..facing = p.vx < 0 ? -1 : 1);
          return FlightOutcome.flying;
        default:
          return o;
      }
    }

    final body = p.body!;
    p.ageTicks++;
    final t = ctx.terrain;
    final before = body.x;
    final wasGrounded = body.grounded;
    if (body.grounded) UnitPhysics.walk(body, body.facing, t);
    UnitPhysics.checkSupport(body, t);
    if (!body.grounded) UnitPhysics.stepAirborne(body, t);
    p
      ..x = body.centerX
      ..y = body.centerY;
    if (body.x < 0 || body.x >= t.width || body.y >= t.height) {
      return FlightOutcome.outOfBounds;
    }
    if (body.centerY >= ctx.waterLevel) return FlightOutcome.water;

    final stopped = wasGrounded && body.grounded && body.x == before;
    var touched = false;
    for (final u in ctx.units) {
      if (!u.alive) continue;
      final dx = u.centerX - body.centerX;
      final dy = u.centerY - body.centerY;
      final reach = u.stats.hitRadius + body.stats.hitRadius;
      if (dx * dx + dy * dy <= reach * reach) {
        touched = true;
        break;
      }
    }
    if (tickFuse(p) || stopped || touched) {
      ctx.explode(body.centerX, body.centerY, p.weapon, sourceId: p.ownerId);
      return FlightOutcome.finished;
    }
    return FlightOutcome.flying;
  }
}
