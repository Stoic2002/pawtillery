import '../../config/weapons.dart';
import '../physics.dart';
import '../projectile.dart';
import 'flight_behavior.dart';
import 'impact.dart';
import 'sim_context.dart';

/// Plain arc; reacts to the first thing it touches.
class BallisticBehavior extends FlightBehavior {
  const BallisticBehavior(this.spec);
  final Ballistic spec;

  @override
  FlightOutcome tick(Projectile p, SimContext ctx) {
    if (tickFuse(p)) {
      ctx.explode(p.x, p.y, p.weapon);
      return FlightOutcome.finished;
    }
    final o = ProjectilePhysics.step(p, ctx.terrain,
        wind: ctx.wind, waterLevel: ctx.waterLevel, units: ctx.units);
    if (o == FlightOutcome.hitTerrain || o == FlightOutcome.hitUnit) {
      applyImpact(spec.onImpact, p, ctx);
    }
    return o;
  }
}
