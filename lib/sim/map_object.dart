import 'mine.dart';

enum ObjectKind { barrel, healthCrate, weaponCrate }

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

  /// Barrel: ticks until it explodes; null = not lit.
  int? fuse;

  /// Crate: destroyed by a blast (removed at the end of the step).
  bool destroyed = false;

  double get centerY => y - 8;
}
