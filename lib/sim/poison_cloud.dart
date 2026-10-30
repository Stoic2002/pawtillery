/// One blob of poison gas: gas is heavy, so it falls, spreads and pools.
class GasPuff {
  GasPuff(this.x, this.y);

  double x;
  double y;
  double vx = 0;
  double vy = 0;
}

/// A cloud of poison gas: a bunch of [puffs] released together that fall,
/// flow along the ground and into any gap, pool in hollows and are stopped
/// by the terrain. Each is [spacing] px from its neighbours once spread.
/// Hangs about for [turnsLeft] more turns.
class PoisonCloud {
  PoisonCloud({
    required this.id,
    required this.radius,
    required this.spacing,
    required this.puffs,
    required this.turnsLeft,
    this.ownerId,
    this.fallout = false,
  });

  final int id;

  /// Size it was released at, px.
  final int radius;
  final double spacing;
  final List<GasPuff> puffs;
  int turnsLeft;
  final int? ownerId;

  /// Left by a mini nuke (drawing only).
  final bool fallout;

  /// Its middle.
  double get x {
    var sum = 0.0;
    for (final p in puffs) {
      sum += p.x;
    }
    return sum / puffs.length;
  }

  double get y {
    var sum = 0.0;
    for (final p in puffs) {
      sum += p.y;
    }
    return sum / puffs.length;
  }
}
