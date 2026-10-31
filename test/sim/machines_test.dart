import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/config/map_objects.dart';
import 'package:pawtillery/config/weapons.dart';
import 'package:pawtillery/net/protocol.dart';
import 'package:pawtillery/sim/inputs.dart';
import 'package:pawtillery/sim/map_object.dart';
import 'package:pawtillery/sim/match_setup.dart';
import 'package:pawtillery/sim/world.dart';

import 'sim_test_utils.dart';

SimWorld _duel() =>
    world(const [UnitPlacement(0, 200, 400), UnitPlacement(1, 1500, 400)]);

void main() {
  test('a mounted gun fires only for a pet beside it, three times', () {
    final w = _duel();
    toAction(w);
    final me = w.units[0];
    expect(w.canUse(me, Weapons.mountedGun), isFalse, reason: 'none near');
    final gun = w.addObject(ObjectKind.gun, 215, 400);
    expect(w.canUse(me, Weapons.mountedGun), isTrue);
    expect(gun.shots, ObjectConfig.gunShots);
    for (var i = 0; i < ObjectConfig.gunShots; i++) {
      w.units[1].x = 1500;
      fireAndSettle(
        w,
        const Fire(weaponId: 'mountedGun', angleDeg: 150, powerPercent: 20),
      );
      expect(gun.shots, ObjectConfig.gunShots - 1 - i);
      toNextTurn(w);
      while (w.activeUnit != me) {
        toNextTurn(w);
      }
      toAction(w);
    }
    expect(w.objects.where((o) => o.kind == ObjectKind.gun), isEmpty);
  });

  test('materials buy a weapon, the turn goes on, and too few buy nothing', () {
    final w = _duel();
    toAction(w);
    expect(w.materials(0), CraftConfig.startMaterials);
    final before = w.ammoLeft(0, Weapons.jetpack)!;
    w.step(const [Craft('jetpack')]);
    expect(w.ammoLeft(0, Weapons.jetpack), before + 1);
    expect(w.materials(0), 0);
    expect(w.turn.allowsFire, isTrue);
    w.step(const [Craft('warMachine')]);
    expect(w.ammoLeft(0, Weapons.warMachine), 0, reason: 'cannot afford it');
  });

  test('a crate of materials adds to the team that finds it', () {
    final w = _duel();
    toAction(w);
    w.addObject(ObjectKind.materialCrate, 204, 400);
    w.step(const []);
    expect(w.materials(0), CraftConfig.startMaterials + CraftConfig.crateMaterials);
    expect(w.materials(1), CraftConfig.startMaterials);
  });

  test('a war machine takes the hits, then is gone', () {
    final w = _duel();
    toAction(w);
    final me = w.units[0];
    w.step(const [Craft('jetpack')]);
    expect(w.canUse(me, Weapons.warMachine), isFalse, reason: 'none yet');
    me.machineHp = 60;
    me.machineTurns = 3;
    expect(w.canUse(me, Weapons.machineCannon), isTrue);
    final x = me.x;
    w.step(const [Walk(1)]);
    final inMachine = me.x - x;
    w.step(const [Jump(JumpKind.high)]);
    expect(me.grounded, isTrue, reason: 'no jumping');
    expect(inMachine, greaterThan(0));
    final hp = me.hp;
    w.explode(me.centerX, me.centerY, Weapons.rock);
    expect(me.hp, hp, reason: 'armour took it');
    expect(me.machineHp, lessThan(60));
    me.machineHp = 1;
    w.explode(me.centerX, me.centerY, Weapons.rock);
    expect(me.inMachine, isFalse);
    expect(me.hp, hp, reason: 'the last hit stops at the machine');
  });

  test('a parked machine can be climbed into for free, once', () {
    final w = _duel();
    toAction(w);
    final me = w.units[0];
    expect(w.canUse(me, Weapons.warMachine), isFalse);
    w.addObject(ObjectKind.machine, 220, 400);
    expect(w.canUse(me, Weapons.warMachine), isTrue);
    w.step(const [Fire(weaponId: 'warMachine')]);
    w.step(const []);
    expect(me.inMachine, isTrue);
    expect(w.ammoLeft(0, Weapons.warMachine), 0, reason: 'nothing spent');
    expect(w.objects.where((o) => o.kind == ObjectKind.machine), isEmpty);
    expect(w.turn.allowsFire, isTrue, reason: 'it can still fire');
  });

  test('a craft input crosses the wire', () {
    final back = decodeInput(encodeInput(const Craft('jetpack')));
    expect(back, isA<Craft>());
    expect((back! as Craft).weaponId, 'jetpack');
  });
}
