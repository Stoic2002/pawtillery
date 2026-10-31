import 'match_defaults.dart';

/// Physics tuning. Pure Dart: imported by the simulation.
abstract final class PhysicsConfig {
  static const double dt = MatchDefaults.tickSeconds;

  /// Downward acceleration, px/s².
  static const double gravity = 500;

  /// Gravity of the match being played, as a share of normal, for pets,
  /// shots and mines alike (SimWorld sets it: only one match runs at a time,
  /// and passing it through every step would touch the whole sim).
  static double gravityScale = 1;

  /// Moon mode's [gravityScale].
  static const double moonGravity = 0.45;

  /// Storm mode: strongest wind, and every [stormShiftTicks] it moves by up
  /// to [stormShift].
  static const int stormWind = 20;
  static const int stormShiftTicks = 4 * MatchDefaults.ticksPerSecond;
  static const int stormShift = 6;

  /// Projectile launch speed at 100 % power, px/s.
  static const double maxLaunchSpeed = 900;

  /// Horizontal acceleration per wind unit, px/s², applied only to weapons
  /// with `affectedByWind`.
  static const double windAccelPerUnit = 12;
  static const int windMin = -10;
  static const int windMax = 10;

  /// Map PNG pixels with alpha above this are ground.
  static const int terrainAlphaThreshold = 128;

  /// Safety cap so a projectile can never fly forever (30 s).
  static const int maxProjectileTicks = 30 * MatchDefaults.ticksPerSecond;
}
