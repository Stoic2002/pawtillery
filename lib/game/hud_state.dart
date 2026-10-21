import 'package:flutter/foundation.dart';

import '../sim/turn_manager.dart';

/// Snapshot of everything the Flutter HUD shows. Rebuilt every frame but
/// only notifies listeners when something actually changed.
@immutable
class HudState {
  const HudState({
    required this.phase,
    required this.activeTeam,
    required this.clockSeconds,
    required this.wind,
    required this.teamHp,
    required this.teamMaxHp,
    required this.winnerTeam,
    this.suddenDeath = false,
    this.frozenSkip = false,
    this.shotgunLeft = 0,
  });

  final TurnPhase phase;
  final int activeTeam;

  /// Whole seconds left on the turn or retreat clock; null when stopped.
  final int? clockSeconds;
  final int wind;
  final List<int> teamHp;

  /// Starting HP per team (differs by family passives).
  final List<int> teamMaxHp;

  /// Only meaningful when [phase] is [TurnPhase.matchOver]; null = draw.
  final int? winnerTeam;
  final bool suddenDeath;

  /// The active pet is frozen: this turn is skipped.
  final bool frozenSkip;

  /// Shotgun pulls still to take this turn.
  final int shotgunLeft;

  bool get canMove =>
      phase == TurnPhase.action || phase == TurnPhase.retreat;
  bool get isOver => phase == TurnPhase.matchOver;

  @override
  bool operator ==(Object other) =>
      other is HudState &&
      other.phase == phase &&
      other.activeTeam == activeTeam &&
      other.clockSeconds == clockSeconds &&
      other.wind == wind &&
      listEquals(other.teamHp, teamHp) &&
      listEquals(other.teamMaxHp, teamMaxHp) &&
      other.suddenDeath == suddenDeath &&
      other.frozenSkip == frozenSkip &&
      other.shotgunLeft == shotgunLeft &&
      other.winnerTeam == winnerTeam;

  @override
  int get hashCode => Object.hash(phase, activeTeam, clockSeconds, wind,
      Object.hashAll(teamHp), Object.hashAll(teamMaxHp), winnerTeam,
      suddenDeath, frozenSkip, shotgunLeft);
}

/// The player's current weapon and aim. [active] = ready to fire: the
/// slingshot is drawn (or fine-adjusted), a valid target is picked, or the
/// weapon needs no aiming.
@immutable
class AimState {
  const AimState({
    required this.weaponId,
    required this.active,
    required this.angle,
    required this.power,
    required this.fuseSeconds,
    this.targetX,
    this.targetY,
    this.targetValid = false,
  });

  final String weaponId;
  final bool active;
  final int angle;
  final int power;
  final int fuseSeconds;
  final int? targetX;
  final int? targetY;
  final bool targetValid;

  bool get hasTarget => targetX != null;

  AimState copyWith({
    String? weaponId,
    bool? active,
    int? angle,
    int? power,
    int? fuseSeconds,
  }) =>
      AimState(
        weaponId: weaponId ?? this.weaponId,
        active: active ?? this.active,
        angle: angle ?? this.angle,
        power: power ?? this.power,
        fuseSeconds: fuseSeconds ?? this.fuseSeconds,
        targetX: targetX,
        targetY: targetY,
        targetValid: targetValid,
      );

  AimState withTarget(int? x, int? y, {required bool valid}) => AimState(
        weaponId: weaponId,
        active: valid,
        angle: angle,
        power: power,
        fuseSeconds: fuseSeconds,
        targetX: x,
        targetY: y,
        targetValid: valid,
      );

  @override
  bool operator ==(Object other) =>
      other is AimState &&
      other.weaponId == weaponId &&
      other.active == active &&
      other.angle == angle &&
      other.power == power &&
      other.fuseSeconds == fuseSeconds &&
      other.targetX == targetX &&
      other.targetY == targetY &&
      other.targetValid == targetValid;

  @override
  int get hashCode => Object.hash(weaponId, active, angle, power, fuseSeconds,
      targetX, targetY, targetValid);
}
