import 'match_defaults.dart';

/// Physics tuning. Pure Dart: imported by the simulation.
abstract final class PhysicsConfig {
  static const double dt = MatchDefaults.tickSeconds;

  /// Downward acceleration, px/s².
  static const double gravity = 500;

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
