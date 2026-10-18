import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../app/field_palette.dart';
import '../../config/breeds.dart';
import '../../config/families.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_lookup.g.dart';
import '../../services/audio_service.dart';
import '../widgets/field/paper.dart';
import '../widgets/field/plate.dart';
import '../widgets/field/stamp.dart';
import 'about_screen.dart';
import 'how_to_play_screen.dart';
import 'settings_screen.dart';
import 'setup_screen.dart';

/// The journal's opening spread: title page on the left (the one stamp is
/// Play; the rest is a table of contents), an engraved plate on the right.
class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    void open(Widget screen) {
      AppServices.of(context).audio.play(Sfx.ui);
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => screen));
    }

    final titlePage = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SpacedTitle(l10n.appTitle, size: 38, spacing: 9),
        const SizedBox(height: 4),
        Text(
          l10n.menuSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontStyle: FontStyle.italic,
            color: FieldPalette.inkSoft,
          ),
        ),
        const SizedBox(height: 10),
        const LeafRule(width: 240),
        const SizedBox(height: 18),
        StampButton(
          label: l10n.menuPlay,
          fontSize: 20,
          minWidth: 180,
          onPressed: () => open(const SetupScreen()),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SpacedTitle(
                l10n.menuContents,
                size: 11,
                spacing: 3,
                color: FieldPalette.inkSoft,
              ),
              const SizedBox(height: 2),
              ContentsEntry(
                numeral: 'I.',
                label: l10n.menuHowToPlay,
                page: '3',
                onTap: () => open(const HowToPlayScreen()),
              ),
              ContentsEntry(
                numeral: 'II.',
                label: l10n.menuSettings,
                page: '41',
                onTap: () => open(const SettingsScreen()),
              ),
              ContentsEntry(
                numeral: 'III.',
                label: l10n.menuAbout,
                page: '47',
                onTap: () => open(const AboutScreen()),
              ),
            ],
          ),
        ),
      ],
    );

    final plate = Plate(
      number: l10n.plateNumber('I'),
      caption: [
        for (final f in const [Families.cat, Families.dog, Families.rabbit])
          l10n.byKey(f.latinKey),
      ].join(' · '),
      child: SizedBox(
        width: 250,
        height: 150,
        child: Stack(
          children: [
            for (final (f, x, y, size, facing) in const [
              (Families.dog, 0.0, 30.0, 120.0, 1),
              (Families.rabbit, 140.0, 46.0, 100.0, -1),
              (Families.cat, 70.0, 56.0, 96.0, 1),
            ])
              Positioned(
                left: x,
                top: y,
                child: AnimalFigure(
                  familyId: f.id,
                  breedId: Breeds.ofFamily(f.id).first.id,
                  size: size,
                  engraved: true,
                  facing: facing,
                ),
              ),
          ],
        ),
      ),
    );

    return Scaffold(
      body: PaperAtmosphere(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 56,
                runSpacing: 24,
                children: [titlePage, plate],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
