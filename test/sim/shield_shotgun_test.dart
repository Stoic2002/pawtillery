import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/config/weapons.dart';
import 'package:pawtillery/sim/events.dart';
import 'package:pawtillery/sim/inputs.dart';
import 'package:pawtillery/sim/match_setup.dart';
import 'package:pawtillery/sim/turn_manager.dart';
import 'package:pawtillery/sim/world.dart';

import 'sim_test_utils.dart';

SimWorld _duel({int x1 = 900}) =>
    world([UnitPlacement(0, 200, 400), UnitPlacement(1, x1, 400)]);

void main() {
  group('Gelembung Perisai', () {
    test('takes the next hit instead of the pet, with no knockback', () {
      final w = _duel();
      final e = fireAndSettle(w, const Fire(weaponId: 'shield'));
      expect(e.whereType<ShieldRaised>().single.unitId, 0);
      expect(w.units[0].shielded, isTrue);
      expect(w.ammoLeft(0, Weapons.shield), Weapons.shield.ammo! - 1);

      // Team 1 hits the shielded pet.
      final x = w.units[0].x;
      w.strikeUnit(w.units[0], 30, 1, 0, 1, sourceId: 1);
      expect(w.units[0].hp, 100);
      expect(w.units[0].x, x);
      expect(w.units[0].shielded, isFalse);

      // The bubble is gone: the next hit lands.
      w.strikeUnit(w.units[0], 30, 1, 0, 1, sourceId: 1);
      expect(w.units[0].hp, 70);
    });

    test('it runs out when its pet\'s own turn comes round', () {
      final w = _duel();
      fireAndSettle(w, const Fire(weaponId: 'shield'));
      toNextTurn(w); // Team 1's turn ends untouched.
      expect(w.turn.activeUnitId, 0);
      expect(w.units[0].shielded, isFalse, reason: 'its own turn again');
    });

    test('falls and water still hurt', () {
      final w = _duel();
      fireAndSettle(w, const Fire(weaponId: 'shield'));
      final u = w.units[0]
        ..y = 200
        ..peakY = 200
        ..grounded = false;
      runUntil(w, () => u.grounded);
      expect(u.hp, lessThan(100), reason: 'a fall of 200 px');
      expect(u.shielded, isTrue);
    });
  });

  group('Shotgun', () {
    test('two aimed shots a turn, each hitting the first pet in line', () {
      final w = _duel(x1: 400);
      toAction(w);
      final first = w.step(const [Fire(weaponId: 'shotgun', angleDeg: 0)]);
      expect(first.whereType<ShotgunFired>(), hasLength(1));
      expect(damageTo(first, 1).single.amount, Weapons.shotgun.maxDamage);
      expect(w.turn.phase, TurnPhase.action, reason: 'one more to go');
      expect(w.shotgunShotsLeft, 1);
      expect(w.ammoLeft(0, Weapons.shotgun), Weapons.shotgun.ammo! - 1);
      // Only the shotgun until it is done.
      expect(w.canUse(w.units[0], Weapons.rock), isFalse);
      expect(w.step(const [
        Fire(weaponId: 'rock', angleDeg: 45, powerPercent: 50),
      ]).whereType<WeaponUsed>(), isEmpty);

      final second = w.step(const [Fire(weaponId: 'shotgun', angleDeg: 30)]);
      expect(second.whereType<ShotgunFired>(), hasLength(1));
      expect(damageTo(second, 1), isEmpty, reason: 'aimed over it');
      expect(w.turn.phase, TurnPhase.retreat);
      expect(w.ammoLeft(0, Weapons.shotgun), Weapons.shotgun.ammo! - 1,
          reason: 'both pulls are one use');
    });

    test('out of range or into the ground does not hurt', () {
      final w = _duel();
      toAction(w);
      final far = w.step(const [Fire(weaponId: 'shotgun', angleDeg: 0)]);
      final shot = far.whereType<ShotgunFired>().single;
      expect(shot.x1 - shot.x0, closeTo(
          (Weapons.shotgun.delivery as Shotgun).range, 1));
      expect(damageTo(far, 1), isEmpty);
      final down = w.step(const [Fire(weaponId: 'shotgun', angleDeg: -60)]);
      expect(down.whereType<TerrainCarved>(), isNotEmpty);
    });

    test('a shield blocks a shotgun hit', () {
      final w = _duel(x1: 400);
      w.units[1].shielded = true;
      toAction(w);
      final e = w.step(const [Fire(weaponId: 'shotgun', angleDeg: 0)]);
      expect(e.whereType<ShieldPopped>().single.blocked, isTrue);
      expect(w.units[1].hp, 100);
    });
  });
}
