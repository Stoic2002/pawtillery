import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/field_palette.dart';
import '../../config/controls.dart';
import '../../config/weapons.dart';
import '../../game/hud_state.dart';
import '../../game/pawtillery_game.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_lookup.g.dart';
import '../../sim/inputs.dart';
import '../../sim/turn_manager.dart';
import '../widgets/field/ink_icons.dart';
import '../widgets/field/paper.dart';
import '../widgets/field/stamp.dart';
import 'tutorial.dart';
import 'weapon_menu.dart';

/// Arena HUD as field notes taped over the scene (docs/art_style_guide.md):
/// a turn slip, a wind note, an HP tally, paper tokens with ink icons, and
/// the red Fire stamp. Everything sits along the edges so the middle of the
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
                      child: _TurnSlip(
                        hud: hud,
                        teamName: teamNames[hud.activeTeam],
                        teamInk: Color(game.teamColors[hud.activeTeam]),
                        onPause: onPause,
                      ),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: _FieldNotes(hud: hud, teamColors: game.teamColors),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: _TopRight(game: game, seed: seed),
                    ),
                    if (!hud.isOver) ...[
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: _WalkTokens(
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
            // Upper third: the camera centres the active unit, so a centred
            // banner would hide it.
            if (hud.phase == TurnPhase.turnStart)
              Align(
                alignment: const Alignment(0, -0.4),
                child: _TurnBanner(
                  name: teamNames[hud.activeTeam],
                  ink: Color(game.teamColors[hud.activeTeam]),
                ),
              ),
          ],
        );
      },
    );
  }
}

const _ink = TextStyle(color: FieldPalette.ink, fontSize: 15);

// ------------------------------------------------------------------ tokens

/// A round paper token with an ink glyph: the HUD's buttons.
class PaperToken extends StatelessWidget {
  const PaperToken({
    super.key,
    required this.glyph,
    required this.tooltip,
    required this.onPressed,
    this.size = 50,
  });

  final InkGlyph glyph;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: GestureDetector(
          onTap: onPressed,
          child: _TokenFace(
            glyph: glyph,
            size: size,
            pressed: false,
            enabled: enabled,
          ),
        ),
      ),
    );
  }
}

class _TokenFace extends StatelessWidget {
  const _TokenFace({
    required this.glyph,
    required this.size,
    required this.pressed,
    required this.enabled,
  });

  final InkGlyph glyph;
  final double size;
  final bool pressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: pressed ? FieldPalette.ink : FieldPalette.paper,
          shape: BoxShape.circle,
          border: Border.all(color: FieldPalette.ink, width: 1.2),
          boxShadow: const [
            BoxShadow(
                color: Color(0x40000000), blurRadius: 2, offset: Offset(0, 1)),
          ],
        ),
        alignment: Alignment.center,
        child: InkIcon(
          glyph,
          size: size * 0.5,
          color: !enabled
              ? FieldPalette.pencil
              : (pressed ? FieldPalette.paper : FieldPalette.ink),
        ),
      );
}

// -------------------------------------------------------------- top left

class _TurnSlip extends StatelessWidget {
  const _TurnSlip({
    required this.hud,
    required this.teamName,
    required this.teamInk,
    required this.onPause,
  });

  final HudState hud;
  final String teamName;
  final Color teamInk;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final clock = hud.clockSeconds;
    final retreat = hud.phase == TurnPhase.retreat;
    final urgent = clock != null && clock <= 5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PaperToken(glyph: InkGlyph.pause, tooltip: l10n.hudPause, onPressed: onPause),
        const SizedBox(width: 10),
        if (!hud.isOver)
          PaperPanel(
            tilt: -0.6,
            accent: teamInk,
            padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10, color: teamInk),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: Text(teamName.toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      style: _ink.copyWith(letterSpacing: 2)),
                ),
                if (clock != null) ...[
                  const SizedBox(width: 12),
                  InkIcon(InkGlyph.timer,
                      size: 18,
                      color: urgent ? FieldPalette.stamp : FieldPalette.inkSoft),
                  const SizedBox(width: 4),
                  Text(
                    retreat ? l10n.hudRetreat(clock) : l10n.hudSeconds(clock),
                    style: _ink.copyWith(
                      fontSize: 19,
                      color: urgent ? FieldPalette.stamp : FieldPalette.ink,
                      fontStyle: retreat ? FontStyle.italic : null,
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

// ------------------------------------------------------------ top centre

class _FieldNotes extends StatelessWidget {
  const _FieldNotes({required this.hud, required this.teamColors});

  final HudState hud;
  final List<int> teamColors;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PaperPanel(
          tape: true,
          padding: const EdgeInsets.fromLTRB(10, 7, 12, 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const InkIcon(InkGlyph.wind, size: 20),
              const SizedBox(width: 8),
              _WindScale(wind: hud.wind),
              const SizedBox(width: 8),
              Text(l10n.hudWind(hud.wind), style: _ink),
            ],
          ),
        ),
        if (hud.suddenDeath)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: StampMark(
                label: l10n.hudSuddenDeath, fontSize: 12, tilt: -2),
          ),
        const SizedBox(height: 6),
        PaperPanel(
          tilt: 0.4,
          padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var team = 0; team < hud.teamHp.length; team++)
                Padding(
                  padding: EdgeInsets.only(top: team == 0 ? 0 : 4),
                  child: _HpTally(
                    ink: Color(teamColors[team]),
                    hp: hud.teamHp[team],
                    maxHp: hud.teamMaxHp[team],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Wind on an inked scale from −10 to 10, the reading drawn as a pen arrow.
class _WindScale extends StatelessWidget {
  const _WindScale({required this.wind});
  final int wind;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 110,
        height: 16,
        child: CustomPaint(painter: _WindScalePainter(wind)),
      );
}

class _WindScalePainter extends CustomPainter {
  _WindScalePainter(this.wind);
  final int wind;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.width / 2;
    final base = size.height - 3;
    final pen = Paint()
      ..color = FieldPalette.ink
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, base), Offset(size.width, base), pen);
    for (var i = -10; i <= 10; i++) {
      final x = mid + i * (size.width / 2 - 2) / 10;
      final tall = i % 5 == 0;
      canvas.drawLine(Offset(x, base), Offset(x, base - (tall ? 7 : 3.5)),
          pen..strokeWidth = tall ? 1.1 : 0.7);
    }
    if (wind == 0) return;
    final end = mid + wind * (size.width / 2 - 2) / 10;
    final arrow = Paint()
      ..color = FieldPalette.stamp
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final y = base - 9;
    final dir = wind.sign.toDouble();
    canvas
      ..drawLine(Offset(mid, y), Offset(end, y), arrow)
      ..drawLine(Offset(end, y), Offset(end - dir * 4, y - 3.5), arrow)
      ..drawLine(Offset(end, y), Offset(end - dir * 4, y + 3.5), arrow);
  }

  @override
  bool shouldRepaint(_WindScalePainter old) => old.wind != wind;
}

/// A team's HP as a hatched bar in its ink, with the number.
class _HpTally extends StatelessWidget {
  const _HpTally({required this.ink, required this.hp, required this.maxHp});

  final Color ink;
  final int hp;
  final int maxHp;

  @override
  Widget build(BuildContext context) {
    final fraction = maxHp == 0 ? 0.0 : (hp / maxHp).clamp(0.0, 1.0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 9, height: 9, color: ink),
        const SizedBox(width: 6),
        SizedBox(
          width: 120,
          height: 9,
          child: CustomPaint(painter: _HatchBarPainter(ink, fraction)),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 30,
          child: Text('$hp',
              textAlign: TextAlign.right, style: _ink.copyWith(fontSize: 13)),
        ),
      ],
    );
  }
}

class _HatchBarPainter extends CustomPainter {
  _HatchBarPainter(this.ink, this.fraction);
  final Color ink;
  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = Offset.zero & size;
    final filled = Rect.fromLTWH(0, 0, size.width * fraction, size.height);
    canvas
      ..save()
      ..clipRect(filled)
      ..drawRect(filled, Paint()..color = ink.withValues(alpha: 0.85));
    final hatch = Paint()
      ..color = FieldPalette.paper.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (var x = -size.height; x < size.width; x += 4) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), hatch);
    }
    canvas
      ..restore()
      ..drawRect(
          frame,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = FieldPalette.ink);
  }

  @override
  bool shouldRepaint(_HatchBarPainter old) =>
      old.ink != ink || old.fraction != fraction;
}

// -------------------------------------------------------------- top right

class _TopRight extends StatelessWidget {
  const _TopRight({required this.game, required this.seed});

  final PawtilleryGame game;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const debug = TextStyle(fontSize: 11, color: FieldPalette.inkSoft);
    Widget note(String text) => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: PaperPanel(
            frame: PanelFrame.none,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Text(text, style: debug),
          ),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        PaperToken(
          glyph: InkGlyph.focus,
          tooltip: l10n.hudCenterCamera,
          onPressed: game.centerOnActiveUnit,
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
                : note(l10n.debugExplosionTime(
                    t.lastMs.toStringAsFixed(2), t.maxMs.toStringAsFixed(2))),
          ),
        ],
      ],
    );
  }
}

// ------------------------------------------------------------ bottom left

/// Hold-to-walk tokens. Raw pointer events, so walking starts on touch down.
class _WalkTokens extends StatelessWidget {
  const _WalkTokens({
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HoldToken(
          label: l10n.hudWalkLeft,
          glyph: InkGlyph.walkLeft,
          enabled: enabled,
          onHold: (down) {
            if (down) onWalk();
            game.setWalk(down ? -1 : 0);
          },
        ),
        const SizedBox(width: 14),
        _HoldToken(
          label: l10n.hudWalkRight,
          glyph: InkGlyph.walkRight,
          enabled: enabled,
          onHold: (down) {
            if (down) onWalk();
            game.setWalk(down ? 1 : 0);
          },
        ),
      ],
    );
  }
}

class _HoldToken extends StatefulWidget {
  const _HoldToken({
    required this.label,
    required this.glyph,
    required this.enabled,
    required this.onHold,
  });

  final String label;
  final InkGlyph glyph;
  final bool enabled;
  final ValueChanged<bool> onHold;

  @override
  State<_HoldToken> createState() => _HoldTokenState();
}

class _HoldTokenState extends State<_HoldToken> {
  bool _down = false;

  void _set(bool down) {
    if (_down == down) return;
    setState(() => _down = down);
    widget.onHold(down);
  }

  @override
  void didUpdateWidget(_HoldToken old) {
    super.didUpdateWidget(old);
    if (!widget.enabled && _down) _set(false);
  }

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: widget.label,
        child: Listener(
          onPointerDown: widget.enabled ? (_) => _set(true) : null,
          onPointerUp: (_) => _set(false),
          onPointerCancel: (_) => _set(false),
          child: _TokenFace(
            glyph: widget.glyph,
            size: 62,
            pressed: _down,
            enabled: widget.enabled,
          ),
        ),
      );
}

// ----------------------------------------------------------- bottom right

/// Weapon card, jumps, and the controls for the current weapon's aim mode
/// (or a pencilled hint for how to aim it).
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
                    PaperToken(
                      glyph: InkGlyph.jump,
                      tooltip: l10n.hudJump,
                      onPressed: hud.canMove
                          ? () => game.jump(JumpKind.forward)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    PaperToken(
                      glyph: InkGlyph.highJump,
                      tooltip: l10n.hudHighJump,
                      onPressed:
                          hud.canMove ? () => game.jump(JumpKind.high) : null,
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
        child: PaperPanel(
          tilt: 0.7,
          frame: PanelFrame.double,
          padding: const EdgeInsets.fromLTRB(4, 3, 10, 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              WeaponIcon(weapon: weapon, size: 40),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.byKey(weapon.nameKey).toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _ink.copyWith(fontSize: 12, letterSpacing: 1.5)),
                    if (weapon.isSignature)
                      Text(
                        unit != null && game.sim.canUse(unit, weapon)
                            ? l10n.hudSignature
                            : l10n.hudUsed,
                        style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: FieldPalette.stamp),
                      )
                    else
                      AmmoTally(ammo: ammo),
                  ],
                ),
              ),
            ],
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

    // Not ready yet: a pencilled note on how to aim this weapon.
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
              padding: const EdgeInsets.only(bottom: 10),
              child: PaperPanel(
                tilt: -0.8,
                frame: PanelFrame.none,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Text(hint,
                    style: const TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: FieldPalette.inkSoft)),
              ),
            );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        PaperPanel(
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
              InkButton(
                label: l10n.hudCancel,
                minWidth: 92,
                onPressed: game.cancelAim,
              ),
              const SizedBox(height: 8),
            ],
            StampButton(
              label: thrown ? l10n.hudFire : l10n.hudUse,
              round: true,
              fontSize: 18,
              tilt: -4,
              onPressed: game.fire,
            ),
          ],
        ),
      ],
    );
  }
}

/// − value + on one line of the aiming slip.
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
    Widget sign(String text, String tooltip, VoidCallback onTap) => Tooltip(
          message: tooltip,
          child: InkWell(
            onTap: onTap,
            child: SizedBox.square(
              dimension: 46,
              child: Center(
                child: Text(text,
                    style: const TextStyle(fontSize: 26, height: 1)),
              ),
            ),
          ),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        sign('−', l10n.hudDecrease, onMinus),
        SizedBox(
          width: 128,
          child: Text(label,
              textAlign: TextAlign.center, style: _ink.copyWith(fontSize: 16)),
        ),
        sign('+', l10n.hudIncrease, onPlus),
      ],
    );
  }
}

class _TurnBanner extends StatelessWidget {
  const _TurnBanner({required this.name, required this.ink});

  final String name;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IgnorePointer(
      child: PaperPanel(
        tilt: -1,
        tape: true,
        frame: PanelFrame.double,
        accent: ink,
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
        child: Text(
          l10n.turnBanner(name).toUpperCase(),
          style: TextStyle(fontSize: 22, letterSpacing: 4, color: ink),
        ),
      ),
    );
  }
}
