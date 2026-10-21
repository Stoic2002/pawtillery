/// A patch of napalm fire on the ground at ([x], [y]) (its base, on the
/// surface). Burns for [turnsLeft] more turns.
class FirePatch {
  FirePatch({
    required this.id,
    required this.x,
    required this.y,
    required this.turnsLeft,
    this.ownerId,
  });

  final int id;
  final int x;
  int y;
  int turnsLeft;

  /// Credited with the burns.
  final int? ownerId;
}
