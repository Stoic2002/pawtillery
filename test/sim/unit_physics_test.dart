import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/config/units.dart';
import 'package:pawtillery/sim/terrain_mask.dart';
import 'package:pawtillery/sim/unit.dart';

void main() {
  /// Flat ground with its surface (feet row) at y = 300.
  TerrainMask flat() => TerrainMask(600, 400)..fillRect(0, 300, 600, 100);

  Unit unitAt(double x, double y) => Unit(id: 0, team: 0, x: x, y: y);

  /// Runs [ticks] ticks of walking, like SimWorld does.
  void walk(Unit u, TerrainMask t, int dir, int ticks) {
    for (var i = 0; i < ticks; i++) {
      UnitPhysics.walk(u, dir, t);
      UnitPhysics.checkSupport(u, t);
      if (!u.grounded) UnitPhysics.stepAirborne(u, t);
    }
  }

  /// Steps physics until the unit lands; returns the fall distance.
  double fallUntilLanded(Unit u, TerrainMask t) {
    for (var i = 0; i < 2000; i++) {
      final fell = UnitPhysics.stepAirborne(u, t);
      if (fell != null) return fell;
    }
    fail('never landed');
  }

  test('walks walkSpeed px per second on flat ground', () {
    final t = flat();
    final u = unitAt(100, 300);
    walk(u, t, 1, 60);
    expect(u.x, 100 + UnitConfig.walkSpeed);
    expect(u.y, 300);
    expect(u.grounded, isTrue);
    expect(u.facing, 1);
    walk(u, t, -1, 30);
    expect(u.x, closeTo(100 + UnitConfig.walkSpeed / 2, 1));
    expect(u.facing, -1);
  });

  test('climbs a 6 px step but not a 7 px one', () {
    final low = flat()..fillRect(200, 294, 400, 6); // 6 px step at x=200
    final u = unitAt(190, 300);
    walk(u, low, 1, 30);
    expect(u.x, greaterThan(200));
    expect(u.y, 294);

    final high = flat()..fillRect(200, 293, 400, 7); // 7 px step
    final v = unitAt(190, 300);
    walk(v, high, 1, 60);
    expect(v.x, 199, reason: 'stops at the wall');
    expect(v.y, 300);
  });

  test('follows a gentle downhill slope without leaving the ground', () {
    // Surface drops 2 px every 4 px to the right of x = 200.
    final t = TerrainMask(600, 600);
    for (var x = 0; x < 600; x++) {
      final top = x < 200 ? 300 : 300 + (x - 200) ~/ 2;
      t.fillRect(x, top, 1, 600 - top);
    }
    final u = unitAt(190, 300);
    var everAirborne = false;
    for (var i = 0; i < 120; i++) {
      UnitPhysics.walk(u, 1, t);
      UnitPhysics.checkSupport(u, t);
      if (!u.grounded) everAirborne = true;
    }
    expect(everAirborne, isFalse);
    expect(u.y, greaterThan(300));
  });

  test('walking off a cliff falls, lands and reports the fall height', () {
    final t = TerrainMask(600, 800)
      ..fillRect(0, 300, 200, 500) // ledge
      ..fillRect(200, 600, 400, 200); // 300 px lower
    final u = unitAt(195, 300);
    walk(u, t, 1, 10);
    expect(u.grounded, isFalse);
    final fell = fallUntilLanded(u, t);
    expect(u.y, 600);
    expect(fell, closeTo(300, 1));
  });

  test('falls when the ground beneath is carved away', () {
    final t = flat();
    final u = unitAt(300, 300);
    t.carveCircle(300, 300, 30);
    UnitPhysics.checkSupport(u, t);
    expect(u.grounded, isFalse);
    fallUntilLanded(u, t);
    expect(u.y, 331);
  });

  test('forward jump moves along facing and lands on the ground', () {
    final t = flat();
    final u = unitAt(300, 300)..facing = -1;
    UnitPhysics.jump(u, UnitConfig.jumpForwardVx, UnitConfig.jumpForwardVy);
    final fell = fallUntilLanded(u, t);
    expect(u.y, 300);
    expect(u.x, lessThan(300));
    expect(fell, greaterThan(0));
    expect(fell, lessThan(UnitConfig.fallDamageThreshold));
  });

  test('high jump goes higher and less far than forward jump', () {
    double peak(double vx, double vy, Unit u, TerrainMask t) {
      UnitPhysics.jump(u, vx, vy);
      fallUntilLanded(u, t);
      return u.peakY;
    }

    final t = flat();
    final a = unitAt(300, 300);
    final b = unitAt(300, 300);
    final peakForward =
        peak(UnitConfig.jumpForwardVx, UnitConfig.jumpForwardVy, a, t);
    final peakHigh = peak(UnitConfig.jumpHighVx, UnitConfig.jumpHighVy, b, t);
    expect(peakHigh, lessThan(peakForward));
    expect((b.x - 300).abs(), lessThan((a.x - 300).abs()));
  });

  test('a jump into a ceiling stops rising', () {
    final t = flat()..fillRect(0, 250, 600, 10); // ceiling 50 px above feet
    final u = unitAt(100, 300);
    UnitPhysics.jump(u, 0, UnitConfig.jumpHighVy);
    fallUntilLanded(u, t);
    expect(u.peakY, greaterThanOrEqualTo(260 + UnitConfig.bodyHeight));
  });

  test('airborne units stop against walls', () {
    final t = flat()..fillRect(150, 0, 10, 300);
    final u = unitAt(100, 300)..facing = 1;
    UnitPhysics.jump(u, 400, 200);
    fallUntilLanded(u, t);
    expect(u.x, lessThan(150));
  });

  test('neither jump causes fall damage on flat ground', () {
    for (final (vx, vy) in [
      (UnitConfig.jumpForwardVx, UnitConfig.jumpForwardVy),
      (UnitConfig.jumpHighVx, UnitConfig.jumpHighVy),
    ]) {
      final u = unitAt(300, 300);
      UnitPhysics.jump(u, vx, vy);
      final fell = fallUntilLanded(u, flat());
      expect(fell, lessThanOrEqualTo(UnitConfig.fallDamageThreshold));
    }
  });
}
