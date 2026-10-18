import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../config/controls.dart';
import '../config/families.dart';
import '../config/maps.dart';
import '../config/match_defaults.dart';
import '../config/weapons.dart';
import '../sim/events.dart';
import '../sim/inputs.dart';
import '../sim/match_setup.dart';
import '../sim/turn_manager.dart';
import '../sim/world.dart';
import 'camera/arena_camera.dart';
import 'components/aim_guide_component.dart';
import 'components/backdrop_components.dart';
import 'components/projectiles_component.dart';
import 'components/terrain_component.dart';
import 'components/units_component.dart';
import 'effects/explosion_flash.dart';
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
    required this.familyLetters,
    required this.teamColors,
    required this.unitNames,
    required this.map,
    this.timings = const TurnTimings(),
    this.suddenDeathAfterTicks,
    this.showAimGuide = true,
  });

  final int seed;
  final List<List<UnitSpec>> rosters;

  /// Localized first letter of each family name, for placeholder units.
  final Map<String, String> familyLetters;

  /// Colour (0xAARRGGBB) of each team, in roster order.
  final List<int> teamColors;

  /// Display name of each unit, in roster order (= unit id).
  final List<String> unitNames;
  final MapDef map;
  final TurnTimings timings;
  final int? suddenDeathAfterTicks;

  /// Settings: draw the aim guide path (the readout always shows).
  bool showAimGuide;

  late final MatchStats stats;

  late final SimWorld sim;
  late final TerrainComponent _terrain;
  late final AimGuideComponent _aimGuide;
  late final ArenaCamera _camera;

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

  /// Each team keeps its last chosen weapon between turns.
  final Map<int, String> _weaponByTeam = {};

  final List<SimInput> _pendingInputs = [];
  int _walkDir = 0;
  double _accumulator = 0;
  final Stopwatch _stopwatch = Stopwatch();

  @override
  Color backgroundColor() => Color(map.skyBottomArgb);

  @override
  Future<void> onLoad() async {
    final mask = await loadTerrainMask(map.maskAsset);
    sim = SimWorld.newMatch(
      seed: seed,
      terrain: mask,
      waterLevel: map.waterLevel,
      rosters: rosters,
      timings: timings,
      suddenDeathAfterTicks: suddenDeathAfterTicks,
    );
    stats = MatchStats(sim);

    final worldSize = Vector2(mask.width.toDouble(), mask.height.toDouble());
    _terrain = TerrainComponent(mask: mask, map: map);
    _aimGuide = AimGuideComponent(
      sim: sim,
      aim: () => aim.value,
      showPath: () => showAimGuide,
    );
    await world.addAll([
      SkyComponent(map: map, worldSize: worldSize),
      _terrain,
      UnitsComponent(
        sim,
        familyLetters: familyLetters,
        teamColors: teamColors,
        unitNames: unitNames,
      ),
      ProjectilesComponent(sim),
      WaterComponent(
          map: map, worldSize: worldSize, level: () => sim.waterLevel),
      _aimGuide,
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

  // ------------------------------------------------------------ weapons

  bool get canAim => sim.turn.allowsFire;

  WeaponDef get weapon => Weapons.byId(aim.value.weaponId);

  /// The menu for the active unit: the shared arsenal plus its family's
  /// signature weapon.
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

  void cancelAim() => aim.value = aim.value
      .withTarget(null, null, valid: false)
      .copyWith(active: weapon.aim == AimMode.none && canAim);

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
  void _onTurnStarted() {
    _walkDir = 0;
    final unit = sim.activeUnit;
    var id = Weapons.rock.id;
    if (unit != null) {
      final last = _weaponByTeam[unit.team];
      if (last != null && sim.canUse(unit, Weapons.byId(last))) id = last;
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
    _accumulator += dt;
    var steps = 0;
    while (_accumulator >= MatchDefaults.tickSeconds &&
        steps < MatchDefaults.maxStepsPerFrame) {
      _stepSim();
      _accumulator -= MatchDefaults.tickSeconds;
      steps++;
    }
    // Still behind after the cap: drop the backlog instead of queueing it.
    if (_accumulator >= MatchDefaults.tickSeconds) _accumulator = 0;

    if (sim.projectiles.isNotEmpty) {
      final p = sim.projectiles.first;
      _camera.follow(Vector2(p.x, p.y));
    } else {
      _keepActiveUnitInView();
    }
    _camera.update(dt);
    if (aim.value.active && !canAim) {
      aim.value = aim.value.copyWith(active: false);
    } else if (!aim.value.active && canAim && weapon.aim == AimMode.none) {
      aim.value = aim.value.copyWith(active: true);
    }
    _publishHud();
  }

  void _stepSim() {
    final inputs = [
      if (_walkDir != 0) Walk(_walkDir),
      ..._pendingInputs,
    ];
    _pendingInputs.clear();
    _stopwatch
      ..reset()
      ..start();
    final events = sim.step(inputs);
    final exploded = _handleEvents(events);
    _stopwatch.stop();
    if (exploded) _recordExplosionTime(_stopwatch.elapsedMicroseconds);
  }

  /// Returns whether any explosion happened.
  bool _handleEvents(List<SimEvent> events) {
    var exploded = false;
    for (final event in events) {
      stats.record(event);
      switch (event) {
        case ExplosionEvent(:final x, :final y, :final radius, :final carved):
          exploded = true;
          if (carved != null) _terrain.carve(x, y, radius);
          _aimGuide.invalidate();
          world.add(ExplosionFlash(
              x: x.toDouble(), y: y.toDouble(), radius: radius.toDouble()));
        case TerrainCarved(:final x, :final y, :final radius):
          _terrain.carve(x, y, radius);
          _aimGuide.invalidate();
        case TerrainAdded(:final area):
          _terrain.rebuild(area);
          _aimGuide.invalidate();
        case TurnStarted():
          _onTurnStarted();
        case ProjectileLaunched() ||
              ProjectileRemoved() ||
              UnitDamaged() ||
              UnitDied() ||
              UnitJumped() ||
              UnitSaved() ||
              UnitTeleported() ||
              WeaponUsed() ||
              MinePlaced() ||
              MineTriggered() ||
              MineRemoved() ||
              PhaseChanged() ||
              SuddenDeathStarted() ||
              WaterRose() ||
              MatchEnded():
          // Sound, haptics and particles hook in here (M5).
          break;
      }
    }
    return exploded;
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
    super.onDispose();
  }
}
