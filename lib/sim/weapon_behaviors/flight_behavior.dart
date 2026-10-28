import '../../config/weapons.dart';
import '../physics.dart';
import '../projectile.dart';
import 'ballistic_behavior.dart';
import 'boomerang_behavior.dart';
import 'bouncy_behavior.dart';
import 'drill_behavior.dart';
import 'homing_behavior.dart';
import 'pierce_behavior.dart';
import 'ricochet_behavior.dart';
import 'roll_behavior.dart';
import 'sim_context.dart';
import 'sticky_behavior.dart';
import 'vortex_behavior.dart';
import 'walker_behavior.dart';

/// One way a projectile can move and react (PRD: perilaku khusus sebagai
/// strategi). Each weapon picks a behaviour through its data.
abstract class FlightBehavior {
  const FlightBehavior();

  /// Advances [p] one tick. Anything but [FlightOutcome.flying] removes it.
  FlightOutcome tick(Projectile p, SimContext ctx);

  static final Map<WeaponDef, FlightBehavior> _cache = Map.identity();

  static FlightBehavior of(WeaponDef weapon) =>
      _cache.putIfAbsent(weapon, () => _create(weapon));

  static FlightBehavior _create(WeaponDef w) {
    final delivery = w.delivery;
    if (delivery is SpawnWalker) return WalkerBehavior(delivery);
    return switch (w.flight) {
      final Ballistic spec => BallisticBehavior(spec),
      final Bouncy spec => BouncyBehavior(spec),
      final Boomerang spec => BoomerangBehavior(spec),
      final Drill spec => DrillBehavior(spec),
      final Homing spec => HomingBehavior(spec),
      final Vortex spec => VortexBehavior(spec),
      Sticky() => const StickyBehavior(),
      final Ricochet spec => RicochetBehavior(spec),
      final Pierce spec => PierceBehavior(spec),
      final Roll spec => RollBehavior(spec),
      null => throw ArgumentError('${w.id} has no flight behaviour'),
    };
  }
}

/// Counts a fuse down; returns true when it has just run out.
bool tickFuse(Projectile p) {
  final fuse = p.fuseTicks;
  if (fuse == null) return false;
  p.fuseTicks = fuse - 1;
  return fuse - 1 <= 0;
}
