/// Discrete player inputs fed into the simulation, one batch per tick. They
/// always act on the active unit and are ignored when the turn phase does
/// not allow them. Values are whole numbers so recorded inputs replay
/// exactly.
sealed class SimInput {
  const SimInput();
}

/// Walk one tick; sent every tick while a walk button is held.
final class Walk extends SimInput {
  const Walk(this.direction) : assert(direction == -1 || direction == 1);

  /// -1 = left, 1 = right.
  final int direction;
}

enum JumpKind { forward, high }

final class Jump extends SimInput {
  const Jump(this.kind);
  final JumpKind kind;
}

/// Uses a weapon. Which fields matter depends on the weapon's aim mode:
/// angle and power for slingshot weapons, angle only for direction
/// weapons, the target for teleport / air strike / wall.
final class Fire extends SimInput {
  const Fire({
    required this.weaponId,
    this.angleDeg = 0,
    this.powerPercent = 0,
    this.fuseTicks,
    this.targetX,
    this.targetY,
  });

  final String weaponId;

  /// 0 = right, 90 = up.
  final int angleDeg;
  final int powerPercent;

  /// Player-chosen fuse (Granat Pantul), clamped to 1–5 s.
  final int? fuseTicks;

  /// World point for target weapons.
  final int? targetX;
  final int? targetY;
}
