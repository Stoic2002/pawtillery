import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/paw_palette.dart';
import '../../config/controls.dart';
import '../../config/teams.dart';
import '../../config/weapons.dart';
import '../../game/hud_state.dart';
import '../../game/pawtillery_game.dart';
import '../../l10n/app_localizations.dart';
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
  });

  final PawtilleryGame game;
  final int seed;
  final List<String> teamNames;
  final List<TeamSymbol> teamSymbols;
  final VoidCallback onPause;

  /// First-match tutorial, if it should show.
  final TutorialController? tutorial;

  @override
  Widget build(BuildContext context) {
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
            final aiming =
                acting &&
                aim.active &&
                (weapon.aim == AimMode.angleAndPower ||
                    weapon.aim == AimMode.direction);
            final teamColor = Color(game.teamColors[hud.activeTeam]);
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
                            targeting: targeting,
                          ),
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          child: _TopRight(game: game, hud: hud, seed: seed),
                        ),
                        if (!hud.isOver) ...[
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
                  ),
              ],
            );
          },
        );
      },
    );
  }
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
    required this.targeting,
  });

  final HudState hud;
  final PawtilleryGame game;
  final Color teamColor;
  final TeamSymbol symbol;
  final bool targeting;

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
          if (targeting) ...[
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
                  Text(
                    l10n.hudTapTarget,
                    style: Paw.text(14, color: Paw.cream),
                  ),
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
        if (kDebugMode || kProfileMode) ...[
          note(l10n.debugSeed(seed)),
          ValueListenableBuilder<FrameStats?>(
            valueListenable: game.frameStats,
            builder: (context, f, _) => f == null
                ? const SizedBox.shrink()
                : note(l10n.debugFps(f.fps, f.worstMs.toStringAsFixed(1))),
          ),
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
    final ammo = unit == null
        ? null
        : weapon.isSignature
        ? (game.sim.canUse(unit, weapon) ? 1 : 0)
        : game.sim.ammoLeft(unit.team, weapon);
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
          _WeaponButton(
            weapon: weapon,
            ammo: ammo == null ? l10n.hudAmmoUnlimited : '$ammo',
            tooltip: l10n.hudWeapons,
            onPressed: () {
              onOpenWeapons();
              showWeaponMenu(context, game);
            },
          ),
          const SizedBox(width: 12),
          _FireButton(
            label: weapon.delivery is Launch || weapon.delivery is Beam
                ? l10n.hudFire
                : l10n.hudUse,
            onPressed: ready ? game.fire : null,
          ),
        ],
      ],
    );
  }
}

class _WeaponButton extends StatelessWidget {
  const _WeaponButton({
    required this.weapon,
    required this.ammo,
    required this.tooltip,
    required this.onPressed,
  });

  final WeaponDef weapon;
  final String ammo;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Semantics(
      button: true,
      label: tooltip,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onPressed,
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

/// Target weapons: Cancel and Confirm instead of the usual buttons.
class _TargetActions extends StatelessWidget {
  const _TargetActions({
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
  });

  final String name;
  final String unitName;
  final Color color;
  final TeamSymbol symbol;

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
              child: Container(
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
                          painter: TeamSymbolPainter(
                            symbol,
                            fill: color,
                            strokeWidth: 2,
                          ),
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
