import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/app/match_config.dart';
import 'package:pawtillery/config/map_objects.dart';
import 'package:pawtillery/config/weapons.dart';
import 'package:pawtillery/sim/events.dart';
import 'package:pawtillery/sim/inputs.dart';
import 'package:pawtillery/sim/map_object.dart';
import 'package:pawtillery/sim/match_setup.dart';
import 'package:pawtillery/sim/world.dart';

import 'sim_test_utils.dart';

const _mix = ObjectMix(mines: 2, barrels: 2, healthCrates: 1, weaponCrates: 1);

SimWorld _match(int seed, {ObjectMix? objects = _mix}) => SimWorld.newMatch(
  seed: seed,
  terrain: flatMap(w: 3000),
  waterLevel: 560,
  rosters: const [
    [UnitSpec(familyId: 'cat')],
    [UnitSpec(familyId: 'dog')],
  ],
  timings: testTimings,
  objects: objects,
);

void main() {
  test('a match places its starter objects away from the units', () {
    final w = _match(4);
    expect(w.mines, hasLength(_mix.mines));
    expect(w.objects.where((o) => o.kind == ObjectKind.barrel), hasLength(2));
    expect(
      w.objects.where((o) => o.kind == ObjectKind.healthCrate),
      hasLength(1),
    );
    expect(
      w.objects.where((o) => o.kind == ObjectKind.weaponCrate),
      hasLength(1),
    );
    for (final o in [
      ...w.objects.map((o) => (o.x, o.y)),
      ...w.mines.map((m) => (m.x, m.y)),
    ]) {
      expect(o.$2, 400, reason: 'on the ground');
      for (final u in w.units) {
        expect(
          (u.x - o.$1).abs(),
          greaterThanOrEqualTo(ObjectConfig.minDistanceFromUnits - 1),
        );
      }
    }
    // Same seed, same layout.
    final again = _match(4);
    expect(again.stateHash(), w.stateHash());
  });

  test('no objects leave unit placement exactly as before', () {
    final none = _match(9, objects: null);
    final some = _match(9);
    expect(none.objects, isEmpty);
    expect(none.mines, isEmpty);
    for (var i = 0; i < none.units.length; i++) {
      expect(some.units[i].x, none.units[i].x);
    }
  });

  test('starter mines are armed from the first turn', () {
    final w = world([UnitPlacement(0, 200, 400), UnitPlacement(1, 900, 400)]);
    expect(_match(4).mines.every((m) => m.armedOnTurn == 0), isTrue);
    expect(w.mines, isEmpty);
  });

  test('a blast lights a barrel, which blows up and sets off the next', () {
    final w = world([UnitPlacement(0, 200, 400), UnitPlacement(1, 1800, 400)]);
    w
      ..addObject(ObjectKind.barrel, 800, 400)
      ..addObject(ObjectKind.barrel, 840, 400)
      ..addObject(ObjectKind.healthCrate, 870, 400);
    final e = fireAndSettle(
      w,
      const Fire(weaponId: 'thunderCloud', targetX: 800, targetY: 300),
    );
    // The bolt, then both barrels one after another.
    expect(explosions(e).length, 3);
    expect(e.whereType<ObjectRemoved>().length, 3, reason: 'crate broke too');
    expect(w.objects, isEmpty);
  });

  test('a unit walking into a health crate heals up to its maximum', () {
    final w = world([UnitPlacement(0, 200, 400), UnitPlacement(1, 1800, 400)]);
    w.units[0].hp = 60;
    w.addObject(ObjectKind.healthCrate, 240, 400);
    toAction(w);
    final events = <SimEvent>[];
    for (var i = 0; i < 120 && w.objects.isNotEmpty; i++) {
      events.addAll(w.step(const [Walk(1)]));
    }
    final got = events.whereType<CrateCollected>().single;
    expect(got.health, isTrue);
    expect(got.hp, ObjectConfig.healthAmount);
    expect(w.units[0].hp, 60 + ObjectConfig.healthAmount);
  });

  test('a weapon crate gives the team one more of a limited weapon', () {
    final w = world([UnitPlacement(0, 200, 400), UnitPlacement(1, 1800, 400)]);
    final before = {
      for (final weapon in Weapons.shared) weapon.id: w.ammoLeft(0, weapon),
    };
    w.addObject(ObjectKind.weaponCrate, 240, 400);
    toAction(w);
    final events = <SimEvent>[];
    for (var i = 0; i < 120 && w.objects.isNotEmpty; i++) {
      events.addAll(w.step(const [Walk(1)]));
    }
    final got = events.whereType<CrateCollected>().single;
    expect(got.health, isFalse);
    final weapon = Weapons.byId(got.weaponId!);
    expect(w.ammoLeft(0, weapon), before[weapon.id]! + 1);
  });

  test('the setup choice is saved and old saves get the default', () {
    final config = MatchConfig.defaults(const ['A']);
    expect(config.objects, ObjectAmount.few);
    final many = config.copyWith(objects: ObjectAmount.many);
    expect(
      MatchConfig.fromJson(many.toJson(), const ['A'])!.objects,
      ObjectAmount.many,
    );
    final old = config.toJson()..remove('objects');
    expect(MatchConfig.fromJson(old, const ['A'])!.objects, ObjectAmount.few);
    expect(_mix.forAmount(ObjectAmount.off), isNull);
    expect(_mix.forAmount(ObjectAmount.many)!.total, _mix.total * 2);
  });
}
