import 'dart:math' show min;

import '../config/physics.dart';
import '../config/units.dart';
import 'terrain_mask.dart';

/// Per-unit numbers. Family passives (M3) produce modified copies of these
/// instead of branching on the family in game code.
class UnitStats {
  const UnitStats({
    this.maxHp = UnitConfig.baseHp,
    this.bodyHeight = UnitConfig.bodyHeight,
    this.hitRadius = UnitConfig.hitRadius,
    this.walkSpeed = UnitConfig.walkSpeed,
    this.maxClimb = UnitConfig.maxClimb,
  });

  final int maxHp;
  final int bodyHeight;
  final double hitRadius;
  final double walkSpeed;
  final int maxClimb;
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
    this.stats = const UnitStats(),
  })  : hp = stats.maxHp,
        peakY = y;

  final int id;
  final int team;
  final UnitStats stats;

  double x;
  double y;
  double vx = 0;
  double vy = 0;
  int hp;
  bool alive = true;
  bool grounded = true;

  /// -1 = facing left, 1 = facing right.
  int facing = 1;

  /// Highest point (smallest y) of the current airborne stretch.
  double peakY;

  /// Sub-pixel walking progress.
  double walkCarry = 0;

  double get centerX => x.floorToDouble() + 0.5;
  double get centerY => y - stats.bodyHeight / 2;
}

/// Movement against the terrain mask. Shared by units and, in M3, by
/// ground-following weapons (Bebek Peledak, Seruduk).
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

  static void jump(Unit u, double vx, double vy) {
    if (!u.grounded) return;
    launch(u, u.facing * vx, -vy);
  }

  /// Starts falling if the ground under a grounded unit is gone.
  static void checkSupport(Unit u, TerrainMask t) {
    if (u.grounded && !t.isSolid(u.x.toInt(), u.y.toInt())) launch(u, 0, 0);
  }

  /// Advances an airborne unit one tick. Returns the fall distance (peak to
  /// landing, px) when it lands this tick, otherwise null.
  static double? stepAirborne(Unit u, TerrainMask t) {
    final h = u.stats.bodyHeight;
    u.vy = min(u.vy + PhysicsConfig.gravity * _dt, UnitConfig.maxFallSpeed);

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
          ..grounded = true;
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
