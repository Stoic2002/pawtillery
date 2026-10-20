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

/// Fires [shots] projectiles from the unit, [shotIntervalTicks] apart. With
/// [spreadDeg], all shots leave at once in a fan that wide around the aim.
final class Launch extends Delivery {
  const Launch({this.shots = 1, this.shotIntervalTicks = 0, this.spreadDeg = 0});
  final int shots;
  final int shotIntervalTicks;
  final int spreadDeg;
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

/// What flies in for an [AirRaid] (drawing only).
enum CraftKind { bomber, jet, flock }

/// An aircraft (or a flock of birds) flies in from the shooter's side at
/// [altitude] (world y) and [speed] px/s and drops [count] [childId]
/// projectiles, which keep its speed and so fall at a slant. They are
/// released early by their fall drift so they land [spacing] px apart
/// around the chosen spot; a guided payload is instead released
/// [releaseAhead] px before the spot and steers there itself. The craft
/// appears [leadIn] px before its first drop and leaves the same distance
/// after its last.
final class AirRaid extends Delivery {
  const AirRaid({
    required this.childId,
    required this.count,
    required this.speed,
    required this.altitude,
    required this.leadIn,
    this.spacing = 0,
    this.releaseAhead,
    this.craft = CraftKind.bomber,
  });
  final String childId;
  final int count;
  final int spacing;
  final double speed;
  final int altitude;
  final int leadIn;
  final int? releaseAhead;
  final CraftKind craft;
}

/// The chosen column is marked, and after [delayTicks] a beam from orbit
/// burns straight down it to the water: a [carveRadius] shaft through the
/// ground, and every unit within reach of it hit once (the shooter too).
final class OrbitalStrike extends Delivery {
  const OrbitalStrike({required this.delayTicks, required this.carveRadius});
  final int delayTicks;
  final int carveRadius;
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

/// A straight beam [length] px from the unit along the aim. It burns a
/// [carveRadius] tunnel through the ground and hits every unit on its way
/// once (never the user).
final class Beam extends Delivery {
  const Beam({required this.length, required this.carveRadius});
  final int length;
  final int carveRadius;
}

/// A bolt from the sky straight down the chosen column; it blasts the
/// first ground or unit it meets. With [delayTicks], a storm cloud drifts
/// in on the wind first.
final class Lightning extends Delivery {
  const Lightning({this.delayTicks = 0});
  final int delayTicks;
}

/// Sets this weapon down in front of the unit with its fuse lit; it then
/// moves with its [FlightSpec].
final class DropCharge extends Delivery {
  const DropCharge();
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

/// Flies like a normal shot for [delayTicks], then its motor starts:
/// constant [speed], no gravity or wind, turning towards its quarry by
/// [steer] (0–1) of the way each tick. Explodes on what it touches.
///
/// The quarry is the nearest enemy unit, or with [chosenTarget] the point
/// the player tapped. With [fuelTicks] the motor burns out after that long
/// and the projectile falls like a normal shot.
final class Homing extends FlightSpec {
  const Homing({
    required this.delayTicks,
    required this.speed,
    required this.steer,
    this.chosenTarget = false,
    this.fuelTicks,
  });
  final int delayTicks;

  /// px/s.
  final double speed;
  final double steer;
  final bool chosenTarget;
  final int? fuelTicks;
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
    this.launchSpeedScale = 1,
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

  /// Launch speed relative to a normal throw at the same power (rockets
  /// leave faster).
  final double launchSpeedScale;
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

  // ---- added arsenal (2026-10-19, docs/decisions.md) -----------------

  /// A fast, flat rocket: low gravity, still pushed by the wind.
  static const bottleRocket = WeaponDef(
    id: 'bottleRocket',
    nameKey: 'weaponBottleRocket',
    aim: AimMode.angleAndPower,
    delivery: Launch(),
    flight: Ballistic(),
    affectedByWind: true,
    maxDamage: 45,
    radius: 42,
    gravityScale: 0.35,
    launchSpeedScale: 1.2,
    ammo: 3,
    placeholderArgb: 0xFF3B82F6,
  );

  /// Thrown like a rock; after a moment its motor starts and it chases
  /// the nearest enemy.
  static const snifferRocket = WeaponDef(
    id: 'snifferRocket',
    nameKey: 'weaponSnifferRocket',
    aim: AimMode.angleAndPower,
    delivery: Launch(),
    flight: Homing(delayTicks: 45, speed: 330, steer: 0.08),
    affectedByWind: true,
    maxDamage: 40,
    radius: 40,
    ammo: 1,
    placeholderArgb: 0xFF8B5CF6,
  );

  /// A beam that burns straight through the ground.
  static const laserPointer = WeaponDef(
    id: 'laserPointer',
    nameKey: 'weaponLaserPointer',
    aim: AimMode.direction,
    delivery: Beam(length: 520, carveRadius: 5),
    maxDamage: 28,
    knockbackScale: 0.6,
    ammo: 2,
    placeholderArgb: 0xFFE5484D,
  );

  /// A lightning bolt down a chosen column.
  static const thunderCloud = WeaponDef(
    id: 'thunderCloud',
    nameKey: 'weaponThunderCloud',
    aim: AimMode.target,
    delivery: Lightning(delayTicks: 60),
    maxDamage: 45,
    radius: 34,
    ammo: 1,
    placeholderArgb: 0xFFF5B700,
  );

  /// Five seeds at once in a narrow fan; weak alone, strong up close.
  static const seedSpitter = WeaponDef(
    id: 'seedSpitter',
    nameKey: 'weaponSeedSpitter',
    aim: AimMode.angleAndPower,
    delivery: Launch(shots: 5, spreadDeg: 18),
    flight: Ballistic(),
    maxDamage: 12,
    radius: 14,
    gravityScale: 0.25,
    launchSpeedScale: 1.1,
    ammo: 2,
    placeholderArgb: 0xFF7A9A3A,
  );

  /// Set down and run: a big blast after four seconds.
  static const firecracker = WeaponDef(
    id: 'firecracker',
    nameKey: 'weaponFirecracker',
    aim: AimMode.none,
    delivery: DropCharge(),
    flight: Bouncy(restitution: 0.25),
    maxDamage: 70,
    radius: 65,
    fuseTicks: 4 * 60,
    ammo: 1,
    placeholderArgb: 0xFFE2681C,
  );

  /// Five flowerpots fall across the chosen spot.
  static const flowerpotRain = WeaponDef(
    id: 'flowerpotRain',
    nameKey: 'weaponFlowerpotRain',
    aim: AimMode.target,
    delivery: AirStrike(childId: 'flowerpot', count: 5, spacing: 34),
    ammo: 1,
    placeholderArgb: 0xFFC0623A,
  );

  // ---- military air support (2026-10-20, docs/decisions.md) ----------

  /// A bomber crosses the sky and carpets the chosen spot with five bombs.
  static const bomber = WeaponDef(
    id: 'bomber',
    nameKey: 'weaponBomber',
    aim: AimMode.target,
    delivery: AirRaid(
      childId: 'bomberBomb',
      count: 5,
      spacing: 36,
      speed: 300,
      altitude: 40,
      leadIn: 520,
    ),
    ammo: 1,
    placeholderArgb: 0xFF5B6B4A,
  );

  /// A satellite marks a column, then burns it from orbit.
  static const satellite = WeaponDef(
    id: 'satellite',
    nameKey: 'weaponSatellite',
    aim: AimMode.target,
    delivery: OrbitalStrike(delayTicks: 75, carveRadius: 14),
    maxDamage: 55,
    radius: 22,
    knockbackScale: 0.7,
    ammo: 1,
    placeholderArgb: 0xFF7FD3FF,
  );

  /// Tap a target: a fighter jet streaks in and fires a missile that
  /// steers to that spot until its fuel runs out.
  static const homingMissile = WeaponDef(
    id: 'homingMissile',
    nameKey: 'weaponHomingMissile',
    aim: AimMode.target,
    delivery: AirRaid(
      childId: 'missile',
      count: 1,
      speed: 460,
      altitude: 70,
      leadIn: 560,
      releaseAhead: 420,
      craft: CraftKind.jet,
    ),
    ammo: 1,
    placeholderArgb: 0xFF9AA3A8,
  );

  /// Dig a short tunnel sideways (a tool, no damage).
  static const digClaws = WeaponDef(
    id: 'digClaws',
    nameKey: 'weaponDigClaws',
    aim: AimMode.direction,
    delivery: Dash(distance: 80, speed: 140, carveRadius: 13),
    knockbackScale: 0,
    placeholderArgb: 0xFF8D6E63,
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
    delivery: AirRaid(
      childId: 'egg',
      count: 5,
      spacing: 40,
      speed: 240,
      altitude: 80,
      leadIn: 420,
      craft: CraftKind.flock,
    ),
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

  static const flowerpot = WeaponDef(
    id: 'flowerpot',
    nameKey: 'weaponFlowerpotRain',
    hidden: true,
    aim: AimMode.none,
    delivery: Launch(),
    flight: Ballistic(),
    maxDamage: 22,
    radius: 28,
    placeholderArgb: 0xFFC0623A,
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

  /// The jet's missile (Rudal Pemburu): after a short drop its motor locks
  /// on to the tapped spot.
  static const missile = WeaponDef(
    id: 'missile',
    nameKey: 'weaponHomingMissile',
    aim: AimMode.none,
    delivery: Launch(),
    flight: Homing(
      delayTicks: 15,
      speed: 380,
      steer: 0.12,
      chosenTarget: true,
      fuelTicks: 4 * 60,
    ),
    maxDamage: 50,
    radius: 46,
    hidden: true,
    placeholderArgb: 0xFF9AA3A8,
  );

  /// One bomb of the bomber's carpet: heavy, not pushed by the wind.
  static const bomberBomb = WeaponDef(
    id: 'bomberBomb',
    nameKey: 'weaponBomber',
    aim: AimMode.none,
    delivery: Launch(),
    flight: Ballistic(),
    maxDamage: 30,
    radius: 32,
    hidden: true,
    placeholderArgb: 0xFF4E5A3C,
  );

  /// The shared arsenal, in menu order.
  static const shared = [
    rock,
    bottleRocket,
    snifferRocket,
    homingMissile,
    grenade,
    cluster,
    firecracker,
    twinSling,
    seedSpitter,
    laserPointer,
    thunderCloud,
    flowerpotRain,
    bomber,
    satellite,
    punch,
    mine,
    digClaws,
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
    flowerpot,
    seedMine,
    bomberBomb,
    missile,
  ];

  static final Map<String, WeaponDef> _byId = {for (final w in all) w.id: w};

  static WeaponDef byId(String id) =>
      _byId[id] ?? (throw ArgumentError('Unknown weapon: $id'));
}

/// Which shared weapons a match starts with and how many of each, per team
/// (setup's Weapons tab). [ammo] overrides a weapon's default: null =
/// unlimited, 0 = off; weapons not listed keep [WeaponDef.ammo]. Skip
/// Turn is always on. [signatures] turns every family weapon on or off.
class WeaponLoadout {
  const WeaponLoadout({this.ammo = const {}, this.signatures = true});

  final Map<String, int?> ammo;
  final bool signatures;

  /// Highest ammo the setup offers before "unlimited".
  static const maxAmmo = 9;

  static const standard = WeaponLoadout();

  /// Only the original eight shared weapons, default ammo.
  static final classic = WeaponLoadout(ammo: {
    for (final w in Weapons.shared)
      if (!_classicIds.contains(w.id)) w.id: 0,
  });

  /// Everything unlimited.
  static final chaos = WeaponLoadout(ammo: {
    for (final w in Weapons.shared) w.id: null,
  });

  static const _classicIds = {
    'rock', 'grenade', 'cluster', 'twinSling', 'punch', 'mine', //
    'teleport', 'skip',
  };

  /// Weapons whose ammo the player can change (all shared but Skip).
  static List<WeaponDef> get editable =>
      [for (final w in Weapons.shared) if (w.id != Weapons.skip.id) w];

  /// Starting ammo of [weapon] per team; null = unlimited.
  int? ammoOf(WeaponDef weapon) {
    if (weapon.id == Weapons.skip.id) return null;
    return ammo.containsKey(weapon.id) ? ammo[weapon.id] : weapon.ammo;
  }

  /// Whether [weapon] can appear in this match at all.
  bool enabled(WeaponDef weapon) {
    if (weapon.hidden) return false;
    if (weapon.isSignature) return signatures;
    return ammoOf(weapon) != 0;
  }

  WeaponLoadout withAmmo(WeaponDef weapon, int? value) => WeaponLoadout(
        ammo: {...ammo, weapon.id: value},
        signatures: signatures,
      );

  WeaponLoadout withSignatures(bool on) =>
      WeaponLoadout(ammo: ammo, signatures: on);

  /// Same effective ammo for every weapon and the same signature switch.
  bool sameAs(WeaponLoadout other) =>
      signatures == other.signatures &&
      editable.every((w) => ammoOf(w) == other.ammoOf(w));

  /// Only overrides that differ from the defaults, so a saved standard
  /// loadout picks up future default changes.
  Map<String, Object?> toJson() => {
        'ammo': {
          for (final w in editable)
            if (ammoOf(w) != w.ammo) w.id: ammoOf(w) ?? -1,
        },
        'signatures': signatures,
      };

  /// Unknown weapons and bad values are skipped; null if [json] is not a
  /// loadout at all.
  static WeaponLoadout? fromJson(Object? json) {
    if (json is! Map) return null;
    final raw = json['ammo'];
    final signatures = json['signatures'];
    if (raw is! Map || signatures is! bool) return null;
    final ids = {for (final w in editable) w.id};
    return WeaponLoadout(
      ammo: {
        for (final MapEntry(:key, :value) in raw.entries)
          if (ids.contains(key) && value is int && value >= -1 && value <= maxAmmo)
            key as String: value == -1 ? null : value,
      },
      signatures: signatures,
    );
  }
}
