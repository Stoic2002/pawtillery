import 'dart:collection';
import 'dart:math' show sqrt;
import 'dart:typed_data';

import '../config/physics.dart';
import '../config/units.dart';
import '../config/weapons.dart';
import 'damage.dart';
import 'events.dart';
import 'inputs.dart';
import 'physics.dart';
import 'projectile.dart';
import 'rng.dart';
import 'spawn.dart';
import 'terrain_mask.dart';
import 'trig.dart';
import 'turn_manager.dart';
import 'unit.dart';

/// Root of the deterministic simulation. Pure Dart: must never import
/// Flutter or Flame, read wall-clock time, or know the screen size.
class SimWorld {
  SimWorld._({
    required this.seed,
    required this.rng,
    required this.terrain,
    required this.waterLevel,
    required List<Unit> units,
    required int teamCount,
    required TurnTimings timings,
  })  : _units = units,
        turn = TurnManager(teamCount: teamCount, timings: timings) {
    _beginTurn(<SimEvent>[]);
  }

  /// A new match: [teamCount] × [unitsPerTeam] units on random flat ground.
  factory SimWorld.newMatch({
    required int seed,
    required TerrainMask terrain,
    required int waterLevel,
    required int teamCount,
    required int unitsPerTeam,
    TurnTimings timings = const TurnTimings(),
  }) {
    final rng = SimRng(seed);
    final points = findSpawnPoints(
      terrain: terrain,
      waterLevel: waterLevel,
      count: teamCount * unitsPerTeam,
      rng: rng,
    );
    final units = <Unit>[
      for (var t = 0; t < teamCount; t++)
        for (var k = 0; k < unitsPerTeam; k++)
          _unitAt(t * unitsPerTeam + k, t, points[t * unitsPerTeam + k]),
    ];
    return SimWorld._(
      seed: seed,
      rng: rng,
      terrain: terrain,
      waterLevel: waterLevel,
      units: units,
      teamCount: teamCount,
      timings: timings,
    );
  }

  /// Explicit placements as (team, x, feetY); for tests and scripted setups.
  factory SimWorld.withUnits({
    required int seed,
    required TerrainMask terrain,
    required int waterLevel,
    required int teamCount,
    required List<(int, int, int)> placements,
    TurnTimings timings = const TurnTimings(),
  }) {
    return SimWorld._(
      seed: seed,
      rng: SimRng(seed),
      terrain: terrain,
      waterLevel: waterLevel,
      units: [
        for (var i = 0; i < placements.length; i++)
          _unitAt(i, placements[i].$1, (placements[i].$2, placements[i].$3)),
      ],
      teamCount: teamCount,
      timings: timings,
    );
  }

  static Unit _unitAt(int id, int team, (int, int) p) =>
      Unit(id: id, team: team, x: p.$1.toDouble(), y: p.$2.toDouble());

  final int seed;
  final SimRng rng;
  final TerrainMask terrain;
  final int waterLevel;
  final TurnManager turn;

  int _tick = 0;
  int get tick => _tick;

  int _wind = 0;
  int get wind => _wind;

  final List<Unit> _units;
  late final List<Unit> units = UnmodifiableListView(_units);

  final List<Projectile> _projectiles = [];
  late final List<Projectile> projectiles = UnmodifiableListView(_projectiles);
  bool get isProjectileInFlight => _projectiles.isNotEmpty;

  int _nextProjectileId = 0;

  int get teamCount => turn.teamCount;

  Unit? get activeUnit {
    final id = turn.activeUnitId;
    return id < 0 ? null : _units[id];
  }

  /// Sum of the remaining HP of each team's living units.
  List<int> teamHp() {
    final hp = List.filled(teamCount, 0);
    for (final u in _units) {
      if (u.alive && u.hp > 0) hp[u.team] += u.hp;
    }
    return hp;
  }

  /// Advances exactly one fixed step (1 / [MatchDefaults.ticksPerSecond] s)
  /// and returns the events produced during it.
  List<SimEvent> step(List<SimInput> inputs) {
    _tick++;
    final events = <SimEvent>[];

    final walkDir = _applyInputs(inputs, events);
    _stepProjectiles(events);
    _stepUnits(walkDir, events);
    _stepTurn(events);
    return events;
  }

  /// Applies inputs the current phase allows; returns this tick's walk
  /// direction (0 = none).
  int _applyInputs(List<SimInput> inputs, List<SimEvent> events) {
    final unit = activeUnit;
    if (unit == null || !unit.alive) return 0;
    var walkDir = 0;
    for (final input in inputs) {
      switch (input) {
        case Walk(:final direction):
          if (turn.allowsMovement) walkDir = direction;
        case Jump(:final kind):
          if (turn.allowsMovement && unit.grounded) {
            final (vx, vy) = switch (kind) {
              JumpKind.forward =>
                (UnitConfig.jumpForwardVx, UnitConfig.jumpForwardVy),
              JumpKind.high => (UnitConfig.jumpHighVx, UnitConfig.jumpHighVy),
            };
            UnitPhysics.jump(unit, vx, vy);
            events.add(UnitJumped(unit.id));
          }
        case Fire():
          if (turn.allowsFire) _fire(unit, input, events);
      }
    }
    return walkDir;
  }

  /// Where a shot from [unit] at [angleDeg] starts: just outside the
  /// shooter's own hit circle. Shared with the aim guide.
  static (double, double) launchOrigin(Unit unit, int angleDeg) {
    final offset = unit.stats.hitRadius + 2;
    return (
      unit.centerX + SimTrig.cosDeg(angleDeg) * offset,
      unit.centerY - SimTrig.sinDeg(angleDeg) * offset,
    );
  }

  void _fire(Unit unit, Fire input, List<SimEvent> events) {
    final weapon = Weapons.byId(input.weaponId);
    final (x, y) = launchOrigin(unit, input.angleDeg);
    final p = ProjectilePhysics.launch(
      id: _nextProjectileId++,
      ownerId: unit.id,
      weapon: weapon,
      x: x,
      y: y,
      angleDeg: input.angleDeg,
      powerPercent: input.powerPercent,
    );
    final dirX = SimTrig.cosDeg(input.angleDeg);
    if (dirX != 0) unit.facing = dirX > 0 ? 1 : -1;
    _projectiles.add(p);
    events.add(ProjectileLaunched(p.id));
    turn.hasFired = true;
    _setPhase(
        weapon.endsTurn ? TurnPhase.settling : TurnPhase.retreat, events);
  }

  void _stepProjectiles(List<SimEvent> events) {
    for (var i = _projectiles.length - 1; i >= 0; i--) {
      final p = _projectiles[i];
      final outcome = ProjectilePhysics.step(p, terrain,
          wind: _wind, waterLevel: waterLevel, units: _units);
      if (outcome == FlightOutcome.flying) continue;
      _projectiles.removeAt(i);
      if (outcome == FlightOutcome.hitTerrain ||
          outcome == FlightOutcome.hitUnit) {
        _explode(p.x.round(), p.y.round(), p.weapon, events);
      }
      events.add(ProjectileRemoved(p.id, outcome));
    }
  }

  void _explode(int x, int y, WeaponDef weapon, List<SimEvent> events) {
    final radius = weapon.radius;
    final carved = terrain.carveCircle(x, y, radius);
    events.add(ExplosionEvent(x: x, y: y, radius: radius, carved: carved));

    for (final u in _units) {
      if (!u.alive) continue;
      final dx = u.centerX - x;
      final dy = u.centerY - y;
      final dist = sqrt(dx * dx + dy * dy);
      final edge = dist - u.stats.hitRadius;
      final damage = Damage.explosion(
        maxDamage: weapon.maxDamage,
        radius: radius,
        distance: edge < 0 ? 0 : edge,
      );
      if (damage == 0) continue;
      u.hp -= damage;
      events.add(UnitDamaged(u.id, damage, DamageCause.explosion));

      final speed = damage * UnitConfig.knockbackPerDamage;
      final nx = dist > 0 ? dx / dist : 0.0;
      final ny = dist > 0 ? dy / dist : -1.0;
      UnitPhysics.launch(
          u, nx * speed, (ny - UnitConfig.knockbackLift) * speed);
    }
  }

  void _stepUnits(int walkDir, List<SimEvent> events) {
    final active = activeUnit;
    for (final u in _units) {
      if (!u.alive) continue;
      if (walkDir != 0 && u == active) {
        UnitPhysics.walk(u, walkDir, terrain);
      }
      UnitPhysics.checkSupport(u, terrain);
      if (!u.grounded) {
        final fell = UnitPhysics.stepAirborne(u, terrain);
        if (fell != null) {
          final damage = Damage.fall(fell);
          if (damage > 0) {
            u.hp -= damage;
            events.add(UnitDamaged(u.id, damage, DamageCause.fall));
          }
        }
      }
      // Water and leaving the map kill at once (PRD: Gerak unit).
      if (u.x < 0 || u.x >= terrain.width || u.y >= terrain.height) {
        _kill(u, DeathCause.outOfBounds, events);
      } else if (u.centerY >= waterLevel) {
        _kill(u, DeathCause.water, events);
      }
    }
  }

  void _kill(Unit u, DeathCause cause, List<SimEvent> events) {
    u
      ..alive = false
      ..hp = 0
      ..vx = 0
      ..vy = 0;
    events.add(UnitDied(u.id, cause));
  }

  void _stepTurn(List<SimEvent> events) {
    turn.phaseTicks++;
    final active = activeUnit;
    final activeGone = active == null || !active.alive;
    final t = turn.timings;

    switch (turn.phase) {
      case TurnPhase.turnStart:
        if (turn.phaseTicks >= t.bannerTicks) {
          _setPhase(TurnPhase.action, events);
        }
      case TurnPhase.action:
        if (activeGone || turn.phaseTicks >= t.turnTicks) {
          _setPhase(TurnPhase.settling, events);
        }
      case TurnPhase.retreat:
        if (activeGone || turn.phaseTicks >= t.retreatTicks) {
          _setPhase(TurnPhase.settling, events);
        }
      case TurnPhase.settling:
        if (_isAtRest || turn.phaseTicks >= t.settleTimeoutTicks) {
          _finishTurn(events);
        }
      case TurnPhase.matchOver:
        break;
    }
  }

  bool get _isAtRest =>
      _projectiles.isEmpty && _units.every((u) => !u.alive || u.grounded);

  /// Deaths from HP are resolved only once everything is at rest, then the
  /// winner check runs (PRD: Core loop).
  void _finishTurn(List<SimEvent> events) {
    for (final u in _units) {
      if (u.alive && u.hp <= 0) _kill(u, DeathCause.hp, events);
    }
    final teamsAlive = <int>{
      for (final u in _units)
        if (u.alive) u.team,
    };
    if (teamsAlive.length <= 1) {
      final winner = teamsAlive.isEmpty ? null : teamsAlive.first;
      turn.endMatch(winner);
      events
        ..add(const PhaseChanged(TurnPhase.matchOver))
        ..add(MatchEnded(winner));
      return;
    }
    _beginTurn(events);
  }

  void _beginTurn(List<SimEvent> events) {
    turn.startNextTurn([
      for (var team = 0; team < teamCount; team++)
        [
          for (final u in _units)
            if (u.team == team) (u.id, u.alive),
        ],
    ]);
    _wind = rng.nextIntInRange(PhysicsConfig.windMin, PhysicsConfig.windMax);
    events
      ..add(TurnStarted(team: turn.activeTeam, unitId: turn.activeUnitId))
      ..add(const PhaseChanged(TurnPhase.turnStart));
  }

  void _setPhase(TurnPhase phase, List<SimEvent> events) {
    turn.enter(phase);
    events.add(PhaseChanged(phase));
  }

  /// Hash of the full simulation state, used by determinism tests. Stable
  /// across runs and devices (unlike `Object.hash`, which is seeded per run).
  int stateHash() {
    final h = StateHasher()
      ..add(seed)
      ..add(_tick)
      ..add(rng.state)
      ..add(_wind)
      ..add(_nextProjectileId)
      ..add(turn.phase.index)
      ..add(turn.phaseTicks)
      ..add(turn.activeTeam)
      ..add(turn.activeUnitId)
      ..add(turn.turnNumber)
      ..add(turn.hasFired ? 1 : 0)
      ..add(turn.winnerTeam ?? -1);
    for (final c in turn.cursors) {
      h.add(c);
    }
    for (final u in _units) {
      h
        ..add(u.id)
        ..add(u.hp)
        ..add(u.alive ? 1 : 0)
        ..add(u.grounded ? 1 : 0)
        ..add(u.facing)
        ..addDouble(u.x)
        ..addDouble(u.y)
        ..addDouble(u.vx)
        ..addDouble(u.vy)
        ..addDouble(u.peakY)
        ..addDouble(u.walkCarry);
    }
    h.add(_projectiles.length);
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
