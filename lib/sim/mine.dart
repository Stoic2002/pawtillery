import 'dart:math' show max, min, sqrt;

import '../config/physics.dart';
import '../config/units.dart';
import '../config/weapons.dart';
import 'terrain_mask.dart';

/// Something small lying on (or falling to) the ground: a mine, a barrel,
/// a crate. Moved by [MinePhysics].
class GroundBody {
  GroundBody({required this.x, required this.y, this.vx = 0, this.vy = 0});

  double x;

  /// Resting row (like a unit's feet pixel) once grounded.
  double y;
  double vx;
  double vy;
  bool grounded = false;
}

/// A mine. Armed from turn [armedOnTurn]; once triggered it explodes after
/// a short countdown.
class Mine extends GroundBody {
  Mine({
    required this.id,
    required this.weapon,
    required super.x,
    required super.y,
    required this.armedOnTurn,
    super.vx,
    super.vy,
    this.ownerId,
  });

  final int id;
  final WeaponDef weapon;
  final int armedOnTurn;
  final int? ownerId;

  /// Ticks until it explodes; null = not triggered.
  int? countdown;

  double get centerY => y - 3;
}

enum MineMove { resting, falling, landed, water, outOfBounds }

abstract final class MinePhysics {
  static const double _dt = PhysicsConfig.dt;

  /// Falls (with any throw velocity) until it lands on ground.
  static MineMove step(GroundBody m, TerrainMask t, int waterLevel) {
    if (m.grounded) {
      if (t.isSolid(m.x.floor(), m.y.floor())) return MineMove.resting;
      m.grounded = false;
    }
    m.vy = min(
      m.vy + PhysicsConfig.gravity * PhysicsConfig.gravityScale * _dt,
      UnitConfig.maxFallSpeed,
    );
    final dx = m.vx * _dt;
    final dy = m.vy * _dt;
    final samples = max(1, sqrt(dx * dx + dy * dy).ceil());
    final x0 = m.x;
    final y0 = m.y;
    for (var i = 1; i <= samples; i++) {
      final sx = x0 + dx * i / samples;
      final sy = y0 + dy * i / samples;
      if (sx < 0 || sx >= t.width || sy >= t.height) return MineMove.outOfBounds;
      if (sy >= waterLevel) return MineMove.water;
      if (t.isSolid(sx.floor(), sy.floor())) {
        // Stop where it touched; it rests on that pixel from now on.
        m
          ..x = sx.floorToDouble()
          ..y = sy.floorToDouble()
          ..vx = 0
          ..vy = 0
          ..grounded = true;
        return MineMove.landed;
      }
    }
    m
      ..x = x0 + dx
      ..y = y0 + dy;
    return MineMove.falling;
  }
}
