import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/ai/cpu_planner.dart';
import 'package:pawtillery/ai/cpu_player.dart';
import 'package:pawtillery/app/match_config.dart';
import 'package:pawtillery/config/cpu.dart';
import 'package:pawtillery/config/maps.dart';
import 'package:pawtillery/config/match_defaults.dart';
import 'package:pawtillery/config/weapons.dart';
import 'package:pawtillery/game/map_loader.dart';
import 'package:pawtillery/sim/events.dart';
import 'package:pawtillery/sim/inputs.dart';
import 'package:pawtillery/sim/match_setup.dart';
import 'package:pawtillery/sim/terrain_mask.dart';
import 'package:pawtillery/sim/turn_manager.dart';
import 'package:pawtillery/sim/world.dart';

import '../sim/sim_test_utils.dart';

const _names = ['Milo', 'Luna', 'Bobo', 'Kiki', 'Coco'];

/// Plays [w] with [cpu] for every team until the match ends (or [limit]
/// ticks); returns every event.
List<SimEvent> _play(SimWorld w, CpuPlayer cpu, {int limit = 120000}) {
  final events = <SimEvent>[];
  for (var i = 0; i < limit && w.turn.phase != TurnPhase.matchOver; i++) {
    events.addAll(w.step(cpu.step(w)));
  }
  return events;
}

/// Steps until the active unit has used a weapon; returns the weapon id.
String _playOneShot(SimWorld w, CpuPlayer cpu) {
  for (var i = 0; i < 5000; i++) {
    for (final e in w.step(cpu.step(w))) {
      if (e is WeaponUsed) return e.weaponId;
    }
  }
  fail('the CPU never fired');
}

void main() {
  group('planner', () {
    test('a hard CPU on flat ground plans a hit on the enemy', () {
      final w = world(const [
        UnitPlacement(0, 400, 400),
        UnitPlacement(1, 800, 400),
      ]);
      toAction(w);
      final plan = CpuPlanner(w, CpuTuning.hard, seed: 1).planNow()!;
      expect(plan.score, greaterThan(20));

      final hp = w.units[1].hp;
      fireAndSettle(w, plan.fire);
      expect(w.units[1].hp, lessThan(hp));
      expect(w.units[0].hp, w.units[0].stats.maxHp);
    });

    test('reads the wind when its level does', () {
      final w = world(const [
        UnitPlacement(0, 400, 400),
        UnitPlacement(1, 900, 400),
      ]);
      toAction(w);
      // Force a strong head wind for this turn.
      while (w.wind > -6) {
        toNextTurn(w);
        toNextTurn(w);
        toAction(w);
      }
      final plan = CpuPlanner(w, CpuTuning.hard, seed: 2).planNow()!;
      final hp = w.units[1].hp;
      fireAndSettle(w, plan.fire);
      expect(w.units[1].hp, lessThan(hp));
    });

    test('never plans a blast on its own teammate', () {
      // Enemy right behind the CPU's teammate: a hit on the enemy would
      // also catch the teammate, so it must look elsewhere or hold back.
      final w = world(const [
        UnitPlacement(0, 300, 400),
        UnitPlacement(0, 780, 400),
        UnitPlacement(1, 800, 400),
        UnitPlacement(1, 1500, 400),
      ]);
      toAction(w);
      final plan = CpuPlanner(w, CpuTuning.hard, seed: 3).planNow()!;
      fireAndSettle(w, plan.fire);
      expect(w.units[0].hp, w.units[0].stats.maxHp);
      expect(w.units[1].hp, w.units[1].stats.maxHp);
    });

    test('same world and seed, same plan', () {
      SimWorld make() {
        final w = world(const [
          UnitPlacement(0, 400, 400),
          UnitPlacement(1, 760, 400),
        ]);
        toAction(w);
        return w;
      }

      final a = CpuPlanner(make(), CpuTuning.normal, seed: 9).planNow()!;
      final b = CpuPlanner(make(), CpuTuning.normal, seed: 9).planNow()!;
      expect(
        (a.fire.weaponId, a.fire.angleDeg, a.fire.powerPercent, a.score),
        (b.fire.weaponId, b.fire.angleDeg, b.fire.powerPercent, b.score),
      );
    });

    test('an easy CPU keeps to unlimited weapons', () {
      final w = world(const [
        UnitPlacement(0, 400, 400),
        UnitPlacement(1, 700, 400),
      ]);
      toAction(w);
      final plan = CpuPlanner(w, CpuTuning.easy, seed: 4).planNow()!;
      final weapon = Weapons.byId(plan.fire.weaponId);
      expect(w.ammoLeft(0, weapon), isNull);
    });

    test('plans in slices, a few flights at a time', () {
      final w = world(const [
        UnitPlacement(0, 400, 400),
        UnitPlacement(1, 800, 400),
      ]);
      toAction(w);
      final planner = CpuPlanner(w, CpuTuning.normal, seed: 5);
      var slices = 0;
      while (!planner.work()) {
        slices++;
      }
      expect(slices, greaterThan(10));
      expect(planner.result, isNotNull);
    });
  });

  group('player', () {
    test('waits, swings the aim into view, then fires', () {
      final w = world(const [
        UnitPlacement(0, 400, 400),
        UnitPlacement(1, 800, 400),
      ]);
      final cpu = CpuPlayer(levels: {0: CpuLevel.normal}, seed: 1);
      var aimed = 0;
      var fired = false;
      for (var i = 0; i < 2000 && !fired; i++) {
        final inputs = cpu.step(w);
        if (cpu.aim != null) aimed++;
        fired = inputs.whereType<Fire>().isNotEmpty;
        w.step(inputs);
      }
      expect(fired, isTrue);
      expect(aimed, greaterThanOrEqualTo(CpuConfig.aimTicks ~/ 2));
    });

    test("leaves a player's turn alone", () {
      final w = world(const [
        UnitPlacement(0, 400, 400),
        UnitPlacement(1, 800, 400),
      ]);
      final cpu = CpuPlayer(levels: {1: CpuLevel.hard}, seed: 1);
      toAction(w);
      for (var i = 0; i < 300; i++) {
        expect(cpu.step(w), isEmpty);
        w.step(const []);
      }
    });

    test('walks towards an enemy that is out of reach, then shoots', () {
      // Farther than any throw goes, and an easy CPU has no air support.
      final w = world(const [
        UnitPlacement(0, 200, 400),
        UnitPlacement(1, 3700, 400),
      ], terrain: flatMap(w: 4000));
      final cpu = CpuPlayer(levels: {0: CpuLevel.easy}, seed: 2);
      final x0 = w.units[0].x;
      _playOneShot(w, cpu);
      expect(w.units[0].x, greaterThan(x0 + 20));
    });

    testWidgets('CPU against CPU on the real maps reaches a result',
        (tester) async {
      for (final map in [Maps.backyard, Maps.ruins]) {
        late TerrainMask original;
        await tester.runAsync(() async {
          original = (await loadMapData(map.maskAsset)).mask;
        });
        for (final seed in [1, 2]) {
          final terrain = TerrainMask(original.width, original.height)
            ..data.setAll(0, original.data);
          final w = SimWorld.newMatch(
            seed: seed,
            terrain: terrain,
            waterLevel: map.waterLevel,
            rosters: const [
              [
                UnitSpec(familyId: 'cat', breedId: 'catBengal'),
                UnitSpec(familyId: 'monkey', breedId: 'monkeyEkorPanjang'),
              ],
              [
                UnitSpec(familyId: 'dog', breedId: 'dogHusky'),
                UnitSpec(familyId: 'bird', breedId: 'birdBeo'),
              ],
            ],
            objects: map.objects,
            suddenDeathAfterTicks: 6 * 60 * MatchDefaults.ticksPerSecond,
          );
          final cpu = CpuPlayer(
            levels: {0: CpuLevel.hard, 1: CpuLevel.normal},
            seed: seed,
          );
          final events = _play(w, cpu, limit: 400000);
          final reason = '${map.id} seed $seed';
          expect(w.turn.phase, TurnPhase.matchOver, reason: reason);
          final hits = events
              .whereType<UnitDamaged>()
              .where((d) => d.cause != DamageCause.fall)
              .length;
          expect(hits, greaterThan(3), reason: reason);
        }
      }
    }, timeout: const Timeout(Duration(minutes: 5)));
  });

  group('setup', () {
    test('CPU levels are saved with the team, and old saves are players', () {
      var c = MatchConfig.defaults(_names);
      c = c.withTeam(1, c.teams[1].copyWith(cpu: CpuLevel.hard));
      expect(c.cpuTeams(), {1: CpuLevel.hard});

      final back = MatchConfig.fromJson(
        jsonDecode(jsonEncode(c.toJson())),
        _names,
      )!;
      expect(back.cpuTeams(), {1: CpuLevel.hard});

      final old = c.toJson();
      for (final t in old['teams'] as List) {
        (t as Map).remove('cpu');
      }
      expect(MatchConfig.fromJson(old, _names)!.cpuTeams(), isEmpty);

      expect(c.withoutCpu().cpuTeams(), isEmpty);
      expect(
        c.withTeam(1, c.teams[1].copyWith(human: true)).cpuTeams(),
        isEmpty,
      );
    });
  });
}
