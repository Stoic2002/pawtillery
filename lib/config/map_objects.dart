/// Starter objects every map begins with (setup: "Map objects"). Balance
/// numbers live here. Pure Dart.
library;

/// The setup choice.
enum ObjectAmount { off, few, many }

/// How many of each starter object a map places for [ObjectAmount.few];
/// [ObjectAmount.many] doubles them.
class ObjectMix {
  const ObjectMix({
    this.mines = 0,
    this.barrels = 0,
    this.healthCrates = 0,
    this.weaponCrates = 0,
  });

  final int mines;
  final int barrels;
  final int healthCrates;
  final int weaponCrates;

  int get total => mines + barrels + healthCrates + weaponCrates;

  /// The mix for [amount], or null for none.
  ObjectMix? forAmount(ObjectAmount amount) => switch (amount) {
    ObjectAmount.off => null,
    ObjectAmount.few => this,
    ObjectAmount.many => ObjectMix(
      mines: mines * 2,
      barrels: barrels * 2,
      healthCrates: healthCrates * 2,
      weaponCrates: weaponCrates * 2,
    ),
  };
}

abstract final class ObjectConfig {
  /// Barrels and crates are about this wide and tall (px).
  static const int size = 16;

  /// A barrel caught in a blast (or a beam) blows up this much later, so
  /// chains go off one after another.
  static const int barrelFuseTicks = 24;

  /// A unit whose body centre comes this close picks a crate up.
  static const double pickupRadius = 22;

  /// HP a health crate gives (never above the unit's maximum).
  static const int healthAmount = 25;

  /// Objects keep at least this far from units and from each other.
  static const int minDistanceFromUnits = 90;
  static const int minDistanceBetween = 45;
}
