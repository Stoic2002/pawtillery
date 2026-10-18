import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../config/controls.dart';
import '../../config/weapons.dart';
import '../../game/hud_state.dart';
import '../../game/pawtillery_game.dart';
import '../../l10n/app_localizations.dart';
import '../../sim/inputs.dart';
import '../../sim/turn_manager.dart';
import '../../l10n/l10n_lookup.g.dart';
import 'weapon_menu.dart';

/// Arena HUD. Everything sits along the screen edges so the middle of the
/// map stays clear; every tap target is at least 48 × 48 dp.
class ArenaHud extends StatelessWidget {
  const ArenaHud({
    super.key,
    required this.game,
    required this.seed,
    required this.teamNames,
    required this.onPause,
  });

  final PawtilleryGame game;
  final int seed;
  final List<String> teamNames;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<HudState?>(
      valueListenable: game.hud,
      builder: (context, hud, _) {
        if (hud == null) return const SizedBox.shrink();
        return Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: _TopLeft(
                        hud: hud,
                        teamName: teamNames[hud.activeTeam],
                        teamColor: Color(game.teamColors[hud.activeTeam]),
                        onPause: onPause,
                      ),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: _TopCenter(hud: hud, teamColors: game.teamColors),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: _TopRight(game: game, seed: seed),
                    ),
                    if (!hud.isOver) ...[
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: _WalkButtons(game: game, enabled: hud.canMove),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: _ActionCluster(game: game, hud: hud),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Upper third: the camera centres the active unit, so a centred
            // banner would hide it.
            if (hud.phase == TurnPhase.turnStart)
              Align(
                alignment: const Alignment(0, -0.4),
                child: _TurnBanner(
                  name: teamNames[hud.activeTeam],
                  color: Color(game.teamColors[hud.activeTeam]),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TopLeft extends StatelessWidget {
  const _TopLeft({
    required this.hud,
    required this.teamName,
    required this.teamColor,
    required this.onPause,
  });

  final HudState hud;
  final String teamName;
  final Color teamColor;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final clock = hud.clockSeconds;
    final clockText = clock == null
        ? null
        : (hud.phase == TurnPhase.retreat
            ? l10n.hudRetreat(clock)
            : l10n.hudSeconds(clock));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          tooltip: l10n.hudPause,
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          onPressed: onPause,
          icon: const Icon(Icons.pause),
        ),
        const SizedBox(width: 8),
        if (!hud.isOver)
          _Chip(
            border: teamColor,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(teamName,
                      style: _chipText, overflow: TextOverflow.ellipsis),
                ),
                if (clockText != null) ...[
                  const SizedBox(width: 10),
                  Text(
                    clockText,
                    style: _chipText.copyWith(
                      color: clock! <= 5 ? Colors.orangeAccent : Colors.white,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _TopCenter extends StatelessWidget {
  const _TopCenter({required this.hud, required this.teamColors});

  final HudState hud;
  final List<int> teamColors;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final wind = hud.wind;
    final icon = wind == 0
        ? Icons.remove
        : (wind > 0 ? Icons.arrow_forward : Icons.arrow_back);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Chip(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 6),
              Text(l10n.hudWind(wind), style: _chipText),
            ],
          ),
        ),
        if (hud.suddenDeath) ...[
          const SizedBox(height: 4),
          _Chip(
            border: Colors.lightBlueAccent,
            child: Text(l10n.hudSuddenDeath, style: _chipText),
          ),
        ],
        const SizedBox(height: 4),
        for (var team = 0; team < hud.teamHp.length; team++)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: _TeamHpBar(
              color: Color(teamColors[team]),
              hp: hud.teamHp[team],
              maxHp: hud.teamMaxHp[team],
            ),
          ),
      ],
    );
  }
}

class _TeamHpBar extends StatelessWidget {
  const _TeamHpBar({
    required this.color,
    required this.hp,
    required this.maxHp,
  });

  final Color color;
  final int hp;
  final int maxHp;

  static const double _width = 120;

  @override
  Widget build(BuildContext context) {
    final fraction = maxHp == 0 ? 0.0 : (hp / maxHp).clamp(0.0, 1.0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: _width,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0x66000000),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: fraction,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 30,
          child: Text('$hp',
              style: _chipText.copyWith(
                  fontSize: 12,
                  shadows: const [Shadow(blurRadius: 3)])),
        ),
      ],
    );
  }
}

class _TopRight extends StatelessWidget {
  const _TopRight({required this.game, required this.seed});

  final PawtilleryGame game;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        IconButton.filledTonal(
          tooltip: l10n.hudCenterCamera,
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          onPressed: game.centerOnActiveUnit,
          icon: const Icon(Icons.center_focus_strong),
        ),
        if (kDebugMode || kProfileMode) ...[
          const SizedBox(height: 4),
          _Chip(child: Text(l10n.debugSeed(seed), style: _debugText)),
          ValueListenableBuilder<ExplosionTiming?>(
            valueListenable: game.explosionTiming,
            builder: (context, t, _) => t == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _Chip(
                      child: Text(
                        l10n.debugExplosionTime(
                          t.lastMs.toStringAsFixed(2),
                          t.maxMs.toStringAsFixed(2),
                        ),
                        style: _debugText,
                      ),
                    ),
                  ),
          ),
        ],
      ],
    );
  }
}

/// Hold-to-walk buttons. Uses raw pointer events so walking starts on touch
/// down, with no tap delay.
class _WalkButtons extends StatelessWidget {
  const _WalkButtons({required this.game, required this.enabled});

  final PawtilleryGame game;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HoldButton(
          label: l10n.hudWalkLeft,
          icon: Icons.arrow_left,
          enabled: enabled,
          onHold: (down) => game.setWalk(down ? -1 : 0),
        ),
        const SizedBox(width: 12),
        _HoldButton(
          label: l10n.hudWalkRight,
          icon: Icons.arrow_right,
          enabled: enabled,
          onHold: (down) => game.setWalk(down ? 1 : 0),
        ),
      ],
    );
  }
}

class _HoldButton extends StatefulWidget {
  const _HoldButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onHold,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final ValueChanged<bool> onHold;

  @override
  State<_HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<_HoldButton> {
  bool _down = false;

  void _set(bool down) {
    if (_down == down) return;
    setState(() => _down = down);
    widget.onHold(down);
  }

  @override
  void didUpdateWidget(_HoldButton old) {
    super.didUpdateWidget(old);
    if (!widget.enabled && _down) _set(false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: widget.label,
      child: Listener(
        onPointerDown: widget.enabled ? (_) => _set(true) : null,
        onPointerUp: (_) => _set(false),
        onPointerCancel: (_) => _set(false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: !widget.enabled
                ? scheme.surfaceContainerHighest.withValues(alpha: 0.4)
                : (_down ? scheme.primary : scheme.secondaryContainer),
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.icon,
            size: 40,
            color: _down ? scheme.onPrimary : scheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}

/// Bottom-right: weapon button, jumps, and the controls for the current
/// weapon's aim mode (or a hint for how to aim it).
class _ActionCluster extends StatelessWidget {
  const _ActionCluster({required this.game, required this.hud});

  final PawtilleryGame game;
  final HudState hud;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AimState>(
      valueListenable: game.aim,
      builder: (context, aim, _) {
        final canAim = hud.phase == TurnPhase.action && game.canAim;
        final weapon = Weapons.byId(aim.weaponId);
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (canAim) _AimControls(game: game, aim: aim, weapon: weapon),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _WeaponButton(game: game, weapon: weapon, enabled: canAim),
                const SizedBox(height: 8),
                _JumpButtons(game: game, enabled: hud.canMove),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _JumpButtons extends StatelessWidget {
  const _JumpButtons({required this.game, required this.enabled});

  final PawtilleryGame game;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          tooltip: l10n.hudJump,
          constraints: const BoxConstraints.tightFor(width: 52, height: 52),
          onPressed: enabled ? () => game.jump(JumpKind.forward) : null,
          icon: const Icon(Icons.trending_up),
        ),
        const SizedBox(width: 6),
        IconButton.filledTonal(
          tooltip: l10n.hudHighJump,
          constraints: const BoxConstraints.tightFor(width: 52, height: 52),
          onPressed: enabled ? () => game.jump(JumpKind.high) : null,
          icon: const Icon(Icons.keyboard_double_arrow_up),
        ),
      ],
    );
  }
}

class _WeaponButton extends StatelessWidget {
  const _WeaponButton({
    required this.game,
    required this.weapon,
    required this.enabled,
  });

  final PawtilleryGame game;
  final WeaponDef weapon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unit = game.sim.activeUnit;
    final ammo = unit == null ? null : game.sim.ammoLeft(unit.team, weapon);
    return Tooltip(
      message: l10n.hudWeapons,
      child: Material(
        color: const Color(0x99000000),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled ? () => showWeaponMenu(context, game) : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                WeaponIcon(weapon: weapon, size: 40),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 110),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.byKey(weapon.nameKey),
                        style: _chipText.copyWith(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        weapon.isSignature
                            ? (unit != null && game.sim.canUse(unit, weapon)
                                ? l10n.hudSignature
                                : l10n.hudUsed)
                            : (ammo == null
                                ? l10n.hudAmmoUnlimited
                                : l10n.hudAmmoLeft(ammo)),
                        style: _debugText,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AimControls extends StatelessWidget {
  const _AimControls({
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
    final mode = weapon.aim;
    final thrown = weapon.delivery is Launch;

    // Not ready yet: tell the player how to aim this weapon.
    if (!aim.active) {
      final hint = switch (mode) {
        AimMode.angleAndPower => l10n.hudAimHint,
        AimMode.direction => l10n.hudDirectionHint,
        AimMode.target =>
          aim.hasTarget ? l10n.hudInvalidTarget : l10n.hudTapTarget,
        AimMode.none => null,
      };
      return hint == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _Chip(child: Text(hint, style: _chipText)),
            );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (weapon.playerFuse) ...[
              _FuseSelector(game: game, seconds: aim.fuseSeconds),
              const SizedBox(height: 4),
            ],
            if (mode == AimMode.angleAndPower ||
                mode == AimMode.direction)
              _Stepper(
                label: l10n.hudAngle(aim.angle),
                onMinus: () => game.adjustAngle(-ControlsConfig.angleStep),
                onPlus: () => game.adjustAngle(ControlsConfig.angleStep),
              ),
            if (mode == AimMode.angleAndPower) ...[
              const SizedBox(height: 4),
              _Stepper(
                label: l10n.hudPower(aim.power),
                onMinus: () => game.adjustPower(-ControlsConfig.powerStep),
                onPlus: () => game.adjustPower(ControlsConfig.powerStep),
              ),
            ],
          ],
        ),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (mode != AimMode.none) ...[
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(88, 48),
                  backgroundColor: const Color(0x99000000),
                  foregroundColor: Colors.white,
                ),
                onPressed: game.cancelAim,
                child: Text(l10n.hudCancel),
              ),
              const SizedBox(height: 6),
            ],
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(88, 88),
                shape: const CircleBorder(),
                backgroundColor: Colors.deepOrange,
              ),
              onPressed: game.fire,
              child: Text(
                thrown ? l10n.hudFire : l10n.hudUse,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FuseSelector extends StatelessWidget {
  const _FuseSelector({required this.game, required this.seconds});

  final PawtilleryGame game;
  final int seconds;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _Stepper(
      label: l10n.hudFuse(seconds),
      onMinus: () => game.setFuse(seconds - 1),
      onPlus: () => game.setFuse(seconds + 1),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          tooltip: l10n.hudDecrease,
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          onPressed: onMinus,
          icon: const Icon(Icons.remove),
        ),
        // Wide enough for the longer Indonesian label ("Kekuatan 100%").
        SizedBox(
          width: 132,
          child: _Chip(
            child: Text(label, style: _chipText, textAlign: TextAlign.center),
          ),
        ),
        IconButton.filledTonal(
          tooltip: l10n.hudIncrease,
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          onPressed: onPlus,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

class _TurnBanner extends StatelessWidget {
  const _TurnBanner({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xCC000000),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 4),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          child: Text(
            l10n.turnBanner(name),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.child, this.border});

  final Widget child;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x99000000),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        border: border == null ? null : Border.all(color: border!, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: child,
      ),
    );
  }
}

const _chipText = TextStyle(color: Colors.white, fontWeight: FontWeight.w600);
const _debugText = TextStyle(color: Colors.white70, fontSize: 11);
