import 'dart:collection';
import 'dart:math' show max, min, sqrt;
import 'dart:typed_data';

import '../config/families.dart';
import '../config/map_objects.dart';
import '../config/match_defaults.dart';
import '../config/physics.dart';
import '../config/units.dart';
import '../config/weapons.dart';
import 'air_support.dart';
import 'damage.dart';
import 'events.dart';
import 'fire_patch.dart';
import 'inputs.dart';
import 'map_object.dart';
import 'match_setup.dart';
import 'mine.dart';
import 'physics.dart';
import 'poison_cloud.dart';
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

part 'world_hazards.dart';
part 'world_impacts.dart';
part 'world_weapons.dart';

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
    this.loadout = WeaponLoadout.standard,
    this.randomWeapons = false,
  })  : _waterLevel = waterLevel,
        _units = units,
        turn = TurnManager(teamCount: teamCount, timings: timings),
        _ammo = [
          for (var t = 0; t < teamCount; t++)
            {
              for (final w in Weapons.shared)
                if (loadout.ammoOf(w) case final int n) w.id: n,
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
    WeaponLoadout loadout = WeaponLoadout.standard,
    ObjectMix? objects,
    bool randomWeapons = false,
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
    final world = SimWorld._(
      seed: seed,
      rng: rng,
      terrain: terrain,
      waterLevel: waterLevel,
      units: units,
      teamCount: rosters.length,
      timings: timings,
      suddenDeathAfterTicks: suddenDeathAfterTicks,
      loadout: loadout,
      randomWeapons: randomWeapons,
    );
    if (objects != null && objects.total > 0) {
      world._placeObjects(objects, points);
    }
    return world;
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
    WeaponLoadout loadout = WeaponLoadout.standard,
    bool randomWeapons = false,
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
      loadout: loadout,
      randomWeapons: randomWeapons,
    );
  }

  final int seed;

  /// Random weapons rule: each turn draws one weapon (from the loadout,
  /// tools left out) and that is the turn's only weapon, free of ammo.
  final bool randomWeapons;
  String? _drawn;

  /// This turn's weapon under [randomWeapons]; null otherwise.
  String? get drawnWeaponId => _drawn;

  /// Weapons on and their starting ammo (setup's Weapons tab).
  final WeaponLoadout loadout;
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
  int _turnsThisRound = 0;

  /// Rounds of sudden death the ground has already crumbled.
  int _crumbles = 0;

  int _tick = 0;
  int get tick => _tick;

  /// Tick of the latest damage or death, so settling can hold on it.
  int _lastHitTick = -1;

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

  /// Starter barrels and crates (map objects).
  final List<MapObject> _objects = [];
  late final List<MapObject> objects = UnmodifiableListView(_objects);
  int _nextObjectId = 0;

  /// Napalm fire burning on the ground.
  final List<FirePatch> _fires = [];
  late final List<FirePatch> fires = UnmodifiableListView(_fires);
  int _nextFireId = 0;

  /// Poison gas hanging about.
  final List<PoisonCloud> _clouds = [];
  late final List<PoisonCloud> clouds = UnmodifiableListView(_clouds);
  int _nextCloudId = 0;

  /// Units burnt this turn (fire hurts each at most once a turn).
  final Set<int> _burnt = {};

  /// Shotgun pulls left this turn after the first (0 = none started).
  int _shotgunLeft = 0;
  int get shotgunShotsLeft => _shotgunLeft;

  /// This turn's unit was frozen, so the turn was skipped.
  bool _frozenSkip = false;
  bool get frozenSkip => _frozenSkip;

  /// Aircraft (and bird flocks) crossing the sky for air raids.
  final List<Aircraft> _aircraft = [];
  late final List<Aircraft> aircraft = UnmodifiableListView(_aircraft);

  /// Satellite beams and storm-cloud bolts waiting to land.
  final List<PendingStrike> _strikes = [];
  late final List<PendingStrike> pendingStrikes =
      UnmodifiableListView(_strikes);

  /// Follow-up shots of a burst weapon: (due tick, unit id, fire input).
  final List<(int, int, Fire)> _pendingShots = [];

  /// Per team: remaining ammo of limited shared weapons (absent =
  /// unlimited).
  final List<Map<String, int>> _ammo;

  int _nextProjectileId = 0;
  int _nextMineId = 0;

  /// Events of the step in progress.
  final List<SimEvent> _events = [];

  int get teamCount => turn.teamCount;

  /// Puts a starter object down with its base on row [y] (tests and
  /// scripted setups; matches place them with the map's mix).
  MapObject addObject(ObjectKind kind, int x, int y) {
    final o = MapObject(
      id: _nextObjectId++,
      kind: kind,
      x: x.toDouble(),
      y: y.toDouble(),
    )..grounded = terrain.isSolid(x, y);
    _objects.add(o);
    return o;
  }

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
      weapon.isSignature ? null : _ammo[team][weapon.id];

  /// Whether [unit] may use [weapon] right now (ignoring the turn phase).
  bool canUse(Unit unit, WeaponDef weapon) {
    // Mid-shotgun: only its second pull.
    if (_shotgunLeft > 0) return weapon.delivery is Shotgun;
    if (!loadout.enabled(weapon)) return false;
    if (randomWeapons) {
      return weapon.id == _drawn || weapon.delivery is SkipTurn;
    }
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
      SwapPlaces() => switch (ProjectilePhysics.unitAt(
          x.toDouble(), y.toDouble(), _units)) {
        final other? => other.id != unit.id,
        null => false,
      },
      BuildWall(:final width, :final height) =>
        _wallFits(_wallRect(x, y, width, height)),
      AirStrike() ||
      Lightning() ||
      AirRaid() ||
      OrbitalStrike() ||
      MeteorShower() =>
        x >= 0 && x < terrain.width,
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
    _stepAirSupport();
    _stepProjectiles();
    _stepMines();
    _stepObjects();
    _stepUnits(walkDir);
    _stepFires();
    _stepGas();
    _stepTurn();
    return List.of(_events);
  }

  /// Applies inputs the current phase allows; returns this tick's walk
  /// direction (0 = none).
  int _applyInputs(List<SimInput> inputs) {
    final unit = activeUnit;
    if (unit == null || !unit.alive) return 0;
    var walkDir = 0;
    final busy = unit.isDashing || unit.isDigging || unit.isGrappling;
    for (final input in inputs) {
      switch (input) {
        case Walk(:final direction):
          if (turn.allowsMovement && !busy) walkDir = direction;
        case Jump(:final kind):
          if (turn.allowsMovement && !busy) _jump(unit, kind);
        case Fire():
          if (turn.allowsFire && !busy) _fire(unit, input);
        case Dig(:final angleDeg):
          if (unit.isDigging) _dig(unit, angleDeg);
        case StopDigging():
          if (unit.isDigging) _stopDigging(unit);
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

  /// Where a grappling hook shot from [unit] at [angleDeg] ends: the first
  /// ground pixel within [length] px (hooked), or where it gives out at
  /// [length], the map edge or the water. Shared with the aim guide.
  static (double, double, bool) grappleReach(TerrainMask terrain,
      int waterLevel, Unit unit, int angleDeg, int length) {
    final (x0, y0) = launchOrigin(unit, angleDeg);
    final dx = SimTrig.cosDeg(angleDeg);
    final dy = -SimTrig.sinDeg(angleDeg);
    var x = x0;
    var y = y0;
    for (var d = 0; d <= length; d++) {
      final nx = x0 + dx * d;
      final ny = y0 + dy * d;
      if (nx < 0 || nx >= terrain.width || ny >= waterLevel) break;
      if (terrain.isSolid(nx.floor(), ny.floor())) return (nx, ny, true);
      x = nx;
      y = ny;
    }
    return (x, y, false);
  }

  /// Where a shotgun shot from [unit] at [angleDeg] stops: on the first
  /// pet, ground, object or mine within [range] px (that thing returned),
  /// or at the end of its range, the map edge or the water.
  static (double, double, Object?) shotgunReach(SimWorld w, Unit unit,
      int angleDeg, int range) {
    final (x0, y0) = launchOrigin(unit, angleDeg);
    final dx = SimTrig.cosDeg(angleDeg);
    final dy = -SimTrig.sinDeg(angleDeg);
    var x = x0;
    var y = y0;
    for (var d = 0; d <= range; d++) {
      final nx = x0 + dx * d;
      final ny = y0 + dy * d;
      if (nx < 0 || nx >= w.terrain.width || ny >= w.waterLevel) break;
      x = nx;
      y = ny;
      for (final u in w._units) {
        if (!u.alive || u.id == unit.id) continue;
        final ux = u.centerX - nx;
        final uy = u.centerY - ny;
        final r = u.stats.hitRadius;
        if (ux * ux + uy * uy <= r * r) return (nx, ny, u);
      }
      for (final o in w._objects) {
        const r = ObjectConfig.size / 2;
        final ox = o.x - nx;
        final oy = o.centerY - ny;
        if (ox * ox + oy * oy <= r * r) return (nx, ny, o);
      }
      for (final m in w._mines) {
        final mx = m.x - nx;
        final my = m.centerY - ny;
        if (mx * mx + my * my <= 25) return (nx, ny, m);
      }
      if (w.terrain.isSolid(nx.floor(), ny.floor())) return (nx, ny, w.terrain);
    }
    return (x, y, null);
  }

  /// -1 / 1 from the aim angle; straight up or down keeps the facing.
  static int _horizontalDir(Unit unit, int angleDeg) {
    final c = SimTrig.cosDeg(angleDeg);
    return c > 1e-9 ? 1 : (c < -1e-9 ? -1 : unit.facing);
  }

  /// Where the satellite of [strike] parks to fire, and where each of its
  /// beams is aimed (they go on past it). Shared with the drawing.
  static ((double, double), List<(double, double)>) satelliteAim(
      PendingStrike strike) {
    final spec = strike.weapon.delivery as OrbitalStrike;
    final origin = (
      (strike.x + strike.fromDir * spec.offset).toDouble(),
      max(satelliteParkY, strike.y - spec.height).toDouble(),
    );
    // The far beam first, sweeping back towards the satellite.
    final aims = [
      for (var i = 0; i < spec.beams; i++)
        (
          strike.x +
              strike.fromDir * spec.spread * (i - (spec.beams - 1) / 2),
          strike.y.toDouble(),
        ),
    ];
    return (origin, aims);
  }

  /// Highest a satellite parks (world y).
  static const double satelliteParkY = 40;

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
  void ignite(double x, double y, Ignite spec, {int? sourceId}) {
    final cx = x.round();
    for (var i = 0; i < spec.patches; i++) {
      final offset = spec.patches == 1
          ? 0
          : (spec.spread * i) ~/ (spec.patches - 1) - spec.spread ~/ 2;
      final px = cx + offset + rng.nextIntInRange(-4, 4);
      if (px < 0 || px >= terrain.width) continue;
      // The first ground below a point a little above the blast.
      int? surface;
      for (var py = max(0, y.round() - 30);
          py < min(waterLevel, y.round() + 120);
          py++) {
        if (terrain.isSolid(px, py)) {
          surface = py;
          break;
        }
      }
      if (surface == null) continue;
      final patch = FirePatch(
        id: _nextFireId++,
        x: px,
        y: surface,
        turnsLeft: FireConfig.turns,
        ownerId: sourceId,
      );
      _fires.add(patch);
      _events.add(FireStarted(patch.id, px, surface));
    }
  }

  @override
  void nuke(double x, double y, WeaponDef weapon, Nuke spec, {int? sourceId}) {
    _events.add(NukeDetonated(x, y, weapon.radius));
    explode(x, y, weapon, sourceId: sourceId);
    _releaseGas(x, y, spec.falloutRadius, sourceId: sourceId, fallout: true);
  }

  @override
  void releaseGas(double x, double y, GasCloud spec, {int? sourceId}) =>
      _releaseGas(x, y, spec.radius, sourceId: sourceId);

  @override
  void freeze(double x, double y, WeaponDef weapon, Freeze spec,
      {int? sourceId}) {
    _events.add(IceBurst(x, y, spec.radius));
    // The cold freezes gas out of the air.
    _clouds.removeWhere((c) {
      final dx = c.x - x;
      final dy = c.y - y;
      final r = spec.radius + c.radius * 0.5;
      return dx * dx + dy * dy <= r * r;
    });
    for (final u in _units) {
      if (!u.alive) continue;
      final dx = u.centerX - x;
      final dy = u.centerY - y;
      final r = spec.radius + u.stats.hitRadius;
      if (dx * dx + dy * dy > r * r) continue;
      if (!_damage(u, weapon.maxDamage, DamageCause.impact,
          sourceId: sourceId)) {
        continue;
      }
      if (!u.frozen) _events.add(UnitFrozen(u.id));
      u.frozenTurns = 1;
    }
    for (var i = _fires.length - 1; i >= 0; i--) {
      final f = _fires[i];
      final dx = f.x - x;
      final dy = f.y - y;
      if (dx * dx + dy * dy <= spec.radius * spec.radius) {
        _fires.removeAt(i);
        _events.add(FireOut(f.id));
      }
    }
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
    if (_damage(unit, damage, DamageCause.impact, sourceId: sourceId)) {
      _knockback(unit, damage, dirX, dirY, knockbackScale);
    }
  }

  @override
  void addGround(int x, int y, int radius) {
    final left = (x - radius).clamp(0, terrain.width - 1);
    final right = (x + radius).clamp(0, terrain.width - 1);
    final top = (y - radius).clamp(0, terrain.height - 1);
    final bottom = (y + radius).clamp(0, terrain.height - 1);
    final r2 = radius * radius;
    for (var py = top; py <= bottom; py++) {
      for (var px = left; px <= right; px++) {
        final dx = px - x;
        final dy = py - y;
        if (dx * dx + dy * dy > r2 || _insideAUnit(px, py)) continue;
        terrain.data[py * terrain.width + px] = 1;
      }
    }
    _events.add(TerrainAdded(IntRect(left, top, right + 1, bottom + 1)));
  }

  @override
  void carveTunnel(int x, int y, int radius) {
    if (terrain.carveCircle(x, y, radius) != null) {
      _events.add(TerrainCarved(x, y, radius));
    }
  }

  // --------------------------------------------------------- simulation

  // ------------------------------------------------------------- targets

  // ---------------------------------------------------------------- turn

  void _stepTurn() {
    turn.phaseTicks++;
    final active = activeUnit;
    final activeGone = active == null || !active.alive;
    final t = turn.timings;

    switch (turn.phase) {
      case TurnPhase.turnStart:
        if (turn.phaseTicks >= t.bannerTicks) {
          // A frozen pet sits its turn out and thaws.
          if (active != null && active.alive && active.frozen) {
            active.frozenTurns--;
            _frozenSkip = true;
            _events.add(UnitThawed(active.id, skippedTurn: true));
            _setPhase(TurnPhase.settling);
          } else {
            _setPhase(TurnPhase.action);
          }
        }
      case TurnPhase.action:
        if (activeGone || turn.phaseTicks >= t.turnTicks) {
          _setPhase(TurnPhase.settling);
        }
      case TurnPhase.retreat:
        if (activeGone || turn.phaseTicks >= t.retreatTicks) {
          _setPhase(TurnPhase.settling);
        }
      case TurnPhase.settling:
        final atRest = _isAtRest;
        // Knocked-out pets fall once the dust settles, while the camera is
        // still on them, rather than under the next turn's banner.
        if (atRest) _killKnockedOut();
        final held = (_lastHitTick >= 0 &&
                _tick - _lastHitTick < t.hitHoldTicks) ||
            // Long enough to see the frozen pet sit its turn out.
            (_frozenSkip && turn.phaseTicks < t.bannerTicks);
        if ((atRest && !held) || turn.phaseTicks >= t.settleTimeoutTicks) {
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
      _aircraft.isEmpty &&
      _strikes.isEmpty &&
      _units.every(
          (u) =>
              !u.alive ||
              (u.grounded &&
                  !u.isDashing &&
                  !u.isDigging &&
                  !u.isGrappling)) &&
      _mines.every((m) => m.grounded && m.countdown == null) &&
      _objects.every((o) => o.grounded && o.fuse == null);

  /// Deaths from HP are resolved only once everything is at rest, then the
  /// winner check runs (PRD: Core loop).
  void _finishTurn() {
    // A settle timeout must not leave a burst half-fired into the next turn.
    _pendingShots.clear();
    _aircraft.clear();
    _strikes.clear();
    if (_suddenDeath) _maybeCrumble();
    _killKnockedOut();
    _clouds.removeWhere((c) => --c.turnsLeft <= 0);
    for (var i = _fires.length - 1; i >= 0; i--) {
      final f = _fires[i];
      if (--f.turnsLeft <= 0) {
        _fires.removeAt(i);
        _events.add(FireOut(f.id));
      }
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

  void _killKnockedOut() {
    for (final u in _units) {
      if (u.alive && u.hp <= 0) _kill(u, DeathCause.hp);
    }
  }

  void _beginTurn() {
    _burnt.clear();
    _frozenSkip = false;
    _shotgunLeft = 0;
    for (final u in _units) {
      u.gasTakenThisTurn = 0;
    }
    turn.startNextTurn([
      for (var team = 0; team < teamCount; team++)
        [
          for (final u in _units)
            if (u.team == team) (u.id, u.alive),
        ],
    ]);
    _wind = rng.nextIntInRange(PhysicsConfig.windMin, PhysicsConfig.windMax);
    // A shield lasts until its pet's own next turn.
    final active = _units[turn.activeUnitId];
    if (randomWeapons) _drawWeapon(active);
    if (active.shielded) {
      active.shielded = false;
      _events.add(ShieldPopped(active.id, blocked: false));
    }
    // Poison bites at the start of the pet's turn, never taking its last
    // HP.
    if (active.alive && active.poisoned && active.hp > 1) {
      _damage(active, min(GasConfig.damage, active.hp - 1), DamageCause.poison);
    }
    _events
      ..add(TurnStarted(team: turn.activeTeam, unitId: turn.activeUnitId))
      ..add(const PhaseChanged(TurnPhase.turnStart));
    final start = suddenDeathAfterTicks;
    if (!_suddenDeath && start != null && _tick >= start) _startSuddenDeath();
  }

  /// PRD: every unit drops to 1 HP, then the water rises each round.
  void _startSuddenDeath() {
    _suddenDeath = true;
    _turnsThisRound = 0;
    _crumbles = 0;
    _events.add(const SuddenDeathStarted());
  }

  /// A round is over once every team still in the game has had a turn;
  /// then the ground gives way near every pet and in more places each
  /// round, until there is nowhere left to stand.
  void _maybeCrumble() {
    _turnsThisRound++;
    final living = [
      for (final u in _units)
        if (u.alive) u,
    ];
    final teamsAlive = {for (final u in living) u.team}.length;
    if (_turnsThisRound < teamsAlive) return;
    _turnsThisRound = 0;
    final random = min(
      MatchDefaults.crumbleHolesMax,
      MatchDefaults.crumbleHolesFirst + _crumbles,
    );
    final holes = living.length + random;
    _crumbles++;
    const r = MatchDefaults.crumbleRadius;
    for (var i = 0; i < holes; i++) {
      final int x;
      if (i < living.length) {
        x = living[i].centerX.round() +
            rng.nextIntInRange(
              -MatchDefaults.crumbleNearPet,
              MatchDefaults.crumbleNearPet,
            );
      } else {
        x = rng.nextIntInRange(0, terrain.width - 1);
      }
      final cx = x.clamp(0, terrain.width - 1);
      var top = 0;
      while (top < _waterLevel && !terrain.isSolid(cx, top)) {
        top++;
      }
      if (top >= _waterLevel) continue;
      carveTunnel(cx, top + r ~/ 2, r);
    }
    _events.add(GroundCrumbled(holes));
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
      ..add(_turnsThisRound)
      ..add(_crumbles)
      ..add(_lastHitTick)
      ..add(_nextFireId)
      ..add(_frozenSkip ? 1 : 0)
      ..add(_shotgunLeft)
      ..add(_nextCloudId);
    // Only with the rule on, so hashes of other matches stay as they were.
    if (randomWeapons) {
      h.add(_drawn == null ? -1 : Weapons.all.indexWhere((w) => w.id == _drawn));
    }
    for (final c in _clouds) {
      h
        ..add(c.id)
        ..addDouble(c.x)
        ..add(c.turnsLeft);
    }
    for (final f in _fires) {
      h
        ..add(f.id)
        ..add(f.x)
        ..add(f.y)
        ..add(f.turnsLeft);
    }
    for (final id in _burnt.toList()..sort()) {
      h.add(id);
    }
    for (final c in turn.cursors) {
      h.add(c);
    }
    for (final team in _ammo) {
      for (final w in Weapons.shared) {
        h.add(team[w.id] ?? -1);
      }
    }
    h.add(loadout.signatures ? 1 : 0);
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
        ..add(u.digTicks)
        ..addDouble(u.digLeft)
        ..add(u.grappleTicks)
        ..add(u.frozenTurns)
        ..add(u.shielded ? 1 : 0)
        ..add(u.poisoned ? 1 : 0)
        ..add(u.gasTicks)
        ..add(u.gasTakenThisTurn)
        ..addDouble(u.grappleX)
        ..addDouble(u.grappleY)
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
        ..addDouble(p.traveled)
        ..addDouble(p.targetX ?? -1)
        ..addDouble(p.targetY ?? -1)
        ..add(p.stuckTo ?? -2)
        ..add(p.hitUnits.length);
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
    h.add(_nextObjectId);
    h.add(_objects.length);
    for (final o in _objects) {
      h
        ..add(o.id)
        ..add(o.kind.index)
        ..add(o.fuse ?? -1)
        ..add(o.grounded ? 1 : 0)
        ..addDouble(o.x)
        ..addDouble(o.y);
    }
    h.add(_pendingShots.length);
    h.add(_aircraft.length);
    for (final b in _aircraft) {
      h
        ..add(b.dir)
        ..add(b.dropped)
        ..addDouble(b.x);
    }
    h.add(_strikes.length);
    for (final s in _strikes) {
      h
        ..add(s.dueTick)
        ..add(s.x)
        ..add(s.shot);
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
