import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/config/weapons.dart';
import 'package:pawtillery/sim/events.dart';
import 'package:pawtillery/sim/inputs.dart';
import 'package:pawtillery/sim/match_setup.dart';
import 'package:pawtillery/sim/turn_manager.dart';
import 'package:pawtillery/sim/world.dart';

import 'sim_test_utils.dart';

void main() {
  group('Hujan Meteor', () {
    test('six meteors land one after another around the spot', () {
      final w = world([UnitPlacement(0, 200, 400), UnitPlacement(1, 900, 400)]);
      toAction(w);
      final fired = w.step(const [
        Fire(weaponId: 'meteorShower', targetX: 905, targetY: 395),
      ]);
      expect(fired.whereType<WeaponUsed>(), isNotEmpty);
      final spec = Weapons.meteorShower.delivery as MeteorShower;
      expect(w.projectiles.where((p) => p.weapon.id == 'meteor'),
          hasLength(spec.count));

      final landed = <int>[];
      final xs = <int>[];
      while (w.projectiles.isNotEmpty) {
        final events = w.step(const []);
        for (final e in explosions(events)) {
          landed.add(w.tick);
          xs.add(e.x);
        }
      }
      expect(landed, hasLength(spec.count));
      expect(landed.toSet(), hasLength(spec.count), reason: 'in turn');
      for (final x in xs) {
        expect((x - 905).abs(), lessThanOrEqualTo(spec.spread + 20));
      }
      expect(w.units[1].hp, lessThan(100));
    });

    test('the turn waits for the last meteor', () {
      final w = world([UnitPlacement(0, 200, 400), UnitPlacement(1, 900, 400)]);
      final events = fireAndSettle(
        w,
        const Fire(weaponId: 'meteorShower', targetX: 905, targetY: 395),
      );
      expect(explosions(events), hasLength(6));
      expect(w.projectiles, isEmpty);
    });
  });

  group('Tali Pengait', () {
    // Flat ground at y 400 and a ledge to the right: x 360–700, top y 330.
    SimWorld ledgeWorld() {
      final t = flatMap()..fillRect(360, 330, 340, 70);
      return world(
        [UnitPlacement(0, 300, 400), UnitPlacement(1, 1500, 400)],
        terrain: t,
      );
    }

    test('hooking the lip of a ledge pulls the pet up onto it, and the '
        'turn goes on with its shot', () {
      final w = ledgeWorld();
      toAction(w);
      final unit = w.units[0];
      final e = w.step(const [Fire(weaponId: 'grapple', angleDeg: 35)]);
      final shot = e.whereType<GrappleFired>().single;
      expect(shot.hooked, isTrue);
      expect(w.ammoLeft(0, Weapons.grapple), Weapons.grapple.ammo! - 1);
      runUntil(w, () => !unit.isGrappling);
      expect(unit.y, 330, reason: 'standing on the ledge');
      expect(unit.x, greaterThanOrEqualTo(360));
      expect(unit.grounded, isTrue);
      expect(w.turn.phase, TurnPhase.action);
      expect(w.turn.hasFired, isFalse);

      final fired = w.step(const [
        Fire(weaponId: 'rock', angleDeg: 30, powerPercent: 60),
      ]);
      expect(fired.whereType<WeaponUsed>().single.weaponId, 'rock');
    });

    test('a miss costs nothing and leaves the pet where it was', () {
      final w = ledgeWorld();
      toAction(w);
      final unit = w.units[0];
      final x = unit.x;
      final e = w.step(const [Fire(weaponId: 'grapple', angleDeg: 90)]);
      expect(e.whereType<GrappleFired>().single.hooked, isFalse);
      expect(e.whereType<WeaponUsed>(), isEmpty);
      expect(unit.isGrappling, isFalse);
      expect(unit.x, x);
      expect(w.ammoLeft(0, Weapons.grapple), Weapons.grapple.ammo);
    });

    test('no walking, jumping or firing while being reeled in', () {
      final w = ledgeWorld();
      toAction(w);
      w.step(const [Fire(weaponId: 'grapple', angleDeg: 35)]);
      final e = w.step(const [
        Fire(weaponId: 'rock', angleDeg: 30, powerPercent: 60),
        Jump(JumpKind.high),
      ]);
      expect(e.whereType<WeaponUsed>(), isEmpty);
      expect(e.whereType<UnitJumped>(), isEmpty);
      expect(w.units[0].isGrappling, isTrue);
    });

    test('hooking a ceiling: reeled up, then lets go and falls', () {
      // A floating slab over the pet, too thick to climb onto.
      final t = flatMap()..fillRect(240, 200, 120, 80);
      final w = world(
        [UnitPlacement(0, 300, 400), UnitPlacement(1, 1500, 400)],
        terrain: t,
      );
      toAction(w);
      final unit = w.units[0];
      w.step(const [Fire(weaponId: 'grapple', angleDeg: 90)]);
      runUntil(w, () => !unit.isGrappling);
      expect(unit.y, lessThan(330), reason: 'pulled up under the slab');
      runUntil(w, () => unit.grounded);
      expect(unit.y, 400, reason: 'back on the ground');
    });
  });
}
