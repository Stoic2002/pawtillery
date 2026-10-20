import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/config/weapons.dart';
import 'package:pawtillery/sim/events.dart';
import 'package:pawtillery/sim/inputs.dart';
import 'package:pawtillery/sim/match_setup.dart';

import 'sim_test_utils.dart';

void main() {
  group('Pesawat Pengebom', () {
    test('flies in from the shooter\'s side and carpets the target', () {
      final w = world([
        UnitPlacement(0, 200, 400),
        UnitPlacement(1, 1200, 400),
      ]);
      toAction(w);
      final turn = w.turn.turnNumber;
      final events = [
        ...w.step(const [
          Fire(weaponId: 'bomber', targetX: 1200, targetY: 395),
        ]),
      ];
      expect(w.bombers.single.dir, 1);
      // The turn waits for the plane and every bomb.
      while (w.bombers.isNotEmpty || w.projectiles.isNotEmpty) {
        expect(w.turn.turnNumber, turn);
        events.addAll(w.step(const []));
      }
      if (w.turn.turnNumber == turn) events.addAll(toNextTurn(w));

      expect(events.whereType<BombDropped>().length, 5);
      final blasts = explosions(events).toList();
      expect(blasts.length, 5);
      final xs = blasts.map((b) => b.x).toList()..sort();
      final mid = xs.reduce((a, b) => a + b) / xs.length;
      expect((mid - 1200).abs(), lessThan(40), reason: '$xs');
      // Spread along the run, about four spacings wide.
      expect(xs.last - xs.first, inInclusiveRange(100, 200), reason: '$xs');
      expect(damageTo(events, 1), isNotEmpty);
      expect(damageTo(events, 0), isEmpty);
      expect(w.ammoLeft(0, Weapons.bomber), 0);
    });

    test('a target on the left brings the plane from the right', () {
      final w = world([
        UnitPlacement(0, 1500, 400),
        UnitPlacement(1, 600, 400),
      ]);
      toAction(w);
      w.step(const [Fire(weaponId: 'bomber', targetX: 600, targetY: 395)]);
      final b = w.bombers.single;
      expect(b.dir, -1);
      expect(b.x, greaterThan(600));
    });
  });

  group('Serangan Satelit', () {
    test('marks the column, then burns it to the water after the delay', () {
      final w = world([UnitPlacement(0, 200, 400), UnitPlacement(1, 900, 400)]);
      toAction(w);
      final fired = w.step(const [
        Fire(weaponId: 'satellite', targetX: 905, targetY: 395),
      ]);
      expect(fired.whereType<WeaponUsed>(), isNotEmpty);
      expect(w.pendingStrikes.single.x, 905);
      final firedAt = w.tick;

      final events = <SimEvent>[];
      while (w.pendingStrikes.isNotEmpty) {
        events.addAll(w.step(const []));
      }
      final delay = (Weapons.satellite.delivery as OrbitalStrike).delayTicks;
      expect(w.tick - firedAt, delay);
      final strike = events.whereType<SatelliteStruck>().single;
      expect(strike.x, 905);
      expect(strike.y, 560, reason: 'down to the water');
      expect(damageTo(events, 1).single.amount, Weapons.satellite.maxDamage);
      expect(damageTo(events, 0), isEmpty);
      // A shaft through the ground, which is untouched beside it.
      expect(w.terrain.isSolid(905, 450), isFalse);
      expect(w.terrain.isSolid(905, 540), isFalse);
      expect(w.terrain.isSolid(1100, 450), isTrue);
    });

    test('it does not spare the shooter', () {
      final w = world([UnitPlacement(0, 200, 400), UnitPlacement(1, 900, 400)]);
      final e = fireAndSettle(
        w,
        const Fire(weaponId: 'satellite', targetX: 200, targetY: 395),
      );
      expect(damageTo(e, 0), isNotEmpty);
    });
  });

  group('Rudal Pemburu', () {
    test('chases the chosen target, not the nearest enemy', () {
      final w = world([
        UnitPlacement(0, 200, 400),
        UnitPlacement(1, 500, 400),
        UnitPlacement(1, 1500, 400),
      ]);
      final target = w.units[2];
      final e = fireAndSettle(
        w,
        Fire(
          weaponId: 'homingMissile',
          angleDeg: 60,
          powerPercent: 50,
          targetX: target.centerX.round(),
          targetY: target.centerY.round(),
        ),
      );
      expect(damageTo(e, 2), isNotEmpty);
      expect(damageTo(e, 1), isEmpty);
      expect((explosions(e).single.x - 1500).abs(), lessThan(50));
    });

    test('needs a target to fire', () {
      final w = world([UnitPlacement(0, 200, 400), UnitPlacement(1, 900, 400)]);
      toAction(w);
      final e = w.step(const [
        Fire(weaponId: 'homingMissile', angleDeg: 60, powerPercent: 50),
      ]);
      expect(e.whereType<WeaponUsed>(), isEmpty);
      expect(w.projectiles, isEmpty);
    });

    test('burns out and falls when it cannot reach its target in time', () {
      final w = world([
        UnitPlacement(0, 200, 400),
        UnitPlacement(1, 1800, 400),
      ]);
      toAction(w);
      // Circling a point in open sky until the fuel runs out.
      w.step(const [
        Fire(
          weaponId: 'homingMissile',
          angleDeg: 80,
          powerPercent: 40,
          targetX: 400,
          targetY: 60,
        ),
      ]);
      final spec = Weapons.homingMissile.flight! as Homing;
      var burntOut = false;
      final events = <SimEvent>[];
      for (var i = 0; i < 2000 && w.projectiles.isNotEmpty; i++) {
        events.addAll(w.step(const []));
        if (w.projectiles.isNotEmpty && w.projectiles.first.mode == 2) {
          burntOut = true;
          expect(
            w.projectiles.first.ageTicks,
            greaterThanOrEqualTo(spec.delayTicks + spec.fuelTicks!),
          );
        }
      }
      expect(burntOut, isTrue);
      expect(explosions(events), isNotEmpty);
    });
  });

  test('Classic leaves them out; Chaos makes them unlimited', () {
    for (final weapon in [
      Weapons.bomber,
      Weapons.satellite,
      Weapons.homingMissile,
    ]) {
      expect(WeaponLoadout.classic.enabled(weapon), isFalse);
      expect(WeaponLoadout.chaos.ammoOf(weapon), isNull);
      expect(WeaponLoadout.standard.ammoOf(weapon), 1);
    }
  });
}
