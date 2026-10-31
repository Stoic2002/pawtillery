import 'mine.dart';

enum ObjectKind { barrel, healthCrate, weaponCrate, materialCrate, gun, machine }

/// A starter object on the map: a fuel barrel that blows up when caught in
/// a blast, or a crate a unit picks up by touching it. Mines use [Mine].
class MapObject extends GroundBody {
  MapObject({
    required this.id,
    required this.kind,
    required super.x,
    required super.y,
  });

  final int id;
  final ObjectKind kind;

  /// Mounted gun: shots it has left.
  int shots = 0;

  /// Barrel: ticks until it explodes; null = not lit.
  int? fuse;

  /// Coming down from the sky: falls slowly, and the turn doesn't wait for it.
  bool parachute = false;

  /// Crate: destroyed by a blast (removed at the end of the step).
  bool destroyed = false;

  double get centerY => y - 14;
}
