/// Weapon data (PRD: Senjata). Every weapon is a combination of reusable
/// pieces: how the player aims it, how it enters the world ([Delivery]),
/// how a launched projectile flies ([FlightSpec]) and what happens on
/// impact ([ImpactSpec]). Pure Dart.
library;

enum AimMode {
  /// Slingshot sets angle and power.
  angleAndPower,

  /// Slingshot sets only a direction.
  direction,

  /// No aiming; just use it.
  none,

  /// Tap a point on the map, then confirm.
  target,
}

// ------------------------------------------------------------- delivery

sealed class Delivery {
  const Delivery();
}

/// Fires [shots] projectiles from the unit, [shotIntervalTicks] apart.
final class Launch extends Delivery {
  const Launch({this.shots = 1, this.shotIntervalTicks = 0});
  final int shots;
  final int shotIntervalTicks;
}

/// Drops [count] [childId] projectiles from above the chosen column.
final class AirStrike extends Delivery {
  const AirStrike({
    required this.childId,
    required this.count,
    required this.spacing,
  });
  final String childId;
  final int count;
  final int spacing;
}

/// Puts this weapon down as a mine next to the unit.
final class PlaceMine extends Delivery {
  const PlaceMine();
}

/// Instant blast centred [reach] px from the unit along the aim, which
/// never hurts the user. Used for melee and shockwaves.
final class AreaHit extends Delivery {
  const AreaHit({required this.reach});
  final double reach;
}

/// The unit charges horizontally, digging through terrain, and hits the
/// first unit in its way.
final class Dash extends Delivery {
  const Dash({
    required this.distance,
    required this.speed,
    required this.carveRadius,
  });
  final int distance;

  /// px/s.
  final double speed;
  final int carveRadius;
}

final class Teleport extends Delivery {
  const Teleport();
}

/// Adds a [width] × [height] block of ground centred on the target.
final class BuildWall extends Delivery {
  const BuildWall({required this.width, required this.height});
  final int width;
  final int height;
}

final class SkipTurn extends Delivery {
  const SkipTurn();
}

/// A small creature that walks along the ground in the aim direction, hops
/// over walls, and explodes when its fuse runs out or it touches a unit.
final class SpawnWalker extends Delivery {
  const SpawnWalker({
    required this.walkSpeed,
    required this.bodyHeight,
    required this.hopVx,
    required this.hopVy,
  });
  final double walkSpeed;
  final int bodyHeight;
  final double hopVx;
  final double hopVy;
}

// --------------------------------------------------------------- flight

sealed class FlightSpec {
  const FlightSpec();
}

/// Gravity (scaled by [WeaponDef.gravityScale]) and optional wind; reacts to
/// the first thing it touches with [onImpact]. A fuse, if any, detonates it
/// in the air.
final class Ballistic extends FlightSpec {
  const Ballistic({this.onImpact = const Explode()});
  final ImpactSpec onImpact;
}

/// Bounces off ground and units, losing speed; explodes when the fuse ends.
final class Bouncy extends FlightSpec {
  const Bouncy({required this.restitution});
  final double restitution;
}

/// Flies straight out, turns around, and flies back, hitting every unit
/// on the way out and again on the way back. Passes through terrain.
final class Boomerang extends FlightSpec {
  const Boomerang({
    required this.speed,
    required this.minRange,
    required this.maxRange,
  });

  /// px/s.
  final double speed;

  /// Range at 0 % and 100 % power, px.
  final double minRange;
  final double maxRange;
}

/// Ballistic until it touches ground, then tunnels straight on for
/// [length] px and explodes.
final class Drill extends FlightSpec {
  const Drill({
    required this.length,
    required this.speed,
    required this.tunnelRadius,
  });
  final int length;
  final double speed;
  final int tunnelRadius;
}

// --------------------------------------------------------------- impact

sealed class ImpactSpec {
  const ImpactSpec();
}

final class Explode extends ImpactSpec {
  const Explode();
}

/// Bursts into [count] [childId] projectiles thrown upwards, optionally
/// exploding itself first.
final class Split extends ImpactSpec {
  const Split({
    required this.childId,
    required this.count,
    required this.explodeSelf,
    this.minSpeed = 150,
    this.maxSpeed = 260,
  });
  final String childId;
  final int count;
  final bool explodeSelf;
  final double minSpeed;
  final double maxSpeed;
}

/// Scatters [count] [mineId] mines around the landing point.
final class ScatterMines extends ImpactSpec {
  const ScatterMines({
    required this.mineId,
    required this.count,
    this.minSpeed = 90,
    this.maxSpeed = 180,
  });
  final String mineId;
  final int count;
  final double minSpeed;
  final double maxSpeed;
}

// --------------------------------------------------------------- weapon

class WeaponDef {
  const WeaponDef({
    required this.id,
    required this.nameKey,
    required this.aim,
    required this.delivery,
    required this.placeholderArgb,
    this.flight,
    this.affectedByWind = false,
    this.maxDamage = 0,
    this.radius = 0,
    this.fuseTicks,
    this.playerFuse = false,
    this.ammo,
    this.endsTurn = false,
    this.gravityScale = 1,
    this.knockbackScale = 1,
    this.terrainDamage = true,
    this.familyId,
    this.hidden = false,
  });

  final String id;

  /// ARB key of the display name.
  final String nameKey;
  final AimMode aim;
  final Delivery delivery;

  /// For [Launch] and [AirStrike] projectiles.
  final FlightSpec? flight;
  final bool affectedByWind;
  final int maxDamage;

  /// Explosion radius in world px.
  final int radius;

  /// Fuse in sim ticks; `null` = no fuse.
  final int? fuseTicks;

  /// The player picks the fuse (1–5 s) before firing.
  final bool playerFuse;

  /// Per team per match; `null` = unlimited. Signature weapons are once per
  /// unit instead.
  final int? ammo;
  final bool endsTurn;
  final double gravityScale;
  final double knockbackScale;
  final bool terrainDamage;

  /// Set for a family's signature weapon (PRD: Family dan breed).
  final String? familyId;

  /// Sub-munitions (bomblets, eggs, …) that never appear in the menu.
  final bool hidden;

  bool get isSignature => familyId != null;

  /// Placeholder projectile / icon colour (0xAARRGGBB).
  final int placeholderArgb;
}

/// Mine behaviour shared by every mine-type weapon.
abstract final class MineConfig {
  /// A unit's body centre this close sets a mine off.
  static const double triggerRadius = 30;

  /// Delay between triggering and exploding (0.5 s).
  static const int triggerDelayTicks = 30;
}

/// Player-chosen fuse range (Granat Pantul).
abstract final class FuseConfig {
  static const int minSeconds = 1;
  static const int maxSeconds = 5;
  static const int defaultSeconds = 3;
}

abstract final class Weapons {
  // ---- shared arsenal (PRD table) --------------------------------------

  static const rock = WeaponDef(
    id: 'rock',
    nameKey: 'weaponRock',
    aim: AimMode.angleAndPower,
    delivery: Launch(),
    flight: Ballistic(),
    affectedByWind: true,
    maxDamage: 45,
    radius: 40,
    placeholderArgb: 0xFF5B5B66,
  );

  static const grenade = WeaponDef(
    id: 'grenade',
    nameKey: 'weaponGrenade',
    aim: AimMode.angleAndPower,
    delivery: Launch(),
    flight: Bouncy(restitution: 0.5),
    affectedByWind: true,
    maxDamage: 50,
    radius: 45,
    fuseTicks: FuseConfig.defaultSeconds * 60,
    playerFuse: true,
    ammo: 5,
    placeholderArgb: 0xFF2E7D32,
  );

  static const cluster = WeaponDef(
    id: 'cluster',
    nameKey: 'weaponCluster',
    aim: AimMode.angleAndPower,
    delivery: Launch(),
    flight: Ballistic(
      onImpact: Split(childId: 'clusterBomblet', count: 5, explodeSelf: true),
    ),
    affectedByWind: true,
    maxDamage: 30,
    radius: 35,
    ammo: 2,
    placeholderArgb: 0xFFC62828,
  );

  static const twinSling = WeaponDef(
    id: 'twinSling',
    nameKey: 'weaponTwinSling',
    aim: AimMode.angleAndPower,
    delivery: Launch(shots: 2, shotIntervalTicks: 20),
    flight: Ballistic(),
    maxDamage: 20,
    radius: 15,
    gravityScale: 0.1,
    ammo: 3,
    placeholderArgb: 0xFF6D4C41,
  );

  static const punch = WeaponDef(
    id: 'punch',
    nameKey: 'weaponPunch',
    aim: AimMode.direction,
    delivery: AreaHit(reach: 16),
    maxDamage: 30,
    radius: 20,
    knockbackScale: 3,
    terrainDamage: false,
    placeholderArgb: 0xFFFF8F00,
  );

  static const mine = WeaponDef(
    id: 'mine',
    nameKey: 'weaponMine',
    aim: AimMode.none,
    delivery: PlaceMine(),
    maxDamage: 50,
    radius: 45,
    ammo: 2,
    placeholderArgb: 0xFF37474F,
  );

  static const teleport = WeaponDef(
    id: 'teleport',
    nameKey: 'weaponTeleport',
    aim: AimMode.target,
    delivery: Teleport(),
    ammo: 2,
    endsTurn: true,
    placeholderArgb: 0xFF7E57C2,
  );

  static const skip = WeaponDef(
    id: 'skip',
    nameKey: 'weaponSkip',
    aim: AimMode.none,
    delivery: SkipTurn(),
    endsTurn: true,
    placeholderArgb: 0xFF90A4AE,
  );

  // ---- family signature weapons (PRD: Family dan breed) ----------------

  static const hairball = WeaponDef(
    id: 'hairball',
    nameKey: 'weaponHairball',
    familyId: 'cat',
    aim: AimMode.angleAndPower,
    delivery: Launch(),
    flight: Ballistic(
      onImpact: Split(childId: 'hairballBomb', count: 4, explodeSelf: false),
    ),
    affectedByWind: true,
    placeholderArgb: 0xFFBCAAA4,
  );

  static const boneBoomerang = WeaponDef(
    id: 'boneBoomerang',
    nameKey: 'weaponBoneBoomerang',
    familyId: 'dog',
    aim: AimMode.angleAndPower,
    delivery: Launch(),
    flight: Boomerang(speed: 500, minRange: 150, maxRange: 500),
    maxDamage: 30,
    knockbackScale: 1.5,
    terrainDamage: false,
    placeholderArgb: 0xFFF5F5F5,
  );

  static const drillCarrot = WeaponDef(
    id: 'drillCarrot',
    nameKey: 'weaponDrillCarrot',
    familyId: 'rabbit',
    aim: AimMode.angleAndPower,
    delivery: Launch(),
    flight: Drill(length: 200, speed: 300, tunnelRadius: 10),
    affectedByWind: true,
    maxDamage: 25,
    radius: 25,
    placeholderArgb: 0xFFFF7043,
  );

  static const eggStrike = WeaponDef(
    id: 'eggStrike',
    nameKey: 'weaponEggStrike',
    familyId: 'bird',
    aim: AimMode.target,
    delivery: AirStrike(childId: 'egg', count: 5, spacing: 40),
    placeholderArgb: 0xFFFFF9C4,
  );

  static const seedMines = WeaponDef(
    id: 'seedMines',
    nameKey: 'weaponSeedMines',
    familyId: 'hamster',
    aim: AimMode.angleAndPower,
    delivery: Launch(),
    flight: Ballistic(onImpact: ScatterMines(mineId: 'seedMine', count: 3)),
    affectedByWind: true,
    placeholderArgb: 0xFFD7B56D,
  );

  static const boomDuck = WeaponDef(
    id: 'boomDuck',
    nameKey: 'weaponBoomDuck',
    familyId: 'duck',
    aim: AimMode.direction,
    delivery: SpawnWalker(walkSpeed: 90, bodyHeight: 14, hopVx: 100, hopVy: 220),
    maxDamage: 40,
    radius: 40,
    fuseTicks: 5 * 60,
    placeholderArgb: 0xFFFFEB3B,
  );

  static const startleCrow = WeaponDef(
    id: 'startleCrow',
    nameKey: 'weaponStartleCrow',
    familyId: 'chicken',
    aim: AimMode.none,
    delivery: AreaHit(reach: 0),
    maxDamage: 15,
    radius: 120,
    knockbackScale: 3,
    terrainDamage: false,
    placeholderArgb: 0xFFE53935,
  );

  static const fortress = WeaponDef(
    id: 'fortress',
    nameKey: 'weaponFortress',
    familyId: 'turtle',
    aim: AimMode.target,
    delivery: BuildWall(width: 20, height: 60),
    placeholderArgb: 0xFF8D6E63,
  );

  static const headbutt = WeaponDef(
    id: 'headbutt',
    nameKey: 'weaponHeadbutt',
    familyId: 'goat',
    aim: AimMode.direction,
    delivery: Dash(distance: 150, speed: 600, carveRadius: 12),
    maxDamage: 35,
    knockbackScale: 3,
    placeholderArgb: 0xFF9E9E9E,
  );

  static const coconut = WeaponDef(
    id: 'coconut',
    nameKey: 'weaponCoconut',
    familyId: 'monkey',
    aim: AimMode.angleAndPower,
    delivery: Launch(),
    flight: Ballistic(),
    maxDamage: 70,
    radius: 60,
    gravityScale: 1.5,
    placeholderArgb: 0xFF6D4C41,
  );

  // ---- sub-munitions ---------------------------------------------------

  static const clusterBomblet = WeaponDef(
    id: 'clusterBomblet',
    nameKey: 'weaponCluster',
    hidden: true,
    aim: AimMode.none,
    delivery: Launch(),
    flight: Ballistic(),
    affectedByWind: true,
    maxDamage: 15,
    radius: 20,
    placeholderArgb: 0xFFEF5350,
  );

  static const hairballBomb = WeaponDef(
    id: 'hairballBomb',
    nameKey: 'weaponHairball',
    hidden: true,
    aim: AimMode.none,
    delivery: Launch(),
    flight: Ballistic(),
    affectedByWind: true,
    maxDamage: 20,
    radius: 25,
    placeholderArgb: 0xFFBCAAA4,
  );

  static const egg = WeaponDef(
    id: 'egg',
    nameKey: 'weaponEggStrike',
    hidden: true,
    aim: AimMode.none,
    delivery: Launch(),
    flight: Ballistic(),
    maxDamage: 25,
    radius: 30,
    placeholderArgb: 0xFFFFF9C4,
  );

  static const seedMine = WeaponDef(
    id: 'seedMine',
    nameKey: 'weaponSeedMines',
    hidden: true,
    aim: AimMode.none,
    delivery: PlaceMine(),
    maxDamage: 25,
    radius: 30,
    placeholderArgb: 0xFFD7B56D,
  );

  /// The shared arsenal, in menu order.
  static const shared = [
    rock,
    grenade,
    cluster,
    twinSling,
    punch,
    mine,
    teleport,
    skip,
  ];

  static const signatures = [
    hairball,
    boneBoomerang,
    drillCarrot,
    eggStrike,
    seedMines,
    boomDuck,
    startleCrow,
    fortress,
    headbutt,
    coconut,
  ];

  static const all = [
    ...shared,
    ...signatures,
    clusterBomblet,
    hairballBomb,
    egg,
    seedMine,
  ];

  static final Map<String, WeaponDef> _byId = {for (final w in all) w.id: w};

  static WeaponDef byId(String id) =>
      _byId[id] ?? (throw ArgumentError('Unknown weapon: $id'));
}
