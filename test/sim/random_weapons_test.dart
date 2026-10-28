import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/ai/cpu_player.dart';
import 'package:pawtillery/app/match_config.dart';
import 'package:pawtillery/config/cpu.dart';
import 'package:pawtillery/config/weapons.dart';
import 'package:pawtillery/sim/events.dart';
import 'package:pawtillery/sim/inputs.dart';
import 'package:pawtillery/sim/match_setup.dart';
import 'package:pawtillery/sim/world.dart';

import 'sim_test_utils.dart';

SimWorld _world({bool random = true, int seed = 3}) => SimWorld.withUnits(
  seed: seed,
  terrain: flatMap(),
  waterLevel: 560,
  teamCount: 2,
  placements: const [
    UnitPlacement(0, 400, 400, familyId: 'cat'),
    UnitPlacement(1, 1400, 400, familyId: 'dog'),
  ],
  timings: testTimings,
  randomWeapons: random,
);

void main() {
  test('each turn draws one weapon, never a tool; only it and skip work',
      () {
    final w = _world();
    final seen = <String>{};
    for (var turn = 0; turn < 30; turn++) {
      toAction(w);
      final id = w.drawnWeaponId!;
      seen.add(id);
      final drawn = Weapons.byId(id);
      expect(Weapons.groupOf(drawn), isNot(WeaponGroup.tools));
      final me = w.activeUnit!;
      expect(w.canUse(me, drawn), isTrue);
      expect(w.canUse(me, Weapons.skip), isTrue);
      final other = Weapons.shared.firstWhere(
          (o) => o.id != id && o.delivery is! SkipTurn);
      expect(w.canUse(me, other), isFalse, reason: '${other.id} with $id');
      fireAndSettle(w, const Fire(weaponId: 'skip'));
    }
    expect(seen.length, greaterThan(8), reason: 'the draw varies');
  });

  test('a drawn weapon costs no ammo', () {
    final w = _world();
    toAction(w);
    while (w.ammoLeft(w.activeUnit!.team, Weapons.byId(w.drawnWeaponId!)) ==
        null) {
      fireAndSettle(w, const Fire(weaponId: 'skip'));
      toAction(w);
    }
    final weapon = Weapons.byId(w.drawnWeaponId!);
    final team = w.activeUnit!.team;
    final before = w.ammoLeft(team, weapon);
    final events = fireAndSettle(
      w,
      Fire(weaponId: weapon.id, angleDeg: 60, powerPercent: 50,
          targetX: 900, targetY: 380),
    );
    expect(events.whereType<WeaponUsed>(), isNotEmpty, reason: weapon.id);
    expect(w.ammoLeft(team, weapon), before);
  });

  test('the draws follow the seed, and the rule off draws nothing', () {
    List<String> draws(int seed) {
      final w = _world(seed: seed);
      final ids = <String>[];
      for (var i = 0; i < 8; i++) {
        toAction(w);
        ids.add(w.drawnWeaponId!);
        fireAndSettle(w, const Fire(weaponId: 'skip'));
      }
      return ids;
    }

    expect(draws(5), draws(5));
    expect(draws(5), isNot(draws(6)));
    final off = _world(random: false);
    toAction(off);
    expect(off.drawnWeaponId, isNull);
  });

  test('a CPU plays the drawn weapon, even an easy one', () {
    final w = _world();
    final cpu = CpuPlayer(
      levels: {0: CpuLevel.easy, 1: CpuLevel.easy},
      seed: 1,
    );
    var fired = 0;
    for (var i = 0; i < 20000 && fired < 6; i++) {
      final drawn = w.drawnWeaponId;
      for (final e in w.step(cpu.step(w))) {
        if (e is WeaponUsed && e.weaponId != 'skip') {
          expect(e.weaponId, drawn);
          fired++;
        }
      }
    }
    expect(fired, greaterThanOrEqualTo(3));
  });

  test('the rule is saved with the setup', () {
    const names = ['Milo', 'Luna'];
    final c = MatchConfig.defaults(names).copyWith(randomWeapons: true);
    expect(MatchConfig.fromJson(c.toJson(), names)!.randomWeapons, isTrue);
    final old = c.toJson()..remove('randomWeapons');
    expect(MatchConfig.fromJson(old, names)!.randomWeapons, isFalse);
  });
}
