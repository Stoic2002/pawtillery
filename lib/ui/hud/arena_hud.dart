import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../app/paw_palette.dart';
import '../../config/controls.dart';
import '../../config/teams.dart';
import '../../config/weapons.dart';
import '../../game/hud_state.dart';
import '../../game/pawtillery_game.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_lookup.g.dart';
import '../../sim/inputs.dart';
import '../../sim/turn_manager.dart';
import '../widgets/paw/paw_widgets.dart';
import 'tutorial.dart';
import 'weapon_menu.dart';

/// Arena HUD (redesign prototype): pause and team HP pills top left, the
/// turn timer and active unit top centre, wind and the camera button top
/// right, walk buttons bottom left, jumps / weapon / Fire bottom right, an
/// aim panel above them while aiming, and the team banner at each turn
/// start. Every tap target is at least 48 × 48 dp.
class ArenaHud extends StatelessWidget {
  const ArenaHud({
    super.key,
    required this.game,
    required this.seed,
    required this.teamNames,
    required this.teamSymbols,
    required this.onPause,
    this.tutorial,
    this.otherTurnLabel,
  });

  final PawtilleryGame game;
  final int seed;
  final List<String> teamNames;
  final List<TeamSymbol> teamSymbols;
  final VoidCallback onPause;

  /// First-match tutorial, if it should show.
  final TutorialController? tutorial;

  /// Who is taking the turn when it is not this phone's players ("Ana's
  /// turn" on Wi-Fi, "Red Team is thinking…" for a CPU team), or null when
  /// the controls are here.
  final String? Function()? otherTurnLabel;

  @override
  Widget build(BuildContext context) {
    // Laid out on a larger canvas, then shrunk to fit: every piece is
    // smaller by the same share and keeps its corner.
    const scale = ControlsConfig.hudScale;
    return LayoutBuilder(
      builder: (context, box) => FittedBox(
        fit: BoxFit.fill,
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: box.maxWidth / scale,
          height: box.maxHeight / scale,
          child: _hud(context),
        ),
      ),
    );
  }

  Widget _hud(BuildContext context) {
    return ValueListenableBuilder<HudState?>(
      valueListenable: game.hud,
      builder: (context, hud, _) {
        if (hud == null) return const SizedBox.shrink();
        return ValueListenableBuilder<AimState>(
          valueListenable: game.aim,
          builder: (context, aim, _) {
            final weapon = Weapons.byId(aim.weaponId);
            final acting = hud.phase == TurnPhase.action && game.canAim;
            final targeting = acting && weapon.aim == AimMode.target;
            final hint = targeting
                ? AppLocalizations.of(context).hudTapTarget
                : hud.shotgunLeft > 0 && acting
                ? AppLocalizations.of(context).hudShotgunMore
                : null;
            final aiming =
                acting &&
                aim.active &&
                (weapon.aim == AimMode.angleAndPower ||
                    weapon.aim == AimMode.direction);
            final teamColor = Color(game.teamColors[hud.activeTeam]);
            final remote = otherTurnLabel?.call();
            final digging = remote == null && game.digging;
            return Stack(
              children: [
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: _TopLeft(
                            hud: hud,
                            game: game,
                            symbols: teamSymbols,
                            onPause: onPause,
                          ),
                        ),
                        Align(
                          alignment: Alignment.topCenter,
                          child: _TopCentre(
                            hud: hud,
                            game: game,
                            teamColor: teamColor,
                            symbol: teamSymbols[hud.activeTeam],
                            hint: hint,
                          ),
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          child: _TopRight(game: game, hud: hud, seed: seed),
                        ),
                        if (!hud.isOver && remote != null)
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: _RemoteTurn(label: remote, color: teamColor),
                          ),
                        if (!hud.isOver && digging) ...[
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: _DigJoystick(game: game),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: _DigDone(game: game),
                          ),
                        ],
                        if (!hud.isOver && remote == null && !digging) ...[
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: _Walk(
                              game: game,
                              hud: hud,
                              dim: aiming,
                              onWalk: () =>
                                  tutorial?.complete(TutorialStep.walk),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: targeting
                                ? _TargetActions(
                                    game: game,
                                    aim: aim,
                                    weapon: weapon,
                                    onOpenWeapons: () => tutorial?.complete(
                                      TutorialStep.weapons,
                                    ),
                                  )
                                : _Actions(
                                    game: game,
                                    hud: hud,
                                    aim: aim,
                                    weapon: weapon,
                                    acting: acting,
                                    dim: aiming,
                                    onOpenWeapons: () => tutorial?.complete(
                                      TutorialStep.weapons,
                                    ),
                                  ),
                          ),
                          if (aiming)
                            Positioned(
                              right: 0,
                              bottom: 96,
                              child: _AimPanel(
                                game: game,
                                aim: aim,
                                weapon: weapon,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (tutorial != null)
                  TutorialOverlay(
                    controller: tutorial!,
                    visible: hud.phase == TurnPhase.action,
                  ),
                if (hud.phase == TurnPhase.turnStart)
                  _TurnBanner(
                    name: teamNames[hud.activeTeam],
                    unitName: _activeName(game),
                    color: teamColor,
                    symbol: teamSymbols[hud.activeTeam],
                    drawnWeaponId: game.sim.drawnWeaponId,
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Dig mode: a joystick that steers the tunnel. The knob follows the
/// finger inside the ring; its direction is sent while held, and letting
/// go stops digging on the spot (the timer keeps running).
class _DigJoystick extends StatefulWidget {
  const _DigJoystick({required this.game});

  final PawtilleryGame game;

  @override
  State<_DigJoystick> createState() => _DigJoystickState();
}

class _DigJoystickState extends State<_DigJoystick> {
  static const double _size = 132;
  static const double _knob = 52;
  static const double _deadZone = 10;

  Offset _offset = Offset.zero;

  void _move(Offset local) {
    const c = Offset(_size / 2, _size / 2);
    var v = local - c;
    const max = (_size - _knob) / 2;
    if (v.distance > max) v = v / v.distance * max;
    setState(() => _offset = v);
    if (v.distance < _deadZone) {
      widget.game.setDig(null);
      return;
    }
    final deg = (math.atan2(-v.dy, v.dx) * 180 / math.pi).round() % 360;
    widget.game.setDig(deg);
  }

  void _release() {
    setState(() => _offset = Offset.zero);
    widget.game.setDig(null);
  }

  @override
  void dispose() {
    widget.game.setDig(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.hudDigHint,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (d) => _move(d.localPosition),
        onPanUpdate: (d) => _move(d.localPosition),
        onPanEnd: (_) => _release(),
        onPanCancel: _release,
        child: SizedBox.square(
          dimension: _size,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Paw.cream.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                  border: Border.all(color: Paw.ink, width: 3),
                  boxShadow: Paw.drop(4),
                ),
              ),
              // Direction ticks.
              for (final a in const [0.0, 90.0, 180.0, 270.0])
                Positioned(
                  left: _size / 2 + math.cos(a * math.pi / 180) * 50 - 4,
                  top: _size / 2 - math.sin(a * math.pi / 180) * 50 - 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Paw.line,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              Positioned(
                left: _size / 2 - _knob / 2 + _offset.dx,
                top: _size / 2 - _knob / 2 + _offset.dy,
                child: Container(
                  width: _knob,
                  height: _knob,
                  decoration: BoxDecoration(
                    color: Paw.orange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Paw.ink, width: 3),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.pets_rounded,
                    size: 24,
                    color: Paw.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dig mode: how long is left, and Done to stop and retreat.
class _DigDone extends StatelessWidget {
  const _DigDone({required this.game});

  final PawtilleryGame game;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unit = game.sim.activeUnit;
    final spec = Weapons.digClaws.delivery as DigMode;
    final time = unit == null ? 0.0 : unit.digTicks / spec.durationTicks;
    final distance = unit == null ? 0.0 : unit.digLeft / spec.maxDistance;
    final left = math.min(time, distance).clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 150,
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
          decoration: BoxDecoration(
            color: Paw.cream,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Paw.ink, width: 2),
            boxShadow: Paw.drop(3),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.hudDigHint, style: Paw.text(12)),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: left,
                  minHeight: 8,
                  color: Paw.orange,
                  backgroundColor: Paw.peach,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        PawButton(
          label: l10n.hudDigDone,
          icon: Icons.check_rounded,
          fill: Paw.green,
          display: true,
          fontSize: 20,
          height: 60,
          borderWidth: 3,
          onPressed: game.stopDigging,
        ),
      ],
    );
  }
}

/// Bottom of the screen on the other phones during a Wi-Fi turn.
class _RemoteTurn extends StatelessWidget {
  const _RemoteTurn({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    decoration: BoxDecoration(
      color: Paw.cream,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: color, width: 3),
      boxShadow: Paw.drop(3),
    ),
    child: Text(label, style: Paw.text(16)),
  );
}

String _activeName(PawtilleryGame game) {
  final u = game.sim.activeUnit;
  return u == null || u.id >= game.unitNames.length ? '' : game.unitNames[u.id];
}

// -------------------------------------------------------------- top left

class _TopLeft extends StatelessWidget {
  const _TopLeft({
    required this.hud,
    required this.game,
    required this.symbols,
    required this.onPause,
  });

  final HudState hud;
  final PawtilleryGame game;
  final List<TeamSymbol> symbols;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PawCircleButton(
          icon: Icons.pause_rounded,
          tooltip: l10n.hudPause,
          onPressed: onPause,
        ),
        const SizedBox(height: 8),
        for (var t = 0; t < hud.teamHp.length; t++)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: _TeamBar(
              color: Color(game.teamColors[t]),
              symbol: symbols[t],
              hp: hud.teamHp[t],
              maxHp: hud.teamMaxHp[t],
              active: t == hud.activeTeam,
            ),
          ),
      ],
    );
  }
}

class _TeamBar extends StatelessWidget {
  const _TeamBar({
    required this.color,
    required this.symbol,
    required this.hp,
    required this.maxHp,
    required this.active,
  });

  final Color color;
  final TeamSymbol symbol;
  final int hp;
  final int maxHp;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final out = hp <= 0;
    final fraction = maxHp == 0 ? 0.0 : (hp / maxHp).clamp(0.0, 1.0);
    return Opacity(
      opacity: out ? 0.5 : 1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(2, 2, 8, 2),
            decoration: BoxDecoration(
              color: active ? Paw.cream : Paw.cream.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: active ? color : Paw.ink, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TeamBadge(color: color, symbol: symbol, size: 20),
                const SizedBox(width: 6),
                Container(
                  width: 84,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: Paw.ink, width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.centerLeft,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: fraction),
                    duration: const Duration(milliseconds: 400),
                    builder: (context, f, _) => FractionallySizedBox(
                      widthFactor: f,
                      child: ColoredBox(color: color),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (out)
            Transform.rotate(
              angle: -0.07,
              child: Container(width: 110, height: 2.5, color: Paw.ink),
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ top centre

class _TopCentre extends StatelessWidget {
  const _TopCentre({
    required this.hud,
    required this.game,
    required this.teamColor,
    required this.symbol,
    required this.hint,
  });

  final HudState hud;
  final PawtilleryGame game;
  final Color teamColor;
  final TeamSymbol symbol;

  /// A how-to-aim hint under the clock (target weapons).
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final clock = hud.clockSeconds;
    final running = hud.phase == TurnPhase.action;
    final warn = running && clock != null && clock < 10;
    final retreat = hud.phase == TurnPhase.retreat;
    Widget pill(
      Widget child, {
      Color fill = Paw.cream,
      Color border = Paw.ink,
    }) => Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border, width: 2),
        boxShadow: fill == Paw.ink ? null : Paw.drop(3),
      ),
      child: child,
    );
    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (clock != null && !hud.isOver)
            TweenAnimationBuilder<double>(
              key: ValueKey(warn ? clock : -1),
              tween: Tween(begin: warn ? 1.07 : 1, end: 1),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              builder: (context, s, child) =>
                  Transform.scale(scale: s, child: child),
              child: Container(
                constraints: const BoxConstraints(minWidth: 84),
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: warn ? Paw.yellow : Paw.cream,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Paw.ink, width: 3),
                  boxShadow: Paw.drop(),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!running && !retreat) ...[
                      const Icon(
                        Icons.pause_circle_rounded,
                        size: 18,
                        color: Paw.muted,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      '$clock',
                      style: Paw.title(
                        30,
                        weight: 800,
                        height: 1,
                        color: running || retreat ? Paw.ink : Paw.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 6),
          if (!hud.isOver)
            Container(
              height: 28,
              padding: const EdgeInsets.fromLTRB(3, 0, 10, 0),
              decoration: BoxDecoration(
                color: Paw.cream,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: teamColor, width: 2),
                boxShadow: Paw.drop(2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TeamBadge(color: teamColor, symbol: symbol, size: 20),
                  const SizedBox(width: 6),
                  Text(_activeName(game), style: Paw.text(14)),
                ],
              ),
            ),
          if (hud.suddenDeath) ...[
            const SizedBox(height: 6),
            Container(
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Paw.cream,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFC42A2F), width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.water_rounded,
                    size: 16,
                    color: Color(0xFFC42A2F),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.hudSuddenDeath,
                    style: Paw.text(12, color: const Color(0xFFC42A2F)),
                  ),
                ],
              ),
            ),
          ],
          if (hud.frozenSkip && !hud.isOver) ...[
            const SizedBox(height: 6),
            pill(
              fill: const Color(0xFFCFF2FF),
              border: const Color(0xFF2F7FB5),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.ac_unit_rounded,
                    size: 20,
                    color: Color(0xFF2F7FB5),
                  ),
                  const SizedBox(width: 6),
                  Text(l10n.hudFrozenSkip, style: Paw.title(18, weight: 800)),
                ],
              ),
            ),
          ],
          if (retreat) ...[
            const SizedBox(height: 6),
            pill(
              fill: Paw.yellow,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.directions_run_rounded,
                    size: 20,
                    color: Paw.ink,
                  ),
                  const SizedBox(width: 6),
                  Text(l10n.hudRetreatNow, style: Paw.title(18, weight: 800)),
                ],
              ),
            ),
          ],
          if (hint case final String text) ...[
            const SizedBox(height: 6),
            pill(
              fill: Paw.ink,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.touch_app_rounded,
                    size: 18,
                    color: Paw.cream,
                  ),
                  const SizedBox(width: 6),
                  Text(text, style: Paw.text(14, color: Paw.cream)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- top right

class _TopRight extends StatelessWidget {
  const _TopRight({required this.game, required this.hud, required this.seed});

  final PawtilleryGame game;
  final HudState hud;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = AppServices.of(context).settings;
    final wind = hud.wind;
    final strong = wind.abs() >= 7;
    Widget note(String text) => Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Paw.ink.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: Paw.text(11, weight: 700, color: Paw.cream)),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Tooltip(
              message: l10n.hudWind(wind),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: strong ? Paw.peach : Paw.cream,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Paw.ink, width: 2),
                  boxShadow: Paw.drop(),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.hudWindLabel, style: Paw.text(12)),
                    const SizedBox(width: 8),
                    Container(
                      width: 64,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: Paw.ink, width: 2),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final w = box.maxWidth;
                          final fill = w * wind.abs() / 20;
                          return Stack(
                            children: [
                              Positioned(
                                left: wind >= 0 ? w / 2 : w / 2 - fill,
                                width: fill,
                                top: 0,
                                bottom: 0,
                                child: ColoredBox(
                                  color: strong ? Paw.yellow : Paw.muted,
                                ),
                              ),
                              Positioned(
                                left: w / 2 - 1,
                                width: 2,
                                top: 0,
                                bottom: 0,
                                child: const ColoredBox(color: Paw.ink),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      wind > 0
                          ? Icons.east_rounded
                          : wind < 0
                          ? Icons.west_rounded
                          : Icons.remove_rounded,
                      size: 18,
                      color: Paw.ink,
                    ),
                    SizedBox(
                      width: 34,
                      child: Text(
                        wind > 0 ? '+$wind' : '$wind',
                        textAlign: TextAlign.right,
                        style: Paw.title(22, weight: 800, height: 1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            PawCircleButton(
              icon: Icons.center_focus_strong_rounded,
              tooltip: l10n.hudCenterCamera,
              onPressed: game.centerOnActiveUnit,
            ),
          ],
        ),
        // Frame rate: when Settings asks for it, and always in debug and
        // profile builds.
        ListenableBuilder(
          listenable: settings,
          builder: (context, _) =>
              !(settings.showFps || kDebugMode || kProfileMode)
              ? const SizedBox.shrink()
              : ValueListenableBuilder<FrameStats?>(
                  valueListenable: game.frameStats,
                  builder: (context, f, _) => f == null
                      ? const SizedBox.shrink()
                      : note(
                          l10n.debugFps(f.fps, f.worstMs.toStringAsFixed(1)),
                        ),
                ),
        ),
        if (kDebugMode || kProfileMode) ...[
          note(l10n.debugSeed(seed)),
          ValueListenableBuilder<ExplosionTiming?>(
            valueListenable: game.explosionTiming,
            builder: (context, t, _) => t == null
                ? const SizedBox.shrink()
                : note(
                    l10n.debugExplosionTime(
                      t.lastMs.toStringAsFixed(2),
                      t.maxMs.toStringAsFixed(2),
                    ),
                  ),
          ),
        ],
      ],
    );
  }
}

// ------------------------------------------------------------ bottom left

class _Walk extends StatelessWidget {
  const _Walk({
    required this.game,
    required this.hud,
    required this.dim,
    required this.onWalk,
  });

  final PawtilleryGame game;
  final HudState hud;
  final bool dim;
  final VoidCallback onWalk;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget walk(String label, IconData icon, int dir) => PawCircleButton(
      icon: icon,
      tooltip: label,
      size: 64,
      borderWidth: 3,
      enabled: hud.canMove,
      onHold: (down) {
        if (down) onWalk();
        game.setWalk(down ? dir : 0);
      },
    );
    return Opacity(
      opacity: dim ? 0.4 : 1,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          walk(l10n.hudWalkLeft, Icons.arrow_back_rounded, -1),
          const SizedBox(width: 12),
          walk(l10n.hudWalkRight, Icons.arrow_forward_rounded, 1),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------- bottom right

class _Actions extends StatelessWidget {
  const _Actions({
    required this.game,
    required this.hud,
    required this.aim,
    required this.weapon,
    required this.acting,
    required this.dim,
    required this.onOpenWeapons,
  });

  final PawtilleryGame game;
  final HudState hud;
  final AimState aim;
  final WeaponDef weapon;
  final bool acting;
  final bool dim;
  final VoidCallback onOpenWeapons;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unit = game.sim.activeUnit;
    final ready = acting && (aim.active || weapon.aim == AimMode.none);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Opacity(
          opacity: dim ? 0.4 : 1,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PawCircleButton(
                icon: Icons.north_east_rounded,
                tooltip: l10n.hudJump,
                size: 64,
                borderWidth: 3,
                mirror: (unit?.facing ?? 1) < 0,
                enabled: hud.canMove,
                onPressed: () => game.jump(JumpKind.forward),
              ),
              const SizedBox(width: 12),
              PawCircleButton(
                icon: Icons.keyboard_double_arrow_up_rounded,
                tooltip: l10n.hudHighJump,
                size: 64,
                borderWidth: 3,
                enabled: hud.canMove,
                onPressed: () => game.jump(JumpKind.high),
              ),
            ],
          ),
        ),
        if (acting) ...[
          const SizedBox(width: 12),
          _WeaponButton(game: game, weapon: weapon, onOpen: onOpenWeapons),
          const SizedBox(width: 12),
          _FireButton(
            label:
                weapon.delivery is Launch ||
                    weapon.delivery is Beam ||
                    weapon.delivery is Shotgun
                ? l10n.hudFire
                : l10n.hudUse,
            onPressed: ready ? game.fire : null,
          ),
        ],
      ],
    );
  }
}

/// The current weapon with its ammo; opens the weapon menu.
class _WeaponButton extends StatelessWidget {
  const _WeaponButton({
    required this.game,
    required this.weapon,
    required this.onOpen,
  });

  final PawtilleryGame game;
  final WeaponDef weapon;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tooltip = l10n.hudWeapons;
    final unit = game.sim.activeUnit;
    final left = unit == null
        ? null
        : weapon.isSignature
        ? (game.sim.canUse(unit, weapon) ? 1 : 0)
        : game.sim.ammoLeft(unit.team, weapon);
    final ammo = left == null ? l10n.hudAmmoUnlimited : '$left';
    return _button(context, tooltip, ammo);
  }

  Widget _button(BuildContext context, String tooltip, String ammo) => Tooltip(
    message: tooltip,
    child: Semantics(
      button: true,
      label: tooltip,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          onOpen();
          showWeaponMenu(context, game);
        },
        child: SizedBox(
          width: 64,
          height: 68,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Paw.peach,
                  shape: BoxShape.circle,
                  border: Border.all(color: Paw.ink, width: 3),
                  boxShadow: Paw.drop(),
                ),
                alignment: Alignment.center,
                child: WeaponIcon(weapon: weapon, size: 38),
              ),
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 26),
                  height: 26,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: Paw.cream,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Paw.ink, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    ammo,
                    style: Paw.title(14, weight: 800, height: 1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// The round Fire button: orange with a target when the shot is ready,
/// grey while there is nothing to fire yet.
class _FireButton extends StatefulWidget {
  const _FireButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  State<_FireButton> createState() => _FireButtonState();
}

class _FireButtonState extends State<_FireButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final ready = widget.onPressed != null;
    final down = _down && ready;
    return Semantics(
      button: true,
      enabled: ready,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: ready ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: ready
            ? (_) {
                setState(() => _down = false);
                widget.onPressed!();
              }
            : null,
        child: SizedBox(
          width: 80,
          height: 85,
          child: Align(
            alignment: Alignment.topCenter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              width: 80,
              height: 80,
              transform: Matrix4.translationValues(0, down ? 4 : 0, 0),
              decoration: BoxDecoration(
                color: !ready
                    ? Paw.line
                    : down
                    ? Paw.orangeDeep
                    : Paw.orange,
                shape: BoxShape.circle,
                border: Border.all(color: Paw.ink, width: 3),
                boxShadow: Paw.drop(down ? 1 : (ready ? 5 : 3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.gps_fixed_rounded,
                    size: 34,
                    color: ready ? Paw.ink : Paw.muted,
                  ),
                  Text(
                    widget.label,
                    style: Paw.text(12, color: ready ? Paw.ink : Paw.muted),
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

/// Target weapons: Cancel (back to the previous weapon), the weapon
/// button and Confirm instead of the usual buttons.
class _TargetActions extends StatelessWidget {
  const _TargetActions({
    required this.game,
    required this.aim,
    required this.weapon,
    required this.onOpenWeapons,
  });

  final PawtilleryGame game;
  final AimState aim;
  final WeaponDef weapon;
  final VoidCallback onOpenWeapons;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ok = aim.hasTarget && aim.targetValid;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PawButton(
          label: l10n.hudCancel,
          height: 56,
          borderWidth: 3,
          onPressed: game.cancelAim,
        ),
        const SizedBox(width: 12),
        _WeaponButton(game: game, weapon: weapon, onOpen: onOpenWeapons),
        const SizedBox(width: 12),
        PawButton(
          label: l10n.hudConfirm,
          icon: Icons.gps_fixed_rounded,
          fill: ok ? Paw.orange : Paw.line,
          foreground: ok ? Paw.ink : Paw.muted,
          display: true,
          fontSize: 20,
          height: 56,
          borderWidth: 3,
          onPressed: ok ? game.fire : null,
        ),
      ],
    );
  }
}

/// While aiming: Cancel, angle − value +, power − value + in one pill.
class _AimPanel extends StatelessWidget {
  const _AimPanel({
    required this.game,
    required this.aim,
    required this.weapon,
  });

  final PawtilleryGame game;
  final AimState aim;
  final WeaponDef weapon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget round(IconData icon, String tip, VoidCallback onTap) =>
        PawCircleButton(
          icon: icon,
          tooltip: tip,
          size: 44,
          fill: Paw.peach,
          iconSize: 20,
          onPressed: onTap,
        );
    Widget value(String label, String text, double width) => SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Paw.text(11, color: Paw.muted, height: 1)),
          Text(text, style: Paw.title(18, weight: 800, height: 1.1)),
        ],
      ),
    );
    Widget divider() => Container(
      width: 2,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Paw.peach,
    );
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Paw.cream,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Paw.ink, width: 3),
        boxShadow: Paw.drop(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PawButton(
            label: l10n.hudCancel,
            icon: Icons.close_rounded,
            height: 44,
            fontSize: 13,
            radius: 999,
            shadow: 0,
            padding: 12,
            onPressed: game.cancelAim,
          ),
          divider(),
          round(
            Icons.remove_rounded,
            l10n.hudDecrease,
            () => game.adjustAngle(-ControlsConfig.angleStep),
          ),
          value(l10n.hudAngleLabel, '${aim.angle}°', 56),
          round(
            Icons.add_rounded,
            l10n.hudIncrease,
            () => game.adjustAngle(ControlsConfig.angleStep),
          ),
          if (weapon.aim == AimMode.angleAndPower) ...[
            divider(),
            round(
              Icons.remove_rounded,
              l10n.hudDecrease,
              () => game.adjustPower(-ControlsConfig.powerStep),
            ),
            value(l10n.hudPowerLabel, '${aim.power}%', 64),
            round(
              Icons.add_rounded,
              l10n.hudIncrease,
              () => game.adjustPower(ControlsConfig.powerStep),
            ),
          ],
        ],
      ),
    );
  }
}

/// The team banner that slides down at each turn start.
class _TurnBanner extends StatelessWidget {
  const _TurnBanner({
    required this.name,
    required this.unitName,
    required this.color,
    required this.symbol,
    this.drawnWeaponId,
  });

  final String name;
  final String unitName;
  final Color color;
  final TeamSymbol symbol;

  /// Random weapons rule: this turn's weapon, shown under the banner.
  final String? drawnWeaponId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = l10n.turnBanner(name);
    final big = Paw.title(32, weight: 800, height: 1);
    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: -110, end: 16),
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutBack,
            builder: (context, y, child) =>
                Transform.translate(offset: Offset(0, y), child: child),
            child: FractionallySizedBox(
              widthFactor: 0.64,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _banner(text, big),
                  if (drawnWeaponId case final id?) ...[
                    const SizedBox(height: 8),
                    _drawn(l10n, Weapons.byId(id)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _drawn(AppLocalizations l10n, WeaponDef weapon) => Container(
    height: 40,
    padding: const EdgeInsets.fromLTRB(8, 0, 14, 0),
    decoration: BoxDecoration(
      color: Paw.cream,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Paw.ink, width: 2),
      boxShadow: Paw.drop(3),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.casino_rounded, size: 22, color: Paw.ink),
        const SizedBox(width: 6),
        WeaponIcon(weapon: weapon, size: 28),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            l10n.hudDrawnWeapon(l10n.byKey(weapon.nameKey)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Paw.text(15),
          ),
        ),
      ],
    ),
  );

  Widget _banner(String text, TextStyle big) => Container(
    height: 76,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Paw.ink, width: 3),
      boxShadow: Paw.drop(5),
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Paw.cream,
            shape: BoxShape.circle,
            border: Border.all(color: Paw.ink, width: 3),
          ),
          alignment: Alignment.center,
          child: SizedBox.square(
            dimension: 24,
            child: CustomPaint(
              painter: TeamSymbolPainter(symbol, fill: color, strokeWidth: 2),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Stack(
            children: [
              Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: big.copyWith(
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 6
                    ..strokeJoin = StrokeJoin.round
                    ..color = Paw.ink,
                ),
              ),
              Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: big.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
        if (unitName.isNotEmpty)
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Paw.cream,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Paw.ink, width: 2),
            ),
            child: Text(unitName, style: Paw.text(14)),
          ),
      ],
    ),
  );
}
