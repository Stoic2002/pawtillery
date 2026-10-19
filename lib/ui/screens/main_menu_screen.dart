import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../app/iron_palette.dart';
import '../../config/breeds.dart';
import '../../config/families.dart';
import '../../config/teams.dart';
import '../../l10n/app_localizations.dart';
import '../../services/audio_service.dart';
import '../widgets/iron/iron_backdrop.dart';
import '../widgets/iron/iron_button.dart';
import '../widgets/iron/iron_controls.dart';
import '../widgets/iron/iron_icons.dart';
import '../widgets/iron/iron_logo.dart';
import 'about_screen.dart';
import 'how_to_play_screen.dart';
import 'settings_screen.dart';
import 'setup_screen.dart';

/// Title screen: the painted meadow, the wordmark and a big Play button on
/// the left, a gang of animals standing on the hill on the right.
class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  static const _groundLine = 0.8;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    void open(Widget screen) {
      AppServices.of(context).audio.play(Sfx.ui);
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => screen));
    }

    final menu = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(child: IronLogo(title: l10n.appTitle, size: 54)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: IronPalette.night,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            l10n.menuSubtitle,
            style: const TextStyle(fontSize: 15, color: IronPalette.parchment),
          ),
        ),
        const SizedBox(height: 16),
        IronButton(
          label: l10n.menuPlay,
          icon: IronGlyph.play,
          fontSize: 28,
          height: 62,
          minWidth: 240,
          onPressed: () => open(const SetupScreen()),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            IronButton(
              label: l10n.menuHowToPlay,
              icon: IronGlyph.question,
              tone: IronTone.steel,
              fontSize: 16,
              height: 46,
              onPressed: () => open(const HowToPlayScreen()),
            ),
            IronButton(
              label: l10n.menuSettings,
              icon: IronGlyph.gear,
              tone: IronTone.steel,
              fontSize: 16,
              height: 46,
              onPressed: () => open(const SettingsScreen()),
            ),
            IronButton(
              label: l10n.menuAbout,
              icon: IronGlyph.info,
              tone: IronTone.steel,
              fontSize: 16,
              height: 46,
              onPressed: () => open(const AboutScreen()),
            ),
          ],
        ),
      ],
    );

    return Scaffold(
      body: IronBackdrop(
        groundLine: _groundLine,
        child: LayoutBuilder(
          builder: (context, box) {
            final wide = box.maxWidth > 700;
            final ground = box.maxHeight * _groundLine;
            final gang = box.maxHeight * 0.36;
            return Stack(
              children: [
                if (wide)
                  for (final (f, team, dx, scale, facing) in _gang)
                    Positioned(
                      left: box.maxWidth * dx - gang * scale / 2,
                      top: ground - gang * scale * 0.94,
                      child: AnimalFigure(
                        familyId: f.id,
                        breedId: Breeds.ofFamily(f.id).first.id,
                        teamArgb: Teams.styles[team].colorArgb,
                        size: gang * scale,
                        facing: facing,
                      ),
                    ),
                SafeArea(
                  child: Align(
                    alignment: wide
                        ? const Alignment(-0.72, -0.35)
                        : Alignment.center,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: menu,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Who stands on the title hill: family, team colour, x, scale, facing.
  static final _gang = [
    (Families.goat, 2, 0.67, 0.95, 1),
    (Families.dog, 0, 0.77, 1.15, -1),
    (Families.cat, 1, 0.87, 1.0, -1),
    (Families.rabbit, 3, 0.95, 0.8, -1),
  ];
}
