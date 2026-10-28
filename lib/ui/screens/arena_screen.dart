import 'dart:async';
import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../app/match_config.dart';
import '../../app/paw_palette.dart';
import '../../config/controls.dart';
import '../../config/maps.dart';
import '../../config/match_defaults.dart';
import '../../config/teams.dart';
import '../../config/weapons.dart';
import '../../game/hud_state.dart';
import '../../services/audio_service.dart';
import '../../game/pawtillery_game.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_lookup.g.dart';
import '../../net/lockstep.dart';
import '../../net/protocol.dart';
import '../../net/session.dart';
import '../../sim/events.dart';
import '../../sim/turn_manager.dart';
import '../hud/arena_hud.dart';
import '../hud/pause_dialog.dart';
import '../hud/tutorial.dart';
import '../widgets/paw/paw_widgets.dart';
import 'lobby_screen.dart';
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
///
/// With [net] (Play on Wi-Fi) the seed, map and team owners come from the
/// host's start message, steps follow the [Lockstep], and the pause menu
/// leaves the game running.
class ArenaScreen extends StatefulWidget {
  const ArenaScreen({super.key, required this.config, this.net});

  final MatchConfig config;

  /// The Wi-Fi room this match belongs to; its [NetSession.match] is set.
  final NetSession? net;

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

enum _GestureMode { none, aim, camera }

/// What stopped a Wi-Fi match.
enum _NetStop { desync, playerLeft, hostLost }

class _ArenaScreenState extends State<ArenaScreen> with WidgetsBindingObserver {
  // The seed is the only randomness outside the sim; it is logged so any
  // match can be replayed while debugging.
  late final int _seed =
      widget.net?.match!.seed ?? math.Random().nextInt(1 << 31);
  PawtilleryGame? _game;
  late List<String> _teamNames;
  late List<TeamSymbol> _teamSymbols;
  late List<String> _unitNames;
  bool _paused = false;
  AudioService? _audio;
  TutorialController? _tutorial;
  bool _finished = false;

  // Play on Wi-Fi.
  Lockstep? _lockstep;
  _NetStop? _netStop;
  String _leftName = '';
  Timer? _waitTimer;

  /// The player whose phone the match is waiting for, if it has waited
  /// more than a moment.
  final _waitingFor = ValueNotifier<String?>(null);

  _GestureMode _mode = _GestureMode.none;
  Offset _aimStart = Offset.zero;
  AimState? _aimBefore;
  Offset _lastFocal = Offset.zero;
  double _zoomBase = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    debugPrint('Pawtillery match seed: $_seed');
    final net = widget.net;
    if (net != null) {
      final start = net.match!;
      _lockstep = Lockstep(
        owners: start.owners,
        me: net.myId,
        send: net.sendTicks,
        onHash: (tick, hash) {
          net.sendHash(tick, hash);
          // Logged like the seed, to compare phones after a match.
          if (_lockstep!.isOver) {
            debugPrint('Pawtillery final state hash: tick $tick, $hash');
          }
        },
      );
      net.attachMatch(_onNetMessage);
      _waitTimer = Timer.periodic(
        const Duration(milliseconds: 250),
        (_) => _checkWaiting(),
      );
    }
  }

  String _playerName(int id) {
    for (final p in widget.net!.match!.players) {
      if (p.id == id) return p.name;
    }
    return '?';
  }

  void _onNetMessage(NetMessage m) {
    final lock = _lockstep!;
    switch (m) {
      case TicksMsg():
        lock.receive(m);
      case DesyncMsg():
        _stopNet(_NetStop.desync);
      case PlayerLeftMsg(:final playerId):
        _leftName = _playerName(playerId);
        _stopNet(
          playerId == 0 && !widget.net!.isHost
              ? _NetStop.hostLost
              : _NetStop.playerLeft,
        );
      case EndMatchMsg():
        if (mounted) _backToLobby();
      default:
        break;
    }
  }

  void _stopNet(_NetStop reason) {
    _lockstep!.paused = true;
    // The final hashes are compared just as the match ends: a desync then
    // still replaces the results.
    if (!mounted || (_finished && reason != _NetStop.desync)) return;
    // A lost host outranks everything; otherwise keep the first reason.
    if (_netStop != null && reason != _NetStop.hostLost) return;
    _game?.setWalk(0);
    setState(() => _netStop = reason);
  }

  void _checkWaiting() {
    final lock = _lockstep!;
    final game = _game;
    String? name;
    if (game != null &&
        game.isLoaded &&
        !lock.paused &&
        !lock.isOver &&
        !lock.isMyTurn &&
        lock.sinceStep.elapsedMilliseconds > 1000) {
      name = _playerName(lock.activeOwner);
    }
    _waitingFor.value = name;
  }

  String? _otherTurnLabel(PawtilleryGame game) {
    final l10n = AppLocalizations.of(context);
    final lock = _lockstep;
    if (lock != null) {
      return game.hasControl ? null : l10n.netTurnOf(_playerName(lock.activeOwner));
    }
    if (!game.cpuTurn) return null;
    return l10n.hudCpuThinking(_teamNames[game.sim.turn.activeTeam]);
  }

  void _backToLobby() {
    widget.net?.matchFinished();
    Navigator.of(context).popUntil(ModalRoute.withName(LobbyScreen.routeName));
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
    _teamSymbols = [
      for (final t in config.teams) Teams.styles[t.styleIndex].symbol,
    ];
    _unitNames = [
      for (final t in config.teams)
        for (final u in t.units) u.name,
    ];
    final net = widget.net;
    final map = net != null
        ? Maps.byId(net.match!.mapId)
        : config.resolveMap(math.Random(_seed));
    final game = PawtilleryGame(
      seed: _seed,
      rosters: config.rosters(),
      map: map,
      objects: map.objects.forAmount(config.objects),
      teamColors: [
        for (final t in config.teams) Teams.styles[t.styleIndex].colorArgb,
      ],
      teamSymbols: _teamSymbols,
      unitNames: _unitNames,
      timings: TurnTimings(
        turnTicks: config.turnSeconds * MatchDefaults.ticksPerSecond,
      ),
      suddenDeathAfterTicks: config.suddenDeathMinutes == null
          ? null
          : config.suddenDeathMinutes! * 60 * MatchDefaults.ticksPerSecond,
      loadout: config.weapons,
      showAimGuide: AppServices.of(context).settings.showAimGuide,
      lockstep: _lockstep,
      cpuTeams: net == null ? config.cpuTeams() : const {},
    );
    game.hud.addListener(_onHudChanged);
    final services = AppServices.of(context);
    final haptics = Haptics(services.settings);
    _audio = services.audio..playMusic(Music.match).ignore();
    // The tutorial is for the first turn, so only when a person plays it.
    if (!services.settings.tutorialDone &&
        net == null &&
        config.teams.first.cpu == null) {
      final tutorial = _tutorial = TutorialController();
      tutorial.addListener(() {
        if (tutorial.isDone) services.settings.tutorialDone = true;
      });
      game.aim.addListener(() {
        if (game.aim.value.active) tutorial.complete(TutorialStep.aim);
      });
    }
    game.onEvent = (event) {
      final sfx = AudioService.sfxFor(event);
      if (sfx != null) services.audio.play(sfx);
      haptics.onEvent(event);
      if (event is WeaponUsed) _tutorial?.complete(TutorialStep.fire);
      // PRD: the tutorial belongs to the first turn only.
      if (event is TurnStarted) _tutorial?.skip();
    };
    return _game = game;
  }

  /// Match over: show the result briefly in the arena, then move on.
  void _onHudChanged() {
    final game = _game!;
    final hud = game.hud.value;
    if (_finished || hud == null || !hud.isOver) return;
    _finished = true;
    widget.net?.matchFinished();
    final top = game.stats.topDamage;
    final teamDamage = List.filled(_teamNames.length, 0);
    for (final MapEntry(:key, :value) in game.stats.damageDealt.entries) {
      teamDamage[game.sim.units[key].team] += value;
    }
    final unitsLeft = List.filled(_teamNames.length, 0);
    for (final u in game.sim.units) {
      if (u.alive) unitsLeft[u.team]++;
    }
    final result = MatchResult(
      winnerTeam: hud.winnerTeam,
      teamNames: _teamNames,
      teamColors: game.teamColors,
      teamSymbols: _teamSymbols,
      teamDamage: teamDamage,
      unitsLeft: unitsLeft,
      knockouts: List.of(game.stats.knockouts),
      turns: game.sim.turn.turnNumber,
      topUnitName: top == null ? null : _unitNames[top.$1],
      topUnitTeam: top == null ? null : game.sim.units[top.$1].team,
      topDamage: top?.$2,
    );
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted || _netStop != null) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ResultsScreen(
            result: result,
            config: widget.config,
            net: widget.net != null,
          ),
        ),
      );
    });
  }

  /// Leaving the app (home button, a call) mid-match opens the pause
  /// menu, so the turn clock doesn't run on as soon as the player is back.
  /// A Wi-Fi match keeps going for the other phones either way.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden && widget.net == null) _pause();
  }

  Future<void> _pause() async {
    final game = _game;
    if (game == null || _paused || _finished) return;
    _paused = true;
    // A Wi-Fi match can't stop for one phone: only the menu opens.
    final net = widget.net != null;
    game.setWalk(0);
    if (!net) game.pauseEngine();
    while (mounted) {
      final choice = await showPauseDialog(context);
      if (!mounted) return;
      if (choice == PauseChoice.settings) {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
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
    if (!net) game.resumeEngine();
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
    WidgetsBinding.instance.removeObserver(this);
    widget.net?.detachMatch();
    _waitTimer?.cancel();
    _waitingFor.dispose();
    _tutorial?.dispose();
    _game?.hud.removeListener(_onHudChanged);
    _audio?.playMusic(Music.menu).ignore();
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
                      teamSymbols: _teamSymbols,
                      onPause: _pause,
                      tutorial: _tutorial,
                      otherTurnLabel: () => _otherTurnLabel(game),
                    )
                  : const SizedBox.shrink(),
            ),
            if (_lockstep != null)
              ValueListenableBuilder<String?>(
                valueListenable: _waitingFor,
                builder: (context, name, _) => name == null || _netStop != null
                    ? const SizedBox.shrink()
                    : Align(
                        alignment: const Alignment(0, -0.45),
                        child: _NetPill(
                          AppLocalizations.of(context).netWaiting(name),
                        ),
                      ),
              ),
            if (_netStop case final stop?) _netStopCard(context, stop),
          ],
        ),
      ),
    );
  }

  /// A Wi-Fi match stopped: why, and what this phone can do about it.
  Widget _netStopCard(BuildContext context, _NetStop stop) {
    final l10n = AppLocalizations.of(context);
    final isHost = widget.net!.isHost;
    void toMenu() => Navigator.of(context).popUntil((route) => route.isFirst);
    final (title, body, button, action) = switch (stop) {
      _NetStop.desync => (
        l10n.netDesyncTitle,
        l10n.netDesyncBody,
        l10n.netBackToLobby,
        () {
          if (isHost) {
            (widget.net! as HostSession).endMatch();
          } else {
            _backToLobby();
          }
        },
      ),
      _NetStop.playerLeft => (
        l10n.netPlayerLeft(_leftName),
        isHost ? l10n.netPausedHost : l10n.netPausedGuest,
        isHost ? l10n.netEndMatch : l10n.lobbyLeave,
        isHost ? (widget.net! as HostSession).endMatch : toMenu,
      ),
      _NetStop.hostLost => (
        l10n.netHostLost,
        null,
        l10n.resultMainMenu,
        toMenu,
      ),
    };
    return Positioned.fill(
      child: ColoredBox(
        color: Paw.scrim,
        child: Center(
          child: SizedBox(
            width: 380,
            child: PawCard(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title, style: Paw.title(22)),
                  if (body != null) ...[
                    const SizedBox(height: 6),
                    Text(body, style: Paw.text(15, weight: 600, height: 1.4)),
                  ],
                  const SizedBox(height: 16),
                  PawButton(
                    label: button,
                    fill: Paw.orange,
                    height: 48,
                    fontSize: 15,
                    onPressed: action,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A small cream label over the arena (Wi-Fi match status).
class _NetPill extends StatelessWidget {
  const _NetPill(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: Paw.cream,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Paw.ink, width: 2),
      boxShadow: Paw.drop(3),
    ),
    child: Text(text, style: Paw.text(14)),
  );
}
