import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../app/iron_palette.dart';
import '../../config/weapons.dart';
import '../../game/art/weapon_art.dart';
import '../../game/pawtillery_game.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_lookup.g.dart';
import '../../services/audio_service.dart';
import '../widgets/iron/iron_button.dart';
import '../widgets/iron/iron_controls.dart';
import '../widgets/iron/iron_icons.dart';
import '../widgets/iron/iron_panel.dart';
import '../widgets/iron/iron_text.dart';

/// Weapon menu (PRD: Menu senjata): a panel that slides in from the right
/// with a grid of weapon cards — colour art, name, ammo badge. The
/// family's signature weapon sits on a tomato card.
Future<void> showWeaponMenu(BuildContext context, PawtilleryGame game) {
  final l10n = AppLocalizations.of(context);
  final choices = game.weaponChoices();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: l10n.hudWeapons,
    barrierColor: const Color(0x66101820),
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (context, _, _) => SafeArea(
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 6, 8, 6),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 470),
            child: Material(
              type: MaterialType.transparency,
              child: IronPanel(
                style: IronPanelStyle.night,
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 6),
                        const IronIcon(IronGlyph.bag, size: 26, color: IronPalette.brass),
                        const SizedBox(width: 8),
                        Expanded(
                          child: IronText(
                            l10n.hudWeapons.toUpperCase(),
                            size: 22,
                            textAlign: TextAlign.start,
                          ),
                        ),
                        IronRoundButton(
                          glyph: IronGlyph.close,
                          tooltip: l10n.dialogCancel,
                          tone: IronTone.blood,
                          size: 40,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            for (final c in choices)
                              Opacity(
                                opacity: c.usable ? 1 : 0.45,
                                child: IronTile(
                                  width: 102,
                                  selected:
                                      c.weapon.id == game.aim.value.weaponId,
                                  tone: c.weapon.isSignature
                                      ? const IronTone(
                                          Color(0xFF3A1E1A),
                                          Color(0xFF1E100E),
                                        )
                                      : null,
                                  onTap: c.usable
                                      ? () {
                                          AppServices.of(
                                            context,
                                          ).audio.play(Sfx.ui);
                                          game.selectWeapon(c.weapon.id);
                                          Navigator.of(context).pop();
                                        }
                                      : null,
                                  child: Column(
                                    children: [
                                      WeaponIcon(weapon: c.weapon, size: 52),
                                      Text(
                                        l10n.byKey(c.weapon.nameKey),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          height: 1.05,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      if (c.weapon.isSignature)
                                        _Badge(
                                          text: c.usable
                                              ? l10n.hudSignature
                                              : l10n.hudUsed,
                                          tone: IronTone.blood,
                                        )
                                      else
                                        AmmoBadge(ammo: c.ammoLeft),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (context, anim, _, child) => SlideTransition(
      position: Tween(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
      child: child,
    ),
  );
}

/// Ammo as a small badge: "×3", or ∞ when unlimited.
class AmmoBadge extends StatelessWidget {
  const AmmoBadge({super.key, required this.ammo});

  final int? ammo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final n = ammo;
    return _Badge(
      text: n == null ? l10n.hudAmmoUnlimited : l10n.hudAmmoLeft(n),
      tone: n == null ? IronTone.steel : IronTone.brass,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.tone});
  final String text;
  final IronTone tone;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [tone.light, tone.deep],
      ),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: IronPalette.ink, width: 2),
    ),
    child: IronText(text, size: 13, maxLines: 1, drop: 1),
  );
}

/// A weapon's art in colour.
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
