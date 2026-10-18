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
    required this.winnerTeam,
  });

  final TurnPhase phase;
  final int activeTeam;

  /// Whole seconds left on the turn or retreat clock; null when stopped.
  final int? clockSeconds;
  final int wind;
  final List<int> teamHp;

  /// Only meaningful when [phase] is [TurnPhase.matchOver]; null = draw.
  final int? winnerTeam;

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
      other.winnerTeam == winnerTeam;

  @override
  int get hashCode => Object.hash(phase, activeTeam, clockSeconds, wind,
      Object.hashAll(teamHp), winnerTeam);
}

/// The player's current aim. [active] = the slingshot is drawn (or fine
/// adjusted) and the fire button is live.
@immutable
class AimState {
  const AimState({
    required this.active,
    required this.angle,
    required this.power,
  });

  final bool active;
  final int angle;
  final int power;

  AimState copyWith({bool? active, int? angle, int? power}) => AimState(
        active: active ?? this.active,
        angle: angle ?? this.angle,
        power: power ?? this.power,
      );

  @override
  bool operator ==(Object other) =>
      other is AimState &&
      other.active == active &&
      other.angle == angle &&
      other.power == power;

  @override
  int get hashCode => Object.hash(active, angle, power);
}
