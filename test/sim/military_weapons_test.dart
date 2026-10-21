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
      expect(w.aircraft.single.dir, 1);
      // The turn waits for the plane and every bomb.
      while (w.aircraft.isNotEmpty || w.projectiles.isNotEmpty) {
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
      final b = w.aircraft.single;
      expect(b.dir, -1);
      expect(b.x, greaterThan(600));
    });
  });

  group('Serangan Satelit', () {
    test('marks the spot, then fires three slanted beams in turn', () {
      final w = world([UnitPlacement(0, 200, 400), UnitPlacement(1, 900, 400)]);
      toAction(w);
      final fired = w.step(const [
        Fire(weaponId: 'satellite', targetX: 905, targetY: 395),
      ]);
      expect(fired.whereType<WeaponUsed>(), isNotEmpty);
      expect(w.pendingStrikes.single.x, 905);
      final firedAt = w.tick;
      final spec = Weapons.satellite.delivery as OrbitalStrike;

      final events = <SimEvent>[];
      final beamTicks = <int>[];
      while (w.pendingStrikes.isNotEmpty) {
        final e = w.step(const []);
        if (e.whereType<SatelliteStruck>().isNotEmpty) beamTicks.add(w.tick);
        events.addAll(e);
      }
      expect(beamTicks, [
        for (var i = 0; i < spec.beams; i++)
          firedAt + spec.delayTicks + i * spec.intervalTicks,
      ]);
      final beams = events.whereType<SatelliteStruck>().toList();
      expect(beams.last.last, isTrue);
      for (final b in beams) {
        expect(b.x1, isNot(closeTo(b.x0, 20)), reason: 'slanted, not straight');
        expect(b.y1, lessThan(400 + spec.depth + 2),
            reason: 'only a short way into the ground');
      }
      // The middle beam lands on the pet; the others beside it miss.
      expect(damageTo(events, 1).single.amount, Weapons.satellite.maxDamage);
      expect(damageTo(events, 0), isEmpty);
      // Shallow channels: the ground deep below is untouched.
      expect(w.terrain.isSolid(905, 500), isTrue);
    });

    test('a pet standing between beams can take more than one', () {
      final w = world([UnitPlacement(0, 200, 400), UnitPlacement(1, 900, 400)]);
      final e = fireAndSettle(
        w,
        const Fire(weaponId: 'satellite', targetX: 918, targetY: 395),
      );
      expect(damageTo(e, 1).length, inInclusiveRange(1, 2));
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
    test('a jet fires it; it chases the chosen target, not the nearest '
        'enemy', () {
      final w = world([
        UnitPlacement(0, 200, 400),
        UnitPlacement(1, 500, 400),
        UnitPlacement(1, 1500, 400),
      ]);
      final target = w.units[2];
      toAction(w);
      w.step([
        Fire(
          weaponId: 'homingMissile',
          targetX: target.centerX.round(),
          targetY: target.centerY.round(),
        ),
      ]);
      final jet = w.aircraft.single;
      expect(jet.craft, CraftKind.jet);
      expect(jet.dir, 1);
      final e = [...runUntil(w, () => w.turn.turnNumber > 1)];
      expect(e.whereType<BombDropped>(), hasLength(1));
      expect(damageTo(e, 2), isNotEmpty);
      expect(damageTo(e, 1), isEmpty);
      expect((explosions(e).single.x - 1500).abs(), lessThan(50));
      expect(w.ammoLeft(0, Weapons.homingMissile), 0);
    });

    test('needs a target to fire', () {
      final w = world([UnitPlacement(0, 200, 400), UnitPlacement(1, 900, 400)]);
      toAction(w);
      final e = w.step(const [Fire(weaponId: 'homingMissile')]);
      expect(e.whereType<WeaponUsed>(), isEmpty);
      expect(w.aircraft, isEmpty);
    });

    test('burns out and falls when it cannot reach its target in time', () {
      final w = world([
        UnitPlacement(0, 200, 400),
        UnitPlacement(1, 1800, 400),
      ]);
      toAction(w);
      // A point high in open sky: it circles there until the fuel runs out.
      w.step(const [
        Fire(weaponId: 'homingMissile', targetX: 900, targetY: 150),
      ]);
      final spec = Weapons.missile.flight! as Homing;
      var burntOut = false;
      final events = <SimEvent>[];
      for (var i = 0; i < 3000; i++) {
        events.addAll(w.step(const []));
        if (w.projectiles.isNotEmpty && w.projectiles.first.mode == 2) {
          burntOut = true;
          expect(
            w.projectiles.first.ageTicks,
            greaterThanOrEqualTo(spec.delayTicks + spec.fuelTicks!),
          );
        }
        if (burntOut && w.projectiles.isEmpty) break;
      }
      expect(burntOut, isTrue);
      expect(explosions(events), isNotEmpty);
    });
  });

  group('Awan Petir', () {
    test('the cloud drifts in on the wind, then strikes after the delay', () {
      final w = world([UnitPlacement(0, 200, 400), UnitPlacement(1, 900, 400)]);
      toAction(w);
      final fired = w.step(const [
        Fire(weaponId: 'thunderCloud', targetX: 905, targetY: 300),
      ]);
      expect(fired.whereType<LightningStruck>(), isEmpty);
      final strike = w.pendingStrikes.single;
      expect(strike.fromDir, w.wind >= 0 ? -1 : 1);
      final delay = (Weapons.thunderCloud.delivery as Lightning).delayTicks;
      final events = <SimEvent>[];
      for (var i = 0; i < delay; i++) {
        events.addAll(w.step(const []));
      }
      expect(events.whereType<LightningStruck>(), hasLength(1));
      expect(damageTo(events, 1), isNotEmpty);
    });
  });

  test('Serangan Telur comes as a flock of the shooter\'s birds', () {
    final w = world([
      UnitPlacement(0, 200, 400, familyId: 'bird'),
      UnitPlacement(1, 1800, 400),
    ]);
    toAction(w);
    w.step(const [Fire(weaponId: 'eggStrike', targetX: 1000, targetY: 100)]);
    expect(w.aircraft.single.craft, CraftKind.flock);
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
