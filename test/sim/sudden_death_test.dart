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
  test('off by default: HP and water never change', () {
    final w = _match();
    for (var i = 0; i < 6; i++) {
      toNextTurn(w);
    }
    expect(w.suddenDeath, isFalse);
    expect(w.waterLevel, 560);
    expect(w.units.every((u) => u.hp == 100), isTrue);
  });

  test('starts with the first turn after the limit: everyone to 1 HP', () {
    final w = _match(suddenDeathAfterTicks: 1000);
    final events = <SimEvent>[];
    while (!w.suddenDeath) {
      events.addAll(toNextTurn(w));
    }
    expect(w.tick, greaterThanOrEqualTo(1000));
    expect(events.whereType<SuddenDeathStarted>(), hasLength(1));
    expect(w.units.every((u) => u.hp == 1), isTrue);
    expect(w.turn.phase, TurnPhase.turnStart);
  });

  test('water rises 20 px after every full round', () {
    final w = _match(suddenDeathAfterTicks: 0);
    expect(w.suddenDeath, isTrue, reason: 'limit 0 = from the first turn');
    final levels = <int>[];
    for (var turn = 0; turn < 6; turn++) {
      levels.addAll(toNextTurn(w).whereType<WaterRose>().map((e) => e.level));
    }
    // Two teams → a rise every second turn.
    const rise = MatchDefaults.suddenDeathWaterRise;
    expect(levels, [560 - rise, 560 - 2 * rise, 560 - 3 * rise]);
    expect(w.waterLevel, 560 - 3 * rise);
  });

  test('rising water drowns units and decides the match', () {
    // Ground at y = 540: the water reaches unit centres after one rise.
    final w = SimWorld.withUnits(
      seed: 5,
      terrain: flatMap(ground: 540),
      waterLevel: 560,
      teamCount: 2,
      placements: const [
        UnitPlacement(0, 300, 540),
        UnitPlacement(1, 1300, 540),
      ],
      timings: testTimings,
      suddenDeathAfterTicks: 0,
    );
    final events = runUntil(w, () => w.turn.phase == TurnPhase.matchOver);
    expect(events.whereType<UnitDied>().map((e) => e.cause).toSet(),
        {DeathCause.water});
    expect(events.whereType<MatchEnded>().single.winnerTeam, isNull,
        reason: 'both drowned at the same rise: a draw');
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
