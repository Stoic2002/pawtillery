import '../config/weapons.dart';

/// A bomber crossing the sky (BomberRun). It moves [dir] × [speed] px/s
/// along [y] and drops a bomb each time it passes the next of [dropXs].
class Bomber {
  Bomber({
    required this.ownerId,
    required this.bomb,
    required this.dir,
    required this.x,
    required this.y,
    required this.speed,
    required this.dropXs,
    required this.exitX,
  });

  final int ownerId;

  /// Weapon of the dropped bombs.
  final WeaponDef bomb;

  /// -1 = flying left, 1 = flying right.
  final int dir;
  double x;
  final double y;
  final double speed;

  /// Release points in flight order.
  final List<double> dropXs;

  /// Leaves the map (is removed) once past this x.
  final double exitX;

  /// Bombs dropped so far.
  int dropped = 0;

  bool get gone =>
      dropped >= dropXs.length && (dir > 0 ? x >= exitX : x <= exitX);
}

/// An orbital strike waiting to fire at [dueTick] down column [x]; [y] is
/// the tapped point, where the marker shows.
class PendingStrike {
  const PendingStrike({
    required this.dueTick,
    required this.x,
    required this.y,
    required this.ownerId,
    required this.weapon,
  });

  final int dueTick;
  final int x;
  final int y;
  final int ownerId;
  final WeaponDef weapon;
}
