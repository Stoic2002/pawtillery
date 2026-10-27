import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_services.dart';
import '../../app/paw_palette.dart';
import '../../config/app_info.dart';
import '../../config/breeds.dart';
import '../../config/teams.dart';
import '../../l10n/app_localizations.dart';
import '../../net/lan.dart';
import '../../services/audio_service.dart';
import '../widgets/paw/paw_backdrop.dart';
import '../widgets/paw/paw_logo.dart';
import '../widgets/paw/paw_widgets.dart';
import '../widgets/paw/pet_figure.dart';
import 'how_to_play_screen.dart';
import 'lan_screen.dart';
import 'settings_screen.dart';
import 'setup_screen.dart';

/// Title screen (redesign prototype): sky and two hills, the wordmark top
/// left, a row of pets on the green hill, the Play button with How to Play
/// and Settings on the right, version and About bottom right.
class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  /// Pets on the hill: family, breed colour from the family's first
  /// breed, team, x (fraction), lift (fraction of height), size, flip.
  static const _gang = [
    ('dog', 0, 0.06, 0.30, 60.0, false),
    ('cat', 1, 0.14, 0.35, 64.0, false),
    ('turtle', 2, 0.24, 0.37, 72.0, false),
    ('rabbit', 3, 0.34, 0.35, 64.0, true),
    ('duck', 0, 0.42, 0.30, 56.0, true),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    void open(Widget screen) {
      AppServices.of(context).audio.play(Sfx.ui);
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => screen));
    }

    return PopScope(
      canPop: false,
      // The back gesture here would close the app: ask first.
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) confirmQuitApp(context);
      },
      child: Scaffold(
        body: PawBackdrop(
          hills: PawHills.menu,
          child: LayoutBuilder(
            builder: (context, box) => Stack(
              children: [
                for (final (family, team, x, lift, size, flip) in _gang)
                  Positioned(
                    left: box.maxWidth * x - size / 2,
                    bottom: box.maxHeight * lift - 8,
                    child: PetFigure(
                      familyId: family,
                      breedId: Breeds.ofFamily(family).first.id,
                      teamArgb: Teams.styles[team].colorArgb,
                      size: size,
                      flip: flip,
                    ),
                  ),
                SafeArea(
                  child: Stack(
                    children: [
                      Positioned(
                        left: 24,
                        top: 24,
                        width: box.maxWidth * 0.55,
                        child: Center(
                          child: FittedBox(
                            child: PawLogo(title: l10n.appTitle, size: 68),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 24,
                        top: 0,
                        bottom: 24,
                        width: (box.maxWidth * 0.36).clamp(220, 340),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            PawButton(
                              label: l10n.menuPlay,
                              icon: Icons.play_arrow_rounded,
                              fill: Paw.orange,
                              height: 68,
                              fontSize: 30,
                              display: true,
                              borderWidth: 3,
                              radius: 16,
                              onPressed: () => open(const SetupScreen()),
                            ),
                            // No sockets on the web.
                            if (lanSupported) ...[
                              const SizedBox(height: 14),
                              PawButton(
                                label: l10n.menuPlayWifi,
                                icon: Icons.wifi_rounded,
                                fill: Paw.green,
                                borderWidth: 3,
                                onPressed: () => open(const LanScreen()),
                              ),
                            ],
                            const SizedBox(height: 14),
                            PawButton(
                              label: l10n.menuHowToPlay,
                              icon: Icons.menu_book_rounded,
                              borderWidth: 3,
                              onPressed: () => open(const HowToPlayScreen()),
                            ),
                            const SizedBox(height: 14),
                            PawButton(
                              label: l10n.menuSettings,
                              icon: Icons.settings_rounded,
                              borderWidth: 3,
                              onPressed: () => open(const SettingsScreen()),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 24,
                        bottom: 12,
                        child: Row(
                          children: [
                            Text(
                              'v${AppInfo.version}',
                              style: Paw.text(
                                12,
                                weight: 700,
                                color: Paw.muted,
                              ),
                            ),
                            const SizedBox(width: 10),
                            PawCircleButton(
                              icon: Icons.info_rounded,
                              tooltip: l10n.menuAbout,
                              onPressed: () => showAbout(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Quit Pawtillery?" — closes the app only on a yes.
Future<void> confirmQuitApp(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  AppServices.of(context).audio.play(Sfx.ui);
  final quit = await showPawConfirm(
    context: context,
    title: l10n.quitAppTitle,
    body: l10n.quitAppBody,
    ok: l10n.pauseQuit,
    cancel: l10n.dialogCancel,
  );
  if (quit) await SystemNavigator.pop();
}

/// About (PRD: versi, kredit aset, tautan kebijakan privasi) as a card over
/// the menu.
Future<void> showAbout(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showPawDialog<void>(
    context: context,
    width: 420,
    builder: (context) {
      Widget row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(k, style: Paw.text(14, color: Paw.muted)),
            ),
            Expanded(child: Text(v, style: Paw.text(14, weight: 700))),
          ],
        ),
      );
      return PawCard(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(l10n.menuAbout, style: Paw.title(22))),
                Text(
                  l10n.aboutVersion(AppInfo.version),
                  style: Paw.text(12, weight: 700, color: Paw.muted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(l10n.aboutDescription, style: Paw.text(14, weight: 600)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Paw.peach,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Paw.ink, width: 2),
              ),
              child: Column(
                children: [
                  row(l10n.aboutDeveloper, AppInfo.developer),
                  row(l10n.aboutArt, l10n.aboutArtValue),
                  row(l10n.aboutFonts, AppInfo.fonts),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(l10n.aboutPrivacyNote, style: Paw.text(13, weight: 600)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      await Clipboard.setData(
                        const ClipboardData(text: AppInfo.privacyPolicyUrl),
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.aboutLinkCopied)),
                      );
                    },
                    child: Text(
                      l10n.aboutPrivacy,
                      style: Paw.text(14, color: Paw.orangeDeep).copyWith(
                        decoration: TextDecoration.underline,
                        decorationColor: Paw.orangeDeep,
                      ),
                    ),
                  ),
                ),
                PawButton(
                  label: l10n.dialogClose,
                  height: 44,
                  fontSize: 14,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
