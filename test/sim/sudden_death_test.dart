import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/config/match_defaults.dart';
import 'package:pawtillery/sim/events.dart';
import 'package:pawtillery/sim/inputs.dart';
import 'package:pawtillery/sim/match_setup.dart';
import 'package:pawtillery/sim/turn_manager.dart';
import 'package:pawtillery/sim/world.dart';

import 'sim_test_utils.dart';

SimWorld _match({int? suddenDeathAfterTicks, int ground = 400}) =>
    SimWorld.withUnits(
      seed: 5,
      terrain: flatMap(ground: ground),
      waterLevel: 560,
      teamCount: 2,
      placements: const [
        UnitPlacement(0, 300, 400),
        UnitPlacement(0, 600, 400),
        UnitPlacement(1, 1300, 400),
      ],
      timings: testTimings,
      suddenDeathAfterTicks: suddenDeathAfterTicks,
    );

void main() {
  test('off by default: the ground and HP never change', () {
    final w = _match();
    final ground = solidCount(w.terrain);
    for (var i = 0; i < 6; i++) {
      toNextTurn(w);
    }
    expect(w.suddenDeath, isFalse);
    expect(solidCount(w.terrain), ground);
    expect(w.units.every((u) => u.hp == 100), isTrue);
  });

  test('starts with the first turn after the limit; HP and water stay', () {
    final w = _match(suddenDeathAfterTicks: 1000);
    final events = <SimEvent>[];
    while (!w.suddenDeath) {
      events.addAll(toNextTurn(w));
    }
    expect(w.tick, greaterThanOrEqualTo(1000));
    expect(events.whereType<SuddenDeathStarted>(), hasLength(1));
    expect(w.units.every((u) => u.hp == 100), isTrue);
    expect(w.waterLevel, 560);
    expect(w.turn.phase, TurnPhase.turnStart);
  });

  test('the ground gives way after every round, in more places each time',
      () {
    final w = _match(suddenDeathAfterTicks: 0);
    expect(w.suddenDeath, isTrue, reason: 'limit 0 = from the first turn');
    final holes = <int>[];
    var ground = solidCount(w.terrain);
    for (var turn = 0; turn < 6; turn++) {
      final e = toNextTurn(w);
      final crumbled = e.whereType<GroundCrumbled>().toList();
      if (crumbled.isNotEmpty) {
        holes.add(crumbled.single.holes);
        expect(solidCount(w.terrain), lessThan(ground));
        ground = solidCount(w.terrain);
      }
    }
    // Two teams → a collapse every second turn: one hole near each of the
    // three pets (while they stand) plus more random ones each round.
    const first = MatchDefaults.crumbleHolesFirst;
    expect(holes, hasLength(3));
    for (var round = 0; round < 3; round++) {
      final random = first + round;
      // Pets that fell out don't get a hole of their own any more.
      expect(holes[round], inInclusiveRange(random + 1, random + 3));
    }
    expect(holes.first, 3 + first);
  });

  test('crumbling ground decides the match', () {
    final w = _match(suddenDeathAfterTicks: 0);
    final events = runUntil(
      w,
      () => w.turn.phase == TurnPhase.matchOver,
      limit: 400000,
    );
    expect(events.whereType<UnitDied>(), isNotEmpty);
    expect(events.whereType<MatchEnded>(), hasLength(1));
  });

  test('damage is credited to the unit whose weapon caused it', () {
    final w = world([
      UnitPlacement(0, 500, 400),
      UnitPlacement(1, 530, 400),
    ]);
    final e = fireAndSettle(
        w, const Fire(weaponId: 'rock', angleDeg: 270, powerPercent: 5));
    final hits = e.whereType<UnitDamaged>().where(
        (d) => d.cause == DamageCause.explosion);
    expect(hits, isNotEmpty);
    expect(hits.every((d) => d.sourceUnitId == 0), isTrue);
    final falls = e.whereType<UnitDamaged>().where(
        (d) => d.cause == DamageCause.fall);
    expect(falls.every((d) => d.sourceUnitId == null), isTrue);
  });
}
