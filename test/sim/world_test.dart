import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/config/physics.dart';
import 'package:pawtillery/sim/events.dart';
import 'package:pawtillery/sim/inputs.dart';
import 'package:pawtillery/sim/physics.dart';
import 'package:pawtillery/sim/terrain_mask.dart';
import 'package:pawtillery/sim/world.dart';

void main() {
  test('stepping advances the tick', () {
    final world = _world(3);
    for (var i = 0; i < 60; i++) {
      world.step(const []);
    }
    expect(world.tick, 60);
  });

  test('initial wind is within range and depends on the seed', () {
    final winds = {for (var s = 0; s < 50; s++) _world(s).wind};
    expect(winds.every((w) => w >= PhysicsConfig.windMin && w <= PhysicsConfig.windMax),
        isTrue);
    expect(winds.length, greaterThan(5));
  });

  test('DebugExplode carves the mask and reports it', () {
    final world = _world(1);
    final events =
        world.step(const [DebugExplode(x: 300, y: 450, radius: 20)]);
    expect(world.terrain.isSolid(300, 450), isFalse);
    expect(world.terrain.isSolid(300, 450 + 21), isTrue);
    final e = events.single as ExplosionEvent;
    expect((e.x, e.y, e.radius), (300, 450, 20));
    expect(e.carved, const IntRect(280, 430, 321, 471));
  });

  test('a shot flies, explodes on the ground and rerolls the wind', () {
    final world = _world(5);
    final first = world.step(const [_fire]);
    expect(first.whereType<ProjectileLaunched>(), hasLength(1));
    expect(world.isProjectileInFlight, isTrue);

    // A second fire while in flight is ignored.
    world.step(const [_fire]);
    expect(world.projectiles, hasLength(1));

    final all = <SimEvent>[];
    for (var i = 0; i < 1000 && world.isProjectileInFlight; i++) {
      all.addAll(world.step(const []));
    }
    expect(world.isProjectileInFlight, isFalse);
    final explosion = all.whereType<ExplosionEvent>().single;
    expect(explosion.y, inInclusiveRange(400, 401));
    expect(world.terrain.isSolid(explosion.x, explosion.y), isFalse);
    expect(all.whereType<ProjectileRemoved>().single.outcome,
        FlightOutcome.hitTerrain);
    expect(all.whereType<WindChanged>(), hasLength(1));
  });

  group('determinism', () {
    int run(int seed, List<List<SimInput>> script) {
      final world = _world(seed);
      for (final inputs in script) {
        world.step(inputs);
      }
      return world.stateHash();
    }

    final script = <List<SimInput>>[
      const [_fire],
      for (var i = 0; i < 200; i++) const <SimInput>[],
      const [DebugExplode(x: 700, y: 420, radius: 40)],
      const [
        DebugFire(x: 1000, y: 100, angleDeg: 120, powerPercent: 55),
      ],
      for (var i = 0; i < 300; i++) const <SimInput>[],
    ];

    test('same seed and inputs give the same final hash', () {
      expect(run(42, script), run(42, script));
    });

    test('a different seed or input changes the hash', () {
      final base = run(42, script);
      expect(run(43, script), isNot(base));
      final tweaked = [...script]..[0] = const [
          DebugFire(x: 200, y: 300, angleDeg: 46, powerPercent: 60),
        ];
      expect(run(42, tweaked), isNot(base));
    });

    test('final hash is pinned across runs and devices', () {
      // Update only for an intended sim change, and note why in the commit.
      expect(run(42, script), _pinnedScriptHash);
    });
  });
}

const _fire = DebugFire(x: 200, y: 300, angleDeg: 45, powerPercent: 60);
const _pinnedScriptHash = 4148230390;

/// 2000 × 600 map, flat ground from y = 400 down.
SimWorld _world(int seed) => SimWorld(
      seed: seed,
      terrain: TerrainMask(2000, 600)..fillRect(0, 400, 2000, 200),
    );
