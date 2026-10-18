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

  void record(SimEvent event) {
    switch (event) {
      case UnitDamaged(
          :final unitId,
          :final amount,
          sourceUnitId: final int source,
        ):
        if (sim.units[source].team == sim.units[unitId].team) return;
        damageDealt[source] = (damageDealt[source] ?? 0) + amount;
        _lastHitBy[unitId] = source;
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
