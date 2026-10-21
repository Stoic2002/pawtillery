import '../config/match_defaults.dart';

/// Phases of one turn (PRD: Core loop dan sistem giliran).
enum TurnPhase {
  /// Team banner; no input.
  turnStart,

  /// Move and fire once; the turn timer runs only here.
  action,

  /// After firing: a few seconds to move away.
  retreat,

  /// Waiting for projectiles and falling units to come to rest, then
  /// resolving deaths and checking for a winner.
  settling,

  matchOver,
}

class TurnTimings {
  const TurnTimings({
    this.bannerTicks = MatchDefaults.bannerTicks,
    this.turnTicks = MatchDefaults.turnSeconds * MatchDefaults.ticksPerSecond,
    this.retreatTicks =
        MatchDefaults.retreatSeconds * MatchDefaults.ticksPerSecond,
    this.settleTimeoutTicks =
        MatchDefaults.settleTimeoutSeconds * MatchDefaults.ticksPerSecond,
    this.hitHoldTicks = MatchDefaults.hitHoldTicks,
  });

  final int bannerTicks;
  final int turnTicks;
  final int retreatTicks;
  final int settleTimeoutTicks;

  /// Settling waits this long after the turn's last hit, even when
  /// everything is already at rest.
  final int hitHoldTicks;
}

/// Turn state machine. Holds no units itself: [SimWorld] drives it and
/// answers its questions, which keeps it easy to test.
class TurnManager {
  TurnManager({required this.teamCount, this.timings = const TurnTimings()})
      : _cursor = List.filled(teamCount, 0);

  final int teamCount;
  final TurnTimings timings;

  TurnPhase phase = TurnPhase.turnStart;

  /// Ticks spent in the current phase.
  int phaseTicks = 0;

  int activeTeam = -1;
  int activeUnitId = -1;
  int turnNumber = 0;
  bool hasFired = false;

  /// Set when [phase] is [TurnPhase.matchOver]; null winner = draw.
  int? winnerTeam;

  /// Per team: index of the next unit to get a turn (round-robin).
  final List<int> _cursor;
  List<int> get cursors => List.unmodifiable(_cursor);

  bool get allowsMovement =>
      phase == TurnPhase.action || phase == TurnPhase.retreat;
  bool get allowsFire => phase == TurnPhase.action && !hasFired;

  /// Ticks left on the visible clock: turn timer in action, retreat timer in
  /// retreat, otherwise null.
  int? get clockTicks => switch (phase) {
        TurnPhase.action => timings.turnTicks - phaseTicks,
        TurnPhase.retreat => timings.retreatTicks - phaseTicks,
        _ => null,
      };

  void enter(TurnPhase next) {
    phase = next;
    phaseTicks = 0;
  }

  /// Picks the next team (after the current one) that still has units, and
  /// its next living unit in round-robin order. [aliveUnitsByTeam] lists
  /// each team's units in roster order as (unitId, alive).
  void startNextTurn(List<List<(int, bool)>> aliveUnitsByTeam) {
    for (var step = 1; step <= teamCount; step++) {
      final team = (activeTeam + step) % teamCount;
      final roster = aliveUnitsByTeam[team];
      for (var k = 0; k < roster.length; k++) {
        final index = (_cursor[team] + k) % roster.length;
        final (id, alive) = roster[index];
        if (!alive) continue;
        _cursor[team] = index + 1;
        activeTeam = team;
        activeUnitId = id;
        turnNumber++;
        hasFired = false;
        enter(TurnPhase.turnStart);
        return;
      }
    }
    throw StateError('No living unit to start a turn with');
  }

  void endMatch(int? winner) {
    winnerTeam = winner;
    enter(TurnPhase.matchOver);
  }
}
