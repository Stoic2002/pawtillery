import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/config/weapons.dart';
import 'package:pawtillery/sim/events.dart';
import 'package:pawtillery/sim/inputs.dart';
import 'package:pawtillery/sim/match_setup.dart';
import 'package:pawtillery/sim/turn_manager.dart';
import 'package:pawtillery/sim/world.dart';

import 'sim_test_utils.dart';

SimWorld _duel() =>
    world([UnitPlacement(0, 200, 400), UnitPlacement(1, 900, 400)]);

Iterable<UnitDamaged> _burns(List<SimEvent> e, int unitId) =>
    damageTo(e, unitId).where((d) => d.cause == DamageCause.fire);

void main() {
  group('Napalm', () {
    test('a shot leaves patches of fire on the ground', () {
      final w = _duel();
      final e = fireAndSettle(w,
          const Fire(weaponId: 'napalm', angleDeg: 60, powerPercent: 60));
      expect(e.whereType<FireStarted>(), isNotEmpty);
      expect(w.fires, isNotEmpty);
      for (final f in w.fires) {
        expect(f.y, 400, reason: 'on the surface');
      }
    });

    test('fire hurts a pet touching it once a turn, then burns out', () {
      final w = _duel();
      toAction(w);
      w.ignite(905, 395, const Ignite(patches: 1, spread: 0));
      final first = <SimEvent>[];
      for (var i = 0; i < 30; i++) {
        first.addAll(w.step(const []));
      }
      expect(_burns(first, 1).single.amount, FireConfig.damage);

      final rest = <SimEvent>[];
      for (var turn = 0; turn < FireConfig.turns; turn++) {
        rest.addAll(toNextTurn(w));
      }
      expect(_burns(rest, 1).length, FireConfig.turns - 1,
          reason: 'once in each later turn while it burns');
      expect(w.fires, isEmpty);
      expect(rest.whereType<FireOut>(), hasLength(1));
    });

    test('fire drops with the ground under it and drowns in water', () {
      final w = _duel();
      toAction(w);
      w.ignite(600, 395, const Ignite(patches: 1, spread: 0));
      final patch = w.fires.single;
      // Blow the ground away to the water.
      for (var y = 380; y < 600; y += 6) {
        w.terrain.carveCircle(patch.x, y, 12);
      }
      final e = <SimEvent>[];
      for (var i = 0; i < 120 && w.fires.isNotEmpty; i++) {
        e.addAll(w.step(const []));
      }
      expect(w.fires, isEmpty);
      expect(e.whereType<FireOut>(), hasLength(1));
    });
  });

  group('Bom Es', () {
    test('a frozen pet sits its next turn out, then thaws', () {
      final w = _duel();
      toAction(w);
      w.freeze(900, 390, Weapons.iceBomb, const Freeze(radius: 55));
      expect(w.units[1].frozen, isTrue);
      expect(w.units[0].frozen, isFalse, reason: 'far away');
      expect(w.units[1].hp, 100 - Weapons.iceBomb.maxDamage);

      final e = toNextTurn(w);
      expect(e.whereType<UnitFrozen>(), isEmpty, reason: 'already reported');
      expect(w.turn.activeUnitId, 1);
      final skipped = runUntil(w, () => w.turn.phase != TurnPhase.turnStart);
      expect(w.turn.phase, TurnPhase.settling, reason: 'no action phase');
      expect(w.frozenSkip, isTrue);
      expect(skipped.whereType<UnitThawed>().single.skippedTurn, isTrue);
      expect(w.units[1].frozen, isFalse);

      toNextTurn(w);
      expect(w.turn.activeUnitId, 0);
      expect(w.frozenSkip, isFalse);
    });

    test('the cold puts fire out, and fire thaws a frozen pet', () {
      final w = _duel();
      toAction(w);
      w.ignite(600, 395, const Ignite(patches: 1, spread: 0));
      w.freeze(600, 390, Weapons.iceBomb, const Freeze(radius: 55));
      expect(w.fires, isEmpty);

      w.freeze(900, 390, Weapons.iceBomb, const Freeze(radius: 55));
      expect(w.units[1].frozen, isTrue);
      w.ignite(905, 395, const Ignite(patches: 1, spread: 0));
      final e = w.step(const []);
      expect(e.whereType<UnitThawed>().single.skippedTurn, isFalse);
      expect(w.units[1].frozen, isFalse);
    });

    test('a shot freezes pets where it lands', () {
      final w = _duel();
      final e = fireAndSettle(w,
          const Fire(weaponId: 'iceBomb', angleDeg: 60, powerPercent: 60));
      expect(e.whereType<IceBurst>(), hasLength(1));
    });
  });
}
