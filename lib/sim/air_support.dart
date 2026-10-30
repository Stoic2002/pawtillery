import '../config/weapons.dart';

/// Something crossing the sky for an [AirRaid]: a bomber, a jet or a flock
/// of birds. It moves [dir] × [speed] px/s along [y] and drops one
/// projectile each time it passes the next of [dropXs].
class Aircraft {
  Aircraft({
    required this.ownerId,
    required this.craft,
    required this.payload,
    required this.dir,
    required this.x,
    required this.y,
    required this.speed,
    required this.dropXs,
    required this.exitX,
    this.targetX,
    this.targetY,
  });

  final int ownerId;
  final CraftKind craft;

  /// Weapon of the dropped projectiles.
  final WeaponDef payload;

  /// -1 = flying left, 1 = flying right.
  final int dir;
  double x;
  final double y;
  final double speed;

  /// Release points in flight order.
  final List<double> dropXs;

  /// Leaves the map (is removed) once past this x.
  final double exitX;

  /// Where a guided payload steers to.
  final double? targetX;
  final double? targetY;

  /// Dropped so far.
  int dropped = 0;

  bool get gone =>
      dropped >= dropXs.length && (dir > 0 ? x >= exitX : x <= exitX);
}

/// A strike from the sky waiting to land at [dueTick] down column [x]: the
/// satellite's beam or the storm cloud's bolt. [y] is the tapped point
/// (marker), [fromDir] the side the cloud drifts in from (-1 = left).
class PendingStrike {
  const PendingStrike({
    required this.dueTick,
    required this.x,
    required this.y,
    required this.ownerId,
    required this.weapon,
    required this.firedTick,
    this.fromDir = -1,
    this.shot = 0,
    this.originY = 0,
  });

  final int dueTick;
  final int x;
  final int y;
  final int ownerId;
  final WeaponDef weapon;

  /// When it was called (drawing: how far the satellite or cloud has come).
  final int firedTick;
  final int fromDir;

  /// Satellite: how many of its beams have fired.
  final int shot;

  /// Satellite: the height it parks at, clear of the ground under it.
  final double originY;

  PendingStrike nextShot(int dueTick) => PendingStrike(
        dueTick: dueTick,
        x: x,
        y: y,
        ownerId: ownerId,
        weapon: weapon,
        firedTick: firedTick,
        fromDir: fromDir,
        shot: shot + 1,
        originY: originY,
      );
}
