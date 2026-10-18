import 'dart:collection';
import 'dart:math' show min, sqrt;
import 'dart:typed_data';

import '../config/match_defaults.dart';
import '../config/physics.dart';
import '../config/units.dart';
import '../config/weapons.dart';
import 'damage.dart';
import 'events.dart';
import 'inputs.dart';
import 'match_setup.dart';
import 'mine.dart';
import 'physics.dart';
import 'projectile.dart';
import 'rng.dart';
import 'spawn.dart';
import 'terrain_mask.dart';
import 'trig.dart';
import 'turn_manager.dart';
import 'unit.dart';
import 'weapon_behaviors/flight_behavior.dart';
import 'weapon_behaviors/sim_context.dart';
import 'weapon_behaviors/walker_behavior.dart';

/// Root of the deterministic simulation. Pure Dart: must never import
/// Flutter or Flame, read wall-clock time, or know the screen size.
class SimWorld implements SimContext {
  SimWorld._({
    required this.seed,
    required this.rng,
    required this.terrain,
    required int waterLevel,
    required List<Unit> units,
    required int teamCount,
    required TurnTimings timings,
    this.suddenDeathAfterTicks,
  })  : _waterLevel = waterLevel,
        _units = units,
        turn = TurnManager(teamCount: teamCount, timings: timings),
        _ammo = [
          for (var t = 0; t < teamCount; t++)
            {
              for (final w in Weapons.shared)
                if (w.ammo != null) w.id: w.ammo!,
            },
        ] {
    _beginTurn();
    _events.clear();
  }

  /// A new match from team rosters, units on random flat ground.
  factory SimWorld.newMatch({
    required int seed,
    required TerrainMask terrain,
    required int waterLevel,
    required List<List<UnitSpec>> rosters,
    TurnTimings timings = const TurnTimings(),
    int? suddenDeathAfterTicks,
  }) {
    final rng = SimRng(seed);
    final count = rosters.fold(0, (n, r) => n + r.length);
    final points = findSpawnPoints(
      terrain: terrain,
      waterLevel: waterLevel,
      count: count,
      rng: rng,
    );
    final units = <Unit>[];
    for (var t = 0; t < rosters.length; t++) {
      for (final spec in rosters[t]) {
        final (x, y) = points[units.length];
        units.add(Unit(
          id: units.length,
          team: t,
          x: x.toDouble(),
          y: y.toDouble(),
          familyId: spec.familyId,
          breedId: spec.breedId,
        ));
      }
    }
    return SimWorld._(
      seed: seed,
      rng: rng,
      terrain: terrain,
      waterLevel: waterLevel,
      units: units,
      teamCount: rosters.length,
      timings: timings,
      suddenDeathAfterTicks: suddenDeathAfterTicks,
    );
  }

  /// Explicit placements; for tests and scripted setups.
  factory SimWorld.withUnits({
    required int seed,
    required TerrainMask terrain,
    required int waterLevel,
    required int teamCount,
    required List<UnitPlacement> placements,
    TurnTimings timings = const TurnTimings(),
    int? suddenDeathAfterTicks,
  }) {
    return SimWorld._(
      seed: seed,
      rng: SimRng(seed),
      terrain: terrain,
      waterLevel: waterLevel,
      units: [
        for (var i = 0; i < placements.length; i++)
          Unit(
            id: i,
            team: placements[i].team,
            x: placements[i].x.toDouble(),
            y: placements[i].y.toDouble(),
            familyId: placements[i].familyId,
          ),
      ],
      teamCount: teamCount,
      timings: timings,
      suddenDeathAfterTicks: suddenDeathAfterTicks,
    );
  }

  final int seed;
  @override
  final SimRng rng;
  @override
  final TerrainMask terrain;
  final TurnManager turn;

  int _waterLevel;
  @override
  int get waterLevel => _waterLevel;

  /// Sudden death starts with the first turn after this many ticks;
  /// null = never (PRD: Pengaturan pertandingan).
  final int? suddenDeathAfterTicks;
  bool _suddenDeath = false;
  bool get suddenDeath => _suddenDeath;

  /// Turns played since the water last rose.
  int _turnsSinceRise = 0;

  int _tick = 0;
  int get tick => _tick;

  int _wind = 0;
  @override
  int get wind => _wind;

  final List<Unit> _units;
  @override
  late final List<Unit> units = UnmodifiableListView(_units);

  final List<Projectile> _projectiles = [];
  final List<Projectile> _spawned = [];
  late final List<Projectile> projectiles = UnmodifiableListView(_projectiles);
  bool get isProjectileInFlight => _projectiles.isNotEmpty;

  final List<Mine> _mines = [];
  late final List<Mine> mines = UnmodifiableListView(_mines);

  /// Follow-up shots of a burst weapon: (due tick, unit id, fire input).
  final List<(int, int, Fire)> _pendingShots = [];

  /// Per team: remaining ammo of limited shared weapons.
  final List<Map<String, int>> _ammo;

  int _nextProjectileId = 0;
  int _nextMineId = 0;

  /// Events of the step in progress.
  final List<SimEvent> _events = [];

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

  /// Sum of each team's starting HP.
  List<int> teamMaxHp() {
    final hp = List.filled(teamCount, 0);
    for (final u in _units) {
      hp[u.team] += u.stats.maxHp;
    }
    return hp;
  }

  // ------------------------------------------------------------- weapons

  /// Remaining ammo of [weapon] for [team]; null = unlimited (or a
  /// signature weapon, which is tracked per unit).
  int? ammoLeft(int team, WeaponDef weapon) =>
      weapon.ammo == null || weapon.isSignature ? null : _ammo[team][weapon.id];

  /// Whether [unit] may use [weapon] right now (ignoring the turn phase).
  bool canUse(Unit unit, WeaponDef weapon) {
    if (weapon.hidden) return false;
    if (weapon.isSignature) {
      return weapon.familyId == unit.familyId && !unit.signatureUsed;
    }
    final left = ammoLeft(unit.team, weapon);
    return left == null || left > 0;
  }

  /// Whether a target weapon may be used at world point ([x], [y]).
  bool isValidTarget(Unit unit, WeaponDef weapon, int x, int y) {
    return switch (weapon.delivery) {
      Teleport() => _canTeleportTo(unit, x, y),
      BuildWall(:final width, :final height) =>
        _wallFits(_wallRect(x, y, width, height)),
      AirStrike() => x >= 0 && x < terrain.width,
      _ => true,
    };
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

  // ---------------------------------------------------------------- step

  /// Advances exactly one fixed step (1 / [MatchDefaults.ticksPerSecond] s)
  /// and returns the events produced during it.
  List<SimEvent> step(List<SimInput> inputs) {
    _tick++;
    _events.clear();

    final walkDir = _applyInputs(inputs);
    _firePendingShots();
    _stepProjectiles();
    _stepMines();
    _stepUnits(walkDir);
    _stepTurn();
    return List.of(_events);
  }

  /// Applies inputs the current phase allows; returns this tick's walk
  /// direction (0 = none).
  int _applyInputs(List<SimInput> inputs) {
    final unit = activeUnit;
    if (unit == null || !unit.alive) return 0;
    var walkDir = 0;
    for (final input in inputs) {
      switch (input) {
        case Walk(:final direction):
          if (turn.allowsMovement && !unit.isDashing) walkDir = direction;
        case Jump(:final kind):
          if (turn.allowsMovement && !unit.isDashing) _jump(unit, kind);
        case Fire():
          if (turn.allowsFire) _fire(unit, input);
      }
    }
    return walkDir;
  }

  void _jump(Unit unit, JumpKind kind) {
    final (vx, vy) = switch (kind) {
      JumpKind.forward => (UnitConfig.jumpForwardVx, UnitConfig.jumpForwardVy),
      JumpKind.high => (
          UnitConfig.jumpHighVx,
          UnitConfig.jumpHighVy * unit.stats.highJumpVelocityScale,
        ),
    };
    if (unit.grounded) {
      UnitPhysics.jump(unit, vx, vy);
    } else if (!UnitPhysics.airJump(unit, vx, vy)) {
      return;
    }
    _events.add(UnitJumped(unit.id));
  }

  void _fire(Unit unit, Fire input) {
    final WeaponDef weapon;
    try {
      weapon = Weapons.byId(input.weaponId);
    } on ArgumentError {
      return;
    }
    if (!canUse(unit, weapon)) return;
    final needsTarget = weapon.aim == AimMode.target;
    final tx = input.targetX;
    final ty = input.targetY;
    if (needsTarget &&
        (tx == null || ty == null || !isValidTarget(unit, weapon, tx, ty))) {
      return;
    }
    final dir = _horizontalDir(unit, input.angleDeg);

    switch (weapon.delivery) {
      case Launch(:final shots, :final shotIntervalTicks):
        _launchShot(unit, weapon, input);
        for (var i = 1; i < shots; i++) {
          _pendingShots.add((_tick + i * shotIntervalTicks, unit.id, input));
        }
      case AirStrike(:final childId, :final count, :final spacing):
        final child = Weapons.byId(childId);
        for (var i = 0; i < count; i++) {
          spawnProjectile(Projectile(
            id: nextProjectileId(),
            ownerId: unit.id,
            weapon: child,
            x: tx! + (i * 2 - (count - 1)) * spacing / 2,
            y: -40,
            vx: 0,
            vy: 0,
          ));
        }
      case PlaceMine():
        unit.facing = dir;
        spawnMine(weapon, unit.centerX + dir * (unit.stats.hitRadius + 4),
            unit.y - 4, 0, 0,
            ownerId: unit.id);
      case AreaHit(:final reach):
        final cx = unit.centerX + SimTrig.cosDeg(input.angleDeg) * reach;
        final cy = unit.centerY - SimTrig.sinDeg(input.angleDeg) * reach;
        if (reach > 0) unit.facing = dir;
        _blast(cx.round(), cy.round(), weapon,
            cause: DamageCause.impact,
            excludeUnitId: unit.id,
            sourceId: unit.id);
      case Dash(:final distance):
        unit
          ..facing = dir
          ..dashDir = dir
          ..dashRemaining = distance.toDouble()
          ..dashSinceCarve = 0
          ..dashWeapon = weapon;
      case Teleport():
        unit
          ..x = tx!.toDouble()
          ..y = (ty! + unit.stats.bodyHeight ~/ 2).toDouble();
        UnitPhysics.launch(unit, 0, 0);
        _events.add(UnitTeleported(unit.id));
      case BuildWall(:final width, :final height):
        final rect = _wallRect(tx!, ty!, width, height)!;
        terrain.fillRect(rect.left, rect.top, rect.width, rect.height);
        _events.add(TerrainAdded(rect));
      case SkipTurn():
        break;
      case final SpawnWalker spec:
        final body = WalkerBehavior.makeBody(spec,
            unit.x + dir * (unit.stats.hitRadius + 4), unit.y, dir);
        spawnProjectile(Projectile(
          id: nextProjectileId(),
          ownerId: unit.id,
          weapon: weapon,
          x: body.centerX,
          y: body.centerY,
          vx: 0,
          vy: 0,
          fuseTicks: weapon.fuseTicks,
        )..body = body);
    }

    if (weapon.isSignature) {
      unit.signatureUsed = true;
    } else if (weapon.ammo != null) {
      _ammo[unit.team][weapon.id] = _ammo[unit.team][weapon.id]! - 1;
    }
    _events.add(WeaponUsed(unit.id, weapon.id));
    turn.hasFired = true;
    _setPhase(weapon.endsTurn ? TurnPhase.settling : TurnPhase.retreat);
  }

  /// -1 / 1 from the aim angle; straight up or down keeps the facing.
  static int _horizontalDir(Unit unit, int angleDeg) {
    final c = SimTrig.cosDeg(angleDeg);
    return c > 1e-9 ? 1 : (c < -1e-9 ? -1 : unit.facing);
  }

  void _launchShot(Unit unit, WeaponDef weapon, Fire input) {
    final (x, y) = launchOrigin(unit, input.angleDeg);
    var fuse = weapon.fuseTicks;
    if (weapon.playerFuse && input.fuseTicks != null) {
      fuse = input.fuseTicks!
          .clamp(FuseConfig.minSeconds * 60, FuseConfig.maxSeconds * 60);
    }
    final p = ProjectilePhysics.launch(
      id: nextProjectileId(),
      ownerId: unit.id,
      weapon: weapon,
      x: x,
      y: y,
      angleDeg: input.angleDeg,
      powerPercent: input.powerPercent,
      speedScale: unit.stats.firePowerScale,
      fuseTicks: fuse,
    );
    final flight = weapon.flight;
    if (flight is Boomerang) {
      final power = input.powerPercent.clamp(0, 100) / 100;
      p
        ..range = flight.minRange + (flight.maxRange - flight.minRange) * power
        ..vx = SimTrig.cosDeg(input.angleDeg) * flight.speed
        ..vy = -SimTrig.sinDeg(input.angleDeg) * flight.speed;
    }
    final dirX = SimTrig.cosDeg(input.angleDeg);
    if (dirX.abs() > 1e-9) unit.facing = dirX > 0 ? 1 : -1;
    spawnProjectile(p);
  }

  void _firePendingShots() {
    for (var i = _pendingShots.length - 1; i >= 0; i--) {
      final (due, unitId, input) = _pendingShots[i];
      if (due > _tick) continue;
      _pendingShots.removeAt(i);
      final unit = _units[unitId];
      if (unit.alive) _launchShot(unit, Weapons.byId(input.weaponId), input);
    }
  }

  // --------------------------------------------------- SimContext actions

  @override
  int nextProjectileId() => _nextProjectileId++;

  @override
  void spawnProjectile(Projectile p) {
    _spawned.add(p);
    _events.add(ProjectileLaunched(p.id));
  }

  @override
  void spawnMine(WeaponDef weapon, double x, double y, double vx, double vy,
      {int? ownerId}) {
    final m = Mine(
      id: _nextMineId++,
      weapon: weapon,
      x: x,
      y: y,
      vx: vx,
      vy: vy,
      ownerId: ownerId,
      // "Active after 1 turn": armed from the next turn on.
      armedOnTurn: turn.turnNumber + 1,
    );
    _mines.add(m);
    _events.add(MinePlaced(m.id));
  }

  @override
  void explode(double x, double y, WeaponDef weapon, {int? sourceId}) =>
      _blast(x.round(), y.round(), weapon,
          cause: DamageCause.explosion,
          carve: weapon.terrainDamage,
          sourceId: sourceId);

  @override
  void strikeUnit(
      Unit unit, int damage, double dirX, double dirY, double knockbackScale,
      {int? sourceId}) {
    _damage(unit, damage, DamageCause.impact, sourceId: sourceId);
    _knockback(unit, damage, dirX, dirY, knockbackScale);
  }

  @override
  void carveTunnel(int x, int y, int radius) {
    if (terrain.carveCircle(x, y, radius) != null) {
      _events.add(TerrainCarved(x, y, radius));
    }
  }

  /// Damage with linear falloff and knockback to every living unit in
  /// range, optionally carving terrain, and sets off nearby mines.
  void _blast(
    int x,
    int y,
    WeaponDef weapon, {
    required DamageCause cause,
    bool carve = false,
    int? excludeUnitId,
    int? sourceId,
  }) {
    final radius = weapon.radius;
    final carved = carve ? terrain.carveCircle(x, y, radius) : null;
    _events.add(ExplosionEvent(x: x, y: y, radius: radius, carved: carved));

    for (final u in _units) {
      if (!u.alive || u.id == excludeUnitId) continue;
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
      _damage(u, damage, cause, sourceId: sourceId);
      _knockback(u, damage, dist > 0 ? dx / dist : 0.0,
          dist > 0 ? dy / dist : -1.0, weapon.knockbackScale);
    }

    for (final m in _mines) {
      final dx = m.x - x;
      final dy = m.centerY - y;
      if (dx * dx + dy * dy <= radius * radius) {
        m.countdown = min(m.countdown ?? 1, 1);
      }
    }
  }

  /// Applies [amount] of damage, with the unit's damage-taken modifier for
  /// explosions and its lethal save (Kucing) if it has one left.
  void _damage(Unit u, int amount, DamageCause cause, {int? sourceId}) {
    var dealt = amount;
    if (cause == DamageCause.explosion) {
      dealt = (amount * u.stats.explosionDamageScale).round();
      if (dealt < 1) dealt = 1;
    }
    if (u.hp > 0 && u.hp - dealt <= 0 && u.lethalSavesLeft > 0) {
      dealt = u.hp - 1;
      u.lethalSavesLeft--;
      _events.add(UnitSaved(u.id, SaveKind.lethal));
    }
    if (dealt <= 0) return;
    u.hp -= dealt;
    _events.add(UnitDamaged(u.id, dealt, cause, sourceUnitId: sourceId));
  }

  void _knockback(
      Unit u, int damage, double dirX, double dirY, double knockbackScale) {
    final speed = damage * UnitConfig.knockbackPerDamage * knockbackScale;
    UnitPhysics.launch(
        u, dirX * speed, (dirY - UnitConfig.knockbackLift) * speed);
  }

  // --------------------------------------------------------- simulation

  void _stepProjectiles() {
    for (var i = _projectiles.length - 1; i >= 0; i--) {
      final p = _projectiles[i];
      final outcome = FlightBehavior.of(p.weapon).tick(p, this);
      if (outcome == FlightOutcome.flying) continue;
      _projectiles.removeAt(i);
      _events.add(ProjectileRemoved(p.id, outcome));
    }
    _projectiles.addAll(_spawned);
    _spawned.clear();
  }

  void _stepMines() {
    for (var i = _mines.length - 1; i >= 0; i--) {
      final m = _mines[i];
      final move = MinePhysics.step(m, terrain, waterLevel);
      if (move == MineMove.water || move == MineMove.outOfBounds) {
        _mines.removeAt(i);
        _events.add(MineRemoved(m.id));
        continue;
      }
      final countdown = m.countdown;
      if (countdown != null) {
        if (countdown <= 1) {
          _mines.removeAt(i);
          _events.add(MineRemoved(m.id));
          _blast(m.x.round(), m.centerY.round(), m.weapon,
              cause: DamageCause.explosion, carve: true, sourceId: m.ownerId);
        } else {
          m.countdown = countdown - 1;
        }
        continue;
      }
      if (!m.grounded || turn.turnNumber < m.armedOnTurn) continue;
      for (final u in _units) {
        if (!u.alive) continue;
        final dx = u.centerX - m.x;
        final dy = u.centerY - m.centerY;
        const r = MineConfig.triggerRadius;
        if (dx * dx + dy * dy <= r * r) {
          m.countdown = MineConfig.triggerDelayTicks;
          _events.add(MineTriggered(m.id));
          break;
        }
      }
    }
  }

  void _stepUnits(int walkDir) {
    final active = activeUnit;
    for (final u in _units) {
      if (!u.alive) continue;
      if (u.isDashing) {
        _stepDash(u);
      } else {
        if (walkDir != 0 && u == active) {
          UnitPhysics.walk(u, walkDir, terrain);
        }
        UnitPhysics.checkSupport(u, terrain);
        if (!u.grounded) {
          final fell = UnitPhysics.stepAirborne(u, terrain);
          if (fell != null && u.stats.fallDamage) {
            final damage =
                Damage.fall(fell, threshold: u.stats.fallDamageThreshold);
            if (damage > 0) _damage(u, damage, DamageCause.fall);
          }
        }
      }
      _checkBounds(u);
    }
  }

  /// Water and leaving the map kill at once (PRD: Gerak unit), unless the
  /// unit can be rescued from the water (Bebek).
  void _checkBounds(Unit u) {
    if (u.x < 0 || u.x >= terrain.width || u.y >= terrain.height) {
      _kill(u, DeathCause.outOfBounds);
    } else if (u.centerY >= waterLevel) {
      if (u.waterSavesLeft > 0 && _rescueFromWater(u)) return;
      _kill(u, DeathCause.water);
    }
  }

  /// Seruduk: charge sideways, digging, until the distance is covered or a
  /// unit is hit. Gravity is suspended during the charge.
  void _stepDash(Unit u) {
    final weapon = u.dashWeapon!;
    final spec = weapon.delivery as Dash;
    var move = min(u.dashRemaining, spec.speed * PhysicsConfig.dt);
    final carveY = (u.y - spec.carveRadius - 1).round();
    if (u.dashSinceCarve == 0) {
      carveTunnel(u.x.round(), carveY, spec.carveRadius);
    }
    while (move > 0 && u.dashRemaining > 0) {
      final s = min(1.0, move);
      move -= s;
      u
        ..x += u.dashDir * s
        ..dashRemaining -= s
        ..dashSinceCarve += s;
      if (u.x < 0 || u.x >= terrain.width) {
        u.dashRemaining = 0;
        break;
      }
      if (u.dashSinceCarve >= 6) {
        carveTunnel(u.x.round(), carveY, spec.carveRadius);
        u.dashSinceCarve = 0.001;
      }
      for (final v in _units) {
        if (!v.alive || v == u) continue;
        final dx = v.centerX - u.centerX;
        final dy = v.centerY - u.centerY;
        final reach = v.stats.hitRadius + u.stats.hitRadius;
        if (dx * dx + dy * dy <= reach * reach) {
          strikeUnit(v, weapon.maxDamage, u.dashDir.toDouble(), 0,
              weapon.knockbackScale,
              sourceId: u.id);
          u.dashRemaining = 0;
          break;
        }
      }
    }
    if (u.dashRemaining <= 0) {
      carveTunnel(u.x.round(), carveY, spec.carveRadius);
      u
        ..dashRemaining = 0
        ..x = u.x.floorToDouble();
      UnitPhysics.launch(u, 0, 0);
    }
  }

  /// Bebek: costs some HP and puts the unit back on the nearest dry
  /// ground. Returns false if there is no dry ground anywhere.
  bool _rescueFromWater(Unit u) {
    final x0 = u.x.round().clamp(0, terrain.width - 1);
    for (var d = 0; d < terrain.width; d++) {
      for (final x in d == 0 ? [x0] : [x0 - d, x0 + d]) {
        if (x < 0 || x >= terrain.width) continue;
        final y = surfaceY(terrain, x, u.stats.bodyHeight);
        if (y == null || y >= waterLevel - 2) continue;
        u
          ..waterSavesLeft -= 1
          ..x = x.toDouble()
          ..y = y.toDouble()
          ..vx = 0
          ..vy = 0
          ..grounded = true
          ..gliding = false
          ..peakY = y.toDouble();
        _events.add(UnitSaved(u.id, SaveKind.water));
        _damage(u, u.stats.waterSaveDamage, DamageCause.water);
        return true;
      }
    }
    return false;
  }

  void _kill(Unit u, DeathCause cause) {
    u
      ..alive = false
      ..hp = 0
      ..vx = 0
      ..vy = 0
      ..dashRemaining = 0;
    _events.add(UnitDied(u.id, cause));
  }

  // ------------------------------------------------------------- targets

  bool _canTeleportTo(Unit u, int x, int y) {
    final feet = y + u.stats.bodyHeight ~/ 2;
    if (x < 0 || x >= terrain.width || y < 0 || feet >= waterLevel) {
      return false;
    }
    return UnitPhysics.bodyFree(terrain, x, feet, u.stats.bodyHeight);
  }

  IntRect? _wallRect(int cx, int cy, int width, int height) {
    final left = cx - width ~/ 2;
    final top = cy - height ~/ 2;
    if (left < 0 ||
        top < 0 ||
        left + width > terrain.width ||
        top + height > terrain.height) {
      return null;
    }
    return IntRect(left, top, left + width, top + height);
  }

  /// A wall must fit on the map and may not be built on a living unit.
  bool _wallFits(IntRect? r) {
    if (r == null) return false;
    for (final u in _units) {
      if (!u.alive) continue;
      final nx = u.centerX.clamp(r.left.toDouble(), r.right.toDouble());
      final ny = u.centerY.clamp(r.top.toDouble(), r.bottom.toDouble());
      final dx = u.centerX - nx;
      final dy = u.centerY - ny;
      if (dx * dx + dy * dy <= u.stats.hitRadius * u.stats.hitRadius) {
        return false;
      }
    }
    return true;
  }

  // ---------------------------------------------------------------- turn

  void _stepTurn() {
    turn.phaseTicks++;
    final active = activeUnit;
    final activeGone = active == null || !active.alive;
    final t = turn.timings;

    switch (turn.phase) {
      case TurnPhase.turnStart:
        if (turn.phaseTicks >= t.bannerTicks) _setPhase(TurnPhase.action);
      case TurnPhase.action:
        if (activeGone || turn.phaseTicks >= t.turnTicks) {
          _setPhase(TurnPhase.settling);
        }
      case TurnPhase.retreat:
        if (activeGone || turn.phaseTicks >= t.retreatTicks) {
          _setPhase(TurnPhase.settling);
        }
      case TurnPhase.settling:
        if (_isAtRest || turn.phaseTicks >= t.settleTimeoutTicks) {
          _finishTurn();
        }
      case TurnPhase.matchOver:
        break;
    }
  }

  bool get _isAtRest =>
      _projectiles.isEmpty &&
      _spawned.isEmpty &&
      _pendingShots.isEmpty &&
      _units.every((u) => !u.alive || (u.grounded && !u.isDashing)) &&
      _mines.every((m) => m.grounded && m.countdown == null);

  /// Deaths from HP are resolved only once everything is at rest, then the
  /// winner check runs (PRD: Core loop).
  void _finishTurn() {
    // A settle timeout must not leave a burst half-fired into the next turn.
    _pendingShots.clear();
    if (_suddenDeath) _maybeRaiseWater();
    for (final u in _units) {
      if (u.alive && u.hp <= 0) _kill(u, DeathCause.hp);
    }
    final teamsAlive = <int>{
      for (final u in _units)
        if (u.alive) u.team,
    };
    if (teamsAlive.length <= 1) {
      final winner = teamsAlive.isEmpty ? null : teamsAlive.first;
      turn.endMatch(winner);
      _events
        ..add(const PhaseChanged(TurnPhase.matchOver))
        ..add(MatchEnded(winner));
      return;
    }
    _beginTurn();
  }

  void _beginTurn() {
    turn.startNextTurn([
      for (var team = 0; team < teamCount; team++)
        [
          for (final u in _units)
            if (u.team == team) (u.id, u.alive),
        ],
    ]);
    _wind = rng.nextIntInRange(PhysicsConfig.windMin, PhysicsConfig.windMax);
    _events
      ..add(TurnStarted(team: turn.activeTeam, unitId: turn.activeUnitId))
      ..add(const PhaseChanged(TurnPhase.turnStart));
    final start = suddenDeathAfterTicks;
    if (!_suddenDeath && start != null && _tick >= start) _startSuddenDeath();
  }

  /// PRD: every unit drops to 1 HP, then the water rises each round.
  void _startSuddenDeath() {
    _suddenDeath = true;
    _turnsSinceRise = 0;
    for (final u in _units) {
      if (u.alive && u.hp > 1) u.hp = 1;
    }
    _events.add(const SuddenDeathStarted());
  }

  /// A round is over once every team still in the game has had a turn;
  /// then the water rises and drowns whoever it reaches.
  void _maybeRaiseWater() {
    _turnsSinceRise++;
    final teamsAlive = {
      for (final u in _units)
        if (u.alive) u.team,
    }.length;
    if (_turnsSinceRise < teamsAlive) return;
    _turnsSinceRise = 0;
    _waterLevel = (_waterLevel - MatchDefaults.suddenDeathWaterRise)
        .clamp(0, terrain.height);
    _events.add(WaterRose(_waterLevel));
    for (final u in _units) {
      if (u.alive) _checkBounds(u);
    }
  }

  void _setPhase(TurnPhase phase) {
    turn.enter(phase);
    _events.add(PhaseChanged(phase));
  }

  // ---------------------------------------------------------------- hash

  /// Hash of the full simulation state, used by determinism tests. Stable
  /// across runs and devices (unlike `Object.hash`, which is seeded per run).
  int stateHash() {
    final h = StateHasher()
      ..add(seed)
      ..add(_tick)
      ..add(rng.state)
      ..add(_wind)
      ..add(_nextProjectileId)
      ..add(_nextMineId)
      ..add(turn.phase.index)
      ..add(turn.phaseTicks)
      ..add(turn.activeTeam)
      ..add(turn.activeUnitId)
      ..add(turn.turnNumber)
      ..add(turn.hasFired ? 1 : 0)
      ..add(turn.winnerTeam ?? -1)
      ..add(_waterLevel)
      ..add(_suddenDeath ? 1 : 0)
      ..add(_turnsSinceRise);
    for (final c in turn.cursors) {
      h.add(c);
    }
    for (final team in _ammo) {
      for (final w in Weapons.shared) {
        h.add(team[w.id] ?? -1);
      }
    }
    for (final u in _units) {
      h
        ..add(u.id)
        ..add(u.hp)
        ..add(u.alive ? 1 : 0)
        ..add(u.grounded ? 1 : 0)
        ..add(u.facing)
        ..add(u.lethalSavesLeft)
        ..add(u.waterSavesLeft)
        ..add(u.airJumpsLeft)
        ..add(u.gliding ? 1 : 0)
        ..add(u.signatureUsed ? 1 : 0)
        ..add(u.dashDir)
        ..addDouble(u.dashRemaining)
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
        ..add(p.mode)
        ..add(p.fuseTicks ?? -1)
        ..add(p.resting ? 1 : 0)
        ..addDouble(p.x)
        ..addDouble(p.y)
        ..addDouble(p.vx)
        ..addDouble(p.vy)
        ..addDouble(p.traveled);
    }
    h.add(_mines.length);
    for (final m in _mines) {
      h
        ..add(m.id)
        ..add(m.countdown ?? -1)
        ..add(m.grounded ? 1 : 0)
        ..addDouble(m.x)
        ..addDouble(m.y);
    }
    h.add(_pendingShots.length);
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
