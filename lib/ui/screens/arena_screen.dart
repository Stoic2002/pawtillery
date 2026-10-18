import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../config/breeds.dart';
import '../../config/controls.dart';
import '../../config/families.dart';
import '../../config/weapons.dart';
import '../../game/hud_state.dart';
import '../../game/pawtillery_game.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_lookup.g.dart';
import '../../sim/match_setup.dart';
import '../hud/arena_hud.dart';

/// Hosts the Flame game, routes touch gestures to it, and layers the
/// Flutter HUD on top.
///
/// Gestures (PRD: Kontrol sentuh): one finger drags the slingshot for
/// weapons aimed that way (when the unit may fire), otherwise pans; a tap
/// picks the target for target weapons; two fingers always pan and pinch.
class ArenaScreen extends StatefulWidget {
  const ArenaScreen({
    super.key,
    required this.teamCount,
    required this.unitsPerTeam,
  });

  final int teamCount;
  final int unitsPerTeam;

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

enum _GestureMode { none, aim, camera }

class _ArenaScreenState extends State<ArenaScreen> {
  // The seed is the only randomness outside the sim; it is logged so any
  // match can be replayed while debugging.
  late final int _seed = math.Random().nextInt(1 << 31);
  PawtilleryGame? _game;

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

  /// Until the setup screen exists (M4): random families and breeds,
  /// derived from the match seed so a seed reproduces the whole match.
  List<List<UnitSpec>> _randomRosters() {
    final rng = math.Random(_seed);
    return [
      for (var t = 0; t < widget.teamCount; t++)
        [
          for (var k = 0; k < widget.unitsPerTeam; k++)
            () {
              final family = Families.all[rng.nextInt(Families.all.length)];
              final breeds = Breeds.ofFamily(family.id);
              return UnitSpec(
                familyId: family.id,
                breedId: breeds[rng.nextInt(breeds.length)].id,
              );
            }(),
        ],
    ];
  }

  PawtilleryGame _gameFor(BuildContext context) {
    final existing = _game;
    if (existing != null) return existing;
    final l10n = AppLocalizations.of(context);
    return _game = PawtilleryGame(
      seed: _seed,
      rosters: _randomRosters(),
      familyLetters: {
        for (final f in Families.all)
          f.id: l10n.byKey(f.nameKey).characters.first.toUpperCase(),
      },
    );
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

  void _playAgain() {
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
      builder: (_) => ArenaScreen(
        teamCount: widget.teamCount,
        unitsPerTeam: widget.unitsPerTeam,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final game = _gameFor(context);
    return Scaffold(
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
                        onBack: () => Navigator.of(context).maybePop(),
                        onPlayAgain: _playAgain,
                      )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
