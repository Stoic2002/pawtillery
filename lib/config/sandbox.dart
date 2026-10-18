/// M1 test-bench settings: a fixed launcher and tap-to-explode. Units and
/// turns replace this in M2.
abstract final class SandboxConfig {
  static const int launcherX = 300;
  static const int launcherY = 520;
  static const int tapExplosionRadius = 40;
  static const int initialAngle = 45;
  static const int initialPower = 70;
}

/// Aiming controls (PRD: Kontrol sentuh).
abstract final class ControlsConfig {
  /// Share of the predicted path shown by the aim guide.
  static const double aimGuideFraction = 0.25;
  static const int angleStep = 1;
  static const int powerStep = 1;
}
