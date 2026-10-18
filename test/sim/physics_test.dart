import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/config/physics.dart';
import 'package:pawtillery/config/weapons.dart';
import 'package:pawtillery/sim/physics.dart';
import 'package:pawtillery/sim/projectile.dart';
import 'package:pawtillery/sim/terrain_mask.dart';

const _dt = PhysicsConfig.dt;
const _g = PhysicsConfig.gravity;
const _windless = WeaponDef(
  id: 'test_windless',
  nameKey: 'weaponRock',
  projectile: ProjectileKind.ballistic,
  affectedByWind: false,
  maxDamage: 1,
  radius: 1,
  placeholderArgb: 0,
);

void main() {
  final open = TerrainMask(4000, 4000);

  test('launch velocity follows angle and power', () {
    final right = _launch(0, 100);
    expect(right.vx, PhysicsConfig.maxLaunchSpeed);
    expect(right.vy, 0);
    final up = _launch(90, 50);
    expect(up.vx, closeTo(0, 1e-9));
    expect(up.vy, -PhysicsConfig.maxLaunchSpeed / 2);
    expect(_launch(45, 150).vx, _launch(45, 100).vx, reason: 'power clamps');
  });

  test('trajectory matches the semi-implicit Euler closed form', () {
    final p = _launch(60, 80, x: 2000, y: 2000);
    final vx0 = p.vx, vy0 = p.vy;
    const n = 90;
    for (var i = 0; i < n; i++) {
      expect(ProjectilePhysics.step(p, open, wind: 0), FlightOutcome.flying);
    }
    expect(p.vy, closeTo(vy0 + n * _g * _dt, 1e-9));
    expect(p.y,
        closeTo(2000 + n * _dt * vy0 + _g * _dt * _dt * n * (n + 1) / 2, 1e-6));
    expect(p.x, closeTo(2000 + n * _dt * vx0, 1e-6));
  });

  test('wind pushes only wind-affected projectiles', () {
    final rock = _launch(90, 50, x: 2000, y: 2000);
    final stone = _launch(90, 50, x: 2000, y: 2000, weapon: _windless);
    for (var i = 0; i < 60; i++) {
      ProjectilePhysics.step(rock, open, wind: 10);
      ProjectilePhysics.step(stone, open, wind: 10);
    }
    // 1 s of wind 10: vx = 10 * accel * 1 s.
    expect(rock.vx, closeTo(10 * PhysicsConfig.windAccelPerUnit, 1e-9));
    expect(stone.vx, closeTo(0, 1e-9));
  });

  test('fast shot cannot tunnel through a 1 px wall', () {
    final mask = TerrainMask(1000, 200)..fillRect(500, 0, 1, 200);
    // ~3000 px/s = 50 px per tick, far more than the wall is thick.
    final p = Projectile(
        id: 0, weapon: _windless, x: 10, y: 100, vx: 3000, vy: 0);
    FlightOutcome outcome;
    do {
      outcome = ProjectilePhysics.step(p, mask, wind: 0);
    } while (outcome == FlightOutcome.flying);
    expect(outcome, FlightOutcome.hitTerrain);
    expect(p.x, inInclusiveRange(500, 501));
  });

  test('falls onto flat ground and stops at its surface', () {
    final mask = TerrainMask(400, 400)..fillRect(0, 300, 400, 100);
    final p = _launch(0, 0, x: 200, y: 100, weapon: _windless);
    FlightOutcome outcome;
    do {
      outcome = ProjectilePhysics.step(p, mask, wind: 0);
    } while (outcome == FlightOutcome.flying);
    expect(outcome, FlightOutcome.hitTerrain);
    expect(p.y, inInclusiveRange(300, 301));
    expect(p.x, 200);
  });

  test('launching from inside ground hits immediately', () {
    final mask = TerrainMask(100, 100)..fillRect(0, 0, 100, 100);
    final p = _launch(45, 100, x: 50, y: 50);
    expect(ProjectilePhysics.step(p, mask, wind: 0), FlightOutcome.hitTerrain);
    expect(p.x, 50);
  });

  test('leaving left, right or bottom is out of bounds; the top is not', () {
    final mask = TerrainMask(200, 200);
    expect(_fly(_launch(180, 100, x: 100, y: 100), mask),
        FlightOutcome.outOfBounds);
    expect(_fly(_launch(0, 100, x: 100, y: 100), mask),
        FlightOutcome.outOfBounds);
    // Straight up: rises far above y = 0, comes back, exits the bottom.
    final up = _launch(90, 100, x: 100, y: 100);
    var minY = up.y;
    FlightOutcome o;
    do {
      o = ProjectilePhysics.step(up, mask, wind: 0);
      if (up.y < minY) minY = up.y;
    } while (o == FlightOutcome.flying);
    expect(minY, lessThan(0));
    expect(o, FlightOutcome.outOfBounds);
    expect(up.y, greaterThanOrEqualTo(200));
  });

  test('predict matches a real no-wind flight and ends at the impact', () {
    final mask = TerrainMask(2000, 1000)..fillRect(0, 800, 2000, 200);
    final path = ProjectilePhysics.predict(
      weapon: Weapons.rock,
      x: 100,
      y: 700,
      angleDeg: 45,
      powerPercent: 70,
      terrain: mask,
    );
    final p = _launch(45, 70, x: 100, y: 700);
    FlightOutcome o;
    do {
      o = ProjectilePhysics.step(p, mask, wind: 0);
    } while (o == FlightOutcome.flying);
    expect(path[path.length - 2], p.x);
    expect(path.last, p.y);
    expect(path.last, inInclusiveRange(800, 801));
  });
}

Projectile _launch(int angle, int power,
        {double x = 0, double y = 0, WeaponDef weapon = Weapons.rock}) =>
    ProjectilePhysics.launch(
        id: 0, weapon: weapon, x: x, y: y, angleDeg: angle, powerPercent: power);

FlightOutcome _fly(Projectile p, TerrainMask mask) {
  FlightOutcome o;
  do {
    o = ProjectilePhysics.step(p, mask, wind: 0);
  } while (o == FlightOutcome.flying);
  return o;
}
