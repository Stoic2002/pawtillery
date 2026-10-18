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

enum DamageCause {
  explosion,

  /// Direct hits without a blast: punch, shockwave, boomerang, headbutt.
  impact,
  fall,
  water,
}

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

/// A once-per-match passive kicked in (Kucing: lethal hit left 1 HP;
/// Bebek: pulled out of the water).
enum SaveKind { lethal, water }

final class UnitSaved extends SimEvent {
  const UnitSaved(this.unitId, this.kind);
  final int unitId;
  final SaveKind kind;
}

final class UnitTeleported extends SimEvent {
  const UnitTeleported(this.unitId);
  final int unitId;
}

final class WeaponUsed extends SimEvent {
  const WeaponUsed(this.unitId, this.weaponId);
  final int unitId;
  final String weaponId;
}

/// Terrain removed without a blast (tunnels, headbutt).
final class TerrainCarved extends SimEvent {
  const TerrainCarved(this.x, this.y, this.radius);
  final int x;
  final int y;
  final int radius;
}

/// Ground was added (Benteng); the area must be redrawn from the mask.
final class TerrainAdded extends SimEvent {
  const TerrainAdded(this.area);
  final IntRect area;
}

final class MinePlaced extends SimEvent {
  const MinePlaced(this.mineId);
  final int mineId;
}

final class MineTriggered extends SimEvent {
  const MineTriggered(this.mineId);
  final int mineId;
}

final class MineRemoved extends SimEvent {
  const MineRemoved(this.mineId);
  final int mineId;
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
