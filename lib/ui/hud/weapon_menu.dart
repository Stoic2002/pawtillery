import 'package:flutter/material.dart';

import '../../config/weapons.dart';
import '../../game/pawtillery_game.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_lookup.g.dart';

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

/// Placeholder weapon icon: the weapon colour with its initial.
class WeaponIcon extends StatelessWidget {
  const WeaponIcon({super.key, required this.weapon, required this.size});

  final WeaponDef weapon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = Color(weapon.placeholderArgb);
    final dark = color.computeLuminance() > 0.5;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Text(
        l10n.byKey(weapon.nameKey).characters.first.toUpperCase(),
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: size * 0.45,
          color: dark ? Colors.black87 : Colors.white,
        ),
      ),
    );
  }
}
