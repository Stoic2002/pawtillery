import 'dart:math' show sqrt;

import '../../config/physics.dart';
import '../../config/weapons.dart';
import '../physics.dart';
import '../projectile.dart';
import '../unit.dart';
import 'flight_behavior.dart';
import 'sim_context.dart';

/// Lubang Hitam: a normal arc (mode 0) until it touches anything; then it
/// hangs where it hit (mode 1) and pulls every living unit within
/// [Vortex.pullRadius] towards itself, linearly harder towards the middle,
/// for [Vortex.pullTicks]; then it collapses in a blast. A pet standing on
/// the ground is lifted into a hop towards it (a landing snaps a unit to
/// whole pixels, which would swallow a small pull). Arithmetic and
/// sqrt only, so it stays deterministic.
class VortexBehavior extends FlightBehavior {
  const VortexBehavior(this.spec);
  final Vortex spec;

  /// Hop off the ground: this share of the pull as sideways speed, and a
  /// fixed upward speed (px/s).
  static const double _hopShare = 0.15;
  static const double _hopLift = 130;

  @override
  FlightOutcome tick(Projectile p, SimContext ctx) {
    if (p.mode == 0) {
      final o = ProjectilePhysics.step(
        p,
        ctx.terrain,
        wind: ctx.wind,
        waterLevel: ctx.waterLevel,
        units: ctx.units,
      );
      if (o == FlightOutcome.hitTerrain || o == FlightOutcome.hitUnit) {
        p
          ..mode = 1
          ..x = p.freeX
          ..y = p.freeY
          ..vx = 0
          ..vy = 0
          ..traveled = 0;
        return FlightOutcome.flying;
      }
      return o;
    }
    p.traveled++;
    if (p.traveled >= spec.pullTicks) {
      ctx.explode(p.x, p.y, p.weapon, sourceId: p.ownerId);
      return FlightOutcome.finished;
    }
    final r = spec.pullRadius;
    for (final u in ctx.units) {
      if (!u.alive) continue;
      final dx = p.x - u.centerX;
      final dy = p.y - u.centerY;
      final d = sqrt(dx * dx + dy * dy);
      if (d >= r || d < 4) continue;
      final strength = spec.pullAccel * (1 - d / r);
      if (u.grounded) {
        UnitPhysics.launch(u, dx / d * strength * _hopShare, -_hopLift);
      } else {
        final a = strength * PhysicsConfig.dt;
        UnitPhysics.launch(u, u.vx + dx / d * a, u.vy + dy / d * a);
      }
    }
    return FlightOutcome.flying;
  }
}
