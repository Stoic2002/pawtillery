import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/config/weapons.dart';
import 'package:pawtillery/sim/events.dart';
import 'package:pawtillery/sim/inputs.dart';
import 'package:pawtillery/sim/match_setup.dart';
import 'package:pawtillery/sim/physics.dart';
import 'package:pawtillery/sim/projectile.dart';
import 'package:pawtillery/sim/rng.dart';
import 'package:pawtillery/sim/terrain_mask.dart';
import 'package:pawtillery/sim/turn_manager.dart';
import 'package:pawtillery/sim/unit.dart';
import 'package:pawtillery/sim/weapon_behaviors/flight_behavior.dart';
import 'package:pawtillery/sim/weapon_behaviors/sim_context.dart';
import 'package:pawtillery/sim/world.dart';

import 'sim_test_utils.dart';

void main() {
  group('shared arsenal', () {
    test('Granat Pantul bounces and explodes when the chosen fuse ends', () {
      final w = world([UnitPlacement(0, 200, 400), UnitPlacement(1, 1800, 400)]);
      toAction(w);
      w.step(const [
        Fire(weaponId: 'grenade', angleDeg: 60, powerPercent: 40, fuseTicks: 120),
      ]);
      expect(w.ammoLeft(0, Weapons.grenade), 4);
      var ticks = 0;
      final events = <SimEvent>[];
      while (explosions(events).isEmpty && ticks < 500) {
        events.addAll(w.step(const []));
        ticks++;
      }
      expect(ticks, inInclusiveRange(119, 121), reason: '2 s fuse');
      expect(explosions(events).single.radius, Weapons.grenade.radius);
    });

    test('grenade fuse is clamped to 1–5 s', () {
      final w = world([UnitPlacement(0, 200, 400), UnitPlacement(1, 1800, 400)]);
      toAction(w);
      w.step(const [
        Fire(weaponId: 'grenade', angleDeg: 90, powerPercent: 10, fuseTicks: 5),
      ]);
      // Spawned this tick; ticks from the next one.
      w.step(const []);
      expect(w.projectiles.single.fuseTicks, 59);
    });

    test('Bom Cluster explodes, then 5 bomblets explode', () {
      final w = world([UnitPlacement(0, 200, 400), UnitPlacement(1, 1800, 400)]);
      final e = fireAndSettle(w,
          const Fire(weaponId: 'cluster', angleDeg: 60, powerPercent: 60));
      final radii = explosions(e).map((x) => x.radius).toList();
      expect(radii.where((r) => r == Weapons.cluster.radius), hasLength(1));
      expect(radii.where((r) => r == Weapons.clusterBomblet.radius),
          hasLength(5));
    });

    test('Ketapel Ganda fires two nearly straight shots, 20 ticks apart', () {
      final w = world([UnitPlacement(0, 200, 400), UnitPlacement(1, 700, 400)]);
      toAction(w);
      final launches = <int>[];
      for (var t = 0; t < 120; t++) {
        final e = w.step(t == 0
            ? const [Fire(weaponId: 'twinSling', angleDeg: 0, powerPercent: 100)]
            : const []);
        if (e.whereType<ProjectileLaunched>().isNotEmpty) launches.add(t);
      }
      expect(launches, [0, 20]);
      expect(w.units[1].hp, lessThan(100), reason: 'flat shots hit the target');
    });

    test('Pukulan hits only the unit in front, hard, without digging', () {
      final w = world([
        UnitPlacement(0, 200, 400),
        UnitPlacement(1, 222, 400),
        UnitPlacement(1, 180, 400),
      ]);
      final before = solidCount(w.terrain);
      toAction(w);
      final e = w.step(const [Fire(weaponId: 'punch', angleDeg: 0)]);
      expect(damageTo(e, 1).single.amount, greaterThan(15));
      expect(damageTo(e, 2), isEmpty, reason: 'behind the puncher');
      expect(damageTo(e, 0), isEmpty, reason: 'never hurts the user');
      expect(w.units[1].vx, greaterThan(200), reason: 'big knockback');
      expect(solidCount(w.terrain), before);
    });

    test('Ranjau arms after one turn, then goes off when approached', () {
      final w = world([UnitPlacement(0, 200, 400), UnitPlacement(1, 1800, 400)]);
      final placed = fireAndSettle(w, const Fire(weaponId: 'mine'));
      expect(placed.whereType<MinePlaced>(), hasLength(1));
      expect(w.mines.single.grounded, isTrue);
      expect(explosions(placed), isEmpty,
          reason: 'not armed in the turn it was placed');
      // Next turn: the mine is armed and its owner is standing next to it.
      final next = runUntil(w, () => w.mines.isEmpty);
      expect(next.whereType<MineTriggered>(), hasLength(1));
      expect(explosions(next).single.radius, Weapons.mine.radius);
      expect(w.units[0].hp, lessThan(100));
    });

    test('Teleport moves the unit and ends the turn at once', () {
      final w = world([UnitPlacement(0, 200, 400), UnitPlacement(1, 1800, 400)]);
      toAction(w);
      w.step(const [Fire(weaponId: 'teleport', targetX: 1000, targetY: 200)]);
      expect(w.units[0].x, 1000);
      expect(w.turn.phase, TurnPhase.settling);
      runUntil(w, () => w.units[0].grounded);
      expect(w.units[0].y, 400, reason: 'falls to the ground');
    });

    test('Teleport into the ground is refused and costs nothing', () {
      final w = world([UnitPlacement(0, 200, 400), UnitPlacement(1, 1800, 400)]);
      toAction(w);
      w.step(const [Fire(weaponId: 'teleport', targetX: 1000, targetY: 500)]);
      expect(w.units[0].x, 200);
      expect(w.turn.phase, TurnPhase.action);
      expect(w.ammoLeft(0, Weapons.teleport), 2);
    });

    test('Lewati Giliran ends the turn with no action', () {
      final w = world([UnitPlacement(0, 200, 400), UnitPlacement(1, 1800, 400)]);
      toAction(w);
      final e = w.step(const [Fire(weaponId: 'skip')]);
      // Nothing is moving, so the turn finishes in the same tick.
      expect(w.turn.turnNumber, 2);
      expect(w.turn.activeTeam, 1);
      expect(e.whereType<ProjectileLaunched>(), isEmpty);
    });
  });

  group('ammo and signature rules', () {
    test('limited ammo runs out per team', () {
      final w = world([UnitPlacement(0, 200, 400), UnitPlacement(1, 1800, 400)]);
      for (var i = 0; i < 2; i++) {
        fireAndSettle(w,
            const Fire(weaponId: 'teleport', targetX: 600, targetY: 300));
        toNextTurn(w); // other team
      }
      expect(w.ammoLeft(0, Weapons.teleport), 0);
      expect(w.ammoLeft(1, Weapons.teleport), 2);
      expect(w.canUse(w.units[0], Weapons.teleport), isFalse);
      toAction(w);
      w.step(const [Fire(weaponId: 'teleport', targetX: 900, targetY: 300)]);
      expect(w.turn.phase, TurnPhase.action, reason: 'refused');
    });

    test('signature weapons: own family only, once per unit', () {
      final w = world([
        UnitPlacement(0, 200, 400, familyId: 'dog'),
        UnitPlacement(1, 1800, 400, familyId: 'monkey'),
      ]);
      expect(w.canUse(w.units[0], Weapons.coconut), isFalse);
      expect(w.canUse(w.units[0], Weapons.boneBoomerang), isTrue);
      toAction(w);
      w.step(const [Fire(weaponId: 'coconut', angleDeg: 45, powerPercent: 50)]);
      expect(w.turn.phase, TurnPhase.action, reason: 'not a monkey');
      w.step(const [
        Fire(weaponId: 'boneBoomerang', angleDeg: 0, powerPercent: 20),
      ]);
      expect(w.units[0].signatureUsed, isTrue);
      expect(w.canUse(w.units[0], Weapons.boneBoomerang), isFalse);
    });

    test('sub-munitions can never be fired directly', () {
      final w = world([UnitPlacement(0, 200, 400), UnitPlacement(1, 1800, 400)]);
      for (final id in ['clusterBomblet', 'hairballBomb', 'egg', 'seedMine']) {
        expect(w.canUse(w.units[0], Weapons.byId(id)), isFalse);
      }
    });
  });

  group('signature weapons', () {
    test('Hairball Cluster splits into 4 bombs without a main blast', () {
      final w = world([
        UnitPlacement(0, 200, 400, familyId: 'cat'),
        UnitPlacement(1, 1800, 400),
      ]);
      final e = fireAndSettle(w,
          const Fire(weaponId: 'hairball', angleDeg: 60, powerPercent: 60));
      expect(explosions(e).map((x) => x.radius).toList(),
          List.filled(4, Weapons.hairballBomb.radius));
    });

    test('Tulang Bumerang hits a unit going out and again coming back', () {
      final thrower = Unit(id: 0, team: 0, x: 100, y: 400);
      final target = Unit(id: 1, team: 1, x: 300, y: 400);
      final ctx = _FakeContext(flatMap(), [thrower, target]);
      final p = Projectile(
        id: 0,
        ownerId: 0,
        weapon: Weapons.boneBoomerang,
        x: thrower.centerX + 14,
        y: thrower.centerY,
        vx: 500,
        vy: 0,
      )..range = 400;
      final behavior = FlightBehavior.of(Weapons.boneBoomerang);
      FlightOutcome o;
      var ticks = 0;
      do {
        o = behavior.tick(p, ctx);
        ticks++;
      } while (o == FlightOutcome.flying && ticks < 1000);
      expect(o, FlightOutcome.finished);
      expect(ctx.strikes.map((s) => s.$1), [1, 1], reason: 'out and back');
      expect(ctx.strikes.first.$2, Weapons.boneBoomerang.maxDamage);
      expect(p.x, closeTo(thrower.centerX + 14, 2), reason: 'came back');
      expect(ctx.carves, isEmpty, reason: 'passes through terrain');
    });

    test('Wortel Bor tunnels about 200 px into the ground, then explodes',
        () {
      final t = flatMap(h: 1000);
      final w = world(
        [UnitPlacement(0, 1000, 400, familyId: 'rabbit'), UnitPlacement(1, 200, 400)],
        terrain: t,
        water: 990,
      );
      final e = fireAndSettle(w,
          const Fire(weaponId: 'drillCarrot', angleDeg: 270, powerPercent: 30));
      final blast = explosions(e).single;
      expect(blast.radius, Weapons.drillCarrot.radius);
      expect(blast.y, inInclusiveRange(590, 620));
      expect(t.isSolid(1000, 500), isFalse, reason: 'tunnel');
      expect(e.whereType<TerrainCarved>().length, greaterThan(5));
    });

    test('Serangan Telur drops 5 eggs around the chosen column', () {
      final w = world([
        UnitPlacement(0, 200, 400, familyId: 'bird'),
        UnitPlacement(1, 1800, 400),
      ]);
      final e = fireAndSettle(w,
          const Fire(weaponId: 'eggStrike', targetX: 1000, targetY: 100));
      final blasts = explosions(e).toList();
      expect(blasts, hasLength(5));
      for (final b in blasts) {
        expect(b.x, inInclusiveRange(910, 1090));
        expect(b.y, inInclusiveRange(398, 402));
      }
    });

    test('Biji Ranjau scatters 3 small mines instead of exploding', () {
      final w = world([
        UnitPlacement(0, 200, 400, familyId: 'hamster'),
        UnitPlacement(1, 1800, 400),
      ]);
      final e = fireAndSettle(w,
          const Fire(weaponId: 'seedMines', angleDeg: 60, powerPercent: 60));
      expect(explosions(e), isEmpty);
      expect(w.mines, hasLength(3));
      expect(w.mines.every((m) => m.weapon == Weapons.seedMine), isTrue);
    });

    test('Bebek Peledak walks to an enemy and explodes on contact', () {
      final w = world([
        UnitPlacement(0, 200, 400, familyId: 'duck'),
        UnitPlacement(1, 400, 400),
      ]);
      final e = fireAndSettle(w, const Fire(weaponId: 'boomDuck', angleDeg: 0));
      expect(e.whereType<ProjectileRemoved>().single.outcome,
          FlightOutcome.hitUnit);
      expect(w.units[1].hp, lessThan(100));
    });

    test('Bebek Peledak with nobody around explodes after 5 s', () {
      final w = world([
        UnitPlacement(0, 200, 400, familyId: 'duck'),
        UnitPlacement(1, 1800, 400),
      ]);
      toAction(w);
      w.step(const [Fire(weaponId: 'boomDuck', angleDeg: 0)]);
      var ticks = 0;
      while (w.projectiles.isNotEmpty || ticks == 0) {
        w.step(const []);
        ticks++;
      }
      expect(ticks, inInclusiveRange(299, 301));
    });

    test('Kokok Kejut knocks back everyone nearby, never the user', () {
      final w = world([
        UnitPlacement(0, 500, 400, familyId: 'chicken'),
        UnitPlacement(1, 580, 400),
        UnitPlacement(1, 800, 400),
      ]);
      final before = solidCount(w.terrain);
      toAction(w);
      final e = w.step(const [Fire(weaponId: 'startleCrow')]);
      expect(damageTo(e, 1).single.amount,
          inInclusiveRange(1, Weapons.startleCrow.maxDamage));
      expect(damageTo(e, 2), isEmpty, reason: 'outside 120 px');
      expect(damageTo(e, 0), isEmpty);
      expect(w.units[1].vx, greaterThan(100));
      expect(solidCount(w.terrain), before, reason: 'no terrain damage');
    });

    test('Benteng builds a 20 × 60 wall, but not on top of a unit', () {
      final w = world([
        UnitPlacement(0, 200, 400, familyId: 'turtle'),
        UnitPlacement(1, 1800, 400),
      ]);
      expect(w.isValidTarget(w.units[0], Weapons.fortress, 200, 380), isFalse);
      final before = solidCount(w.terrain);
      toAction(w);
      final e = w.step(const [
        Fire(weaponId: 'fortress', targetX: 600, targetY: 370),
      ]);
      expect(e.whereType<TerrainAdded>().single.area,
          const IntRect(590, 340, 610, 400));
      expect(solidCount(w.terrain) - before, 20 * 60);
    });

    test('Seruduk digs through a wall and rams the first unit', () {
      final t = flatMap()..fillRect(250, 300, 20, 100); // wall in the way
      final w = world([
        UnitPlacement(0, 200, 400, familyId: 'goat'),
        UnitPlacement(1, 320, 400),
      ], terrain: t);
      final e = fireAndSettle(w, const Fire(weaponId: 'headbutt', angleDeg: 0));
      expect(damageTo(e, 1).first.amount, Weapons.headbutt.maxDamage);
      expect(t.isSolid(260, 390), isFalse, reason: 'tunnel through the wall');
      expect(w.units[0].x, greaterThan(270));
      expect(w.units[0].x, lessThanOrEqualTo(350));
    });

    test('Kelapa Jatuh: heavy, ignores wind, big blast', () {
      final w = world([
        UnitPlacement(0, 200, 400, familyId: 'monkey'),
        UnitPlacement(1, 1800, 400),
      ]);
      final e = fireAndSettle(w,
          const Fire(weaponId: 'coconut', angleDeg: 60, powerPercent: 60));
      expect(explosions(e).single.radius, 60);
      final t = flatMap();
      double landX(WeaponDef weapon) {
        final path = ProjectilePhysics.predict(
          weapon: weapon,
          x: 200,
          y: 380,
          angleDeg: 60,
          powerPercent: 60,
          terrain: t,
          waterLevel: 560,
        );
        return path[path.length - 2];
      }

      expect(landX(Weapons.coconut), lessThan(landX(Weapons.rock)));
      expect(Weapons.coconut.affectedByWind, isFalse);
    });
  });

  group('determinism with every weapon', () {
    // Turn order: cat, dog, hamster, duck, cat, dog, hamster, duck.
    const fires = [
      Fire(weaponId: 'hairball', angleDeg: 70, powerPercent: 60),
      Fire(weaponId: 'boneBoomerang', angleDeg: 180, powerPercent: 80),
      Fire(weaponId: 'seedMines', angleDeg: 60, powerPercent: 50),
      Fire(weaponId: 'boomDuck', angleDeg: 180),
      Fire(weaponId: 'grenade', angleDeg: 50, powerPercent: 55, fuseTicks: 90),
      Fire(weaponId: 'cluster', angleDeg: 120, powerPercent: 60),
      Fire(weaponId: 'mine'),
      Fire(weaponId: 'twinSling', angleDeg: 170, powerPercent: 90),
    ];

    /// Plays one weapon per turn: wait for the action phase, walk a little,
    /// fire, then wait for the next turn. Driven by sim state, so it is as
    /// deterministic as a fixed script but robust to timing changes.
    int run() {
      final w = SimWorld.withUnits(
        seed: 99,
        terrain: flatMap()..fillRect(900, 250, 200, 150),
        waterLevel: 560,
        teamCount: 2,
        placements: const [
          UnitPlacement(0, 300, 400, familyId: 'cat'),
          UnitPlacement(0, 600, 400, familyId: 'hamster'),
          UnitPlacement(1, 1400, 400, familyId: 'dog'),
          UnitPlacement(1, 1700, 400, familyId: 'duck'),
        ],
        timings: testTimings,
      );
      final used = <String>[];
      for (final fire in fires) {
        toAction(w);
        for (var i = 0; i < 10; i++) {
          w.step(const [Walk(1)]);
        }
        used.addAll(w.step([fire]).whereType<WeaponUsed>().map((e) => e.weaponId));
        toNextTurn(w);
      }
      expect(used, [for (final f in fires) f.weaponId]);
      return w.stateHash();
    }

    test('same inputs, same hash', () => expect(run(), run()));

    test('hash is pinned', () => expect(run(), _pinnedWeaponsHash));
  });
}

// Re-pinned 2026-10-20 (three times): the hash now also covers the bomber,
// satellite and missile (4107600983 → 1977243991), the starter map objects
// (→ 3580160855), then dig mode and the sticky bomb (→ 2358037495). Same
// play each time: the previous layout still gives the previous pin.
// Re-pinned 2026-10-21 (→ 3954486270): turns now hold for 2 s after the
// last hit, knocked-out pets fall during that hold, and the storm cloud
// and satellite take longer to arrive, so the play itself changed.
const _pinnedWeaponsHash = 3954486270;

/// Minimal [SimContext] that records what a behaviour does.
class _FakeContext implements SimContext {
  _FakeContext(this.terrain, this.units);

  @override
  final TerrainMask terrain;
  @override
  final List<Unit> units;
  @override
  int get waterLevel => 1 << 30;
  @override
  int get wind => 0;
  @override
  final SimRng rng = SimRng(1);

  final strikes = <(int, int)>[];
  final carves = <(int, int)>[];

  @override
  void strikeUnit(Unit u, int damage, double dx, double dy, double k,
          {int? sourceId}) =>
      strikes.add((u.id, damage));
  @override
  void carveTunnel(int x, int y, int r) => carves.add((x, y));
  @override
  void addGround(int x, int y, int radius) {}
  @override
  void explode(double x, double y, WeaponDef weapon, {int? sourceId}) {}
  @override
  void spawnProjectile(Projectile p) {}
  @override
  int nextProjectileId() => 0;
  @override
  void spawnMine(WeaponDef w, double x, double y, double vx, double vy,
      {int? ownerId}) {}
}
