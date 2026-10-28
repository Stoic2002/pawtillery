import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../ai/cpu_player.dart';
import '../config/controls.dart';
import '../config/cpu.dart';
import '../config/families.dart';
import '../config/map_objects.dart';
import '../config/maps.dart';
import '../config/teams.dart';
import '../config/match_defaults.dart';
import '../config/net.dart';
import '../config/weapons.dart';
import '../net/lockstep.dart';
import '../sim/events.dart';
import '../sim/inputs.dart';
import '../sim/physics.dart';
import '../sim/match_setup.dart';
import '../sim/turn_manager.dart';
import '../sim/unit.dart';
import '../sim/world.dart';
import 'camera/arena_camera.dart';
import 'components/aim_guide_component.dart';
import 'components/air_support_component.dart';
import 'components/backdrop_components.dart';
import 'components/damage_numbers_component.dart';
import 'components/decor_component.dart';
import 'components/fire_component.dart';
import 'components/gas_component.dart';
import 'components/grapple_component.dart';
import 'components/map_objects_component.dart';
import 'components/projectiles_component.dart';
import 'components/scenery_component.dart';
import 'components/terrain_component.dart';
import 'components/units_component.dart';
import 'effects/particle_system.dart';
import 'hud_state.dart';
import 'map_loader.dart';
import 'match_stats.dart';

/// Main-thread cost of the last explosion: sim step (mask carve, damage)
/// plus scheduling the chunk re-render. PRD target: under 4 ms.
class ExplosionTiming {
  const ExplosionTiming({required this.lastMs, required this.maxMs});
  final double lastMs;
  final double maxMs;
}

/// Frame rate over the last half second (debug/profile readout). PRD
/// target: steady 60 fps, never below 50 during cluster explosions.
class FrameStats {
  const FrameStats({required this.fps, required this.worstMs});
  final int fps;
  final double worstMs;
}

/// One entry of the weapon menu for the active unit.
class WeaponChoice {
  const WeaponChoice({
    required this.weapon,
    required this.ammoLeft,
    required this.usable,
  });

  final WeaponDef weapon;

  /// null = unlimited (or a signature weapon).
  final int? ammoLeft;
  final bool usable;
}

/// Renders [SimWorld], drives it at a fixed 60 Hz and turns player gestures
/// into discrete sim inputs. Owns no game rules.
class PawtilleryGame extends FlameGame {
  PawtilleryGame({
    required this.seed,
    required this.rosters,
    required this.teamColors,
    this.teamSymbols = const [],
    required this.unitNames,
    required this.map,
    this.timings = const TurnTimings(),
    this.suddenDeathAfterTicks,
    this.loadout = WeaponLoadout.standard,
    this.showAimGuide = true,
    this.lockstep,
    this.objects,
    this.cpuTeams = const {},
    this.randomWeapons = false,
  });

  final int seed;
  final List<List<UnitSpec>> rosters;

  /// Colour (0xAARRGGBB) of each team, in roster order.
  final List<int> teamColors;

  /// Each team's mark, shown on unit labels.
  final List<TeamSymbol> teamSymbols;

  /// Display name of each unit, in roster order (= unit id).
  final List<String> unitNames;
  final MapDef map;
  final TurnTimings timings;
  final int? suddenDeathAfterTicks;

  /// Weapons on and their ammo (setup's Weapons tab).
  final WeaponLoadout loadout;

  /// Settings: draw the aim guide path (the readout always shows).
  bool showAimGuide;

  /// Starter objects to place (barrels, crates, mines); null = none.
  final ObjectMix? objects;

  /// Play on Wi-Fi: steps come from the network instead of the clock
  /// alone, and only the active team's phone has controls.
  final Lockstep? lockstep;

  /// Random weapons rule (see [SimWorld.randomWeapons]).
  final bool randomWeapons;

  /// Teams the computer plays (hotseat only), by sim team index.
  final Map<int, CpuLevel> cpuTeams;
  late final CpuPlayer? _cpu =
      cpuTeams.isEmpty ? null : CpuPlayer(levels: cpuTeams, seed: seed);

  late final MatchStats stats;
  final ParticleSystem particles = ParticleSystem();

  /// Every sim event, for effects outside the game (sound, vibration).
  void Function(SimEvent event)? onEvent;

  late final SimWorld sim;
  late final TerrainComponent _terrain;
  late final AimGuideComponent _aimGuide;
  late final ArenaCamera _camera;
  late final MapObjectsComponent _objects;
  late final DamageNumbersComponent _damage;
  late final AirSupportComponent _airSupport;
  late final GrappleComponent _grapple;

  /// Where each burning patch is, for the puff when it goes out.
  final Map<int, Vector2> _firePos = {};

  // State the Flutter HUD listens to.
  final hud = ValueNotifier<HudState?>(null);
  final aim = ValueNotifier<AimState>(AimState(
    weaponId: Weapons.rock.id,
    active: false,
    angle: ControlsConfig.initialAngle,
    power: ControlsConfig.initialPower,
    fuseSeconds: FuseConfig.defaultSeconds,
  ));
  final explosionTiming = ValueNotifier<ExplosionTiming?>(null);
  final frameStats = ValueNotifier<FrameStats?>(null);
  double _fpsWindow = 0;
  double _fpsWorst = 0;
  int _fpsFrames = 0;

  /// Each team keeps its last chosen weapon between turns.
  final Map<int, String> _weaponByTeam = {};

  /// The weapon held before a target weapon was picked, for Cancel.
  String? _beforeTarget;

  final List<SimInput> _pendingInputs = [];
  int _walkDir = 0;

  /// Dig mode: the joystick's direction (degrees), null while released.
  int? _digAngle;
  double _accumulator = 0;
  final Stopwatch _stopwatch = Stopwatch();

  @override
  Color backgroundColor() => Color(map.skyBottomArgb);

  @override
  Future<void> onLoad() async {
    final mapData = await loadMapData(map.maskAsset);
    final mask = mapData.mask;
    sim = SimWorld.newMatch(
      seed: seed,
      terrain: mask,
      waterLevel: map.waterLevel,
      rosters: rosters,
      timings: timings,
      suddenDeathAfterTicks: suddenDeathAfterTicks,
      loadout: loadout,
      objects: objects,
      randomWeapons: randomWeapons,
    );
    stats = MatchStats(sim);
    lockstep?.attach(sim);

    final worldSize = Vector2(mask.width.toDouble(), mask.height.toDouble());
    _terrain = TerrainComponent(
      mask: mask,
      map: map,
      materials: mapData.materials,
      visible: () => visibleWorld,
    );
    _aimGuide = AimGuideComponent(
      sim: sim,
      aim: () => aim.value,
      // The CPU's shot path stays a surprise.
      showPath: () => showAimGuide && !cpuTurn,
      teamColors: teamColors,
    );
    await world.addAll([
      SkyComponent(map: map, worldSize: worldSize),
      SceneryComponent(
        map: map,
        worldSize: worldSize,
        cameraPosition: () => camera.viewfinder.position,
      ),
      _terrain,
      DecorComponent(
        mask: mask,
        map: map,
        materials: mapData.materials,
        visible: () => visibleWorld,
      ),
      UnitsComponent(
        sim,
        teamColors: teamColors,
        teamSymbols: teamSymbols,
        unitNames: unitNames,
      ),
      _objects = MapObjectsComponent(sim),
      _grapple = GrappleComponent(sim),
      FireComponent(sim),
      GasComponent(sim),
      ProjectilesComponent(sim),
      _airSupport = AirSupportComponent(
        sim,
        teamColors: teamColors,
        viewHeight: () => camera.viewport.virtualSize.y / _camera.zoom,
      ),
      WaterBackComponent(
          map: map, worldSize: worldSize, level: () => sim.waterLevel),
      WaterComponent(
          map: map, worldSize: worldSize, level: () => sim.waterLevel),
      _aimGuide,
      particles,
      _damage = DamageNumbersComponent(sim),
    ]);

    _camera = ArenaCamera(camera: camera, worldSize: worldSize)
      ..init(center: _activeUnitCenter() ?? worldSize / 2);
    _onTurnStarted();
    _publishHud();
  }

  // --------------------------------------------------------- unit input

  /// Hold-to-walk: -1, 0 (stop) or 1. Sent to the sim every tick while held.
  void setWalk(int direction) => _walkDir = direction;

  void jump(JumpKind kind) => _pendingInputs.add(Jump(kind));

  /// The active unit is in dig mode and this phone controls it.
  bool get digging => hasControl && (sim.activeUnit?.isDigging ?? false);

  /// Dig mode joystick: a direction in degrees (0 = right, 90 = up), or
  /// null when released.
  void setDig(int? angleDeg) => _digAngle = angleDeg;

  /// Dig mode's Done button.
  void stopDigging() {
    _digAngle = null;
    _pendingInputs.add(const StopDigging());
  }

  /// Inputs repeated every tick while held.
  List<SimInput> get _held => [
    if (_walkDir != 0) Walk(_walkDir),
    if (_digAngle case final int a) Dig(a),
  ];

  // ------------------------------------------------------------ weapons

  bool get canAim => _turnAllowsAim && hasControl;

  bool get _turnAllowsAim =>
      sim.turn.allowsFire && !(sim.activeUnit?.isGrappling ?? false);

  /// This phone controls the active team: always in a hotseat match,
  /// except on a CPU team's turn.
  bool get hasControl => lockstep?.isMyTurn ?? !cpuTurn;

  /// The computer is playing the active team.
  bool get cpuTurn => _cpu?.controls(sim) ?? false;

  WeaponDef get weapon => Weapons.byId(aim.value.weaponId);

  /// The menu for the active unit: the shared weapons switched on for this
  /// match plus its family's signature weapon (if signatures are on).
  List<WeaponChoice> weaponChoices() {
    final unit = sim.activeUnit;
    if (unit == null) return const [];
    final familyId = unit.familyId;
    final family = familyId == null ? null : Families.byId(familyId);
    return [
      for (final w in [
        ...Weapons.shared,
        if (family != null) Weapons.byId(family.signatureWeaponId),
      ])
        // Random weapons: only the drawn one (and skip) is on offer.
        if (loadout.enabled(w) && (!randomWeapons || sim.canUse(unit, w)))
          WeaponChoice(
            weapon: w,
            ammoLeft: sim.ammoLeft(unit.team, w),
            usable: sim.canUse(unit, w),
          ),
    ];
  }

  void selectWeapon(String weaponId) {
    final w = Weapons.byId(weaponId);
    final unit = sim.activeUnit;
    if (unit == null || !sim.canUse(unit, w)) return;
    if (w.aim == AimMode.target && weapon.aim != AimMode.target) {
      _beforeTarget = weapon.id;
    }
    _weaponByTeam[unit.team] = weaponId;
    aim.value = AimState(
      weaponId: weaponId,
      active: w.aim == AimMode.none && canAim,
      angle: aim.value.angle,
      power: aim.value.power,
      fuseSeconds: aim.value.fuseSeconds,
    );
  }

  /// Slingshot result; ignored for weapons that aren't aimed that way.
  void setAim({required int angle, required int power}) {
    final mode = weapon.aim;
    if (!canAim ||
        (mode != AimMode.angleAndPower && mode != AimMode.direction)) {
      return;
    }
    aim.value = aim.value.copyWith(
      active: true,
      angle: angle % 360,
      power: power.clamp(0, 100),
    );
  }

  void adjustAngle(int delta) =>
      setAim(angle: aim.value.angle + delta, power: aim.value.power);

  void adjustPower(int delta) =>
      setAim(angle: aim.value.angle, power: aim.value.power + delta);

  void setFuse(int seconds) => aim.value = aim.value.copyWith(
      fuseSeconds:
          seconds.clamp(FuseConfig.minSeconds, FuseConfig.maxSeconds));

  /// Picks a target for target weapons from a screen position.
  void setTargetAtScreen(Vector2 screen) {
    final unit = sim.activeUnit;
    if (!canAim || unit == null || weapon.aim != AimMode.target) return;
    final p = camera.globalToLocal(screen);
    final x = p.x.round();
    final y = p.y.round();
    aim.value = aim.value
        .withTarget(x, y, valid: sim.isValidTarget(unit, weapon, x, y));
  }

  /// Cancel drops the aim. A target weapon is also put away, back to the
  /// weapon held before it (or the turn's fallback), so the usual buttons
  /// and the weapon menu come back instead of staying in target mode.
  void cancelAim() {
    final unit = sim.activeUnit;
    if (weapon.aim == AimMode.target && unit != null) {
      final before = _beforeTarget == null ? null : Weapons.byId(_beforeTarget!);
      final back = before != null &&
              before.aim != AimMode.target &&
              sim.canUse(unit, before)
          ? before
          : _fallbackWeapon(unit);
      if (back.aim != AimMode.target) {
        selectWeapon(back.id);
        return;
      }
    }
    aim.value = aim.value
        .withTarget(null, null, valid: false)
        .copyWith(active: weapon.aim == AimMode.none && canAim);
  }

  void fire() {
    final a = aim.value;
    if (!a.active || !canAim) return;
    _pendingInputs.add(Fire(
      weaponId: a.weaponId,
      angleDeg: a.angle,
      powerPercent: a.power,
      fuseTicks: weapon.playerFuse
          ? a.fuseSeconds * MatchDefaults.ticksPerSecond
          : null,
      targetX: a.targetX,
      targetY: a.targetY,
    ));
    aim.value = a.withTarget(null, null, valid: false).copyWith(active: false);
  }

  /// New turn: restore the team's last weapon if it can still be used.
  /// The rock, or if it is switched off or used up, the first weapon still
  /// usable.
  WeaponDef _fallbackWeapon(Unit unit) => sim.canUse(unit, Weapons.rock)
      ? Weapons.rock
      : Weapons.shared.firstWhere(
          (w) => sim.canUse(unit, w) && w.id != Weapons.grapple.id,
          orElse: () => Weapons.skip,
        );

  void _onTurnStarted() {
    _walkDir = 0;
    _digAngle = null;
    _beforeTarget = null;
    final unit = sim.activeUnit;
    var id = Weapons.rock.id;
    if (sim.drawnWeaponId case final drawn?) {
      id = drawn;
    } else if (unit != null) {
      final last = _weaponByTeam[unit.team];
      if (last != null && sim.canUse(unit, Weapons.byId(last))) {
        id = last;
      } else {
        id = _fallbackWeapon(unit).id;
      }
    }
    aim.value = AimState(
      weaponId: id,
      active: false,
      angle: aim.value.angle,
      power: aim.value.power,
      fuseSeconds: aim.value.fuseSeconds,
    );
    centerOnActiveUnit();
  }

  // ------------------------------------------------------------- camera

  void panCamera(Vector2 screenDelta) => _camera.panByScreen(screenDelta);

  double get cameraZoom => _camera.zoom;

  /// The world on screen with a margin: components skip drawing outside
  /// it.
  Rect get visibleWorld => camera.visibleWorldRect.inflate(64);

  void zoomCamera(Vector2 screenFocal, double zoom) =>
      _camera.zoomAt(screenFocal, zoom);

  void centerOnActiveUnit() {
    final c = _activeUnitCenter();
    if (c != null) _camera.focusOn(c);
  }

  Vector2? _lastActivePos;

  /// When the active unit moves (walk, jump, knockback, dash) out of the
  /// middle of the view, bring it back. Standing still never moves the
  /// camera, so the player can look around freely.
  void _keepActiveUnitInView() {
    final c = _activeUnitCenter();
    final last = _lastActivePos;
    _lastActivePos = c;
    if (c == null || last == null || c == last) return;
    final screen = camera.localToGlobal(c);
    final view = camera.viewport.virtualSize;
    const margin = 0.25;
    if (screen.x < view.x * margin ||
        screen.x > view.x * (1 - margin) ||
        screen.y < view.y * margin ||
        screen.y > view.y * (1 - margin)) {
      _camera.follow(c);
    }
  }

  Vector2? _activeUnitCenter() {
    final u = sim.activeUnit;
    return u == null || !u.alive ? null : Vector2(u.centerX, u.centerY);
  }

  // --------------------------------------------------------------- loop

  @override
  void update(double dt) {
    super.update(dt);
    // Cheap enough to always run; the HUD shows it when Settings asks.
    _measureFrame(dt);
    _accumulator += dt;
    var steps = 0;
    var slots = 0;
    final lock = lockstep;
    while (_accumulator >= MatchDefaults.tickSeconds &&
        slots < MatchDefaults.maxStepsPerFrame) {
      if (lock == null) {
        _stepSim();
        steps++;
      } else {
        steps += _stepNet(lock);
      }
      _accumulator -= MatchDefaults.tickSeconds;
      slots++;
    }
    // Still behind after the cap: drop the backlog instead of queueing it.
    if (_accumulator >= MatchDefaults.tickSeconds) _accumulator = 0;

    if (sim.projectiles.isNotEmpty) {
      final p = sim.projectiles.first;
      _camera.follow(Vector2(p.x, p.y));
    } else if (sim.aircraft.isNotEmpty) {
      final b = sim.aircraft.first;
      _camera.follow(Vector2(b.x, b.y));
    } else if (sim.pendingStrikes.isNotEmpty) {
      // Stay on the marked spot, a little low in the view: the satellite
      // or storm cloud comes in over it near the top of the view, so its
      // arrival, the strike and who it hits are all seen.
      final s = sim.pendingStrikes.first;
      final viewHeight = camera.viewport.virtualSize.y / _camera.zoom;
      // The satellite parks closer above its spot than the cloud.
      final lift = s.weapon.delivery is OrbitalStrike
          ? math.min(viewHeight * 0.15, 100.0)
          : viewHeight * 0.15;
      _camera.follow(Vector2(s.x.toDouble(), s.y - lift));
    } else if (sim.tick >= _impactHoldUntil) {
      _keepActiveUnitInView();
    }
    _camera.update(dt);
    if (cpuTurn) {
      _showCpuAim();
    } else if (aim.value.active && !canAim) {
      aim.value = aim.value.copyWith(active: false);
    } else if (!aim.value.active && canAim && weapon.aim == AimMode.none) {
      aim.value = aim.value.copyWith(active: true);
    }
    // Holes made by this frame's steps show this frame, not the next.
    _terrain.flush();
    // The HUD only shows sim state, so skip the work on frames without a
    // sim step (high-refresh screens run more frames than ticks).
    if (steps > 0) _publishHud();
  }

  void _measureFrame(double dt) {
    _fpsWindow += dt;
    _fpsFrames++;
    if (dt > _fpsWorst) _fpsWorst = dt;
    if (_fpsWindow >= 0.5) {
      frameStats.value = FrameStats(
        fps: (_fpsFrames / _fpsWindow).round(),
        worstMs: _fpsWorst * 1000,
      );
      _fpsWindow = 0;
      _fpsFrames = 0;
      _fpsWorst = 0;
    }
  }

  void _stepSim() {
    final cpu = _cpu?.step(sim) ?? const [];
    final inputs = cpuTurn ? cpu : [..._held, ..._pendingInputs];
    _pendingInputs.clear();
    _runStep(() => sim.step(inputs));
  }

  /// A CPU turn: the aim guide shows the CPU's weapon and aim as it swings
  /// into place, so players see the shot coming.
  void _showCpuAim() {
    final a = _cpu!.aim;
    final AimState next;
    if (a == null) {
      if (!aim.value.active) return;
      next = aim.value.copyWith(active: false);
    } else {
      next = AimState(
        weaponId: a.weaponId,
        active: _turnAllowsAim,
        angle: a.angle,
        power: a.power,
        fuseSeconds: aim.value.fuseSeconds,
        targetX: a.targetX,
        targetY: a.targetY,
        targetValid: a.targetX != null,
      );
    }
    if (next != aim.value) aim.value = next;
  }

  /// One tick of real time in a network match: record this phone's inputs
  /// if it controls the active team, then step every tick whose inputs
  /// are here (several when behind). Returns the number of steps.
  int _stepNet(Lockstep lock) {
    if (lock.produce(_held, _pendingInputs) || !lock.isMyTurn) {
      _pendingInputs.clear();
    }
    var steps = 0;
    while (steps < MatchDefaults.maxStepsPerFrame) {
      if (_runStep(lock.step) == null) break;
      steps++;
      if (lock.buffered <= NetConfig.catchUpTicks) break;
    }
    return steps;
  }

  /// Runs [step] and handles its events; returns them (null = no step).
  List<SimEvent>? _runStep(List<SimEvent>? Function() step) {
    _stopwatch
      ..reset()
      ..start();
    final events = step();
    if (events == null) return null;
    final exploded = _handleEvents(events);
    _stopwatch.stop();
    if (exploded) _recordExplosionTime(_stopwatch.elapsedMicroseconds);
    return events;
  }

  /// Returns whether any explosion happened.
  bool _handleEvents(List<SimEvent> events) {
    var exploded = false;
    // Where a beam, bolt or orbital strike landed this step, and who it hit.
    Vector2? impact;
    final hit = <int>[];
    for (final event in events) {
      stats.record(event);
      onEvent?.call(event);
      switch (event) {
        case ExplosionEvent(:final x, :final y, :final radius, :final carved):
          exploded = true;
          if (carved != null) {
            _terrain.carve(x, y, radius);
            particles.explosion(
              x.toDouble(),
              y.toDouble(),
              radius.toDouble(),
              debris: _terrain.debrisColors(x, y, radius),
            );
          } else {
            particles.ring(x.toDouble(), y.toDouble(), radius.toDouble());
          }
          _aimGuide.invalidate();
        case TerrainCarved(:final x, :final y, :final radius):
          _terrain.carve(x, y, radius, scorch: false);
          particles.dust(x.toDouble(), (y + radius).toDouble(), strength: 0.4);
          _aimGuide.invalidate();
        case BeamFired(:final x0, :final y0, :final x1, :final y1, :final radius):
          _terrain.carveLine(x0, y0, x1, y1, radius);
          particles.beam(x0, y0, x1, y1);
          _aimGuide.invalidate();
          impact = Vector2(x1, y1);
        case LightningStruck(:final x, :final y):
          final cloudY =
              _airSupport.sourceYFor(lightning: true, targetY: y.toDouble());
          particles.bolt(x.toDouble(), y.toDouble(), top: cloudY + 18);
          _airSupport.strikeLanded(
              lightning: true, x: x.toDouble(), y: cloudY);
          impact = Vector2(x.toDouble(), y.toDouble());
        case SatelliteStruck(:final x0, :final y0, :final x1, :final y1,
              :final radius, :final last):
          _terrain.carveLine(x0, y0, x1, y1, radius);
          particles.orbital(x0, y0 + 12, x1, y1);
          if (last) _airSupport.strikeLanded(lightning: false, x: x0, y: y0);
          _aimGuide.invalidate();
          impact = Vector2(x1, y1);
        case UnitDamaged(:final unitId, :final amount):
          _damage.show(unitId, amount);
          hit.add(unitId);
        case TerrainAdded(:final area):
          _terrain.rebuild(area);
          _aimGuide.invalidate();
        case TurnStarted():
          _onTurnStarted();
        case GrappleFired(:final x0, :final y0, :final x1, :final y1,
              :final hooked):
          if (!hooked) _grapple.missed(x0, y0, x1, y1);
        case WeaponUsed(:final weaponId) when weaponId == Weapons.grapple.id:
          // Out of hooks: pick something to shoot with for the rest of the
          // turn.
          final unit = sim.activeUnit;
          if (unit != null && !sim.canUse(unit, Weapons.grapple)) {
            aim.value = aim.value.copyWith(
                weaponId: _fallbackWeapon(unit).id, active: false);
          }
        case UnitLanded(:final unitId, :final fallDistance):
          if (fallDistance > 30) {
            final u = sim.units[unitId];
            particles.dust(u.centerX, u.y,
                strength: (fallDistance / 150).clamp(0.3, 1.5));
          }
        case ProjectileRemoved(:final outcome, :final x)
            when outcome == FlightOutcome.water:
          particles.splash(x, sim.waterLevel.toDouble(),
              waterArgb: map.waterArgb);
        case UnitDied(:final unitId, :final cause)
            when cause == DeathCause.water:
          particles.splash(sim.units[unitId].centerX, sim.waterLevel.toDouble(),
              waterArgb: map.waterArgb);
        case IceBurst(:final x, :final y, :final radius):
          particles.frost(x, y, radius.toDouble());
          impact = Vector2(x, y);
        case UnitThawed(:final unitId):
          final u = sim.units[unitId];
          particles.sparkle(u.centerX, u.centerY, argb: 0xFFCFF2FF);
        case FireOut(:final patchId):
          // Gone from the sim already; a puff where the flames were is
          // drawn from the last frame's position.
          final at = _firePos.remove(patchId);
          if (at != null) particles.dust(at.x, at.y, strength: 0.4);
        case FireStarted(:final patchId, :final x, :final y):
          _firePos[patchId] = Vector2(x.toDouble(), y.toDouble());
          particles.ignite(x.toDouble(), y.toDouble());
        case UnitFrozen():
          break;
        case NukeDetonated(:final x, :final y, :final radius):
          particles.mushroom(x, y, radius.toDouble());
        case GasReleased(:final cloudId, :final x, :final y):
          final cloud = sim.clouds.where((c) => c.id == cloudId).firstOrNull;
          particles.gasBurst(x, y, (cloud?.radius ?? 60).toDouble(),
              fallout: cloud?.fallout ?? false);
          impact = Vector2(x, y);
        case UnitPoisoned(:final unitId):
          final u = sim.units[unitId];
          particles.sparkle(u.centerX, u.centerY, argb: 0xFF9BE070);
        case UnitHealed(:final unitId, :final amount):
          final u = sim.units[unitId];
          _objects.popup(u.centerX, u.y, hp: amount);
          particles.sparkle(u.centerX, u.centerY, argb: 0xFF3CCB6C);
        case ShieldRaised(:final unitId):
          final u = sim.units[unitId];
          particles.sparkle(u.centerX, u.centerY, argb: 0xFF9FE3FF);
        case ShieldPopped(:final unitId, :final blocked):
          final u = sim.units[unitId];
          particles
            ..ring(u.centerX, u.centerY, 26)
            ..sparkle(u.centerX, u.centerY,
                argb: blocked ? 0xFFE6F9FF : 0xFF9FE3FF);
        case ShotgunFired(:final x0, :final y0, :final x1, :final y1):
          particles.tracer(x0, y0, x1, y1);
        case UnitTeleported(:final unitId):
          final u = sim.units[unitId];
          particles.sparkle(u.centerX, u.centerY, argb: 0xFFB98CFF);
        case CrateCollected(:final unitId, :final health, :final hp,
              :final weaponId):
          final u = sim.units[unitId];
          _objects.popup(u.centerX, u.y,
              hp: health ? hp : null, weaponId: weaponId);
          particles.sparkle(u.centerX, u.centerY,
              argb: health ? 0xFF3CCB6C : 0xFFFFD25A);
        case ProjectileLaunched() ||
              BombDropped() ||
              ObjectRemoved() ||
              ProjectileRemoved() ||
              UnitDied() ||
              UnitJumped() ||
              UnitSaved() ||
              WeaponUsed() ||
              MinePlaced() ||
              MineTriggered() ||
              MineRemoved() ||
              PhaseChanged() ||
              WeaponDrawn() ||
              SuddenDeathStarted() ||
              WaterRose() ||
              MatchEnded():
          break;
      }
    }
    if (impact != null) _showImpact(impact, hit);
    return exploded;
  }

  /// Ticks the camera stays on a strike before following the active unit
  /// again.
  static const int _impactHoldTicks = MatchDefaults.hitHoldTicks;
  int _impactHoldUntil = 0;

  /// Strikes without a projectile to follow (laser, lightning, satellite)
  /// land out of view: look at who they hit, or else where they landed.
  void _showImpact(Vector2 impact, List<int> hit) {
    var focus = impact;
    if (hit.isNotEmpty) {
      focus = Vector2.zero();
      for (final id in hit) {
        final u = sim.units[id];
        focus += Vector2(u.centerX, u.centerY);
      }
      focus /= hit.length.toDouble();
    }
    _camera.focusOn(focus);
    _impactHoldUntil = sim.tick + _impactHoldTicks;
    _lastActivePos = _activeUnitCenter();
  }

  void _publishHud() {
    final clock = sim.turn.clockTicks;
    hud.value = HudState(
      phase: sim.turn.phase,
      activeTeam: sim.turn.activeTeam,
      clockSeconds: clock == null
          ? null
          : (clock / MatchDefaults.ticksPerSecond).ceil(),
      wind: sim.wind,
      teamHp: sim.teamHp(),
      teamMaxHp: sim.teamMaxHp(),
      suddenDeath: sim.suddenDeath,
      frozenSkip: sim.frozenSkip,
      shotgunLeft: sim.shotgunShotsLeft,
      winnerTeam:
          sim.turn.phase == TurnPhase.matchOver ? sim.turn.winnerTeam : null,
    );
  }

  void _recordExplosionTime(int micros) {
    final ms = micros / 1000;
    final previousMax = explosionTiming.value?.maxMs ?? 0;
    explosionTiming.value =
        ExplosionTiming(lastMs: ms, maxMs: math.max(ms, previousMax));
  }

  @override
  void onDispose() {
    hud.dispose();
    aim.dispose();
    explosionTiming.dispose();
    frameStats.dispose();
    super.onDispose();
  }
}
