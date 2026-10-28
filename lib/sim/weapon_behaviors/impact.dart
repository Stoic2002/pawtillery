import '../../config/weapons.dart';
import '../projectile.dart';
import '../trig.dart';
import 'sim_context.dart';

/// Applies what happens when a projectile touches something (PRD: pecah,
/// ranjau, ledak). Children are thrown upwards in a fan from the last free
/// point so they don't start inside the ground.
void applyImpact(ImpactSpec spec, Projectile p, SimContext ctx) {
  switch (spec) {
    case Explode():
      ctx.explode(p.x, p.y, p.weapon, sourceId: p.ownerId);
    case Split(:final childId, :final count, :final explodeSelf):
      if (explodeSelf) ctx.explode(p.x, p.y, p.weapon, sourceId: p.ownerId);
      final child = Weapons.byId(childId);
      _fan(count, spec.minSpeed, spec.maxSpeed, ctx, (vx, vy) {
        ctx.spawnProjectile(Projectile(
          id: ctx.nextProjectileId(),
          ownerId: p.ownerId,
          weapon: child,
          x: p.freeX,
          y: p.freeY - 2,
          vx: vx,
          vy: vy,
          fuseTicks: child.fuseTicks,
        ));
      });
    case Ignite():
      ctx
        ..explode(p.x, p.y, p.weapon, sourceId: p.ownerId)
        ..ignite(p.freeX, p.freeY, spec, sourceId: p.ownerId);
    case GasCloud():
      ctx.releaseGas(p.freeX, p.freeY, spec, sourceId: p.ownerId);
    case Nuke():
      ctx.nuke(p.x, p.y, p.weapon, spec, sourceId: p.ownerId);
    case Freeze():
      ctx.freeze(p.freeX, p.freeY, p.weapon, spec, sourceId: p.ownerId);
    case AddGround(:final radius):
      ctx.addGround(p.freeX.round(), p.freeY.round(), radius);
    case ScatterMines(:final mineId, :final count):
      final mine = Weapons.byId(mineId);
      _fan(count, spec.minSpeed, spec.maxSpeed, ctx, (vx, vy) {
        ctx.spawnMine(mine, p.freeX, p.freeY - 2, vx, vy, ownerId: p.ownerId);
      });
  }
}

/// [count] velocities spread evenly across an upward fan (60°–120°), each
/// jittered by the sim RNG.
void _fan(int count, double minSpeed, double maxSpeed, SimContext ctx,
    void Function(double vx, double vy) emit) {
  for (var i = 0; i < count; i++) {
    final spread = count == 1 ? 0 : (i * 60 ~/ (count - 1)) - 30;
    final angle = 90 + spread + ctx.rng.nextIntInRange(-6, 6);
    final speed = minSpeed + ctx.rng.nextDouble() * (maxSpeed - minSpeed);
    emit(SimTrig.cosDeg(angle) * speed, -SimTrig.sinDeg(angle) * speed);
  }
}
