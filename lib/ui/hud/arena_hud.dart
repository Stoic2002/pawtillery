import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/iron_palette.dart';
import '../../config/controls.dart';
import '../../config/weapons.dart';
import '../../game/hud_state.dart';
import '../../game/pawtillery_game.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_lookup.g.dart';
import '../../sim/inputs.dart';
import '../../sim/turn_manager.dart';
import '../widgets/iron/iron_button.dart';
import '../widgets/iron/iron_icons.dart';
import '../widgets/iron/iron_panel.dart';
import '../widgets/iron/iron_text.dart';
import 'tutorial.dart';
import 'weapon_menu.dart';

/// Arena HUD (docs/art_style_guide.md): chunky badges in the corners —
/// timer in the active team's colour, wind meter and team HP on night
/// panels, round icon buttons, and a big Fire button. The middle of the
/// map stays clear; every tap target is at least 48 × 48 dp.
class ArenaHud extends StatelessWidget {
  const ArenaHud({
    super.key,
    required this.game,
    required this.seed,
    required this.teamNames,
    required this.onPause,
    this.tutorial,
  });

  final PawtilleryGame game;
  final int seed;
  final List<String> teamNames;
  final VoidCallback onPause;

  /// First-match tutorial, if it should show.
  final TutorialController? tutorial;

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
                      child: _TurnBadge(
                        hud: hud,
                        teamName: teamNames[hud.activeTeam],
                        teamColor: Color(game.teamColors[hud.activeTeam]),
                        onPause: onPause,
                      ),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: _TopCentre(hud: hud, teamColors: game.teamColors),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: _TopRight(game: game, seed: seed),
                    ),
                    if (!hud.isOver) ...[
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: _WalkButtons(
                          game: game,
                          enabled: hud.canMove,
                          onWalk: () => tutorial?.complete(TutorialStep.walk),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: _ActionCluster(
                          game: game,
                          hud: hud,
                          onOpenWeapons: () =>
                              tutorial?.complete(TutorialStep.weapons),
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
            // Below the middle: the camera centres the active unit, so a
            // centred banner would hide it, and the top holds the HUD.
            if (hud.phase == TurnPhase.turnStart)
              Align(
                alignment: const Alignment(0, 0.45),
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

// -------------------------------------------------------------- top left

/// Pause button, then the turn badge: team name over a big clock in the
/// team's colour. The last five seconds turn tomato and pop each second.
class _TurnBadge extends StatelessWidget {
  const _TurnBadge({
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
    final retreat = hud.phase == TurnPhase.retreat;
    final urgent = clock != null && clock <= 5;
    final tone = urgent ? IronTone.blood : IronTone.of(teamColor);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IronRoundButton(
          glyph: IronGlyph.pause,
          tooltip: l10n.hudPause,
          onPressed: onPause,
          size: 50,
        ),
        const SizedBox(width: 8),
        if (!hud.isOver)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IronPanel(
                style: IronPanelStyle.night,
                radius: 10,
                padding: const EdgeInsets.fromLTRB(10, 3, 10, 4),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: IronText(
                    teamName,
                    size: 15,
                    color: Color.lerp(teamColor, Colors.white, 0.25)!,
                    maxLines: 1,
                    drop: 1,
                  ),
                ),
              ),
              if (clock != null) ...[
                const SizedBox(height: 4),
                TweenAnimationBuilder<double>(
                  key: ValueKey(urgent ? clock : -1),
                  tween: Tween(begin: urgent ? 1.25 : 1, end: 1),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: CustomPaint(
                    painter: IronSlabPainter(tone: tone, radius: 14, depth: 4),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 2, 14, 7),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const IronIcon(IronGlyph.timer, size: 22),
                          const SizedBox(width: 6),
                          IronText(
                            retreat
                                ? l10n.hudRetreat(clock)
                                : l10n.hudSeconds(clock),
                            size: retreat ? 20 : 28,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

// ------------------------------------------------------------ top centre

class _TopCentre extends StatelessWidget {
  const _TopCentre({required this.hud, required this.teamColors});

  final HudState hud;
  final List<int> teamColors;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: l10n.hudWind(hud.wind),
          child: IronPanel(
            style: IronPanelStyle.night,
            radius: 14,
            padding: const EdgeInsets.fromLTRB(10, 5, 12, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const IronIcon(
                  IronGlyph.wind,
                  size: 24,
                  color: IronPalette.steel,
                ),
                const SizedBox(width: 8),
                _WindMeter(wind: hud.wind),
                const SizedBox(width: 8),
                SizedBox(
                  width: 26,
                  child: IronText('${hud.wind.abs()}', size: 18, drop: 1),
                ),
              ],
            ),
          ),
        ),
        if (hud.suddenDeath)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: CustomPaint(
              painter: IronSlabPainter(
                tone: IronTone.blood,
                radius: 10,
                depth: 3,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
                child: IronText(
                  l10n.hudSuddenDeath.toUpperCase(),
                  size: 14,
                  drop: 1,
                ),
              ),
            ),
          ),
        const SizedBox(height: 6),
        IronPanel(
          style: IronPanelStyle.night,
          radius: 12,
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var team = 0; team < hud.teamHp.length; team++)
                Padding(
                  padding: EdgeInsets.only(top: team == 0 ? 0 : 4),
                  child: _HpBar(
                    color: Color(teamColors[team]),
                    hp: hud.teamHp[team],
                    maxHp: hud.teamMaxHp[team],
                    active: team == hud.activeTeam,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Wind from −10 to 10: a pill track with a centre notch, filled from the
/// middle towards where the wind blows, with an arrow head.
class _WindMeter extends StatelessWidget {
  const _WindMeter({required this.wind});
  final int wind;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 130,
    height: 18,
    child: CustomPaint(painter: _WindMeterPainter(wind)),
  );
}

class _WindMeterPainter extends CustomPainter {
  _WindMeterPainter(this.wind);
  final int wind;

  @override
  void paint(Canvas canvas, Size size) {
    final track = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(1.5),
      Radius.circular(size.height / 2),
    );
    canvas.drawRRect(track, Paint()..color = const Color(0xFF0B1118));
    final mid = size.width / 2;
    if (wind != 0) {
      final end = mid + wind / 10 * (size.width / 2 - 3);
      final strong = wind.abs() >= 7;
      final fill = Rect.fromLTRB(
        wind < 0 ? end : mid,
        4,
        wind < 0 ? mid : end,
        size.height - 4,
      );
      canvas
        ..save()
        ..clipRRect(track)
        ..drawRect(
          fill,
          Paint()
            ..shader = LinearGradient(
              begin: wind < 0 ? Alignment.centerRight : Alignment.centerLeft,
              end: wind < 0 ? Alignment.centerLeft : Alignment.centerRight,
              colors: strong
                  ? const [IronPalette.brass, IronPalette.blood]
                  : const [IronPalette.steel, Color(0xFFB8F0FF)],
            ).createShader(fill),
        )
        ..restore();
      // Arrow head at the tip.
      final d = wind.sign.toDouble();
      final head = Path()
        ..moveTo(end + d * 6, size.height / 2)
        ..lineTo(end - d * 2, 1)
        ..lineTo(end - d * 2, size.height - 1)
        ..close();
      canvas
        ..drawPath(head, Paint()..color = IronPalette.parchment)
        ..drawPath(
          head,
          Paint()
            ..color = IronPalette.ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
    }
    canvas
      ..drawLine(
        Offset(mid, 2),
        Offset(mid, size.height - 2),
        Paint()
          ..color = const Color(0x88FFFFFF)
          ..strokeWidth = 2,
      )
      ..drawRRect(
        track,
        Paint()
          ..color = const Color(0x55FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
  }

  @override
  bool shouldRepaint(_WindMeterPainter old) => old.wind != wind;
}

/// A team's HP: a glossy bar in the team colour with the number.
class _HpBar extends StatelessWidget {
  const _HpBar({
    required this.color,
    required this.hp,
    required this.maxHp,
    required this.active,
  });

  final Color color;
  final int hp;
  final int maxHp;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final fraction = maxHp == 0 ? 0.0 : (hp / maxHp).clamp(0.0, 1.0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 140,
          height: 8,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: fraction),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            builder: (context, f, _) =>
                CustomPaint(painter: _HpBarPainter(color, f, active)),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 34,
          child: IronText(
            '$hp',
            size: 14,
            textAlign: TextAlign.right,
            drop: 1,
            color: Color.lerp(color, Colors.white, 0.3)!,
          ),
        ),
      ],
    );
  }
}

class _HpBarPainter extends CustomPainter {
  _HpBarPainter(this.color, this.fraction, this.active);
  final Color color;
  final double fraction;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final track = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(1),
      Radius.circular(size.height / 2),
    );
    canvas
      ..drawRRect(track, Paint()..color = const Color(0xFF0B1118))
      ..save()
      ..clipRRect(track);
    final fill = Rect.fromLTWH(0, 0, size.width * fraction, size.height);
    canvas
      ..drawRect(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.lerp(color, Colors.white, 0.3)!, color],
          ).createShader(fill),
      )
      ..drawRect(
        Rect.fromLTWH(
          3,
          2.5,
          (size.width * fraction - 6).clamp(0, size.width),
          3,
        ),
        Paint()..color = const Color(0x66FFFFFF),
      )
      ..restore()
      ..drawRRect(
        track,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = active ? 2.2 : 1.4
          ..color = active ? IronPalette.parchment : const Color(0x66FFFFFF),
      );
  }

  @override
  bool shouldRepaint(_HpBarPainter old) =>
      old.color != color || old.fraction != fraction || old.active != active;
}

// -------------------------------------------------------------- top right

class _TopRight extends StatelessWidget {
  const _TopRight({required this.game, required this.seed});

  final PawtilleryGame game;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget note(String text) => Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: IronPalette.night,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: IronPalette.parchment),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        IronRoundButton(
          glyph: IronGlyph.focus,
          tooltip: l10n.hudCenterCamera,
          onPressed: game.centerOnActiveUnit,
          size: 50,
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

/// Hold-to-walk buttons; walking starts on touch down.
class _WalkButtons extends StatelessWidget {
  const _WalkButtons({
    required this.game,
    required this.enabled,
    required this.onWalk,
  });

  final PawtilleryGame game;
  final bool enabled;
  final VoidCallback onWalk;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget walk(String label, IronGlyph glyph, int dir) => IronRoundButton(
      glyph: glyph,
      tooltip: label,
      enabled: enabled,
      size: 64,
      onHold: (down) {
        if (down) onWalk();
        game.setWalk(down ? dir : 0);
      },
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        walk(l10n.hudWalkLeft, IronGlyph.walkLeft, -1),
        const SizedBox(width: 12),
        walk(l10n.hudWalkRight, IronGlyph.walkRight, 1),
      ],
    );
  }
}

// ----------------------------------------------------------- bottom right

/// Weapon card, jumps, and the controls for the current weapon's aim mode
/// (or a hint for how to aim it).
class _ActionCluster extends StatelessWidget {
  const _ActionCluster({
    required this.game,
    required this.hud,
    required this.onOpenWeapons,
  });

  final PawtilleryGame game;
  final HudState hud;
  final VoidCallback onOpenWeapons;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _WeaponCard(
                  game: game,
                  weapon: weapon,
                  enabled: canAim,
                  onOpen: onOpenWeapons,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IronRoundButton(
                      glyph: IronGlyph.jump,
                      tooltip: l10n.hudJump,
                      enabled: hud.canMove,
                      onPressed: () => game.jump(JumpKind.forward),
                    ),
                    const SizedBox(width: 8),
                    IronRoundButton(
                      glyph: IronGlyph.highJump,
                      tooltip: l10n.hudHighJump,
                      enabled: hud.canMove,
                      onPressed: () => game.jump(JumpKind.high),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _WeaponCard extends StatelessWidget {
  const _WeaponCard({
    required this.game,
    required this.weapon,
    required this.enabled,
    required this.onOpen,
  });

  final PawtilleryGame game;
  final WeaponDef weapon;
  final bool enabled;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unit = game.sim.activeUnit;
    final ammo = unit == null ? null : game.sim.ammoLeft(unit.team, weapon);
    return Tooltip(
      message: l10n.hudWeapons,
      child: GestureDetector(
        onTap: enabled
            ? () {
                onOpen();
                showWeaponMenu(context, game);
              }
            : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.7,
          child: IronPanel(
            style: IronPanelStyle.night,
            radius: 14,
            padding: const EdgeInsets.fromLTRB(4, 3, 10, 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                WeaponIcon(weapon: weapon, size: 44),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 124),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IronText(
                        l10n.byKey(weapon.nameKey),
                        size: 15,
                        maxLines: 1,
                        textAlign: TextAlign.start,
                        drop: 1,
                      ),
                      const SizedBox(height: 2),
                      if (weapon.isSignature)
                        IronText(
                          unit != null && game.sim.canUse(unit, weapon)
                              ? l10n.hudSignature
                              : l10n.hudUsed,
                          size: 13,
                          color: IronPalette.blood,
                          drop: 1,
                        )
                      else
                        AmmoBadge(ammo: ammo),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const IronIcon(IronGlyph.bag, size: 22, color: IronPalette.brass),
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

    // Not ready yet: a hint on how to aim this weapon.
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
              padding: const EdgeInsets.only(bottom: 12),
              child: IronPanel(
                style: IronPanelStyle.night,
                radius: 14,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Text(
                  hint,
                  style: const TextStyle(
                    fontSize: 16,
                    color: IronPalette.parchment,
                  ),
                ),
              ),
            );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        IronPanel(
          style: IronPanelStyle.night,
          radius: 14,
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (weapon.playerFuse)
                _Stepper(
                  label: l10n.hudFuse(aim.fuseSeconds),
                  onMinus: () => game.setFuse(aim.fuseSeconds - 1),
                  onPlus: () => game.setFuse(aim.fuseSeconds + 1),
                ),
              if (mode == AimMode.angleAndPower || mode == AimMode.direction)
                _Stepper(
                  label: l10n.hudAngle(aim.angle),
                  onMinus: () => game.adjustAngle(-ControlsConfig.angleStep),
                  onPlus: () => game.adjustAngle(ControlsConfig.angleStep),
                ),
              if (mode == AimMode.angleAndPower)
                _Stepper(
                  label: l10n.hudPower(aim.power),
                  onMinus: () => game.adjustPower(-ControlsConfig.powerStep),
                  onPlus: () => game.adjustPower(ControlsConfig.powerStep),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (mode != AimMode.none) ...[
              IronRoundButton(
                glyph: IronGlyph.close,
                tooltip: l10n.hudCancel,
                tone: IronTone.steel,
                size: 48,
                onPressed: game.cancelAim,
              ),
              const SizedBox(height: 8),
            ],
            _FireButton(
              label: thrown ? l10n.hudFire : l10n.hudUse,
              onPressed: game.fire,
            ),
          ],
        ),
      ],
    );
  }
}

/// The big round Fire button: tomato slab, white outlined label.
class _FireButton extends StatefulWidget {
  const _FireButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_FireButton> createState() => _FireButtonState();
}

class _FireButtonState extends State<_FireButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    const size = 84.0;
    const depth = 6.0;
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) {
          setState(() => _down = false);
          widget.onPressed();
        },
        child: CustomPaint(
          painter: IronSlabPainter(
            tone: IronTone.blood,
            circle: true,
            depth: depth,
            pressed: _down,
            outlineWidth: 3.5,
          ),
          child: SizedBox(
            width: size,
            height: size + depth,
            child: Padding(
              padding: EdgeInsets.only(
                top: _down ? depth - 1 : 0,
                bottom: _down ? 1 : depth,
              ),
              child: Center(
                child: IronText(
                  widget.label.toUpperCase(),
                  size: 20,
                  maxLines: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// − value + on one line of the aim panel.
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IronRoundButton(
            glyph: IronGlyph.minus,
            tooltip: l10n.hudDecrease,
            tone: IronTone.steel,
            size: 42,
            onPressed: onMinus,
          ),
          SizedBox(
            width: 120,
            child: IronText(label, size: 16, drop: 1),
          ),
          IronRoundButton(
            glyph: IronGlyph.plus,
            tooltip: l10n.hudIncrease,
            tone: IronTone.steel,
            size: 42,
            onPressed: onPlus,
          ),
        ],
      ),
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
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.6, end: 1),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutBack,
        builder: (context, s, child) =>
            Transform.scale(scale: s, child: child),
        child: IronRibbon(
          l10n.turnBanner(name).toUpperCase(),
          tone: IronTone.of(color),
          fontSize: 30,
        ),
      ),
    );
  }
}
