import 'package:flutter/material.dart';

import '../../app/field_palette.dart';

import '../../app/app_services.dart';
import '../../config/weapons.dart';
import '../../game/art/weapon_art.dart';
import '../../game/pawtillery_game.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_lookup.g.dart';
import '../../services/audio_service.dart';
import '../widgets/field/catalogue.dart';
import '../widgets/field/plate.dart';

/// Weapon menu (PRD: Menu senjata) as a catalogue of arms: engraved
/// plates with spaced names and ammo as tally marks; the family's signature
/// weapon carries a small red stamp.
Future<void> showWeaponMenu(BuildContext context, PawtilleryGame game) {
  final l10n = AppLocalizations.of(context);
  final choices = game.weaponChoices();
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0x552B2620),
    builder: (context) => Catalogue(
      title: l10n.hudWeapons,
      children: [
        for (final (i, c) in choices.indexed)
          Opacity(
            opacity: c.usable ? 1 : 0.4,
            child: CatalogueTile(
              width: 108,
              selected: c.weapon.id == game.aim.value.weaponId,
              onTap: c.usable
                  ? () {
                      AppServices.of(context).audio.play(Sfx.ui);
                      game.selectWeapon(c.weapon.id);
                      Navigator.of(context).pop();
                    }
                  : null,
              child: Column(
                children: [
                  Text(
                    l10n.plateNumber('${i + 1}'),
                    style: const TextStyle(
                      fontSize: 10,
                      letterSpacing: 2,
                      color: FieldPalette.inkSoft,
                    ),
                  ),
                  WeaponIcon(weapon: c.weapon, size: 54),
                  const SizedBox(height: 2),
                  Text(
                    l10n.byKey(c.weapon.nameKey).toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 2),
                  if (c.weapon.isSignature)
                    _Seal(text: c.usable ? l10n.hudSignature : l10n.hudUsed)
                  else
                    AmmoTally(ammo: c.ammoLeft),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

/// Ammo as tally marks (∞ when unlimited).
class AmmoTally extends StatelessWidget {
  const AmmoTally({super.key, required this.ammo});

  final int? ammo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final n = ammo;
    if (n == null) {
      return Text(
        l10n.hudAmmoUnlimited,
        style: const TextStyle(fontSize: 16, color: FieldPalette.inkSoft),
      );
    }
    return SizedBox(
      height: 16,
      width: 8.0 * n + 6,
      child: CustomPaint(painter: _TallyPainter(n)),
    );
  }
}

class _TallyPainter extends CustomPainter {
  _TallyPainter(this.n);
  final int n;

  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = FieldPalette.ink
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < n; i++) {
      final x = 3 + i * 8.0;
      if (i % 5 == 4) {
        canvas.drawLine(Offset(x - 32, size.height - 3), Offset(x + 1, 3), pen);
      } else {
        canvas.drawLine(Offset(x, 2), Offset(x - 1, size.height - 2), pen);
      }
    }
  }

  @override
  bool shouldRepaint(_TallyPainter old) => old.n != n;
}

/// A small red stamp mark.
class _Seal extends StatelessWidget {
  const _Seal({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: -0.05,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: FieldPalette.stamp, width: 1.2),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 9,
          letterSpacing: 1.5,
          color: FieldPalette.stamp,
        ),
      ),
    ),
  );
}

/// Weapon figure as an engraving on the paper.
class WeaponIcon extends StatelessWidget {
  const WeaponIcon({super.key, required this.weapon, required this.size});

  final WeaponDef weapon;
  final double size;

  @override
  Widget build(BuildContext context) => ColorFiltered(
    colorFilter: engravingFilter,
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _IconPainter(weapon.id)),
    ),
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
