/// A patch of napalm fire on the ground at ([x], [y]) (its base, on the
/// surface). Burns for [turnsLeft] more turns.
class FirePatch {
  FirePatch({
    required this.id,
    required this.x,
    required this.y,
    required this.turnsLeft,
    required this.creepLeft,
    this.ownerId,
  });

  final int id;
  int x;
  int y;
  int turnsLeft;

  /// How many more px it may run downhill.
  int creepLeft;

  /// Credited with the burns.
  final int? ownerId;
}
