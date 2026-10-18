import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../app/match_config.dart';
import '../../config/controls.dart';
import '../../config/families.dart';
import '../../config/match_defaults.dart';
import '../../config/teams.dart';
import '../../config/weapons.dart';
import '../../game/hud_state.dart';
import '../../game/pawtillery_game.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_lookup.g.dart';
import '../../sim/turn_manager.dart';
import '../hud/arena_hud.dart';
import '../hud/pause_dialog.dart';
import 'results_screen.dart';
import 'settings_screen.dart';

/// Hosts the Flame game, routes touch gestures to it, and layers the
/// Flutter HUD on top.
///
/// Gestures (PRD: Kontrol sentuh): one finger drags the slingshot for
/// weapons aimed that way (when the unit may fire), otherwise pans; a tap
/// picks the target for target weapons; two fingers always pan and pinch.
/// The back gesture opens the pause menu instead of leaving (PRD: API 36
/// predictive back).
class ArenaScreen extends StatefulWidget {
  const ArenaScreen({super.key, required this.config});

  final MatchConfig config;

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

enum _GestureMode { none, aim, camera }

class _ArenaScreenState extends State<ArenaScreen> {
  // The seed is the only randomness outside the sim; it is logged so any
  // match can be replayed while debugging.
  late final int _seed = math.Random().nextInt(1 << 31);
  PawtilleryGame? _game;
  late List<String> _teamNames;
  late List<String> _unitNames;
  bool _paused = false;
  bool _finished = false;

  _GestureMode _mode = _GestureMode.none;
  Offset _aimStart = Offset.zero;
  AimState? _aimBefore;
  Offset _lastFocal = Offset.zero;
  double _zoomBase = 1;

  @override
  void initState() {
    super.initState();
    debugPrint('Pawtillery match seed: $_seed');
  }

  PawtilleryGame _gameFor(BuildContext context) {
    final existing = _game;
    if (existing != null) return existing;
    final l10n = AppLocalizations.of(context);
    final config = widget.config;
    _teamNames = [
      for (final t in config.teams)
        t.customName ?? l10n.byKey(Teams.styles[t.styleIndex].nameKey),
    ];
    _unitNames = [
      for (final t in config.teams)
        for (final u in t.units) u.name,
    ];
    final game = PawtilleryGame(
      seed: _seed,
      rosters: config.rosters(),
      map: config.resolveMap(math.Random(_seed)),
      teamColors: [
        for (final t in config.teams) Teams.styles[t.styleIndex].colorArgb,
      ],
      unitNames: _unitNames,
      familyLetters: {
        for (final f in Families.all)
          f.id: l10n.byKey(f.nameKey).characters.first.toUpperCase(),
      },
      timings: TurnTimings(
          turnTicks: config.turnSeconds * MatchDefaults.ticksPerSecond),
      suddenDeathAfterTicks: config.suddenDeathMinutes == null
          ? null
          : config.suddenDeathMinutes! * 60 * MatchDefaults.ticksPerSecond,
      showAimGuide: AppServices.of(context).settings.showAimGuide,
    );
    game.hud.addListener(_onHudChanged);
    return _game = game;
  }

  /// Match over: show the result briefly in the arena, then move on.
  void _onHudChanged() {
    final game = _game!;
    final hud = game.hud.value;
    if (_finished || hud == null || !hud.isOver) return;
    _finished = true;
    final top = game.stats.topDamage;
    final result = MatchResult(
      winnerTeam: hud.winnerTeam,
      teamNames: _teamNames,
      teamColors: game.teamColors,
      knockouts: List.of(game.stats.knockouts),
      turns: game.sim.turn.turnNumber,
      topUnitName: top == null ? null : _unitNames[top.$1],
      topUnitTeam: top == null ? null : game.sim.units[top.$1].team,
      topDamage: top?.$2,
    );
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
        builder: (_) => ResultsScreen(result: result, config: widget.config),
      ));
    });
  }

  Future<void> _pause() async {
    final game = _game;
    if (game == null || _paused || _finished) return;
    _paused = true;
    game
      ..setWalk(0)
      ..pauseEngine();
    while (mounted) {
      final choice = await showPauseDialog(context);
      if (!mounted) return;
      if (choice == PauseChoice.settings) {
        await Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const SettingsScreen()));
        if (!mounted) return;
        game.showAimGuide = AppServices.of(context).settings.showAimGuide;
        continue;
      }
      if (choice == PauseChoice.exit) {
        if (!await confirmExit(context)) continue;
        if (!mounted) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }
      break;
    }
    _paused = false;
    game.resumeEngine();
  }

  bool get _slingshotWeapon {
    final mode = _game!.weapon.aim;
    return mode == AimMode.angleAndPower || mode == AimMode.direction;
  }

  void _onScaleStart(ScaleStartDetails d) {
    final game = _game;
    if (game == null || !game.isLoaded) return;
    if (d.pointerCount >= 2 || !game.canAim || !_slingshotWeapon) {
      _startCamera(d.localFocalPoint, 1);
    } else {
      _mode = _GestureMode.aim;
      _aimStart = d.localFocalPoint;
      _aimBefore = game.aim.value;
    }
  }

  void _startCamera(Offset focal, double currentScale) {
    _mode = _GestureMode.camera;
    _lastFocal = focal;
    _zoomBase = _game!.cameraZoom / currentScale;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    final game = _game;
    if (game == null) return;
    if (_mode == _GestureMode.aim && d.pointerCount >= 2) {
      // A second finger turns an aim drag into a camera gesture.
      final before = _aimBefore;
      if (before != null) game.aim.value = before;
      _startCamera(d.localFocalPoint, d.scale);
    }
    switch (_mode) {
      case _GestureMode.aim:
        _updateAim(game, d.localFocalPoint);
      case _GestureMode.camera:
        final delta = d.localFocalPoint - _lastFocal;
        _lastFocal = d.localFocalPoint;
        game.panCamera(Vector2(delta.dx, delta.dy));
        if (d.pointerCount >= 2) {
          game.zoomCamera(
            Vector2(d.localFocalPoint.dx, d.localFocalPoint.dy),
            _zoomBase * d.scale,
          );
        }
      case _GestureMode.none:
        break;
    }
  }

  /// Slingshot: pulling back from the start point aims the opposite way;
  /// the pull length sets the power. Back inside the dead zone = cancel.
  void _updateAim(PawtilleryGame game, Offset finger) {
    final pull = _aimStart - finger;
    if (pull.distance < ControlsConfig.slingshotDeadZone) {
      game.cancelAim();
      return;
    }
    final degrees = math.atan2(-pull.dy, pull.dx) * 180 / math.pi;
    final power = (pull.distance / ControlsConfig.slingshotMaxDrag * 100)
        .clamp(0, 100)
        .round();
    game.setAim(angle: degrees.round() % 360, power: power);
  }

  void _onScaleEnd(ScaleEndDetails d) => _mode = _GestureMode.none;

  void _onTapUp(TapUpDetails d) {
    final game = _game;
    if (game == null || !game.isLoaded) return;
    game.setTargetAtScreen(Vector2(d.localPosition.dx, d.localPosition.dy));
  }

  @override
  void dispose() {
    _game?.hud.removeListener(_onHudChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = _gameFor(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _pause();
      },
      child: Scaffold(
        body: Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: _onTapUp,
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              onScaleEnd: _onScaleEnd,
              child: GameWidget(
                game: game,
                loadingBuilder: (_) =>
                    const Center(child: CircularProgressIndicator()),
              ),
            ),
            FutureBuilder<void>(
              future: game.loaded,
              builder: (context, snapshot) =>
                  snapshot.connectionState == ConnectionState.done
                      ? ArenaHud(
                          game: game,
                          seed: _seed,
                          teamNames: _teamNames,
                          onPause: _pause,
                        )
                      : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
