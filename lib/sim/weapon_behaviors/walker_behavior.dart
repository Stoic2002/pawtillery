import '../../config/weapons.dart';
import '../physics.dart';
import '../projectile.dart';
import '../unit.dart';
import 'flight_behavior.dart';
import 'sim_context.dart';

/// A walking bomb (Bebek Peledak): walks along the ground with the same
/// code as units, hops when blocked, and explodes when its fuse ends or it
/// touches a unit other than its owner.
class WalkerBehavior extends FlightBehavior {
  const WalkerBehavior(this.spec);
  final SpawnWalker spec;

  @override
  FlightOutcome tick(Projectile p, SimContext ctx) {
    final body = p.body!;
    p.ageTicks++;
    if (tickFuse(p)) {
      ctx.explode(body.centerX, body.centerY, p.weapon, sourceId: p.ownerId);
      return FlightOutcome.finished;
    }

    final t = ctx.terrain;
    if (body.grounded) {
      final before = body.x;
      UnitPhysics.walk(body, body.facing, t);
      if (body.grounded && body.x == before) {
        UnitPhysics.jump(body, spec.hopVx, spec.hopVy);
      }
    }
    UnitPhysics.checkSupport(body, t);
    if (!body.grounded) UnitPhysics.stepAirborne(body, t);

    p
      ..x = body.centerX
      ..y = body.centerY;
    if (body.x < 0 || body.x >= t.width || body.y >= t.height) {
      return FlightOutcome.outOfBounds;
    }
    if (body.centerY >= ctx.waterLevel) return FlightOutcome.water;

    for (final u in ctx.units) {
      if (!u.alive || u.id == p.ownerId) continue;
      final dx = u.centerX - body.centerX;
      final dy = u.centerY - body.centerY;
      final reach = u.stats.hitRadius + body.stats.hitRadius;
      if (dx * dx + dy * dy <= reach * reach) {
        ctx.explode(body.centerX, body.centerY, p.weapon, sourceId: p.ownerId);
        return FlightOutcome.hitUnit;
      }
    }
    return FlightOutcome.flying;
  }

  /// The walker's body: a small unit using the weapon's walking numbers.
  static Unit makeBody(SpawnWalker spec, double x, double y, int facing) =>
      Unit(
        id: -1,
        team: -1,
        x: x,
        y: y,
        stats: UnitStats(
          maxHp: 1,
          bodyHeight: spec.bodyHeight,
          hitRadius: spec.bodyHeight / 2,
          walkSpeed: spec.walkSpeed,
        ),
      )..facing = facing;
}
