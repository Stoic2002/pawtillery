import '../sim/events.dart';
import '../sim/world.dart';

/// Match statistics for the results screen (PRD: Hasil — damage terbanyak,
/// kill per tim), built from sim events. Only damage to enemies counts;
/// a knockout is credited to the team that last hurt the unit.
class MatchStats {
  MatchStats(this.sim) : knockouts = List.filled(sim.teamCount, 0);

  final SimWorld sim;

  /// Enemy damage dealt, by unit id.
  final Map<int, int> damageDealt = {};

  /// Knockouts per team.
  final List<int> knockouts;

  final Map<int, int> _lastHitBy = {};

  /// Weapons used, per team (weapon id → times).
  late final List<Map<String, int>> weaponUses = [
    for (var t = 0; t < sim.teamCount; t++) <String, int>{},
  ];

  /// Biggest single hit on an enemy, per team: (damage, unit id).
  late final List<(int, int)?> biggestHit = List.filled(sim.teamCount, null);

  void record(SimEvent event) {
    switch (event) {
      case WeaponUsed(:final unitId, :final weaponId):
        final uses = weaponUses[sim.units[unitId].team];
        uses[weaponId] = (uses[weaponId] ?? 0) + 1;
      case UnitDamaged(
          :final unitId,
          :final amount,
          sourceUnitId: final int source,
        ):
        final team = sim.units[source].team;
        if (team == sim.units[unitId].team) return;
        damageDealt[source] = (damageDealt[source] ?? 0) + amount;
        _lastHitBy[unitId] = source;
        final best = biggestHit[team];
        if (best == null || amount > best.$1) biggestHit[team] = (amount, source);
      case UnitDied(:final unitId):
        final source = _lastHitBy[unitId];
        if (source != null) knockouts[sim.units[source].team]++;
      default:
        break;
    }
  }

  /// The unit with the most enemy damage, or null if nobody hit anyone.
  (int unitId, int damage)? get topDamage {
    (int, int)? best;
    for (final MapEntry(:key, :value) in damageDealt.entries) {
      if (best == null || value > best.$2) best = (key, value);
    }
    return best;
  }
}
