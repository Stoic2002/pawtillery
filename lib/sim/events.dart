import 'physics.dart';
import 'terrain_mask.dart';
import 'turn_manager.dart';

/// Events emitted by the simulation for rendering, audio and UI to react to.
sealed class SimEvent {
  const SimEvent();
}

/// Terrain within [radius] of ([x], [y]) was removed. [carved] is the
/// touched mask area (null if entirely off-map).
final class ExplosionEvent extends SimEvent {
  const ExplosionEvent({
    required this.x,
    required this.y,
    required this.radius,
    required this.carved,
  });

  final int x;
  final int y;
  final int radius;
  final IntRect? carved;
}

final class ProjectileLaunched extends SimEvent {
  const ProjectileLaunched(this.id);
  final int id;
}

final class ProjectileRemoved extends SimEvent {
  const ProjectileRemoved(this.id, this.outcome);
  final int id;
  final FlightOutcome outcome;
}

enum DamageCause { explosion, fall }

final class UnitDamaged extends SimEvent {
  const UnitDamaged(this.unitId, this.amount, this.cause);
  final int unitId;
  final int amount;
  final DamageCause cause;
}

enum DeathCause { hp, water, outOfBounds }

final class UnitDied extends SimEvent {
  const UnitDied(this.unitId, this.cause);
  final int unitId;
  final DeathCause cause;
}

final class UnitJumped extends SimEvent {
  const UnitJumped(this.unitId);
  final int unitId;
}

final class TurnStarted extends SimEvent {
  const TurnStarted({required this.team, required this.unitId});
  final int team;
  final int unitId;
}

final class PhaseChanged extends SimEvent {
  const PhaseChanged(this.phase);
  final TurnPhase phase;
}

/// [winnerTeam] is null for a draw.
final class MatchEnded extends SimEvent {
  const MatchEnded(this.winnerTeam);
  final int? winnerTeam;
}
