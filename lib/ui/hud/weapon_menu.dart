import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../app/paw_palette.dart';
import '../../config/families.dart';
import '../../config/weapons.dart';
import '../../game/art/weapon_art.dart';
import '../../game/hud_state.dart';
import '../../game/pawtillery_game.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_lookup.g.dart';
import '../../services/audio_service.dart';
import '../widgets/paw/paw_widgets.dart';

/// Weapon menu (PRD: Menu senjata; redesign prototype): a cream panel over
/// the right of the arena with tabs per [WeaponGroup] (opening on the
/// held weapon's), a 3-column grid of weapon tiles (picture, name, ammo
/// badge, a star on the family's signature weapon), and a footer that
/// explains the selected weapon or sets its fuse.
Future<void> showWeaponMenu(BuildContext context, PawtilleryGame game) {
  final l10n = AppLocalizations.of(context);
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: l10n.hudWeapons,
    barrierColor: Paw.scrim,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, _, _) => SafeArea(
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 24, 16),
          child: FractionallySizedBox(
            widthFactor: 0.6,
            child: Material(
              type: MaterialType.transparency,
              child: _WeaponPanel(game: game),
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (context, anim, _, child) => SlideTransition(
      position: Tween(
        begin: const Offset(0.3, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
      child: FadeTransition(opacity: anim, child: child),
    ),
  );
}

class _WeaponPanel extends StatefulWidget {
  const _WeaponPanel({required this.game});
  final PawtilleryGame game;

  @override
  State<_WeaponPanel> createState() => _WeaponPanelState();
}

class _WeaponPanelState extends State<_WeaponPanel> {
  PawtilleryGame get game => widget.game;

  late WeaponGroup _group = Weapons.groupOf(game.weapon);

  static String _groupLabel(AppLocalizations l10n, WeaponGroup g) =>
      switch (g) {
        WeaponGroup.thrown => l10n.weaponGroupThrown,
        WeaponGroup.sky => l10n.weaponGroupSky,
        WeaponGroup.effects => l10n.weaponGroupEffects,
        WeaponGroup.close => l10n.weaponGroupClose,
        WeaponGroup.tools => l10n.weaponGroupTools,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unit = game.sim.activeUnit;
    final unitName = unit == null || unit.id >= game.unitNames.length
        ? ''
        : game.unitNames[unit.id];
    final familyId = unit?.familyId;
    final familyName = familyId == null
        ? ''
        : l10n.byKey(Families.byId(familyId).nameKey);
    return ValueListenableBuilder<AimState>(
      valueListenable: game.aim,
      builder: (context, aim, _) {
        final current = Weapons.byId(aim.weaponId);
        final all = game.weaponChoices();
        final groups = [
          for (final g in WeaponGroup.values)
            if (all.any((c) => Weapons.groupOf(c.weapon) == g)) g,
        ];
        final group = groups.contains(_group) || groups.isEmpty
            ? _group
            : groups.first;
        final choices = [
          for (final c in all)
            if (Weapons.groupOf(c.weapon) == group) c,
        ];
        return PawCard(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: l10n.hudWeapons, style: Paw.title(20)),
                          TextSpan(
                            text: '  · $unitName ($familyName)',
                            style: Paw.text(12, weight: 700, color: Paw.muted),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PawCircleButton(
                    icon: Icons.close_rounded,
                    tooltip: l10n.dialogClose,
                    size: 44,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (groups.length > 1)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: PawPillToggle<WeaponGroup>(
                    values: groups,
                    selected: group,
                    label: (g) => _groupLabel(l10n, g),
                    onSelect: (g) {
                      AppServices.of(context).audio.play(Sfx.ui);
                      setState(() => _group = g);
                    },
                  ),
                ),
              const SizedBox(height: 4),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    const cols = 3;
                    final rows = (choices.length / cols).ceil();
                    final tileW = (box.maxWidth - (cols - 1) * 10) / cols;
                    final fit = (box.maxHeight - 6 - (rows - 1) * 10) / rows;
                    // Too many to fit: let part of the next row peek out,
                    // so it is clear the grid scrolls.
                    final tileH = fit >= 48
                        ? fit.clamp(48.0, 70.0)
                        : ((box.maxHeight - 6 - 3 * 10) / 3.45).clamp(
                            40.0,
                            70.0,
                          );
                    return SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 8),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 12,
                        children: [
                          for (final c in choices)
                            SizedBox(
                              width: tileW,
                              height: tileH,
                              child: _WeaponTile(
                                choice: c,
                                selected: c.weapon.id == current.id,
                                onTap: c.usable
                                    ? () {
                                        AppServices.of(
                                          context,
                                        ).audio.play(Sfx.ui);
                                        game.selectWeapon(c.weapon.id);
                                        if (!c.weapon.playerFuse) {
                                          Navigator.of(context).pop();
                                        }
                                      }
                                    : null,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
                decoration: BoxDecoration(
                  color: Paw.peach,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Paw.ink, width: 2),
                ),
                child: current.playerFuse
                    ? Row(
                        children: [
                          Expanded(
                            child: Text(l10n.hudFuseLabel, style: Paw.text(14)),
                          ),
                          for (
                            var s = FuseConfig.minSeconds;
                            s <= FuseConfig.maxSeconds;
                            s++
                          )
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: _FuseBox(
                                seconds: s,
                                selected: aim.fuseSeconds == s,
                                onTap: () => game.setFuse(s),
                              ),
                            ),
                        ],
                      )
                    : Row(
                        children: [
                          WeaponIcon(weapon: current, size: 30),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: l10n.byKey(current.nameKey),
                                    style: Paw.text(13),
                                  ),
                                  TextSpan(
                                    text:
                                        ' · ${l10n.byKey('${current.nameKey}Desc')}',
                                    style: Paw.text(13, weight: 600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WeaponTile extends StatelessWidget {
  const _WeaponTile({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final WeaponChoice choice;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final w = choice.weapon;
    final empty = !choice.usable;
    final ammo = w.isSignature
        ? (choice.usable ? '1' : '0')
        : choice.ammoLeft == null
        ? l10n.hudAmmoUnlimited
        : '${choice.ammoLeft}';
    return Semantics(
      button: true,
      selected: selected,
      enabled: !empty,
      label: l10n.byKey(w.nameKey),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: empty
                    ? Paw.line
                    : selected
                    ? Paw.orange
                    : w.isSignature
                    ? Paw.peach
                    : Paw.cream,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Paw.ink, width: selected ? 3 : 2),
                boxShadow: Paw.drop(3),
              ),
              child: Row(
                children: [
                  Opacity(
                    opacity: empty ? 0.5 : 1,
                    child: WeaponIcon(weapon: w, size: 34),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.byKey(w.nameKey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Paw.text(
                        13,
                        color: empty ? Paw.muted : Paw.ink,
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: -8,
              right: -6,
              child: Container(
                constraints: const BoxConstraints(minWidth: 24),
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: empty ? Paw.line : Paw.cream,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Paw.ink, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(ammo, style: Paw.title(13, weight: 800, height: 1)),
              ),
            ),
            if (w.isSignature)
              const Positioned(
                top: -10,
                left: -7,
                child: Icon(
                  Icons.star_rounded,
                  size: 24,
                  color: Paw.yellow,
                  shadows: [
                    Shadow(color: Paw.ink, offset: Offset(1, 1)),
                    Shadow(color: Paw.ink, offset: Offset(-1, -1)),
                    Shadow(color: Paw.ink, offset: Offset(1, -1)),
                    Shadow(color: Paw.ink, offset: Offset(-1, 1)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FuseBox extends StatelessWidget {
  const _FuseBox({
    required this.seconds,
    required this.selected,
    required this.onTap,
  });

  final int seconds;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: selected ? Paw.orange : Paw.cream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Paw.ink, width: 2),
          boxShadow: Paw.drop(3),
        ),
        alignment: Alignment.center,
        child: Text('$seconds', style: Paw.title(18, weight: 800)),
      ),
    ),
  );
}

/// A weapon's picture in colour (painted or code-drawn, see
/// lib/game/art/weapon_art.dart).
class WeaponIcon extends StatelessWidget {
  const WeaponIcon({super.key, required this.weapon, required this.size});

  final WeaponDef weapon;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _IconPainter(weapon.id)),
  );
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.id);
  final String id;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2);
    WeaponArt.icon(canvas, id, size.shortestSide * 0.86);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IconPainter old) => old.id != id;
}
