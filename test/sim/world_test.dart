import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/config/units.dart';
import 'package:pawtillery/sim/events.dart';
import 'package:pawtillery/sim/inputs.dart';
import 'package:pawtillery/sim/match_setup.dart';
import 'package:pawtillery/sim/physics.dart';
import 'package:pawtillery/sim/terrain_mask.dart';
import 'package:pawtillery/sim/turn_manager.dart';
import 'package:pawtillery/sim/world.dart';

const _timings = TurnTimings(
  bannerTicks: 2,
  turnTicks: 60,
  retreatTicks: 30,
  settleTimeoutTicks: 600,
);
const _water = 560;

/// 2000 × 600 map, flat ground with its surface at y = 400.
TerrainMask _flat() => TerrainMask(2000, 600)..fillRect(0, 400, 2000, 200);

/// Like [_flat] but with bottomless pits at x 1100–1300 and 100–300.
TerrainMask _pits() {
  final t = _flat();
  for (var y = 400; y < 600; y++) {
    t.data.fillRange(y * 2000 + 100, y * 2000 + 300, 0);
    t.data.fillRange(y * 2000 + 1100, y * 2000 + 1300, 0);
  }
  return t;
}

SimWorld _world(List<(int, int, int)> placements,
        {int teams = 2, TerrainMask? terrain}) =>
    SimWorld.withUnits(
      seed: 7,
      terrain: terrain ?? _flat(),
      waterLevel: _water,
      teamCount: teams,
      placements: [for (final (t, x, y) in placements) UnitPlacement(t, x, y)],
      timings: _timings,
    );

/// Steps with no input until [done] or [limit] ticks; returns all events.
List<SimEvent> _runUntil(SimWorld w, bool Function() done,
    {int limit = 5000}) {
  final events = <SimEvent>[];
  for (var i = 0; i < limit && !done(); i++) {
    events.addAll(w.step(const []));
  }
  expect(done(), isTrue, reason: 'condition not reached in $limit ticks');
  return events;
}

void _toAction(SimWorld w) =>
    _runUntil(w, () => w.turn.phase == TurnPhase.action);

void _toNextTurn(SimWorld w) {
  final n = w.turn.turnNumber;
  _runUntil(w, () => w.turn.turnNumber > n || w.turn.phase == TurnPhase.matchOver);
}

const _fireDown = Fire(angleDeg: 270, powerPercent: 10, weaponId: 'rock');

void main() {
  final twoByTwo = [(0, 200, 400), (0, 500, 400), (1, 1200, 400), (1, 1600, 400)];

  group('turns', () {
    test('first turn: team 0, its first unit, banner then action', () {
      final w = _world(twoByTwo);
      expect(w.turn.phase, TurnPhase.turnStart);
      expect((w.turn.activeTeam, w.turn.activeUnitId), (0, 0));
      _toAction(w);
      expect(w.turn.clockTicks, _timings.turnTicks);
    });

    test('no movement during the banner', () {
      final w = _world(twoByTwo);
      w.step(const [Walk(1)]);
      expect(w.units[0].x, 200);
    });

    test('only the active unit walks', () {
      final w = _world(twoByTwo);
      _toAction(w);
      for (var i = 0; i < 30; i++) {
        w.step(const [Walk(1)]);
      }
      expect(w.units[0].x, 200 + (UnitConfig.walkSpeed / 2).floor());
      expect(w.units[1].x, 500);
    });

    test('timer runs out → next team; units take turns round-robin', () {
      final w = _world(twoByTwo);
      final order = <int>[w.turn.activeUnitId];
      for (var i = 0; i < 4; i++) {
        _toNextTurn(w);
        order.add(w.turn.activeUnitId);
      }
      expect(order, [0, 2, 1, 3, 0]);
    });

    test('dead units are skipped', () {
      final w = _world(twoByTwo);
      w.units[2]
        ..alive = false
        ..hp = 0;
      _toNextTurn(w);
      expect(w.turn.activeUnitId, 3);
    });

    test('firing stops the clock, starts retreat, and allows one shot', () {
      final w = _world(twoByTwo);
      _toAction(w);
      final events = w.step(const [_fireDown]);
      expect(events.whereType<ProjectileLaunched>(), hasLength(1));
      expect(w.turn.phase, TurnPhase.retreat);
      expect(w.turn.allowsFire, isFalse);
      expect(w.turn.allowsMovement, isTrue);
      w.step(const [_fireDown]);
      expect(w.projectiles.length + _explosions(events), lessThanOrEqualTo(1));
      _runUntil(w, () => w.turn.phase == TurnPhase.settling);
      expect(w.turn.phaseTicks, lessThan(5), reason: 'retreat lasts 3 s');
    });

    test('new wind every turn, always within -10..10', () {
      final w = _world(twoByTwo);
      final winds = <int>{};
      for (var i = 0; i < 20; i++) {
        expect(w.wind, inInclusiveRange(-10, 10));
        winds.add(w.wind);
        _toNextTurn(w);
      }
      expect(winds.length, greaterThan(3));
    });
  });

  group('damage', () {
    test('shooting at your own feet hurts you and knocks you back', () {
      final w = _world(twoByTwo);
      _toAction(w);
      final events = <SimEvent>[...w.step(const [_fireDown])];
      events.addAll(_runUntil(w, () => w.turn.phase == TurnPhase.settling));
      final hits = events.whereType<UnitDamaged>().toList();
      expect(hits.map((e) => e.unitId), contains(0), reason: 'friendly fire');
      expect(hits.firstWhere((e) => e.unitId == 0).amount, greaterThan(20));
      expect(w.units[0].hp, lessThan(100));
      expect(w.units[2].hp, 100, reason: 'far away, untouched');
    });

    test('HP deaths wait until everything is at rest', () {
      final w = _world([(0, 200, 400), (1, 1200, 400)]);
      w.units[0].hp = 1;
      _toAction(w);
      final events = <SimEvent>[...w.step(const [_fireDown])];
      events.addAll(_runUntil(w, () => w.turn.phase == TurnPhase.settling));
      expect(w.units[0].hp, lessThanOrEqualTo(0));
      expect(w.units[0].alive, isTrue, reason: 'not resolved yet');
      events.addAll(
          _runUntil(w, () => w.turn.phase == TurnPhase.matchOver));
      expect(w.units[0].alive, isFalse);
      expect(events.whereType<UnitDied>().single.cause, DeathCause.hp);
      expect(events.whereType<MatchEnded>().single.winnerTeam, 1);
    });
  });

  group('after a hit', () {
    test('the next turn waits a moment so everyone sees the damage', () {
      final w = _world(twoByTwo);
      _toAction(w);
      var lastHit = -1;
      var next = w.step(const [_fireDown]);
      final turn = w.turn.turnNumber;
      while (w.turn.turnNumber == turn) {
        if (next.whereType<UnitDamaged>().isNotEmpty) lastHit = w.tick;
        next = w.step(const []);
      }
      expect(lastHit, greaterThan(0));
      expect(w.tick - lastHit,
          greaterThanOrEqualTo(_timings.hitHoldTicks));
    });

    test('a knocked-out pet falls before the next turn starts', () {
      final w = _world([(0, 200, 400), (0, 1600, 400), (1, 1200, 400)]);
      w.units[0].hp = 1;
      _toAction(w);
      w.step(const [_fireDown]);
      _runUntil(w, () => !w.units[0].alive);
      expect(w.turn.phase, TurnPhase.settling,
          reason: 'still on the shot, not the next banner');
    });
  });

  group('match end', () {
    test('drowning kills at once and the last team standing wins', () {
      // Team 1's unit starts above a pit and falls into the water.
      final w = _world([(0, 600, 400), (1, 1200, 380)], terrain: _pits());
      final events = <SimEvent>[];
      events.addAll(w.step(const []));
      events.addAll(_runUntil(w, () => !w.units[1].alive, limit: 120));
      expect(events.whereType<UnitDied>().single.cause, DeathCause.water);
      events.addAll(_runUntil(w, () => w.turn.phase == TurnPhase.matchOver));
      expect(w.turn.winnerTeam, 0);
      expect(events.whereType<MatchEnded>().single.winnerTeam, 0);
    });

    test('everyone dying together is a draw', () {
      final w = _world([(0, 200, 380), (1, 1200, 380)], terrain: _pits());
      final events = _runUntil(w, () => w.turn.phase == TurnPhase.matchOver);
      expect(events.whereType<MatchEnded>().single.winnerTeam, isNull);
      expect(w.turn.winnerTeam, isNull);
    });

    test('a shot off the map edge does nothing', () {
      final w = _world(twoByTwo);
      _toAction(w);
      final events = <SimEvent>[
        ...w.step(const [Fire(angleDeg: 180, powerPercent: 100, weaponId: 'rock')]),
      ];
      events.addAll(_runUntil(w, () => w.projectiles.isEmpty));
      expect(events.whereType<ProjectileRemoved>().single.outcome,
          FlightOutcome.outOfBounds);
      expect(events.whereType<ExplosionEvent>(), isEmpty);
    });
  });

  group('spawning and determinism', () {
    TerrainMask hills() {
      final t = TerrainMask(2400, 1200);
      for (var x = 0; x < 2400; x++) {
        // Integer-only hills: plateaus every 300 px with gentle ramps.
        final band = (x ~/ 300) % 3;
        final top = 600 + band * 80;
        t.fillRect(x, top, 1, 1200 - top);
      }
      return t;
    }

    SimWorld newMatch(int seed) => SimWorld.newMatch(
          seed: seed,
          terrain: hills(),
          waterLevel: 1120,
          rosters: const [
            [
              UnitSpec(familyId: 'cat', breedId: 'catKampung'),
              UnitSpec(familyId: 'rabbit', breedId: 'rabbitRex'),
              UnitSpec(familyId: 'chicken', breedId: 'chickenSilkie'),
            ],
            [
              UnitSpec(familyId: 'dog', breedId: 'dogCorgi'),
              UnitSpec(familyId: 'turtle', breedId: 'turtleAmbon'),
              UnitSpec(familyId: 'monkey', breedId: 'monkeyLutung'),
            ],
          ],
          timings: _timings,
        );

    test('units spawn on dry ground, 150 px apart, from the seed', () {
      final w = newMatch(11);
      expect(w.units, hasLength(6));
      for (final u in w.units) {
        expect(w.terrain.isSolid(u.x.toInt(), u.y.toInt()), isTrue);
        expect(u.y, lessThan(1120));
        for (final v in w.units) {
          if (u == v) continue;
          final dx = u.x - v.x, dy = u.y - v.y;
          expect(dx * dx + dy * dy, greaterThanOrEqualTo(150 * 150));
        }
      }
      final again = newMatch(11);
      expect([for (final u in again.units) (u.x, u.y)],
          [for (final u in w.units) (u.x, u.y)]);
      expect([for (final u in newMatch(12).units) (u.x, u.y)],
          isNot([for (final u in w.units) (u.x, u.y)]));
    });

    List<List<SimInput>> script() => [
          for (var i = 0; i < 5; i++) const <SimInput>[],
          for (var i = 0; i < 40; i++) const [Walk(1)],
          const [Jump(JumpKind.forward)],
          for (var i = 0; i < 90; i++) const <SimInput>[],
          const [Fire(angleDeg: 60, powerPercent: 75, weaponId: 'rock')],
          for (var i = 0; i < 400; i++) const <SimInput>[],
          for (var i = 0; i < 20; i++) const [Walk(-1)],
          const [Jump(JumpKind.high)],
          const [Fire(angleDeg: 120, powerPercent: 55, weaponId: 'rock')],
          for (var i = 0; i < 600; i++) const <SimInput>[],
        ];

    int run(int seed, List<List<SimInput>> inputs) {
      final w = newMatch(seed);
      for (final tick in inputs) {
        w.step(tick);
      }
      return w.stateHash();
    }

    test('same seed and inputs give the same final hash', () {
      expect(run(42, script()), run(42, script()));
    });

    test('a different seed or input changes the hash', () {
      final base = run(42, script());
      expect(run(43, script()), isNot(base));
      final tweaked = script()
        ..[50] = const [Fire(angleDeg: 61, powerPercent: 75, weaponId: 'rock')];
      expect(run(42, tweaked), isNot(base));
    });

    test('final hash is pinned across runs and devices', () {
      // Update only for an intended sim change, and say why in the commit.
      expect(run(42, script()), _pinnedScriptHash);
    });
  });
}

int _explosions(List<SimEvent> e) => e.whereType<ExplosionEvent>().length;

// Re-pinned 2026-10-20 (three times): the hash now also covers the bomber,
// satellite and missile (2504866130 → 973916818), the starter map objects
// (→ 2080593234), then dig mode and the sticky bomb (→ 3568307282). Same
// play each time: the previous layout still gives the previous pin.
// Re-pinned 2026-10-21 (→ 264497019): turns now hold for 2 s after the
// last hit, knocked-out pets fall during that hold, and the storm cloud
// and satellite take longer to arrive, so the play itself changed.
// Then (→ 9395643) the hash also covers the grappling hook; same play.
// Then (→ 1282318523) it also covers fire, frozen pets and the satellite's
// beam count; same play.
// Then (→ 2120106523) it also covers shields and shotgun pulls; same play.
// Then (→ 607334203) it also covers poison gas and poisoned pets; same play.
// Then (→ 4033724603) the ammo of two new weapons; same play.
// Re-pinned 2026-10-29 (→ 282814417): play changed on purpose. Pets have
// their own, heavier gravity and walk slower; gas bites while a pet stays
// in it; damage was rebalanced (lower, lightning most); the bottle rocket,
// twin sling, coconut, flowerpots, meteors, eggs and hairball got their own
// mechanics; sudden death crumbles the ground instead of raising water.
const _pinnedScriptHash = 282814417;
