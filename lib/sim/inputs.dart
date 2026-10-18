/// Discrete player inputs fed into the simulation, one batch per tick.
/// Coordinates are whole pixels so recorded inputs replay exactly.
sealed class SimInput {
  const SimInput();
}

/// M1 test bench: explosion at a world point (tap to blast).
final class DebugExplode extends SimInput {
  const DebugExplode({required this.x, required this.y, required this.radius});

  final int x;
  final int y;
  final int radius;
}

/// M1 test bench: fire the basic weapon from a fixed launcher. Ignored while
/// a projectile is still in flight.
final class DebugFire extends SimInput {
  const DebugFire({
    required this.x,
    required this.y,
    required this.angleDeg,
    required this.powerPercent,
  });

  final int x;
  final int y;
  final int angleDeg;
  final int powerPercent;
}
