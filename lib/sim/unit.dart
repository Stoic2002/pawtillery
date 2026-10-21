import 'dart:math' show min, sqrt;

import '../config/families.dart';
import '../config/physics.dart';
import '../config/units.dart';
import '../config/weapons.dart';
import 'terrain_mask.dart';

/// Per-unit numbers. Family passives produce modified copies of the base
/// values ([UnitStats.forFamily]); game code never branches on the family.
class UnitStats {
  const UnitStats({
    this.maxHp = UnitConfig.baseHp,
    this.bodyHeight = UnitConfig.bodyHeight,
    this.hitRadius = UnitConfig.hitRadius,
    this.walkSpeed = UnitConfig.walkSpeed,
    this.maxClimb = UnitConfig.maxClimb,
    this.highJumpVelocityScale = 1,
    this.fallDamage = true,
    this.fallDamageThreshold = UnitConfig.fallDamageThreshold,
    this.glide = false,
    this.airJumps = 0,
    this.explosionDamageScale = 1,
    this.firePowerScale = 1,
    this.lethalSaves = 0,
    this.waterSaves = 0,
    this.waterSaveDamage = 0,
  });

  /// Base stats with [family]'s passive applied; `null` = base unit.
  factory UnitStats.forFamily(FamilyDef? family) {
    if (family == null) return const UnitStats();
    final p = family.passive;
    // Jumping must never hurt on its own landing, so the fall threshold
    // rises by whatever extra height the passive allows: a higher high jump
    // (Kelinci) or extra jumps in mid-air (Ayam). Peak = v² / 2g.
    const basePeak = UnitConfig.jumpHighVy *
        UnitConfig.jumpHighVy /
        (2 * PhysicsConfig.gravity);
    final highPeak = basePeak * p.highJumpHeightScale;
    final extraPeak = (highPeak - basePeak) + p.airJumps * highPeak;
    return UnitStats(
      maxHp: p.maxHp ?? UnitConfig.baseHp,
      bodyHeight: (UnitConfig.bodyHeight * p.hitboxScale).round(),
      hitRadius: UnitConfig.hitRadius * p.hitboxScale,
      walkSpeed: UnitConfig.walkSpeed * p.walkSpeedScale,
      maxClimb: p.maxClimb ?? UnitConfig.maxClimb,
      // Peak height grows with v², so velocity scales with the square root.
      highJumpVelocityScale: sqrt(p.highJumpHeightScale),
      fallDamage: p.fallDamage,
      fallDamageThreshold:
          UnitConfig.fallDamageThreshold + extraPeak.ceil(),
      glide: p.glide,
      airJumps: p.airJumps,
      explosionDamageScale: p.explosionDamageTakenScale,
      firePowerScale: p.firePowerScale,
      lethalSaves: p.lethalSaves,
      waterSaves: p.waterSaves,
      waterSaveDamage: p.waterSaveDamage,
    );
  }

  final int maxHp;
  final int bodyHeight;
  final double hitRadius;
  final double walkSpeed;
  final int maxClimb;
  final double highJumpVelocityScale;
  final bool fallDamage;
  final int fallDamageThreshold;
  final bool glide;
  final int airJumps;
  final double explosionDamageScale;
  final double firePowerScale;
  final int lethalSaves;
  final int waterSaves;
  final int waterSaveDamage;
}

/// A unit. Its body is a 1 px column [UnitStats.bodyHeight] tall whose
/// feet pixel is (x, y): when grounded, that pixel is ground and every body
/// pixel above it is empty.
class Unit {
  Unit({
    required this.id,
    required this.team,
    required this.x,
    required this.y,
    this.familyId,
    this.breedId,
    UnitStats? stats,
  })  : stats = stats ??
            UnitStats.forFamily(
                familyId == null ? null : Families.byId(familyId)),
        peakY = y {
    hp = this.stats.maxHp;
    lethalSavesLeft = this.stats.lethalSaves;
    waterSavesLeft = this.stats.waterSaves;
    airJumpsLeft = this.stats.airJumps;
  }

  final int id;
  final int team;
  final String? familyId;
  final String? breedId;
  final UnitStats stats;

  double x;
  double y;
  double vx = 0;
  double vy = 0;
  late int hp;
  bool alive = true;
  bool grounded = true;

  /// -1 = facing left, 1 = facing right.
  int facing = 1;

  /// Highest point (smallest y) of the current airborne stretch.
  double peakY;

  /// Sub-pixel walking progress.
  double walkCarry = 0;

  // Once-per-match and per-jump abilities.
  late int lethalSavesLeft;
  late int waterSavesLeft;
  late int airJumpsLeft;
  bool gliding = false;
  bool signatureUsed = false;

  /// Remaining dash distance (Seruduk), px; 0 = not dashing.
  double dashRemaining = 0;
  int dashDir = 0;
  double dashSinceCarve = 0;
  WeaponDef? dashWeapon;
  bool get isDashing => dashRemaining > 0;

  /// Dig mode (Cakar Gali): ticks and distance (px) left; 0 = not digging.
  int digTicks = 0;
  double digLeft = 0;
  bool get isDigging => digTicks > 0;

  /// Grappling hook: ticks left of being reeled in to the anchor.
  int grappleTicks = 0;
  double grappleX = 0;
  double grappleY = 0;
  bool get isGrappling => grappleTicks > 0;

  double get centerX => x.floorToDouble() + 0.5;
  double get centerY => y - stats.bodyHeight / 2;
}

/// Movement against the terrain mask. Shared by units and ground-walking
/// weapons (Bebek Peledak).
abstract final class UnitPhysics {
  static const double _dt = PhysicsConfig.dt;

  static bool bodyFree(TerrainMask t, int x, int footY, int height) {
    for (var r = footY - height; r < footY; r++) {
      if (t.isSolid(x, r)) return false;
    }
    return true;
  }

  static void launch(Unit u, double vx, double vy) {
    u
      ..grounded = false
      ..gliding = false
      ..vx = vx
      ..vy = vy
      ..walkCarry = 0
      ..peakY = u.y;
  }

  /// Walks one tick in [dir] (-1 / 1). Grounded units only.
  static void walk(Unit u, int dir, TerrainMask t) {
    if (!u.grounded) return;
    u
      ..facing = dir
      ..walkCarry += u.stats.walkSpeed * _dt;
    while (u.walkCarry >= 1) {
      u.walkCarry -= 1;
      if (!_stepPixel(u, dir, t)) {
        u.walkCarry = 0;
        return;
      }
      if (!u.grounded) return;
    }
  }

  /// Moves one pixel sideways: climbs up to [UnitStats.maxClimb], follows
  /// slopes down by as much, and walks off anything steeper. Returns false
  /// when blocked by a wall.
  static bool _stepPixel(Unit u, int dir, TerrainMask t) {
    final nx = u.x.toInt() + dir;
    final y = u.y.toInt();
    final h = u.stats.bodyHeight;
    final climb = u.stats.maxClimb;

    for (var dy = 0; dy <= climb; dy++) {
      final ny = y - dy;
      if (!bodyFree(t, nx, ny, h)) continue;
      if (t.isSolid(nx, ny)) {
        u
          ..x = nx.toDouble()
          ..y = ny.toDouble();
        return true;
      }
      if (dy > 0) continue; // Headroom over thin air is not a step.
      for (var d = 1; d <= climb; d++) {
        if (t.isSolid(nx, y + d)) {
          u
            ..x = nx.toDouble()
            ..y = (y + d).toDouble();
          return true;
        }
      }
      u.x = nx.toDouble();
      launch(u, dir * u.stats.walkSpeed, 0);
      return true;
    }
    return false;
  }

  /// Jump from the ground: [vx] along facing, [vy] upwards.
  static void jump(Unit u, double vx, double vy) {
    if (!u.grounded) return;
    launch(u, u.facing * vx, -vy);
    u.gliding = u.stats.glide;
  }

  /// Extra jump in mid-air (Ayam). Returns whether one was available.
  static bool airJump(Unit u, double vx, double vy) {
    if (u.grounded || u.airJumpsLeft <= 0) return false;
    u
      ..airJumpsLeft -= 1
      ..vx = u.facing * vx
      ..vy = -vy
      ..gliding = u.stats.glide;
    return true;
  }

  /// Starts falling if the ground under a grounded unit is gone.
  static void checkSupport(Unit u, TerrainMask t) {
    if (u.grounded && !t.isSolid(u.x.toInt(), u.y.toInt())) launch(u, 0, 0);
  }

  /// Advances an airborne unit one tick. Returns the fall distance (peak to
  /// landing, px) when it lands this tick, otherwise null.
  static double? stepAirborne(Unit u, TerrainMask t) {
    final h = u.stats.bodyHeight;
    final maxFall =
        u.gliding ? UnitConfig.glideFallSpeed : UnitConfig.maxFallSpeed;
    u.vy = min(u.vy + PhysicsConfig.gravity * _dt, maxFall);

    var dx = u.vx * _dt;
    while (dx != 0) {
      final s = dx.clamp(-1.0, 1.0);
      final nx = u.x + s;
      if (!bodyFree(t, nx.floor(), u.y.floor(), h)) {
        u.vx = 0;
        break;
      }
      u.x = nx;
      dx -= s;
    }

    var dy = u.vy * _dt;
    while (dy != 0) {
      final s = dy.clamp(-1.0, 1.0);
      final ny = u.y + s;
      if (s > 0 && t.isSolid(u.x.floor(), ny.floor())) {
        u
          ..y = ny.floorToDouble()
          ..x = u.x.floorToDouble()
          ..vx = 0
          ..vy = 0
          ..grounded = true
          ..gliding = false
          ..airJumpsLeft = u.stats.airJumps;
        return u.y - u.peakY;
      }
      if (s < 0 && t.isSolid(u.x.floor(), ny.floor() - h)) {
        u.vy = 0;
        break;
      }
      u.y = ny;
      dy -= s;
    }
    if (u.y < u.peakY) u.peakY = u.y;
    return null;
  }
}
