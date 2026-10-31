import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/config/map_objects.dart';
import 'package:pawtillery/config/weapons.dart';
import 'package:pawtillery/sim/inputs.dart';
import 'package:pawtillery/sim/match_setup.dart';
import 'package:pawtillery/sim/turn_manager.dart';
import 'package:pawtillery/sim/world.dart';

import 'sim_test_utils.dart';

void main() {
  test('crates come down over ground every few turns, under a parachute', () {
    final w = SimWorld.withUnits(
      seed: 5,
      terrain: flatMap(),
      waterLevel: 560,
      teamCount: 2,
      placements: const [UnitPlacement(0, 200, 400), UnitPlacement(1, 900, 400)],
      timings: testTimings,
      crateDrops: true,
    );
    while (w.objects.isEmpty) {
      toNextTurn(w);
    }
    expect(w.turn.turnNumber, ObjectConfig.dropEveryTurns);
    final crate = w.objects.single;
    expect(crate.parachute, isTrue);
    expect(crate.y, lessThan(400));
    var ticks = 0;
    while (crate.parachute && ticks < 2000 && w.objects.contains(crate)) {
      w.step(const []);
      ticks++;
    }
    expect(crate.parachute, isFalse, reason: 'landed');
    expect(crate.y, closeTo(400, 2));
    expect(ticks, greaterThan(60), reason: 'slowly');
  });

  test('without the rule no crate falls', () {
    final w = world(const [UnitPlacement(0, 200, 400), UnitPlacement(1, 900, 400)]);
    for (var i = 0; i <= ObjectConfig.dropEveryTurns; i++) {
      toNextTurn(w);
    }
    expect(w.objects, isEmpty);
  });

  test('the jetpack lifts a pet off the ground, and it lands unhurt', () {
    final w = world(const [UnitPlacement(0, 200, 400), UnitPlacement(1, 1500, 400)]);
    toAction(w);
    final u = w.units[0];
    w.step(const [Fire(weaponId: 'jetpack')]);
    expect(u.isJetting, isTrue);
    expect(w.ammoLeft(0, Weapons.jetpack), Weapons.jetpack.ammo! - 1);
    var top = u.y;
    for (var i = 0; i < 90; i++) {
      w.step(const [Dig(60)]);
      if (u.y < top) top = u.y;
    }
    expect(top, lessThan(300));
    expect(u.x, greaterThan(200));
    // Let go near the ground: out of fuel it falls like anything else.
    w.step(const [StopDigging()]);
    expect(u.isJetting, isFalse);
    expect(w.turn.phase, TurnPhase.retreat);
  });
}
