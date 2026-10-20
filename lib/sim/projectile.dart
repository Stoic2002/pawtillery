import '../config/weapons.dart';
import 'unit.dart';

/// A projectile in flight. Position in world px (y down), velocity in px/s.
/// Behaviour-specific state lives in the generic fields below; which ones
/// matter depends on the weapon's [FlightSpec] or delivery.
class Projectile {
  Projectile({
    required this.id,
    required this.weapon,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    this.ownerId,
    this.fuseTicks,
  })  : freeX = x,
        freeY = y;

  final int id;

  /// Unit that fired it, if any.
  final int? ownerId;
  final WeaponDef weapon;
  double x;
  double y;
  double vx;
  double vy;
  int ageTicks = 0;

  /// Last sampled position that was not inside anything (bounce restart).
  double freeX;
  double freeY;

  /// Ticks until it detonates by itself; null = no fuse.
  int? fuseTicks;

  /// Behaviour phase (boomerang: 0 out / 1 back; drill: 0 flying /
  /// 1 tunnelling) and distance covered in that phase.
  int mode = 0;
  double traveled = 0;

  /// Boomerang range for this throw, px.
  double range = 0;

  /// Resting on the ground (bouncy projectiles).
  bool resting = false;

  /// Units already hit in the current phase (boomerang).
  final Set<int> hitUnits = {};

  /// Body of a walking projectile (Bebek Peledak), moved with [UnitPhysics].
  Unit? body;

  /// Sticky bomb: the unit it is stuck to (-1 = stuck to the ground).
  int? stuckTo;

  /// The point a guided missile steers to (Rudal Pemburu); null = it
  /// chases the nearest enemy.
  double? targetX;
  double? targetY;
}
