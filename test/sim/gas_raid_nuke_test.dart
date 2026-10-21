import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/config/weapons.dart';
import 'package:pawtillery/sim/events.dart';
import 'package:pawtillery/sim/inputs.dart';
import 'package:pawtillery/sim/match_setup.dart';

import 'sim_test_utils.dart';

void main() {
  group('Pesawat Gas', () {
    test('a bomber drops three canisters, each leaving a poison cloud', () {
      final w = world([UnitPlacement(0, 200, 400), UnitPlacement(1, 900, 400)]);
      final e = fireAndSettle(
          w, const Fire(weaponId: 'gasRaid', targetX: 900, targetY: 395));
      expect(e.whereType<BombDropped>(), hasLength(3));
      final clouds = e.whereType<GasReleased>().toList();
      expect(clouds, hasLength(3));
      for (final c in clouds) {
        expect((c.x - 900).abs(), lessThan(140));
      }
      expect(w.units[1].poisoned, isTrue);
      expect(w.units[0].poisoned, isFalse);
      expect(w.ammoLeft(0, Weapons.gasRaid), 0);
    });
  });

  group('Nuklir Mini', () {
    test('a huge blast and a crater, then fallout that poisons', () {
      final w = world([
        UnitPlacement(0, 200, 400),
        UnitPlacement(1, 900, 400),
        UnitPlacement(1, 1000, 400),
      ]);
      toAction(w);
      final before = solidCount(w.terrain);
      w.nuke(905, 398, Weapons.miniNuke, const Nuke(falloutRadius: 70),
          sourceId: 0);
      final e = <SimEvent>[];
      for (var i = 0; i < 5; i++) {
        e.addAll(w.step(const []));
      }
      expect(solidCount(w.terrain), lessThan(before - 8000),
          reason: 'a big crater');
      expect(w.units[1].hp, lessThan(100 - 40));
      expect(w.units[2].hp, lessThan(100), reason: '100 px away, still hit');
      expect(w.clouds.single.fallout, isTrue);
      expect(w.units[0].hp, 100, reason: 'far away');
    });

    test('a shot goes off with a mushroom cloud', () {
      final w = world([UnitPlacement(0, 200, 400), UnitPlacement(1, 1500, 400)]);
      final e = fireAndSettle(w,
          const Fire(weaponId: 'miniNuke', angleDeg: 50, powerPercent: 80));
      expect(e.whereType<NukeDetonated>(), hasLength(1));
      expect(e.whereType<GasReleased>(), hasLength(1));
    });
  });
}
