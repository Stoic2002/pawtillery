/// A cloud of poison gas centred at ([x], [y]), [radius] px across,
/// drifting with the wind. Hangs about for [turnsLeft] more turns.
class PoisonCloud {
  PoisonCloud({
    required this.id,
    required this.x,
    required this.y,
    required this.radius,
    required this.turnsLeft,
    this.ownerId,
  });

  final int id;
  double x;
  final double y;
  final int radius;
  int turnsLeft;
  final int? ownerId;
}
