import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../config/weapons.dart';
import '../../game/art/weapon_art.dart';
import '../../game/pawtillery_game.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_lookup.g.dart';
import '../../services/audio_service.dart';

/// Weapon grid (PRD: Menu senjata): every shared weapon plus the active
/// unit's signature weapon, with remaining ammo; signature marked.
Future<void> showWeaponMenu(BuildContext context, PawtilleryGame game) {
  final l10n = AppLocalizations.of(context);
  final choices = game.weaponChoices();
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.hudWeapons,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in choices)
                        _WeaponTile(
                          choice: c,
                          selected: c.weapon.id == game.aim.value.weaponId,
                          onTap: () {
                            AppServices.of(context).audio.play(Sfx.ui);
                            game.selectWeapon(c.weapon.id);
                            Navigator.of(context).pop();
                          },
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
  );
}

class _WeaponTile extends StatelessWidget {
  const _WeaponTile({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final WeaponChoice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final w = choice.weapon;
    final ammo = choice.ammoLeft;
    final status = w.isSignature
        ? (choice.usable ? l10n.hudSignature : l10n.hudUsed)
        : (ammo == null ? l10n.hudAmmoUnlimited : l10n.hudAmmoLeft(ammo));
    return Opacity(
      opacity: choice.usable ? 1 : 0.4,
      child: Material(
        color: selected
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: w.isSignature
              ? BorderSide(color: scheme.tertiary, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: choice.usable ? onTap : null,
          child: SizedBox(
            width: 108,
            height: 112,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  WeaponIcon(weapon: w, size: 40),
                  const SizedBox(height: 4),
                  Text(
                    l10n.byKey(w.nameKey),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  Text(
                    status,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: w.isSignature ? scheme.tertiary : null,
                          fontWeight: FontWeight.w700,
                        ),
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

/// Weapon icon: the weapon's own art on a dark round backdrop.
class WeaponIcon extends StatelessWidget {
  const WeaponIcon({super.key, required this.weapon, required this.size});

  final WeaponDef weapon;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Color.alphaBlend(
              Color(weapon.placeholderArgb).withValues(alpha: 0.25),
              const Color(0xFF26303A)),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x55FFFFFF), width: 1.5),
        ),
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
    WeaponArt.icon(canvas, id, size.shortestSide * 0.78);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IconPainter old) => old.id != id;
}
