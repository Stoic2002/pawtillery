import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../app/iron_palette.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/iron/iron_backdrop.dart';
import '../widgets/iron/iron_button.dart';
import '../widgets/iron/iron_controls.dart';
import '../widgets/iron/iron_icons.dart';
import '../widgets/iron/iron_panel.dart';

/// Settings on one card: language, volumes, switches. Changes are saved
/// immediately.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = AppServices.of(context).settings;
    return Scaffold(
      body: IronBackdrop(
        dim: 0.15,
        child: SafeArea(
          child: Column(
            children: [
              IronHeader(title: l10n.menuSettings.toUpperCase()),
              Expanded(
                child: ListenableBuilder(
                  listenable: settings,
                  builder: (context, _) => SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: IronPanel(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                          child: Column(
                            children: [
                              _Row(
                                label: l10n.settingsLanguage,
                                child: IronSegmented<String>(
                                  values: const ['', 'en', 'id'],
                                  selected: settings.languageCode ?? '',
                                  label: (v) => switch (v) {
                                    'en' => l10n.languageEnglish,
                                    'id' => l10n.languageIndonesian,
                                    _ => l10n.settingsLanguageSystem,
                                  },
                                  onSelect: (v) => settings.languageCode =
                                      v.isEmpty ? null : v,
                                  wrap: true,
                                ),
                              ),
                              _Row(
                                label: l10n.settingsMusic,
                                child: Slider(
                                  value: settings.musicVolume,
                                  divisions: 10,
                                  label:
                                      '${(settings.musicVolume * 100).round()}%',
                                  onChanged: (v) => settings.musicVolume = v,
                                ),
                              ),
                              _Row(
                                label: l10n.settingsSfx,
                                child: Slider(
                                  value: settings.sfxVolume,
                                  divisions: 10,
                                  label:
                                      '${(settings.sfxVolume * 100).round()}%',
                                  onChanged: (v) => settings.sfxVolume = v,
                                ),
                              ),
                              _Row(
                                label: l10n.settingsHaptics,
                                child: IronSwitch(
                                  value: settings.haptics,
                                  onChanged: (v) => settings.haptics = v,
                                ),
                              ),
                              _Row(
                                label: l10n.settingsAimGuide,
                                last: true,
                                child: IronSwitch(
                                  value: settings.showAimGuide,
                                  onChanged: (v) => settings.showAimGuide = v,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: IronButton(
                                  label: l10n.settingsTutorial,
                                  icon: IronGlyph.replay,
                                  tone: IronTone.steel,
                                  fontSize: 15,
                                  height: 42,
                                  onPressed: () {
                                    settings.tutorialDone = false;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          l10n.settingsTutorialReset,
                                        ),
                                      ),
                                    );
                                  },
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
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.child, this.last = false});

  final String label;
  final Widget child;
  final bool last;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      border: last
          ? null
          : const Border(
              bottom: BorderSide(color: IronPalette.ironEdge, width: 2),
            ),
    ),
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        SizedBox(
          width: 200,
          child: Text(label, style: const TextStyle(fontSize: 18)),
        ),
        Expanded(
          child: Align(alignment: Alignment.centerLeft, child: child),
        ),
      ],
    ),
  );
}
