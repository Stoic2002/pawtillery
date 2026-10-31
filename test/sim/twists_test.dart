import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/config/physics.dart';
import 'package:pawtillery/config/weapons.dart';
import 'package:pawtillery/sim/inputs.dart';
import 'package:pawtillery/sim/match_setup.dart';
import 'package:pawtillery/sim/world.dart';

import 'sim_test_utils.dart';

SimWorld _match(MatchTwist twist, {int x1 = 700}) => SimWorld.withUnits(
  seed: 3,
  terrain: flatMap(w: 6000),
  waterLevel: 560,
  teamCount: 2,
  placements: [UnitPlacement(0, 200, 400), UnitPlacement(1, x1, 400)],
  timings: testTimings,
  twist: twist,
);

/// Where a rock thrown at 45° comes down, with the wind ignored as far as it
/// can be: the distance from the thrower.
double _throw(SimWorld w) {
  toAction(w);
  final e = fireAndSettle(
    w,
    const Fire(weaponId: 'rock', angleDeg: 45, powerPercent: 40),
  );
  return explosions(e).single.x.toDouble() - 200;
}

void main() {
  tearDown(() => PhysicsConfig.gravityScale = 1);

  test('One Hit: a glancing blast knocks a pet out', () {
    final w = _match(MatchTwist.oneHit);
    toAction(w);
    // At the edge of a stone's blast: normally a scratch.
    final stone = Weapons.rock;
    w.explode(700.0 + stone.radius - 4, 395, stone);
    expect(w.units[1].hp, 0);

    final w2 = _match(MatchTwist.none);
    toAction(w2);
    w2.explode(700.0 + stone.radius - 4, 395, stone);
    expect(w2.units[1].hp, greaterThan(50), reason: 'a scratch otherwise');
  });

  test('Storm: the wind goes past the usual limit and shifts in a turn', () {
    final w = _match(MatchTwist.storm);
    var strongest = 0;
    var shifted = false;
    for (var t = 0; t < 12; t++) {
      toAction(w);
      final start = w.wind;
      for (var i = 0; i < PhysicsConfig.stormShiftTicks + 1; i++) {
        w.step(const []);
      }
      if (w.wind != start) shifted = true;
      if (w.wind.abs() > strongest) strongest = w.wind.abs();
      toNextTurn(w);
    }
    expect(shifted, isTrue);
    expect(strongest, greaterThan(PhysicsConfig.windMax));
    expect(strongest, lessThanOrEqualTo(PhysicsConfig.stormWind));
  });

  test('Moon: shots go much further, and the next match is normal again', () {
    final normal = _throw(_match(MatchTwist.none));
    final moon = _throw(_match(MatchTwist.moon));
    expect(moon, greaterThan(normal * 1.5));
    _match(MatchTwist.none);
    expect(PhysicsConfig.gravityScale, 1);
  });

  test('a twist changes the state hash, no twist leaves it alone', () {
    expect(
      _match(MatchTwist.none).stateHash(),
      isNot(_match(MatchTwist.moon).stateHash()),
    );
  });
}
