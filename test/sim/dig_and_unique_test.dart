import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/config/weapons.dart';
import 'package:pawtillery/net/protocol.dart';
import 'package:pawtillery/sim/events.dart';
import 'package:pawtillery/sim/inputs.dart';
import 'package:pawtillery/sim/match_setup.dart';
import 'package:pawtillery/sim/turn_manager.dart';

import 'sim_test_utils.dart';

void main() {
  group('Cakar Gali dig mode', () {
    test('digs straight down into flat ground, steered by the player', () {
      final w = world([
        UnitPlacement(0, 200, 400),
        UnitPlacement(1, 1800, 400),
      ]);
      toAction(w);
      final e = <SimEvent>[
        ...w.step(const [Fire(weaponId: 'digClaws')]),
      ];
      final u = w.units[0];
      expect(u.isDigging, isTrue);
      expect(w.turn.phase, TurnPhase.action, reason: 'the clock keeps going');
      // One second straight down.
      for (var i = 0; i < 60; i++) {
        e.addAll(w.step(const [Dig(270)]));
      }
      expect(u.y, greaterThan(450), reason: 'below the surface at 400');
      expect(w.terrain.isSolid(200, 430), isFalse, reason: 'a shaft');
      // Then sideways.
      final x0 = u.x;
      for (var i = 0; i < 30; i++) {
        e.addAll(w.step(const [Dig(0)]));
      }
      expect(u.x, greaterThan(x0 + 20));
      expect(e.whereType<UnitDamaged>(), isEmpty);
    });

    test('without input it holds still; Done ends it and the retreat '
        'starts', () {
      final w = world([
        UnitPlacement(0, 200, 400),
        UnitPlacement(1, 1800, 400),
      ]);
      toAction(w);
      w.step(const [Fire(weaponId: 'digClaws')]);
      for (var i = 0; i < 20; i++) {
        w.step(const [Dig(270)]);
      }
      final y = w.units[0].y;
      for (var i = 0; i < 30; i++) {
        w.step(const []);
      }
      expect(w.units[0].y, y, reason: 'held in its tunnel');
      w.step(const [StopDigging()]);
      expect(w.units[0].isDigging, isFalse);
      expect(w.turn.phase, TurnPhase.retreat);
      // Walking and jumping work again in the retreat.
      expect(w.turn.allowsMovement, isTrue);
    });

    test('it runs out of time (or distance) by itself', () {
      final w = world([
        UnitPlacement(0, 200, 400),
        UnitPlacement(1, 1800, 400),
      ]);
      toAction(w);
      w.step(const [Fire(weaponId: 'digClaws')]);
      final spec = Weapons.digClaws.delivery as DigMode;
      var travelled = 0.0;
      final y0 = w.units[0].y;
      for (var i = 0; i < spec.durationTicks + 5; i++) {
        w.step(const [Dig(270)]);
      }
      travelled = w.units[0].y - y0;
      expect(w.units[0].isDigging, isFalse);
      expect(w.turn.phase, TurnPhase.retreat);
      expect(travelled, lessThanOrEqualTo(spec.maxDistance + 1));
    });

    test('never digs into the water', () {
      final w = world([
        UnitPlacement(0, 200, 400),
        UnitPlacement(1, 1800, 400),
      ]);
      toAction(w);
      w.step(const [Fire(weaponId: 'digClaws')]);
      for (var i = 0; i < 240; i++) {
        w.step(const [Dig(270)]);
      }
      expect(w.units[0].y, lessThan(560));
      expect(w.units[0].alive, isTrue);
    });
  });

  test('Lubang Hitam pulls a nearby pet in before it collapses', () {
    final w = world([UnitPlacement(0, 200, 400), UnitPlacement(1, 700, 400)]);
    toAction(w);
    // Lob it to land about 100 px short of the enemy.
    final e = <SimEvent>[
      ...w.step(const [
        Fire(weaponId: 'blackHole', angleDeg: 45, powerPercent: 58),
      ]),
    ];
    final x0 = w.units[1].x;
    var hole = -1.0;
    for (var i = 0; i < 600 && w.turn.turnNumber == 1; i++) {
      e.addAll(w.step(const []));
      if (w.projectiles.isNotEmpty && w.projectiles.first.mode == 1) {
        hole = w.projectiles.first.x;
      }
    }
    expect(hole, greaterThan(0), reason: 'it became a vortex');
    final blast = explosions(e).single;
    expect(blast.radius, Weapons.blackHole.radius);
    // The enemy was dragged towards the hole.
    expect((w.units[1].x - hole).abs(), lessThan((x0 - hole).abs()));
  });

  test('Bom Lengket sticks to the pet it hits and goes off on it', () {
    final w = world([UnitPlacement(0, 200, 400), UnitPlacement(1, 300, 400)]);
    toAction(w);
    w.step(const [Fire(weaponId: 'stickyBomb', angleDeg: 0, powerPercent: 60)]);
    // The flat shot runs into the enemy at body height.
    var stuck = false;
    final e = <SimEvent>[];
    for (var i = 0; i < 400 && w.turn.turnNumber == 1; i++) {
      e.addAll(w.step(const []));
      if (w.projectiles.isNotEmpty && w.projectiles.first.stuckTo == 1) {
        // From the tick after it hit, it rides on the pet.
        if (stuck) expect(w.projectiles.first.x, w.units[1].centerX);
        stuck = true;
      }
    }
    expect(stuck, isTrue);
    expect(damageTo(e, 1).first.amount, Weapons.stickyBomb.maxDamage);
  });

  test('Tanah Liat builds ground, but never inside a pet', () {
    final w = world([UnitPlacement(0, 200, 400), UnitPlacement(1, 700, 400)]);
    final before = solidCount(w.terrain);
    final e = fireAndSettle(
      w,
      const Fire(weaponId: 'clay', angleDeg: 50, powerPercent: 60),
    );
    expect(e.whereType<TerrainAdded>(), hasLength(1));
    expect(solidCount(w.terrain), greaterThan(before));
    expect(explosions(e), isEmpty);
    for (final u in w.units) {
      for (var y = u.y.round() - u.stats.bodyHeight; y < u.y; y++) {
        expect(w.terrain.isSolid(u.x.floor(), y), isFalse);
      }
    }
  });

  test('Tukar Tempat swaps places with the tapped pet', () {
    final w = world([UnitPlacement(0, 200, 400), UnitPlacement(1, 900, 400)]);
    toAction(w);
    final other = w.units[1];
    expect(w.isValidTarget(w.units[0], Weapons.swap, 300, 380), isFalse);
    final e = w.step([
      Fire(
        weaponId: 'swap',
        targetX: other.centerX.round(),
        targetY: other.centerY.round(),
      ),
    ]);
    expect(e.whereType<UnitTeleported>(), hasLength(2));
    expect(w.units[0].x, 900);
    expect(w.units[1].x, 200);
    expect(w.turn.turnNumber, 2, reason: 'it ends the turn');
  });

  test('dig inputs survive the wire', () {
    final m =
        decodeMessage(
              encodeMessage(
                const TicksMsg(
                  from: 1,
                  frames: [
                    [Dig(270), StopDigging()],
                  ],
                ),
              ),
            )!
            as TicksMsg;
    expect((m.frames.single.first as Dig).angleDeg, 270);
    expect(m.frames.single.last, isA<StopDigging>());
    expect(
      decodeMessage('{"t":"ticks","from":1,"n":1,"in":[[0,[3,400]]]}'),
      isNull,
    );
  });
}
