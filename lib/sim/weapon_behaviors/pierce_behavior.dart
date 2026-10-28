import 'dart:math' show sqrt;

import '../../config/weapons.dart';
import '../physics.dart';
import '../projectile.dart';
import 'flight_behavior.dart';
import 'sim_context.dart';

/// Ketapel Ganda: the stone goes through pets. Each pet it meets takes
/// the weapon's damage as a direct hit, pushed along the flight, and the
/// stone flies on (it never meets the same pet twice); it explodes where
/// it reaches the ground.
class PierceBehavior extends FlightBehavior {
  const PierceBehavior(this.spec);
  final Pierce spec;

  @override
  FlightOutcome tick(Projectile p, SimContext ctx) {
    final others = [
      for (final u in ctx.units)
        if (!p.hitUnits.contains(u.id)) u,
    ];
    final o = ProjectilePhysics.step(p, ctx.terrain,
        wind: ctx.wind, waterLevel: ctx.waterLevel, units: others);
    switch (o) {
      case FlightOutcome.hitUnit:
        final u = ProjectilePhysics.unitAt(p.x, p.y, others)!;
        p.hitUnits.add(u.id);
        final speed = sqrt(p.vx * p.vx + p.vy * p.vy);
        ctx.strikeUnit(
          u,
          p.weapon.maxDamage,
          speed == 0 ? 0 : p.vx / speed,
          speed == 0 ? -1 : p.vy / speed,
          p.weapon.knockbackScale,
          sourceId: p.ownerId,
        );
        return FlightOutcome.flying;
      case FlightOutcome.hitTerrain:
        ctx.explode(p.x, p.y, p.weapon, sourceId: p.ownerId);
        return o;
      default:
        return o;
    }
  }
}
