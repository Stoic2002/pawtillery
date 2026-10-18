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

  /// Give up waiting for everything to come to rest after this long.
  static const int settleTimeoutSeconds = 20;

  static const int teamCount = 2;
  static const int unitsPerTeam = 3;
  static const int turnSeconds = 45;
  static const int retreatSeconds = 3;
  static const int suddenDeathMinutes = 15;
}
