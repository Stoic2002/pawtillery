import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../config/controls.dart';
import '../config/maps.dart';
import '../config/match_defaults.dart';
import '../config/weapons.dart';
import '../sim/events.dart';
import '../sim/inputs.dart';
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

/// Main-thread cost of the last explosion: sim step (mask carve, damage)
/// plus scheduling the chunk re-render. PRD target: under 4 ms.
class ExplosionTiming {
  const ExplosionTiming({required this.lastMs, required this.maxMs});
  final double lastMs;
  final double maxMs;
}

/// Renders [SimWorld], drives it at a fixed 60 Hz and turns player gestures
/// into discrete sim inputs. Owns no game rules.
class PawtilleryGame extends FlameGame {
  PawtilleryGame({
    required this.seed,
    required this.teamCount,
    required this.unitsPerTeam,
    this.map = Maps.sandbox,
  });

  final int seed;
  final int teamCount;
  final int unitsPerTeam;
  final MapDef map;

  late final SimWorld sim;
  late final TerrainComponent _terrain;
  late final AimGuideComponent _aimGuide;
  late final ArenaCamera _camera;

  // State the Flutter HUD listens to.
  final hud = ValueNotifier<HudState?>(null);
  final aim = ValueNotifier<AimState>(const AimState(
    active: false,
    angle: ControlsConfig.initialAngle,
    power: ControlsConfig.initialPower,
  ));
  final explosionTiming = ValueNotifier<ExplosionTiming?>(null);

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
      teamCount: teamCount,
      unitsPerTeam: unitsPerTeam,
    );

    final worldSize = Vector2(mask.width.toDouble(), mask.height.toDouble());
    _terrain = TerrainComponent(mask: mask, map: map);
    _aimGuide = AimGuideComponent(
      sim: sim,
      isAiming: () => aim.value.active,
      angle: () => aim.value.angle,
      power: () => aim.value.power,
    );
    await world.addAll([
      SkyComponent(map: map, worldSize: worldSize),
      _terrain,
      UnitsComponent(sim),
      ProjectilesComponent(sim),
      WaterComponent(map: map, worldSize: worldSize),
      _aimGuide,
    ]);

    _camera = ArenaCamera(camera: camera, worldSize: worldSize)
      ..init(center: _activeUnitCenter() ?? worldSize / 2);
    _publishHud();
  }

  // ---------------------------------------------------------------- input

  /// Hold-to-walk: -1, 0 (stop) or 1. Sent to the sim every tick while held.
  void setWalk(int direction) => _walkDir = direction;

  void jump(JumpKind kind) => _pendingInputs.add(Jump(kind));

  bool get canAim => sim.turn.allowsFire;

  void setAim({required int angle, required int power}) {
    if (!canAim) return;
    aim.value = AimState(
      active: true,
      angle: angle % 360,
      power: power.clamp(0, 100),
    );
  }

  void cancelAim() => aim.value = aim.value.copyWith(active: false);

  void adjustAngle(int delta) =>
      setAim(angle: aim.value.angle + delta, power: aim.value.power);

  void adjustPower(int delta) =>
      setAim(angle: aim.value.angle, power: aim.value.power + delta);

  void fire() {
    final a = aim.value;
    if (!a.active || !canAim) return;
    _pendingInputs.add(Fire(
      angleDeg: a.angle,
      powerPercent: a.power,
      weaponId: Weapons.rock.id,
    ));
    cancelAim();
  }

  // --------------------------------------------------------------- camera

  void panCamera(Vector2 screenDelta) => _camera.panByScreen(screenDelta);

  double get cameraZoom => _camera.zoom;

  void zoomCamera(Vector2 screenFocal, double zoom) =>
      _camera.zoomAt(screenFocal, zoom);

  void centerOnActiveUnit() {
    final c = _activeUnitCenter();
    if (c != null) _camera.focusOn(c);
  }

  Vector2? _lastActivePos;

  /// When the active unit moves (walk, jump, knockback) out of the middle
  /// of the view, bring it back. Standing still never moves the camera, so
  /// the player can look around freely.
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

  // ----------------------------------------------------------------- loop

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
    if (aim.value.active && !canAim) cancelAim();
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
      switch (event) {
        case ExplosionEvent(:final x, :final y, :final radius, :final carved):
          exploded = true;
          if (carved != null) _terrain.carve(x, y, radius);
          _aimGuide.invalidate();
          world.add(ExplosionFlash(
              x: x.toDouble(), y: y.toDouble(), radius: radius.toDouble()));
        case TurnStarted():
          _walkDir = 0;
          cancelAim();
          centerOnActiveUnit();
        case ProjectileLaunched() ||
              ProjectileRemoved() ||
              UnitDamaged() ||
              UnitDied() ||
              UnitJumped() ||
              PhaseChanged() ||
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
      winnerTeam:
          sim.turn.phase == TurnPhase.matchOver ? sim.turn.winnerTeam : null,
    );
  }

  void _recordExplosionTime(int micros) {
    final ms = micros / 1000;
    final previousMax = explosionTiming.value?.maxMs ?? 0;
    explosionTiming.value = ExplosionTiming(
        lastMs: ms, maxMs: math.max(ms, previousMax));
  }

  @override
  void onDispose() {
    hud.dispose();
    aim.dispose();
    explosionTiming.dispose();
    super.onDispose();
  }
}
