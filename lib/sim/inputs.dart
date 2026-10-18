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

final class Fire extends SimInput {
  const Fire({
    required this.angleDeg,
    required this.powerPercent,
    required this.weaponId,
    this.fuseTicks,
  });

  /// 0 = right, 90 = up.
  final int angleDeg;
  final int powerPercent;
  final String weaponId;

  /// Player-chosen fuse for timed weapons (M3).
  final int? fuseTicks;
}
