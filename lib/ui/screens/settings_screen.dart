import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../l10n/app_localizations.dart';

/// Settings (PRD: Bahasa, volume musik, volume efek, getaran, garis
/// bidikan). Changes are saved immediately.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = AppServices.of(context).settings;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.menuSettings)),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          children: [
            ListTile(
              title: Text(l10n.settingsLanguage),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                        value: '', label: Text(l10n.settingsLanguageSystem)),
                    ButtonSegment(
                        value: 'en', label: Text(l10n.languageEnglish)),
                    ButtonSegment(
                        value: 'id', label: Text(l10n.languageIndonesian)),
                  ],
                  selected: {settings.languageCode ?? ''},
                  onSelectionChanged: (s) => settings.languageCode =
                      s.first.isEmpty ? null : s.first,
                ),
              ),
            ),
            _VolumeTile(
              label: l10n.settingsMusic,
              icon: Icons.music_note,
              value: settings.musicVolume,
              onChanged: (v) => settings.musicVolume = v,
            ),
            _VolumeTile(
              label: l10n.settingsSfx,
              icon: Icons.volume_up,
              value: settings.sfxVolume,
              onChanged: (v) => settings.sfxVolume = v,
            ),
            SwitchListTile(
              secondary: const Icon(Icons.vibration),
              title: Text(l10n.settingsHaptics),
              value: settings.haptics,
              onChanged: (v) => settings.haptics = v,
            ),
            SwitchListTile(
              secondary: const Icon(Icons.timeline),
              title: Text(l10n.settingsAimGuide),
              value: settings.showAimGuide,
              onChanged: (v) => settings.showAimGuide = v,
            ),
            ListTile(
              leading: const Icon(Icons.school_outlined),
              title: Text(l10n.settingsTutorial),
              onTap: () {
                settings.tutorialDone = false;
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.settingsTutorialReset)));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _VolumeTile extends StatelessWidget {
  const _VolumeTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Slider(
          value: value,
          divisions: 10,
          label: '${(value * 100).round()}%',
          onChanged: onChanged,
        ),
      );
}
