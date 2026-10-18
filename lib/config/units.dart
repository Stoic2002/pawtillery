/// Unit tuning (PRD: Mekanik inti → Gerak unit). Pure Dart. Family passives
/// in M3 modify these values; they never replace them in code.
abstract final class UnitConfig {
  static const int baseHp = 100;

  /// Body is a 1 px column [bodyHeight] tall standing on its feet pixel.
  static const int bodyHeight = 24;

  /// Radius for projectile hits and explosion distance, centred on the body.
  static const double hitRadius = 12;

  /// Walking speed, px/s.
  static const double walkSpeed = 60;

  /// Highest step climbed while walking; steeper counts as a wall.
  static const int maxClimb = 6;

  /// Velocities (px/s) for the two jumps. Horizontal is along facing.
  /// Peaks (v² / 2g): forward ≈ 58 px, high ≈ 90 px, both safely under the
  /// fall-damage threshold so a plain jump never hurts.
  static const double jumpForwardVx = 160;
  static const double jumpForwardVy = 240;
  static const double jumpHighVx = 40;
  static const double jumpHighVy = 300;

  /// Fall damage: 1 HP per [fallDamagePxPerHp] px beyond [fallDamageThreshold],
  /// capped at [fallDamageMax].
  static const int fallDamageThreshold = 120;
  static const int fallDamagePxPerHp = 4;
  static const int fallDamageMax = 40;

  /// Knockback speed (px/s) per point of explosion damage, and the extra
  /// upward share added to the blast direction.
  static const double knockbackPerDamage = 9;
  static const double knockbackLift = 0.5;

  /// Terminal fall speed, px/s.
  static const double maxFallSpeed = 1400;

  /// Fall speed cap while gliding (Burung), px/s.
  static const double glideFallSpeed = 90;

  /// Spawn rules (PRD: Peta 1.0).
  static const int spawnMinDistance = 150;
  static const int spawnFlatTolerance = 3;
}
