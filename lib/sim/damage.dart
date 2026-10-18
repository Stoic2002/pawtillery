import '../config/units.dart';

abstract final class Damage {
  /// Linear falloff: `maxDamage × (1 − distance / radius)`, rounded, at least
  /// 1 anywhere inside the radius, 0 outside it.
  static int explosion({
    required int maxDamage,
    required int radius,
    required double distance,
  }) {
    if (distance >= radius) return 0;
    final d = (maxDamage * (1 - distance / radius)).round();
    return d < 1 ? 1 : d;
  }

  /// 1 HP per [UnitConfig.fallDamagePxPerHp] px fallen beyond [threshold],
  /// capped at [UnitConfig.fallDamageMax].
  static int fall(
    double distance, {
    int threshold = UnitConfig.fallDamageThreshold,
  }) {
    final over = distance - threshold;
    if (over <= 0) return 0;
    final d = over ~/ UnitConfig.fallDamagePxPerHp;
    return d > UnitConfig.fallDamageMax ? UnitConfig.fallDamageMax : d;
  }
}
