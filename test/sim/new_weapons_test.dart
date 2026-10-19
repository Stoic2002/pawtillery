import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/config/weapons.dart';
import 'package:pawtillery/sim/events.dart';
import 'package:pawtillery/sim/inputs.dart';
import 'package:pawtillery/sim/match_setup.dart';
import 'package:pawtillery/sim/physics.dart';
import 'package:pawtillery/sim/world.dart';

import 'sim_test_utils.dart';

SimWorld _withLoadout(WeaponLoadout loadout, {String? familyId}) =>
    SimWorld.withUnits(
      seed: 3,
      terrain: flatMap(),
      waterLevel: 560,
      teamCount: 2,
      placements: [
        UnitPlacement(0, 200, 400, familyId: familyId),
        const UnitPlacement(1, 1800, 400),
      ],
      timings: testTimings,
      loadout: loadout,
    );

void main() {
  group('added arsenal', () {
    test('Roket Botol flies flatter and farther than a rock', () {
      double landX(WeaponDef weapon) {
        final path = ProjectilePhysics.predict(
          weapon: weapon,
          x: 200,
          y: 380,
          angleDeg: 30,
          powerPercent: 50,
          terrain: flatMap(),
          waterLevel: 560,
          speedScale: weapon.launchSpeedScale,
        );
        return path[path.length - 2];
      }

      expect(landX(Weapons.bottleRocket), greaterThan(landX(Weapons.rock)));
      final w = world([UnitPlacement(0, 200, 400), UnitPlacement(1, 1800, 400)]);
      fireAndSettle(w,
          const Fire(weaponId: 'bottleRocket', angleDeg: 30, powerPercent: 50));
      expect(w.ammoLeft(0, Weapons.bottleRocket), 2);
    });

    test('Roket Pelacak fired straight up turns and finds the enemy', () {
      final w = world([UnitPlacement(0, 200, 400), UnitPlacement(1, 600, 400)]);
      final e = fireAndSettle(w,
          const Fire(weaponId: 'snifferRocket', angleDeg: 90, powerPercent: 50));
      expect(damageTo(e, 1), isNotEmpty);
      expect(damageTo(e, 0), isEmpty);
      final blast = explosions(e).single;
      expect((blast.x - 600).abs(), lessThan(40));
    });

    test('Laser Pointer burns through a wall and hits the unit behind it', () {
      final t = flatMap()..fillRect(300, 300, 60, 100);
      final w = world(
        [UnitPlacement(0, 200, 400), UnitPlacement(1, 500, 400)],
        terrain: t,
      );
      final before = solidCount(w.terrain);
      toAction(w);
      final e = w.step(const [Fire(weaponId: 'laserPointer', angleDeg: 0)]);
      final beam = e.whereType<BeamFired>().single;
      expect(beam.x1, greaterThan(500));
      expect(solidCount(w.terrain), lessThan(before));
      expect(damageTo(e, 1).single.amount, Weapons.laserPointer.maxDamage);
      expect(damageTo(e, 0), isEmpty);
    });

    test('Awan Petir strikes the first thing down the chosen column', () {
      final w = world([UnitPlacement(0, 200, 400), UnitPlacement(1, 900, 400)]);
      final target = w.units[1];
      final e = fireAndSettle(
        w,
        Fire(
          weaponId: 'thunderCloud',
          targetX: target.centerX.round(),
          targetY: 100,
        ),
      );
      final bolt = e.whereType<LightningStruck>().single;
      expect(bolt.y, lessThan(target.centerY));
      expect(damageTo(e, 1), isNotEmpty);
    });

    test('Penyembur Biji fires five seeds at once in a fan', () {
      final w = world([UnitPlacement(0, 200, 400), UnitPlacement(1, 1800, 400)]);
      toAction(w);
      final e = w.step(const [
        Fire(weaponId: 'seedSpitter', angleDeg: 20, powerPercent: 60),
      ]);
      expect(e.whereType<ProjectileLaunched>(), hasLength(5));
      w.step(const []);
      final angles = {
        for (final p in w.projectiles) (p.vy / p.vx * 1000).round(),
      };
      expect(angles, hasLength(5));
    });

    test('Petasan goes off four seconds after it is set down', () {
      final w = world([UnitPlacement(0, 200, 400), UnitPlacement(1, 1800, 400)]);
      toAction(w);
      w.step(const [Fire(weaponId: 'firecracker')]);
      var ticks = 0;
      final events = <SimEvent>[];
      while (explosions(events).isEmpty && ticks < 400) {
        events.addAll(w.step(const [Walk(-1)]));
        ticks++;
      }
      expect(ticks, inInclusiveRange(239, 241));
      expect(explosions(events).single.radius, Weapons.firecracker.radius);
    });

    test('Hujan Pot Bunga drops five pots', () {
      final w = world([UnitPlacement(0, 200, 400), UnitPlacement(1, 1800, 400)]);
      final e = fireAndSettle(
          w, const Fire(weaponId: 'flowerpotRain', targetX: 1000, targetY: 300));
      expect(explosions(e).where((x) => x.radius == Weapons.flowerpot.radius),
          hasLength(5));
    });

    test('Cakar Gali digs sideways without hurting anyone', () {
      final t = flatMap()..fillRect(230, 300, 120, 100);
      final w = world(
        [UnitPlacement(0, 200, 400), UnitPlacement(1, 1800, 400)],
        terrain: t,
      );
      final before = solidCount(w.terrain);
      final x0 = w.units[0].x;
      final e = fireAndSettle(
          w, const Fire(weaponId: 'digClaws', angleDeg: 0));
      expect(solidCount(w.terrain), lessThan(before));
      expect(w.units[0].x, greaterThan(x0 + 40));
      expect(e.whereType<UnitDamaged>(), isEmpty);
    });
  });

  group('loadout', () {
    test('a weapon set to off cannot be used', () {
      final w = _withLoadout(
          WeaponLoadout.standard.withAmmo(Weapons.rock, 0));
      toAction(w);
      expect(w.canUse(w.activeUnit!, Weapons.rock), isFalse);
      final e = w.step(const [
        Fire(weaponId: 'rock', angleDeg: 45, powerPercent: 50),
      ]);
      expect(e.whereType<WeaponUsed>(), isEmpty);
    });

    test('ammo overrides, and unlimited never runs out', () {
      final w = _withLoadout(WeaponLoadout.standard
          .withAmmo(Weapons.rock, 1)
          .withAmmo(Weapons.cluster, null));
      expect(w.ammoLeft(0, Weapons.rock), 1);
      expect(w.ammoLeft(0, Weapons.cluster), isNull);
      fireAndSettle(
          w, const Fire(weaponId: 'rock', angleDeg: 45, powerPercent: 20));
      expect(w.ammoLeft(0, Weapons.rock), 0);
      expect(w.ammoLeft(1, Weapons.rock), 1, reason: 'per team');
    });

    test('signature weapons can be switched off', () {
      final w = _withLoadout(
        WeaponLoadout.standard.withSignatures(false),
        familyId: 'monkey',
      );
      expect(w.canUse(w.units[0], Weapons.coconut), isFalse);
    });

    test('presets', () {
      expect(WeaponLoadout.classic.enabled(Weapons.laserPointer), isFalse);
      expect(WeaponLoadout.classic.enabled(Weapons.grenade), isTrue);
      expect(WeaponLoadout.chaos.ammoOf(Weapons.mine), isNull);
      expect(WeaponLoadout.chaos.enabled(Weapons.skip), isTrue);
      expect(WeaponLoadout.standard.sameAs(const WeaponLoadout()), isTrue);
      expect(WeaponLoadout.classic.sameAs(WeaponLoadout.standard), isFalse);
    });

    test('JSON round trip keeps only differences and skips junk', () {
      final l = WeaponLoadout.standard
          .withAmmo(Weapons.rock, 4)
          .withAmmo(Weapons.mine, null)
          .withSignatures(false);
      final back = WeaponLoadout.fromJson(l.toJson())!;
      expect(back.sameAs(l), isTrue);
      expect(back.ammoOf(Weapons.mine), isNull);
      expect(WeaponLoadout.standard.toJson()['ammo'], isEmpty);
      final junk = WeaponLoadout.fromJson({
        'ammo': {'rock': 99, 'nope': 2, 'mine': 'x', 'grenade': 3},
        'signatures': true,
      })!;
      expect(junk.ammoOf(Weapons.rock), Weapons.rock.ammo);
      expect(junk.ammoOf(Weapons.grenade), 3);
      expect(WeaponLoadout.fromJson('bad'), isNull);
    });
  });

  test('the added weapons replay identically', () {
    int run() {
      final w = SimWorld.withUnits(
        seed: 21,
        terrain: flatMap()..fillRect(900, 250, 200, 150),
        waterLevel: 560,
        teamCount: 2,
        placements: const [
          UnitPlacement(0, 300, 400),
          UnitPlacement(1, 1500, 400),
        ],
        timings: testTimings,
      );
      const fires = [
        Fire(weaponId: 'snifferRocket', angleDeg: 70, powerPercent: 60),
        Fire(weaponId: 'laserPointer', angleDeg: 180),
        Fire(weaponId: 'seedSpitter', angleDeg: 25, powerPercent: 80),
        Fire(weaponId: 'thunderCloud', targetX: 1000, targetY: 100),
        Fire(weaponId: 'bottleRocket', angleDeg: 40, powerPercent: 70),
        Fire(weaponId: 'flowerpotRain', targetX: 400, targetY: 100),
      ];
      for (final f in fires) {
        fireAndSettle(w, f);
        if (w.turn.winnerTeam != null) break;
      }
      return w.stateHash();
    }

    expect(run(), run());
  });
}
