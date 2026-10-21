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
  const ProjectileRemoved(this.id, this.outcome,
      {required this.x, required this.y});
  final int id;
  final FlightOutcome outcome;

  /// Where it ended (splash, impact effects).
  final double x;
  final double y;
}

enum DamageCause {
  explosion,

  /// Direct hits without a blast: punch, shockwave, boomerang, headbutt.
  impact,
  fall,
  water,
}

final class UnitDamaged extends SimEvent {
  const UnitDamaged(this.unitId, this.amount, this.cause, {this.sourceUnitId});
  final int unitId;
  final int amount;
  final DamageCause cause;

  /// The unit whose weapon caused it (null for falls and water).
  final int? sourceUnitId;
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

/// A laser beam from (x0, y0) to (x1, y1); the ground within [radius] of
/// the line was burnt away (the mask is already carved).
final class BeamFired extends SimEvent {
  const BeamFired(this.x0, this.y0, this.x1, this.y1, this.radius);
  final double x0;
  final double y0;
  final double x1;
  final double y1;
  final int radius;
}

/// [unitId] shot its grappling hook from ([x0], [y0]) to ([x1], [y1]);
/// [hooked] when it caught the ground there (and the unit is being reeled
/// in), otherwise it fell short.
final class GrappleFired extends SimEvent {
  const GrappleFired(
      this.unitId, this.x0, this.y0, this.x1, this.y1, this.hooked);
  final int unitId;
  final double x0;
  final double y0;
  final double x1;
  final double y1;
  final bool hooked;
}

/// Lightning struck down column [x] from the sky to [y], where it blasts
/// (an [ExplosionEvent] follows).
final class LightningStruck extends SimEvent {
  const LightningStruck(this.x, this.y);
  final int x;
  final int y;
}

/// The satellite's beam burnt down column [x] from the sky to [y]; the
/// ground within [radius] of it is gone (the mask is already carved).
/// [targetY] is the spot the player marked in that column.
final class SatelliteStruck extends SimEvent {
  const SatelliteStruck(this.x, this.y, this.radius, {required this.targetY});
  final int x;
  final int y;
  final int radius;
  final int targetY;
}

/// A bomber dropped a bomb at ([x], [y]).
final class BombDropped extends SimEvent {
  const BombDropped(this.x, this.y);
  final double x;
  final double y;
}

/// A starter object is gone: blown up, destroyed, picked up, or lost in
/// the water.
final class ObjectRemoved extends SimEvent {
  const ObjectRemoved(this.objectId);
  final int objectId;
}

/// A unit picked up a crate: [hp] healed (health crate) or one more of
/// [weaponId] for its team (weapon crate; null if it held nothing).
final class CrateCollected extends SimEvent {
  const CrateCollected(
    this.unitId, {
    required this.health,
    this.hp = 0,
    this.weaponId,
  });
  final int unitId;
  final bool health;
  final int hp;
  final String? weaponId;
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

/// An airborne unit touched the ground after falling [fallDistance] px.
final class UnitLanded extends SimEvent {
  const UnitLanded(this.unitId, this.fallDistance);
  final int unitId;
  final double fallDistance;
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

/// Sudden death began: every unit dropped to 1 HP.
final class SuddenDeathStarted extends SimEvent {
  const SuddenDeathStarted();
}

/// The water rose (sudden death) to [level].
final class WaterRose extends SimEvent {
  const WaterRose(this.level);
  final int level;
}

/// [winnerTeam] is null for a draw.
final class MatchEnded extends SimEvent {
  const MatchEnded(this.winnerTeam);
  final int? winnerTeam;
}
