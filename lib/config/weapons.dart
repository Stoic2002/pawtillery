/// How a weapon's projectile moves. Special behaviours (bounce, cluster,
/// boomerang, drill, air strike) are added as strategies in M3.
enum ProjectileKind { ballistic }

class WeaponDef {
  const WeaponDef({
    required this.id,
    required this.nameKey,
    required this.projectile,
    required this.affectedByWind,
    required this.maxDamage,
    required this.radius,
    required this.placeholderArgb,
    this.fuseTicks,
    this.ammo,
    this.endsTurn = false,
  });

  final String id;

  /// ARB key of the display name.
  final String nameKey;
  final ProjectileKind projectile;
  final bool affectedByWind;
  final int maxDamage;

  /// Explosion radius in world px.
  final int radius;

  /// Fuse in sim ticks; `null` = explodes on impact.
  final int? fuseTicks;

  /// Per team per match; `null` = unlimited.
  final int? ammo;
  final bool endsTurn;

  /// Placeholder projectile / icon colour (0xAARRGGBB).
  final int placeholderArgb;
}

abstract final class Weapons {
  static const rock = WeaponDef(
    id: 'rock',
    nameKey: 'weaponRock',
    projectile: ProjectileKind.ballistic,
    affectedByWind: true,
    maxDamage: 45,
    radius: 40,
    placeholderArgb: 0xFF5B5B66,
  );

  static const all = [rock];
}
