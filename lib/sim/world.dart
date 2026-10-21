import 'dart:collection';
import 'dart:math' show max, min, sqrt;
import 'dart:typed_data';

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
    this.loadout = WeaponLoadout.standard,
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
    );
  }

  final int seed;

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
  int _turnsSinceRise = 0;

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

  /// Starter objects on flat ground away from the units ([unitPoints]):
  /// mines (armed from the first turn), barrels and crates.
  void _placeObjects(ObjectMix mix, List<(int, int)> unitPoints) {
    final points = findObjectPoints(
      terrain: terrain,
      waterLevel: waterLevel,
      count: mix.total,
      rng: rng,
      avoid: unitPoints,
      minDistance: ObjectConfig.minDistanceBetween,
      avoidDistance: ObjectConfig.minDistanceFromUnits,
    );
    final kinds = [
      for (var i = 0; i < mix.mines; i++) null,
      for (var i = 0; i < mix.barrels; i++) ObjectKind.barrel,
      for (var i = 0; i < mix.healthCrates; i++) ObjectKind.healthCrate,
      for (var i = 0; i < mix.weaponCrates; i++) ObjectKind.weaponCrate,
    ];
    for (var i = 0; i < points.length; i++) {
      final (x, y) = points[i];
      final kind = kinds[i];
      if (kind == null) {
        _mines.add(Mine(
          id: _nextMineId++,
          weapon: Weapons.mine,
          x: x.toDouble(),
          y: y.toDouble(),
          armedOnTurn: 0,
        )..grounded = true);
      } else {
        addObject(kind, x, y);
      }
    }
  }

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

    if (weapon.delivery case final Shotgun spec) {
      _shotgun(unit, weapon, spec, input.angleDeg);
      return;
    }
    if (weapon.delivery case Grapple(:final length)) {
      _grapple(unit, weapon, input.angleDeg, length);
      return;
    }
    switch (weapon.delivery) {
      case Launch(:final shots, :final spreadDeg)
          when spreadDeg > 0 && shots > 1:
        for (var i = 0; i < shots; i++) {
          final offset = (spreadDeg * (2 * i - (shots - 1))) ~/ (2 * (shots - 1));
          _launchShot(unit, weapon, input, angleDeg: input.angleDeg + offset);
        }
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
      case final AirRaid raid:
        _callAirRaid(unit, raid, tx!, ty!);
      case final MeteorShower shower:
        _meteorShower(unit, shower, tx!, ty!);
      case Grapple() || Shotgun():
        break; // Handled above.
      case ShieldUp():
        unit.shielded = true;
        _events.add(ShieldRaised(unit.id));
      case OrbitalStrike(:final delayTicks) ||
          Lightning(:final delayTicks) when delayTicks > 0:
        _strikes.add(PendingStrike(
          dueTick: _tick + delayTicks,
          x: tx!,
          y: ty!,
          ownerId: unit.id,
          weapon: weapon,
          firedTick: _tick,
          // The cloud rides in on the wind; the satellite parks on the
          // side towards the middle of the map, so its beams start on it.
          fromDir: weapon.delivery is OrbitalStrike
              ? (tx < terrain.width / 2 ? 1 : -1)
              : (_wind >= 0 ? -1 : 1),
        ));
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
      case DigMode(:final durationTicks, :final maxDistance):
        unit
          ..digTicks = durationTicks
          ..digLeft = maxDistance;
        // Digging starts with a hole around the body.
        carveTunnel(unit.centerX.round(), unit.centerY.round(),
            (weapon.delivery as DigMode).carveRadius);
      case SwapPlaces():
        final other = ProjectilePhysics.unitAt(
            tx!.toDouble(), ty!.toDouble(), _units)!;
        final (x, y) = (unit.x, unit.y);
        unit
          ..x = other.x
          ..y = other.y;
        other
          ..x = x
          ..y = y;
        UnitPhysics.launch(unit, 0, 0);
        UnitPhysics.launch(other, 0, 0);
        _events
          ..add(UnitTeleported(unit.id))
          ..add(UnitTeleported(other.id));
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
      case Beam(:final length, :final carveRadius):
        unit.facing = dir;
        _beam(unit, weapon, input.angleDeg, length, carveRadius);
      case Lightning():
        _lightning(unit.id, weapon, tx!);
      case OrbitalStrike():
        _strikes.add(PendingStrike(
            dueTick: _tick + 1, x: tx!, y: ty!, ownerId: unit.id,
            weapon: weapon, firedTick: _tick));
      case DropCharge():
        final f = unit.facing;
        spawnProjectile(Projectile(
          id: nextProjectileId(),
          ownerId: unit.id,
          weapon: weapon,
          x: unit.centerX + f * (unit.stats.hitRadius + 3),
          y: unit.centerY,
          vx: f * 20,
          vy: -60,
          fuseTicks: weapon.fuseTicks,
        ));
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
    } else if (_ammo[unit.team][weapon.id] case final int left) {
      _ammo[unit.team][weapon.id] = left - 1;
    }
    _events.add(WeaponUsed(unit.id, weapon.id));
    turn.hasFired = true;
    // Digging keeps the action phase (and its clock) until it ends.
    if (weapon.delivery is DigMode) return;
    _setPhase(weapon.endsTurn ? TurnPhase.settling : TurnPhase.retreat);
  }

  /// Hujan Meteor: every meteor is in the air at once, stacked high above
  /// the map, so they land one after another. Each falls at a slant with
  /// the wind, aimed to reach the marked height at its landing column.
  void _meteorShower(Unit unit, MeteorShower spec, int tx, int ty) {
    final child = Weapons.byId(spec.childId);
    final g = PhysicsConfig.gravity * child.gravityScale;
    final windDir = _wind >= 0 ? 1 : -1;
    final vx = spec.speed * 0.45;
    for (var i = 0; i < spec.count; i++) {
      final landX = (tx + rng.nextIntInRange(-spec.spread, spec.spread))
          .clamp(4, terrain.width - 5);
      final y0 = -80.0 - i * spec.gap;
      final vy = spec.speed;
      final t = (-vy + sqrt(vy * vy + 2 * g * (ty - y0))) / g;
      var dir = windDir;
      var x0 = landX - dir * vx * t;
      // Coming in from off the map: from the other side instead.
      if (x0 < 1 || x0 > terrain.width - 2) {
        dir = -dir;
        x0 = landX - dir * vx * t;
      }
      spawnProjectile(Projectile(
        id: nextProjectileId(),
        ownerId: unit.id,
        weapon: child,
        x: x0.clamp(1.0, terrain.width - 2.0),
        y: y0,
        vx: dir * vx,
        vy: vy,
      ));
    }
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

  /// One shotgun pull. The first uses up the weapon and leaves the turn
  /// in the action phase for the rest; the last moves on to the retreat.
  void _shotgun(Unit unit, WeaponDef weapon, Shotgun spec, int angleDeg) {
    if (_shotgunLeft == 0) {
      if (_ammo[unit.team][weapon.id] case final int left) {
        _ammo[unit.team][weapon.id] = left - 1;
      }
      _shotgunLeft = spec.shots;
      _events.add(WeaponUsed(unit.id, weapon.id));
    }
    _shotgunLeft--;
    unit.facing = SimTrig.cosDeg(angleDeg) >= 0 ? 1 : -1;
    final (x0, y0) = launchOrigin(unit, angleDeg);
    final (x, y, hit) = shotgunReach(this, unit, angleDeg, spec.range);
    _events.add(ShotgunFired(unit.id, x0, y0, x, y));
    switch (hit) {
      case final Unit u:
        strikeUnit(u, weapon.maxDamage, SimTrig.cosDeg(angleDeg),
            -SimTrig.sinDeg(angleDeg), weapon.knockbackScale,
            sourceId: unit.id);
      case final MapObject o:
        _hitObject(o);
      case final Mine m:
        m.countdown = min(m.countdown ?? 1, 1);
      case TerrainMask():
        carveTunnel(x.round(), y.round(), spec.carveRadius);
      default:
        break;
    }
    if (_shotgunLeft == 0) {
      turn.hasFired = true;
      _setPhase(TurnPhase.retreat);
    }
  }

  /// Tali Pengait: a hooked shot reels the unit in (see [_stepGrapple]);
  /// only then is a hook used up. Either way the turn goes on.
  void _grapple(Unit unit, WeaponDef weapon, int angleDeg, int length) {
    final (x0, y0) = launchOrigin(unit, angleDeg);
    final (x, y, hooked) =
        grappleReach(terrain, waterLevel, unit, angleDeg, length);
    unit.facing = SimTrig.cosDeg(angleDeg) >= 0 ? 1 : -1;
    _events.add(GrappleFired(unit.id, x0, y0, x, y, hooked));
    if (!hooked) return;
    unit
      ..grappleTicks = GrappleConfig.maxReelTicks
      ..grappleX = x
      ..grappleY = y
      ..grounded = false
      ..gliding = false
      ..vx = 0
      ..vy = 0;
    if (_ammo[unit.team][weapon.id] case final int left) {
      _ammo[unit.team][weapon.id] = left - 1;
    }
    _events.add(WeaponUsed(unit.id, weapon.id));
  }

  /// One tick of being reeled in: the body moves straight at the anchor
  /// (no gravity) until it is there, the ground is in the way, or time is
  /// up. Then it lets go and falls from where it is.
  void _stepGrapple(Unit u) {
    final spec = Weapons.grapple.delivery as Grapple;
    var move = spec.speed * PhysicsConfig.dt;
    var done = --u.grappleTicks <= 0;
    final h = u.stats.bodyHeight;
    while (!done && move > 0) {
      final dx = u.grappleX - u.centerX;
      final dy = u.grappleY - u.centerY;
      final dist = sqrt(dx * dx + dy * dy);
      if (dist <= u.stats.hitRadius + 1) {
        done = true;
        break;
      }
      final s = min(1.0, move);
      move -= s;
      final nx = u.x + dx / dist * s;
      final ny = u.y + dy / dist * s;
      if (nx < 1 ||
          nx >= terrain.width - 1 ||
          !UnitPhysics.bodyFree(terrain, nx.floor(), ny.floor(), h)) {
        done = true;
        break;
      }
      u
        ..x = nx
        ..y = ny;
    }
    if (done) {
      u
        ..grappleTicks = 0
        ..peakY = u.y;
      if (!_pullUpOnto(u)) UnitPhysics.launch(u, 0, 0);
    }
  }

  /// At the end of a reel-in close to the hook: if the hook is in the lip
  /// of a ledge (ground with room for the body on top within a pull-up),
  /// climb onto it. Hooking the top of the ground lands there too.
  bool _pullUpOnto(Unit u) {
    final ax = u.grappleX.floor();
    final ay = u.grappleY.floor();
    final h = u.stats.bodyHeight;
    final dx = u.grappleX - u.centerX;
    final dy = u.grappleY - u.centerY;
    final reach = u.stats.hitRadius + h;
    if (dx * dx + dy * dy > reach * reach) return false;
    for (var foot = ay; foot >= ay - h - GrappleConfig.pullUp; foot--) {
      if (!terrain.isSolid(ax, foot)) return false;
      if (!terrain.isSolid(ax, foot - 1) &&
          UnitPhysics.bodyFree(terrain, ax, foot, h)) {
        u
          ..x = ax.toDouble()
          ..y = foot.toDouble()
          ..vx = 0
          ..vy = 0
          ..grounded = true
          ..gliding = false
          ..peakY = foot.toDouble()
          ..airJumpsLeft = u.stats.airJumps;
        return true;
      }
    }
    return false;
  }

  /// One tick of tunnelling towards [angleDeg]: carves ahead of the body
  /// and moves it, staying inside the map and above the water.
  void _dig(Unit unit, int angleDeg) {
    final spec = Weapons.digClaws.delivery as DigMode;
    final step = min(unit.digLeft, spec.speed * PhysicsConfig.dt);
    if (step <= 0) return;
    final dx = SimTrig.cosDeg(angleDeg) * step;
    final dy = -SimTrig.sinDeg(angleDeg) * step;
    final h = unit.stats.bodyHeight.toDouble();
    final nx = (unit.x + dx).clamp(2.0, terrain.width - 3.0);
    final ny = (unit.y + dy).clamp(h + 2, waterLevel - 2.0);
    unit
      ..x = nx
      ..y = ny
      ..digLeft -= step
      ..vx = 0
      ..vy = 0;
    if (dx.abs() > 1e-9) unit.facing = dx > 0 ? 1 : -1;
    carveTunnel(unit.centerX.round(), unit.centerY.round(), spec.carveRadius);
  }

  /// Dig mode is over: the unit drops from wherever it is and the retreat
  /// starts.
  void _stopDigging(Unit unit) {
    unit
      ..digTicks = 0
      ..digLeft = 0;
    UnitPhysics.launch(unit, 0, 0);
    if (turn.phase == TurnPhase.action) _setPhase(TurnPhase.retreat);
  }

  /// -1 / 1 from the aim angle; straight up or down keeps the facing.
  static int _horizontalDir(Unit unit, int angleDeg) {
    final c = SimTrig.cosDeg(angleDeg);
    return c > 1e-9 ? 1 : (c < -1e-9 ? -1 : unit.facing);
  }

  void _launchShot(Unit unit, WeaponDef weapon, Fire input, {int? angleDeg}) {
    final angle = angleDeg ?? input.angleDeg;
    final (x, y) = launchOrigin(unit, angle);
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
      angleDeg: angle,
      powerPercent: input.powerPercent,
      speedScale: unit.stats.firePowerScale * weapon.launchSpeedScale,
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
    final dirX = SimTrig.cosDeg(angle);
    if (dirX.abs() > 1e-9) unit.facing = dirX > 0 ? 1 : -1;
    spawnProjectile(p);
  }

  /// Air raids come from the shooter's side of the target. Free-falling
  /// payloads are released early by the distance they drift while falling
  /// from the craft to the ground under the tapped column (or the water),
  /// so they land around it wherever in the column the player tapped; a
  /// guided payload is released [AirRaid.releaseAhead] before the spot.
  void _callAirRaid(Unit unit, AirRaid raid, int tx, int ty) {
    final payload = Weapons.byId(raid.childId);
    final dir = tx >= unit.centerX ? 1 : -1;
    final ahead = raid.releaseAhead;
    final double lead;
    if (ahead != null) {
      lead = ahead.toDouble();
    } else {
      var ground = raid.altitude;
      while (ground < waterLevel && !terrain.isSolid(tx, ground)) {
        ground++;
      }
      final height = ground - raid.altitude;
      final fallSeconds = height > 0
          ? sqrt(2 * height / (PhysicsConfig.gravity * payload.gravityScale))
          : 0.0;
      lead = raid.speed * fallSeconds;
    }
    final drops = [
      for (var i = 0; i < raid.count; i++)
        (tx + dir * ((i * 2 - (raid.count - 1)) * raid.spacing / 2 - lead))
            .clamp(0, terrain.width - 1)
            .toDouble(),
    ];
    _aircraft.add(Aircraft(
      ownerId: unit.id,
      craft: raid.craft,
      payload: payload,
      dir: dir,
      x: drops.first - dir * raid.leadIn,
      y: raid.altitude.toDouble(),
      speed: raid.speed,
      dropXs: drops,
      exitX: drops.last + dir * raid.leadIn,
      targetX: tx.toDouble(),
      targetY: ty.toDouble(),
    ));
  }

  /// Moves aircraft (dropping their payload as they pass their release
  /// points) and lands strikes from the sky that are due.
  void _stepAirSupport() {
    for (var i = _aircraft.length - 1; i >= 0; i--) {
      final b = _aircraft[i];
      b.x += b.dir * b.speed * PhysicsConfig.dt;
      while (b.dropped < b.dropXs.length &&
          (b.dir > 0
              ? b.x >= b.dropXs[b.dropped]
              : b.x <= b.dropXs[b.dropped])) {
        final x = b.dropXs[b.dropped++];
        final y = b.y + 8;
        final p = Projectile(
          id: nextProjectileId(),
          ownerId: b.ownerId,
          weapon: b.payload,
          x: x,
          y: y,
          vx: b.dir * b.speed,
          vy: 0,
        );
        if (b.payload.flight case Homing(chosenTarget: true)) {
          p
            ..targetX = b.targetX
            ..targetY = b.targetY;
        }
        spawnProjectile(p);
        _events.add(BombDropped(x, y));
      }
      if (b.gone) _aircraft.removeAt(i);
    }
    for (var i = _strikes.length - 1; i >= 0; i--) {
      final strike = _strikes[i];
      if (strike.dueTick > _tick) continue;
      _strikes.removeAt(i);
      if (strike.weapon.delivery case final OrbitalStrike spec) {
        _orbital(strike);
        if (strike.shot + 1 < spec.beams) {
          _strikes.add(strike.nextShot(_tick + spec.intervalTicks));
        }
      } else {
        _lightning(strike.ownerId, strike.weapon, strike.x);
      }
    }
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

  /// Satelit: fires beam [PendingStrike.shot] from the satellite through
  /// its aim point. It burns a channel only [OrbitalStrike.depth] px past
  /// the first ground or pet it meets, hits every unit within reach of its
  /// line once (pushed along the beam), and sets off mines and objects on
  /// it.
  void _orbital(PendingStrike strike) {
    final weapon = strike.weapon;
    final spec = weapon.delivery as OrbitalStrike;
    final ((ox, oy), aims) = satelliteAim(strike);
    final (ax, ay) = aims[strike.shot];
    final len = sqrt((ax - ox) * (ax - ox) + (ay - oy) * (ay - oy));
    final dx = (ax - ox) / len;
    final dy = (ay - oy) / len;
    var x = ox;
    var y = oy;
    var burnt = -1;
    final hit = <int>{};
    for (var d = 0; burnt < spec.depth; d++) {
      final nx = ox + dx * d;
      final ny = oy + dy * d;
      if (nx < 0 || nx >= terrain.width || ny >= waterLevel ||
          ny >= terrain.height) {
        break;
      }
      x = nx;
      y = ny;
      if (burnt < 0 &&
          (terrain.isSolid(nx.floor(), ny.floor()) ||
              ProjectilePhysics.unitAt(nx, ny, _units) != null)) {
        burnt = 0;
      }
      if (burnt >= 0) {
        if (burnt % 3 == 0) {
          terrain.carveCircle(nx.round(), ny.round(), spec.carveRadius);
        }
        burnt++;
      }
      for (final u in _units) {
        if (!u.alive || hit.contains(u.id)) continue;
        final ux = u.centerX - nx;
        final uy = u.centerY - ny;
        final r = weapon.radius + u.stats.hitRadius;
        if (ux * ux + uy * uy <= r * r) {
          hit.add(u.id);
          strikeUnit(u, weapon.maxDamage, dx, dy, weapon.knockbackScale,
              sourceId: strike.ownerId);
        }
      }
      for (final m in _mines) {
        final mx = m.x - nx;
        final my = m.centerY - ny;
        if (mx * mx + my * my <= weapon.radius * weapon.radius + 36) {
          m.countdown = min(m.countdown ?? 1, 1);
        }
      }
      for (final o in _objects) {
        final px = o.x - nx;
        final py = o.centerY - ny;
        final r = ObjectConfig.size / 2 + weapon.radius;
        if (px * px + py * py <= r * r) _hitObject(o);
      }
    }
    _events.add(SatelliteStruck(ox, oy, x, y, spec.carveRadius,
        last: strike.shot + 1 >= spec.beams));
  }

  /// Laser: walks the line 1 px at a time from the launch point, burning
  /// the ground every few px, hitting each unit once and setting off mines
  /// it touches. Stops at the map edge or the water.
  void _beam(Unit unit, WeaponDef weapon, int angleDeg, int length, int radius) {
    final (x0, y0) = launchOrigin(unit, angleDeg);
    final dx = SimTrig.cosDeg(angleDeg);
    final dy = -SimTrig.sinDeg(angleDeg);
    var x = x0;
    var y = y0;
    final hit = <int>{};
    for (var d = 0; d < length; d++) {
      final nx = x0 + dx * d;
      final ny = y0 + dy * d;
      if (nx < 0 || nx >= terrain.width || ny < 0 || ny >= terrain.height ||
          ny >= waterLevel) {
        break;
      }
      x = nx;
      y = ny;
      if (d % 3 == 0) terrain.carveCircle(x.round(), y.round(), radius);
      for (final u in _units) {
        if (!u.alive || u.id == unit.id || hit.contains(u.id)) continue;
        final ux = u.centerX - x;
        final uy = u.centerY - y;
        final r = u.stats.hitRadius;
        if (ux * ux + uy * uy <= r * r) {
          hit.add(u.id);
          strikeUnit(u, weapon.maxDamage, dx, dy, weapon.knockbackScale,
              sourceId: unit.id);
        }
      }
      for (final m in _mines) {
        final mx = m.x - x;
        final my = m.centerY - y;
        if (mx * mx + my * my <= 36) m.countdown = min(m.countdown ?? 1, 1);
      }
      for (final o in _objects) {
        final ox = o.x - x;
        final oy = o.centerY - y;
        const r = ObjectConfig.size / 2 + 2;
        if (ox * ox + oy * oy <= r * r) _hitObject(o);
      }
    }
    _events.add(BeamFired(x0, y0, x, y, radius));
  }

  /// Thunder Cloud: the bolt runs down column [x] from the top of the map
  /// and blasts the first ground or living unit; over open water it fizzles
  /// at the surface.
  void _lightning(int ownerId, WeaponDef weapon, int x) {
    var y = 0;
    while (y < waterLevel && y < terrain.height) {
      if (terrain.isSolid(x, y) ||
          ProjectilePhysics.unitAt(x + 0.5, y + 0.5, _units) != null) {
        break;
      }
      y++;
    }
    _events.add(LightningStruck(x, y));
    _blast(x, y, weapon,
        cause: DamageCause.explosion,
        carve: weapon.terrainDamage,
        sourceId: ownerId);
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
  void freeze(double x, double y, WeaponDef weapon, Freeze spec,
      {int? sourceId}) {
    _events.add(IceBurst(x, y, spec.radius));
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

  /// Fire settles onto the ground below it if that is blown away, goes out
  /// in water, and burns any pet touching it once a turn.
  void _stepFires() {
    for (var i = _fires.length - 1; i >= 0; i--) {
      final f = _fires[i];
      for (var k = 0; k < 3 && !terrain.isSolid(f.x, f.y); k++) {
        f.y++;
      }
      if (f.y >= waterLevel || f.y >= terrain.height) {
        _fires.removeAt(i);
        _events.add(FireOut(f.id));
      }
    }
    final phase = turn.phase;
    if (_fires.isEmpty ||
        phase == TurnPhase.turnStart ||
        phase == TurnPhase.matchOver) {
      return;
    }
    for (final u in _units) {
      if (!u.alive || _burnt.contains(u.id)) continue;
      for (final f in _fires) {
        final dx = u.centerX - f.x;
        final dy = u.centerY - (f.y - 5);
        final r = u.stats.hitRadius + FireConfig.reach;
        if (dx * dx + dy * dy > r * r) continue;
        _burnt.add(u.id);
        if (!_damage(u, FireConfig.damage, DamageCause.fire,
                sourceId: f.ownerId)) {
          break;
        }
        if (u.frozen) {
          u.frozenTurns = 0;
          _events.add(UnitThawed(u.id, skippedTurn: false));
        }
        break;
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

  /// Whether pixel ([px], [py]) is in (or right next to) a living unit's
  /// body column, which added ground must never fill.
  bool _insideAUnit(int px, int py) {
    for (final u in _units) {
      if (!u.alive) continue;
      final cx = u.x.floor();
      if ((px - cx).abs() > 2) continue;
      if (py >= u.y - u.stats.bodyHeight - 2 && py <= u.y) return true;
    }
    return false;
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
      if (!_damage(u, damage, cause, sourceId: sourceId)) continue;
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

    final reach = radius + ObjectConfig.size / 2;
    for (final o in _objects) {
      final dx = o.x - x;
      final dy = o.centerY - y;
      if (dx * dx + dy * dy <= reach * reach) _hitObject(o);
    }
  }

  /// Caught in a blast or a beam: a barrel lights (and blows up shortly),
  /// a crate breaks.
  void _hitObject(MapObject o) {
    if (o.kind == ObjectKind.barrel) {
      o.fuse = min(o.fuse ?? ObjectConfig.barrelFuseTicks,
          ObjectConfig.barrelFuseTicks);
    } else {
      o.destroyed = true;
    }
  }

  /// Objects fall when the ground under them goes; lit barrels count down
  /// and explode; a unit touching a crate picks it up.
  void _stepObjects() {
    for (var i = _objects.length - 1; i >= 0; i--) {
      if (i >= _objects.length) continue;
      final o = _objects[i];
      if (o.destroyed) continue;
      final move = MinePhysics.step(o, terrain, waterLevel);
      if (move == MineMove.water || move == MineMove.outOfBounds) {
        o.destroyed = true;
        continue;
      }
      final fuse = o.fuse;
      if (fuse != null) {
        if (fuse <= 1) {
          _objects.removeAt(i);
          _events.add(ObjectRemoved(o.id));
          _blast(o.x.round(), o.centerY.round(), Weapons.barrel,
              cause: DamageCause.explosion, carve: true);
        } else {
          o.fuse = fuse - 1;
        }
        continue;
      }
      if (o.kind == ObjectKind.barrel) continue;
      for (final u in _units) {
        if (!u.alive) continue;
        final dx = u.centerX - o.x;
        final dy = u.centerY - o.centerY;
        const r = ObjectConfig.pickupRadius;
        if (dx * dx + dy * dy <= r * r) {
          _collect(u, o);
          o.destroyed = true;
          break;
        }
      }
    }
    for (var i = _objects.length - 1; i >= 0; i--) {
      if (!_objects[i].destroyed) continue;
      _events.add(ObjectRemoved(_objects[i].id));
      _objects.removeAt(i);
    }
  }

  /// Health crate: HP up to the unit's maximum. Weapon crate: one more of
  /// a random limited weapon this match uses, for the unit's team.
  void _collect(Unit u, MapObject crate) {
    if (crate.kind == ObjectKind.healthCrate) {
      final before = u.hp;
      u.hp = min(u.stats.maxHp, u.hp + ObjectConfig.healthAmount);
      _events.add(CrateCollected(u.id, health: true, hp: u.hp - before));
      return;
    }
    final ammo = _ammo[u.team];
    final choices = [
      for (final w in Weapons.shared)
        if (loadout.enabled(w) && ammo[w.id] != null) w,
    ];
    if (choices.isEmpty) {
      _events.add(CrateCollected(u.id, health: false));
      return;
    }
    final w = choices[rng.nextIntInRange(0, choices.length - 1)];
    ammo[w.id] = ammo[w.id]! + 1;
    _events.add(CrateCollected(u.id, health: false, weaponId: w.id));
  }

  /// Applies [amount] of damage, with the unit's damage-taken modifier for
  /// explosions and its lethal save (Kucing) if it has one left.
  ///
  /// A shield takes the hit instead (not a fall or the water): returns
  /// false then, so the caller skips knockback and other effects.
  bool _damage(Unit u, int amount, DamageCause cause, {int? sourceId}) {
    if (u.shielded &&
        cause != DamageCause.fall &&
        cause != DamageCause.water) {
      u.shielded = false;
      _lastHitTick = _tick;
      _events.add(ShieldPopped(u.id, blocked: true));
      return false;
    }
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
    if (dealt <= 0) return true;
    u.hp -= dealt;
    _lastHitTick = _tick;
    _events.add(UnitDamaged(u.id, dealt, cause, sourceUnitId: sourceId));
    return true;
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
      _events.add(ProjectileRemoved(p.id, outcome, x: p.x, y: p.y));
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
      if (u.isDigging) {
        // Held in its tunnel (no gravity) until digging ends.
        u.digTicks--;
        if (u.digTicks <= 0 || u.digLeft <= 0 ||
            turn.phase != TurnPhase.action) {
          _stopDigging(u);
        }
      } else if (u.isDashing) {
        _stepDash(u);
      } else if (u.isGrappling) {
        _stepGrapple(u);
      } else {
        if (walkDir != 0 && u == active) {
          UnitPhysics.walk(u, walkDir, terrain);
        }
        UnitPhysics.checkSupport(u, terrain);
        if (!u.grounded) {
          final fell = UnitPhysics.stepAirborne(u, terrain);
          if (fell != null) _events.add(UnitLanded(u.id, fell));
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
    _lastHitTick = _tick;
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
    if (_suddenDeath) _maybeRaiseWater();
    _killKnockedOut();
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
    if (active.shielded) {
      active.shielded = false;
      _events.add(ShieldPopped(active.id, blocked: false));
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
      ..add(_turnsSinceRise)
      ..add(_lastHitTick)
      ..add(_nextFireId)
      ..add(_frozenSkip ? 1 : 0)
      ..add(_shotgunLeft);
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
        ..add(p.stuckTo ?? -2);
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
