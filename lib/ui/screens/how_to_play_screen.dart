import 'package:flutter/material.dart';

import '../../app/paw_palette.dart';
import '../../config/breeds.dart';
import '../../config/families.dart';
import '../../config/teams.dart';
import '../../config/weapons.dart';
import '../../l10n/app_localizations.dart';
import '../hud/weapon_menu.dart';
import '../widgets/paw/paw_backdrop.dart';
import '../widgets/paw/paw_widgets.dart';
import '../widgets/paw/pet_figure.dart';

/// How to Play (PRD: 4–6 illustrated pages; redesign prototype): one card
/// with the page count and a close button, a striped picture panel on the
/// left, title and text on the right, Back · dots · Next at the bottom.
class HowToPlayScreen extends StatefulWidget {
  const HowToPlayScreen({super.key});

  @override
  State<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends State<HowToPlayScreen> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = [
      (l10n.howMoveTitle, l10n.howMoveBody),
      (l10n.howAimTitle, l10n.howAimBody),
      (l10n.howWeaponsTitle, l10n.howWeaponsBody),
      (l10n.howWindTitle, l10n.howWindBody),
      (l10n.howFamiliesTitle, l10n.howFamiliesBody),
      (l10n.howWinTitle, l10n.howWinBody),
    ];
    final (title, body) = pages[_page];
    final last = _page == pages.length - 1;
    return Scaffold(
      body: PawBackdrop(
        clouds: false,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: PawCard(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(l10n.menuHowToPlay, style: Paw.title(22)),
                      ),
                      Text(
                        l10n.hudStepOf(_page + 1, pages.length),
                        style: Paw.text(12, weight: 700, color: Paw.muted),
                      ),
                      const SizedBox(width: 10),
                      PawCircleButton(
                        icon: Icons.close_rounded,
                        tooltip: l10n.back,
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 42,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Paw.ink, width: 2),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: CustomPaint(
                              painter: const StripesPainter(),
                              child: Center(child: _art(_page)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 58,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Text(title, style: Paw.title(28, height: 1.1)),
                                const SizedBox(height: 10),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 420,
                                  ),
                                  child: Text(
                                    body,
                                    style: Paw.text(
                                      16,
                                      weight: 600,
                                      height: 1.5,
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Opacity(
                        opacity: _page == 0 ? 0.4 : 1,
                        child: PawButton(
                          label: l10n.back,
                          icon: Icons.chevron_left_rounded,
                          height: 48,
                          fontSize: 14,
                          onPressed: _page == 0
                              ? null
                              : () => setState(() => _page--),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < pages.length; i++)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: i == _page ? 28 : 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: i == _page ? Paw.orange : Paw.cream,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: Paw.ink, width: 2),
                                ),
                              ),
                          ],
                        ),
                      ),
                      PawButton(
                        label: last ? l10n.howDone : l10n.howNext,
                        trailingIcon: Icons.chevron_right_rounded,
                        fill: Paw.green,
                        height: 48,
                        fontSize: 14,
                        onPressed: last
                            ? () => Navigator.of(context).pop()
                            : () => setState(() => _page++),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pet(String family, int team, {double size = 90, bool flip = false}) =>
      PetFigure(
        familyId: family,
        breedId: Breeds.ofFamily(family).first.id,
        teamArgb: Teams.styles[team].colorArgb,
        size: size,
        flip: flip,
      );

  Widget _art(int page) {
    switch (page) {
      case 0:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_back_rounded, size: 34, color: Paw.ink),
            _pet('rabbit', 0),
            const Icon(Icons.arrow_forward_rounded, size: 34, color: Paw.ink),
          ],
        );
      case 1:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _pet('cat', 1),
            const Icon(Icons.gps_fixed_rounded, size: 40, color: Paw.ink),
          ],
        );
      case 2:
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final w in [
              Weapons.rock,
              Weapons.grenade,
              Weapons.cluster,
              Weapons.mine,
              Weapons.boneBoomerang,
              Weapons.coconut,
            ])
              WeaponIcon(weapon: w, size: 50),
          ],
        );
      case 3:
        return const Icon(Icons.air_rounded, size: 110, color: Paw.ink);
      case 4:
        return Wrap(
          alignment: WrapAlignment.center,
          children: [
            for (final (i, f) in [
              Families.cat,
              Families.dog,
              Families.bird,
              Families.turtle,
              Families.goat,
              Families.monkey,
            ].indexed)
              _pet(f.id, i % 4, size: 60),
          ],
        );
      default:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _pet('dog', 0),
            const Icon(Icons.emoji_events_rounded, size: 46, color: Paw.yellow),
            _pet('duck', 1, flip: true, size: 76),
          ],
        );
    }
  }
}
