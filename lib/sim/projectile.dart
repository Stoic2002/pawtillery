import '../config/weapons.dart';

/// A projectile in flight. Position in world px (y down), velocity in px/s.
class Projectile {
  Projectile({
    required this.id,
    required this.weapon,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
  });

  final int id;
  final WeaponDef weapon;
  double x;
  double y;
  double vx;
  double vy;
  int ageTicks = 0;
}
