import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../config/controls.dart';
import '../../game/hud_state.dart';
import '../../game/pawtillery_game.dart';
import '../hud/arena_hud.dart';

/// Hosts the Flame game, routes touch gestures to it, and layers the
/// Flutter HUD on top.
///
/// Gestures (PRD: Kontrol sentuh): one finger drags the slingshot when the
/// active unit may fire, otherwise pans; two fingers always pan and pinch.
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
  late final PawtilleryGame _game = PawtilleryGame(
    seed: _seed,
    teamCount: widget.teamCount,
    unitsPerTeam: widget.unitsPerTeam,
  );

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

  void _onScaleStart(ScaleStartDetails d) {
    if (!_game.isLoaded) return;
    if (d.pointerCount >= 2 || !_game.canAim) {
      _startCamera(d.localFocalPoint, 1);
    } else {
      _mode = _GestureMode.aim;
      _aimStart = d.localFocalPoint;
      _aimBefore = _game.aim.value;
    }
  }

  void _startCamera(Offset focal, double currentScale) {
    _mode = _GestureMode.camera;
    _lastFocal = focal;
    _zoomBase = _game.cameraZoom / currentScale;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    if (_mode == _GestureMode.aim && d.pointerCount >= 2) {
      // A second finger turns an aim drag into a camera gesture.
      final before = _aimBefore;
      if (before != null) _game.aim.value = before;
      _startCamera(d.localFocalPoint, d.scale);
    }
    switch (_mode) {
      case _GestureMode.aim:
        _updateAim(d.localFocalPoint);
      case _GestureMode.camera:
        final delta = d.localFocalPoint - _lastFocal;
        _lastFocal = d.localFocalPoint;
        _game.panCamera(Vector2(delta.dx, delta.dy));
        if (d.pointerCount >= 2) {
          _game.zoomCamera(
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
  void _updateAim(Offset finger) {
    final pull = _aimStart - finger;
    if (pull.distance < ControlsConfig.slingshotDeadZone) {
      _game.cancelAim();
      return;
    }
    final degrees = math.atan2(-pull.dy, pull.dx) * 180 / math.pi;
    final power = (pull.distance / ControlsConfig.slingshotMaxDrag * 100)
        .clamp(0, 100)
        .round();
    _game.setAim(angle: degrees.round() % 360, power: power);
  }

  void _onScaleEnd(ScaleEndDetails d) => _mode = _GestureMode.none;

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
    return Scaffold(
      body: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            onScaleEnd: _onScaleEnd,
            child: GameWidget(
              game: _game,
              loadingBuilder: (_) =>
                  const Center(child: CircularProgressIndicator()),
            ),
          ),
          FutureBuilder<void>(
            future: _game.loaded,
            builder: (context, snapshot) =>
                snapshot.connectionState == ConnectionState.done
                    ? ArenaHud(
                        game: _game,
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
