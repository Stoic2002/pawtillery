import '../../config/weapons.dart';
import '../projectile.dart';
import '../rng.dart';
import '../terrain_mask.dart';
import '../unit.dart';

/// What weapon behaviours may read and do to the world. Implemented by
/// [SimWorld]; keeps behaviours small, reusable and testable.
abstract interface class SimContext {
  TerrainMask get terrain;
  int get waterLevel;
  int get wind;
  SimRng get rng;
  List<Unit> get units;

  /// A blast with [weapon]'s damage, radius and knockback; carves terrain if
  /// the weapon does. [sourceId] is the unit credited with the damage.
  void explode(double x, double y, WeaponDef weapon, {int? sourceId});

  /// A direct hit without a blast: [damage] plus knockback along the unit
  /// vector ([dirX], [dirY]).
  void strikeUnit(
      Unit unit, int damage, double dirX, double dirY, double knockbackScale,
      {int? sourceId});

  /// Removes terrain without hurting anyone (tunnels).
  void carveTunnel(int x, int y, int radius);

  /// Adds a disc of ground (Tanah Liat), leaving units' bodies clear.
  void addGround(int x, int y, int radius);

  /// Adds a projectile; it starts moving on the next tick.
  void spawnProjectile(Projectile p);
  int nextProjectileId();

  void spawnMine(WeaponDef weapon, double x, double y, double vx, double vy,
      {int? ownerId});
}
