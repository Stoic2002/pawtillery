import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../config/maps.dart';
import '../config/match_defaults.dart';
import '../config/sandbox.dart';
import '../sim/events.dart';
import '../sim/inputs.dart';
import '../sim/world.dart';
import 'components/aim_guide_component.dart';
import 'components/backdrop_components.dart';
import 'components/projectiles_component.dart';
import 'components/terrain_component.dart';
import 'effects/explosion_flash.dart';
import 'map_loader.dart';

/// Main-thread cost of the last explosion: sim step (mask carve) plus
/// scheduling the chunk re-render. PRD target: under 4 ms.
class ExplosionTiming {
  const ExplosionTiming({required this.lastMs, required this.maxMs});
  final double lastMs;
  final double maxMs;
}

/// Renders [SimWorld] and drives it at a fixed 60 Hz. Owns no game rules.
class PawtilleryGame extends FlameGame {
  PawtilleryGame({required this.seed, this.map = Maps.sandbox});

  final int seed;
  final MapDef map;

  late final SimWorld sim;
  late final TerrainComponent _terrain;
  late final AimGuideComponent _aimGuide;

  // State the Flutter HUD listens to.
  final angle = ValueNotifier<int>(SandboxConfig.initialAngle);
  final power = ValueNotifier<int>(SandboxConfig.initialPower);
  final wind = ValueNotifier<int>(0);
  final inFlight = ValueNotifier<bool>(false);
  final explosionTiming = ValueNotifier<ExplosionTiming?>(null);

  final List<SimInput> _pendingInputs = [];
  double _accumulator = 0;
  final Stopwatch _stopwatch = Stopwatch();

  void queueInput(SimInput input) => _pendingInputs.add(input);

  @override
  Color backgroundColor() => Color(map.skyBottomArgb);

  @override
  Future<void> onLoad() async {
    final mask = await loadTerrainMask(map.maskAsset);
    sim = SimWorld(seed: seed, terrain: mask);
    wind.value = sim.wind;

    final worldSize = Vector2(mask.width.toDouble(), mask.height.toDouble());
    _terrain = TerrainComponent(mask: mask, map: map, onTap: _onTerrainTap);
    _aimGuide = AimGuideComponent(
      sim: sim,
      angle: () => angle.value,
      power: () => power.value,
    );
    await world.addAll([
      SkyComponent(map: map, worldSize: worldSize),
      _terrain,
      ProjectilesComponent(sim),
      WaterComponent(map: map, worldSize: worldSize),
      _aimGuide,
    ]);

    // M1: whole map in view. Pan/zoom/follow arrive with the camera work.
    camera.viewfinder
      ..anchor = Anchor.center
      ..position = worldSize / 2
      ..visibleGameSize = worldSize;
  }

  void _onTerrainTap(Vector2 world) => queueInput(DebugExplode(
        x: world.x.round(),
        y: world.y.round(),
        radius: SandboxConfig.tapExplosionRadius,
      ));

  void fire() {
    if (sim.isProjectileInFlight) return;
    queueInput(DebugFire(
      x: SandboxConfig.launcherX,
      y: SandboxConfig.launcherY,
      angleDeg: angle.value,
      powerPercent: power.value,
    ));
  }

  void adjustAngle(int delta) => angle.value = (angle.value + delta) % 360;

  void adjustPower(int delta) =>
      power.value = (power.value + delta).clamp(0, 100);

  @override
  void update(double dt) {
    super.update(dt);
    _accumulator += dt;
    var steps = 0;
    while (_accumulator >= MatchDefaults.tickSeconds &&
        steps < MatchDefaults.maxStepsPerFrame) {
      _stopwatch
        ..reset()
        ..start();
      final events = sim.step(List.of(_pendingInputs));
      _pendingInputs.clear();
      final exploded = _handleEvents(events);
      _stopwatch.stop();
      if (exploded) _recordExplosionTime(_stopwatch.elapsedMicroseconds);
      _accumulator -= MatchDefaults.tickSeconds;
      steps++;
    }
    // Still behind after the cap: drop the backlog instead of queueing it.
    if (_accumulator >= MatchDefaults.tickSeconds) _accumulator = 0;
    inFlight.value = sim.isProjectileInFlight;
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
        case WindChanged(wind: final w):
          wind.value = w;
        case ProjectileLaunched() || ProjectileRemoved():
          break;
      }
    }
    return exploded;
  }

  void _recordExplosionTime(int micros) {
    final ms = micros / 1000;
    final previousMax = explosionTiming.value?.maxMs ?? 0;
    explosionTiming.value = ExplosionTiming(
        lastMs: ms, maxMs: ms > previousMax ? ms : previousMax);
  }

  @override
  void onDispose() {
    angle.dispose();
    power.dispose();
    wind.dispose();
    inFlight.dispose();
    explosionTiming.dispose();
    super.onDispose();
  }
}
