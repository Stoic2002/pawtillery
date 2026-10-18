import 'dart:collection';
import 'dart:typed_data';

import '../config/physics.dart';
import '../config/weapons.dart';
import 'events.dart';
import 'inputs.dart';
import 'physics.dart';
import 'projectile.dart';
import 'rng.dart';
import 'terrain_mask.dart';

/// Root of the deterministic simulation. Pure Dart: must never import
/// Flutter or Flame, read wall-clock time, or know the screen size.
class SimWorld {
  SimWorld({required this.seed, required this.terrain}) : rng = SimRng(seed) {
    _wind = _rollWind();
  }

  final int seed;
  final SimRng rng;
  final TerrainMask terrain;

  int _tick = 0;
  int get tick => _tick;

  /// Current wind, [PhysicsConfig.windMin]..[PhysicsConfig.windMax].
  late int _wind;
  int get wind => _wind;

  final List<Projectile> _projectiles = [];
  late final List<Projectile> projectiles = UnmodifiableListView(_projectiles);
  bool get isProjectileInFlight => _projectiles.isNotEmpty;

  int _nextProjectileId = 0;

  /// Advances exactly one fixed step (1 / [MatchDefaults.ticksPerSecond] s)
  /// and returns the events produced during it.
  List<SimEvent> step(List<SimInput> inputs) {
    _tick++;
    final events = <SimEvent>[];

    for (final input in inputs) {
      switch (input) {
        case DebugExplode(:final x, :final y, :final radius):
          _explode(x, y, radius, events);
        case DebugFire():
          if (_projectiles.isEmpty) _launch(input, events);
      }
    }

    if (_projectiles.isNotEmpty) {
      for (var i = _projectiles.length - 1; i >= 0; i--) {
        final p = _projectiles[i];
        final outcome = ProjectilePhysics.step(p, terrain, wind: _wind);
        if (outcome == FlightOutcome.flying) continue;
        _projectiles.removeAt(i);
        if (outcome == FlightOutcome.hitTerrain) {
          _explode(p.x.round(), p.y.round(), p.weapon.radius, events);
        }
        events.add(ProjectileRemoved(p.id, outcome));
      }
      // Stand-in for "turn ended" until the turn manager lands in M2.
      if (_projectiles.isEmpty) {
        _wind = _rollWind();
        events.add(WindChanged(_wind));
      }
    }
    return events;
  }

  void _launch(DebugFire input, List<SimEvent> events) {
    final p = ProjectilePhysics.launch(
      id: _nextProjectileId++,
      weapon: Weapons.rock,
      x: input.x.toDouble(),
      y: input.y.toDouble(),
      angleDeg: input.angleDeg,
      powerPercent: input.powerPercent,
    );
    _projectiles.add(p);
    events.add(ProjectileLaunched(p.id));
  }

  void _explode(int x, int y, int radius, List<SimEvent> events) {
    final carved = terrain.carveCircle(x, y, radius);
    events.add(ExplosionEvent(x: x, y: y, radius: radius, carved: carved));
  }

  int _rollWind() =>
      rng.nextIntInRange(PhysicsConfig.windMin, PhysicsConfig.windMax);

  /// Hash of the full simulation state, used by determinism tests. Stable
  /// across runs and devices (unlike `Object.hash`, which is seeded per run).
  int stateHash() {
    final h = StateHasher()
      ..add(seed)
      ..add(_tick)
      ..add(rng.state)
      ..add(_wind)
      ..add(_nextProjectileId)
      ..add(_projectiles.length);
    for (final p in _projectiles) {
      h
        ..add(p.id)
        ..add(p.ageTicks)
        ..addDouble(p.x)
        ..addDouble(p.y)
        ..addDouble(p.vx)
        ..addDouble(p.vy);
    }
    h.addBytes(terrain.data);
    return h.value;
  }
}

/// 32-bit FNV-1a, fed byte by byte.
class StateHasher {
  int _h = 0x811C9DC5;
  final ByteData _scratch = ByteData(8);

  int get value => _h;

  void add(int v) {
    for (var i = 0; i < 8; i++) {
      _byte((v >> (i * 8)) & 0xFF);
    }
  }

  void addDouble(double v) {
    _scratch.setFloat64(0, v);
    add(_scratch.getInt64(0));
  }

  void addBytes(Uint8List bytes) {
    for (final b in bytes) {
      _byte(b);
    }
  }

  void _byte(int b) {
    _h ^= b;
    _h = (_h * 0x01000193) & 0xFFFFFFFF;
  }
}
