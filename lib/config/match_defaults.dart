/// Single source for match-level tuning numbers (PRD: all balancing values
/// live in config, never hard-coded in components).
abstract final class MatchDefaults {
  /// Fixed simulation rate.
  static const int ticksPerSecond = 60;
  static const double tickSeconds = 1 / ticksPerSecond;

  /// Max simulation steps run per rendered frame, so a long frame hitch
  /// can't snowball into a "spiral of death".
  static const int maxStepsPerFrame = 5;

  /// Team banner shown at the start of every turn (no input meanwhile):
  /// 1.5 s, kept in whole ticks.
  static const int bannerTicks = 90;

  /// After a turn's last hit (damage or a death), hold everything still
  /// this long before the next turn, so every player sees who got hurt:
  /// 2 s, kept in whole ticks.
  static const int hitHoldTicks = 120;

  /// Give up waiting for everything to come to rest after this long.
  static const int settleTimeoutSeconds = 20;

  static const int teamCount = 2;
  static const int unitsPerTeam = 3;
  static const int turnSeconds = 45;
  static const int retreatSeconds = 3;
  static const int suddenDeathMinutes = 15;

  // Choices offered on the setup screen (PRD: Pengaturan pertandingan).
  static const teamCountOptions = [2, 3, 4];
  static const unitsPerTeamOptions = [1, 2, 3, 4];
  static const turnSecondsOptions = [30, 45, 60];

  /// null = sudden death off.
  static const suddenDeathOptions = <int?>[null, 10, 15];

  /// Sudden death: after every round the ground gives way in holes of
  /// [crumbleRadius] px: one near every pet still standing (up to
  /// [crumbleNearPet] px either side), plus [crumbleHolesFirst] anywhere
  /// after the first round, one more each round up to [crumbleHolesMax].
  static const int crumbleRadius = 44;
  static const int crumbleHolesFirst = 3;
  static const int crumbleHolesMax = 10;
  static const int crumbleNearPet = 30;
}
