import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../widgets/paw_logo.dart';
import 'about_screen.dart';
import 'how_to_play_screen.dart';
import 'settings_screen.dart';
import 'setup_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    void open(Widget screen) => Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 48,
              runSpacing: 24,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const PawLogo(size: 110),
                    Text(l10n.appTitle,
                        style: Theme.of(context).textTheme.displaySmall),
                  ],
                ),
                // Fixed width: a stretched column would take the whole row
                // and push the buttons below the logo, off a landscape
                // phone screen.
                SizedBox(
                  width: 260,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton(
                        style: FilledButton.styleFrom(
                            minimumSize: const Size(240, 56)),
                        onPressed: () => open(const SetupScreen()),
                        child: Text(l10n.menuPlay,
                            style: const TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(height: 10),
                      for (final (label, screen) in [
                        (l10n.menuHowToPlay, const HowToPlayScreen()),
                        (l10n.menuSettings, const SettingsScreen()),
                        (l10n.menuAbout, const AboutScreen()),
                      ]) ...[
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                              minimumSize: const Size(240, 48)),
                          onPressed: () => open(screen),
                          child: Text(label),
                        ),
                        const SizedBox(height: 8),
                      ],
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
