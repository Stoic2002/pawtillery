import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/config/weapons.dart';
import 'package:pawtillery/sim/events.dart';
import 'package:pawtillery/sim/inputs.dart';
import 'package:pawtillery/sim/match_setup.dart';
import 'package:pawtillery/sim/turn_manager.dart';
import 'package:pawtillery/sim/world.dart';

import 'sim_test_utils.dart';

/// Fires [fire] and steps until the turn has played out, calling [watch]
/// every tick; returns every event.
List<SimEvent> _fireWatching(
  SimWorld w,
  Fire fire,
  void Function() watch,
) {
  toAction(w);
  final events = <SimEvent>[...w.step([fire])];
  final n = w.turn.turnNumber;
  for (var i = 0; i < 5000; i++) {
    if (w.turn.turnNumber > n || w.turn.phase == TurnPhase.matchOver) break;
    watch();
    events.addAll(w.step(const []));
  }
  return events;
}

void main() {
  test('Roket Botol glances off the ground twice, then goes off once', () {
    final w = world(const [
      UnitPlacement(0, 300, 400),
      UnitPlacement(1, 1900, 400),
    ]);
    var bounces = 0;
    final e = _fireWatching(
      w,
      const Fire(weaponId: 'bottleRocket', angleDeg: 10, powerPercent: 43),
      () {
        for (final p in w.projectiles) {
          if (p.mode > bounces) bounces = p.mode;
        }
      },
    );
    expect(bounces, 2);
    expect(explosions(e), hasLength(1));
  });

  test('Ketapel Ganda goes through every pet in line', () {
    final w = world(const [
      UnitPlacement(0, 300, 400),
      UnitPlacement(1, 420, 400),
      UnitPlacement(1, 470, 400),
    ]);
    final e = fireAndSettle(
      w,
      const Fire(weaponId: 'twinSling', angleDeg: 0, powerPercent: 80),
    );
    for (final id in [1, 2]) {
      expect(
        damageTo(e, id).where((d) => d.cause == DamageCause.impact),
        isNotEmpty,
        reason: 'unit $id hit directly',
      );
    }
  });

  test('Kelapa rolls on from where it lands, then bursts', () {
    final w = world(const [
      UnitPlacement(0, 300, 400, familyId: 'monkey'),
      UnitPlacement(1, 1900, 400),
    ]);
    double? rollFrom;
    final e = _fireWatching(
      w,
      const Fire(weaponId: 'coconut', angleDeg: 50, powerPercent: 45),
      () {
        for (final p in w.projectiles) {
          if (p.mode == 1) rollFrom ??= p.x;
        }
      },
    );
    expect(rollFrom, isNotNull);
    final blast = explosions(e).single;
    expect(blast.x - rollFrom!, greaterThan(100), reason: 'rolled on');
  });

  test('Hujan Pot Bunga lands every pot on one spot, one after another', () {
    final w = world(const [
      UnitPlacement(0, 300, 400),
      UnitPlacement(1, 1900, 400),
    ]);
    final ticks = <int>[];
    final xs = <int>[];
    toAction(w);
    w.step(const [
      Fire(weaponId: 'flowerpotRain', targetX: 1000, targetY: 380),
    ]);
    for (var i = 0; i < 1500; i++) {
      for (final e in w.step(const [])) {
        if (e is ExplosionEvent) {
          ticks.add(w.tick);
          xs.add(e.x);
        }
      }
    }
    expect(xs, hasLength(5));
    expect(xs.every((x) => (x - 1000).abs() <= 10), isTrue, reason: '$xs');
    expect(ticks.toSet(), hasLength(5), reason: 'one after another');
  });

  test('hairball clumps stick and pop later; eggs bounce before they burst',
      () {
    expect(Weapons.hairballBomb.flight, isA<Sticky>());
    expect(Weapons.hairballBomb.fuseTicks, isNotNull);
    expect(Weapons.egg.flight, isA<Bouncy>());

    final w = world(const [
      UnitPlacement(0, 300, 400, familyId: 'cat'),
      UnitPlacement(1, 1900, 400),
    ]);
    var stuck = 0;
    final e = _fireWatching(
      w,
      const Fire(weaponId: 'hairball', angleDeg: 60, powerPercent: 50),
      () => stuck += w.projectiles.where((p) => p.stuckTo != null).length,
    );
    expect(stuck, greaterThan(0));
    expect(explosions(e).length, greaterThanOrEqualTo(4));
  });

  test('meteors leave small fires', () {
    final w = world(const [
      UnitPlacement(0, 300, 400),
      UnitPlacement(1, 1900, 400),
    ]);
    final e = fireAndSettle(
      w,
      const Fire(weaponId: 'meteorShower', targetX: 1000, targetY: 380),
    );
    expect(e.whereType<FireStarted>(), isNotEmpty);
  });

  test('poison gas keeps biting while a pet stays inside, 15 HP a turn at '
      'most, never the last HP', () {
    final w = world(const [
      UnitPlacement(0, 300, 400),
      UnitPlacement(1, 1000, 400),
    ]);
    toAction(w);
    final pet = w.units[1];
    // A cloud wide enough that the wind can't carry it off the pet.
    w.releaseGas(1000, 380, const GasCloud(radius: 600));
    for (var i = 0; i < 6 * 60; i++) {
      w.step(const []);
    }
    expect(pet.poisoned, isTrue);
    expect(pet.hp, 100 - GasConfig.insideMaxPerTurn);

    pet.hp = 2;
    toNextTurn(w);
    for (var i = 0; i < 6 * 60; i++) {
      w.step(const []);
    }
    expect(pet.hp, 1);
    expect(pet.alive, isTrue);
  });
}
