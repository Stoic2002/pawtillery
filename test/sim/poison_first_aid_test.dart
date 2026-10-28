import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/config/weapons.dart';
import 'package:pawtillery/sim/events.dart';
import 'package:pawtillery/sim/inputs.dart';
import 'package:pawtillery/sim/match_setup.dart';
import 'package:pawtillery/sim/world.dart';

import 'sim_test_utils.dart';

SimWorld _duel() =>
    world([UnitPlacement(0, 200, 400), UnitPlacement(1, 900, 400)]);

void main() {
  group('Gas Beracun', () {
    test('a pet in the cloud is poisoned and loses HP each own turn, '
        'never the last', () {
      final w = _duel();
      toAction(w);
      w.releaseGas(900, 395, const GasCloud(radius: 52));
      final e = w.step(const []);
      expect(e.whereType<UnitPoisoned>().single.unitId, 1);
      expect(w.units[1].poisoned, isTrue);
      expect(w.units[0].poisoned, isFalse);

      // Team 1's turn starts with the poison's bite (the cloud it still
      // stands in bites too, every second).
      final next = toNextTurn(w);
      expect(w.turn.activeUnitId, 1);
      final bites = damageTo(next, 1).toList();
      expect(bites.every((d) => d.cause == DamageCause.poison), isTrue);
      expect(bites.map((d) => d.amount), contains(GasConfig.damage));

      w.units[1].hp = 3;
      toNextTurn(w);
      toNextTurn(w);
      expect(w.units[1].hp, 1);
      toNextTurn(w);
      final last = toNextTurn(w);
      expect(damageTo(last, 1), isEmpty, reason: 'never the last HP');
      expect(w.units[1].alive, isTrue);
    });

    test('the cloud drifts with the wind and clears after its turns', () {
      final w = _duel();
      toAction(w);
      w.releaseGas(600, 395, const GasCloud(radius: 52));
      final cloud = w.clouds.single;
      final x = cloud.x;
      for (var i = 0; i < 120; i++) {
        w.step(const []);
      }
      if (w.wind != 0) expect(cloud.x, isNot(x));
      for (var i = 0; i < GasConfig.turns; i++) {
        toNextTurn(w);
      }
      expect(w.clouds, isEmpty);
    });

    test('a shield keeps the gas out once; the cold clears it', () {
      final w = _duel();
      w.units[1].shielded = true;
      toAction(w);
      w.releaseGas(900, 395, const GasCloud(radius: 52));
      final e = w.step(const []);
      expect(e.whereType<ShieldPopped>().single.blocked, isTrue);
      expect(w.units[1].poisoned, isFalse);
      w.step(const []);
      expect(w.units[1].poisoned, isTrue, reason: 'no bubble left');

      w.freeze(900, 390, Weapons.iceBomb, const Freeze(radius: 55));
      expect(w.clouds, isEmpty);
    });

    test('a shot releases a cloud where it lands', () {
      final w = _duel();
      final e = fireAndSettle(w,
          const Fire(weaponId: 'poisonGas', angleDeg: 60, powerPercent: 60));
      expect(e.whereType<GasReleased>(), hasLength(1));
    });
  });

  group('Kotak P3K', () {
    test('heals 25 up to the maximum, cures poison and ends the turn', () {
      final w = _duel();
      w.units[0]
        ..hp = 50
        ..poisoned = true;
      toAction(w);
      final e = w.step(const [Fire(weaponId: 'firstAid')]);
      expect(w.turn.activeUnitId, 0, reason: 'held a moment to see it');
      runUntil(w, () => w.turn.turnNumber > 1);
      expect(e.whereType<UnitHealed>().single.amount, 25);
      expect(w.units[0].hp, 75);
      expect(w.units[0].poisoned, isFalse);
      expect(w.turn.activeUnitId, 1, reason: 'turn over');
      expect(w.ammoLeft(0, Weapons.firstAid), Weapons.firstAid.ammo! - 1);
    });

    test('never above the maximum', () {
      final w = _duel();
      w.units[0].hp = 90;
      toAction(w);
      final e = w.step(const [Fire(weaponId: 'firstAid')]);
      expect(e.whereType<UnitHealed>().single.amount, 10);
      expect(w.units[0].hp, 100);
    });
  });
}
