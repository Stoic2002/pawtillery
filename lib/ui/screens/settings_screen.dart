import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../app/paw_palette.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/paw/paw_backdrop.dart';
import '../widgets/paw/paw_widgets.dart';
import '../widgets/paw/paw_icon.dart';

/// Settings (redesign prototype): one card of rows, each with an icon,
/// a label and its control. Changes are saved immediately.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = AppServices.of(context).settings;
    return Scaffold(
      body: PawBackdrop(
        clouds: false,
        child: SafeArea(
          child: Column(
            children: [
              PawHeader(title: l10n.menuSettings, backLabel: l10n.back),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 660),
                      child: PawCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 2,
                        ),
                        child: ListenableBuilder(
                          listenable: settings,
                          builder: (context, _) => ListView(
                            shrinkWrap: true,
                            children: [
                              _Row(
                                icon: Icons.translate_rounded,
                                label: l10n.settingsLanguage,
                                child: PawPillToggle<String>(
                                  values: const ['', 'en', 'id'],
                                  selected: settings.languageCode ?? '',
                                  label: (v) => switch (v) {
                                    'en' => l10n.languageEnglish,
                                    'id' => l10n.languageIndonesian,
                                    _ => l10n.settingsLanguageSystem,
                                  },
                                  onSelect: (v) => settings.languageCode =
                                      v.isEmpty ? null : v,
                                ),
                              ),
                              _Row(
                                icon: Icons.library_music_rounded,
                                label: l10n.settingsMusicOn,
                                child: PawSwitch(
                                  value: settings.musicOn,
                                  label: l10n.settingsMusicOn,
                                  onChanged: (v) => settings.musicOn = v,
                                ),
                              ),
                              _Row(
                                icon: Icons.music_note_rounded,
                                label: l10n.settingsMusic,
                                child: _Volume(
                                  value: settings.musicVolume,
                                  label: l10n.settingsMusic,
                                  onChanged: (v) => settings.musicVolume = v,
                                ),
                              ),
                              _Row(
                                icon: Icons.volume_up_rounded,
                                label: l10n.settingsSfx,
                                child: _Volume(
                                  value: settings.sfxVolume,
                                  label: l10n.settingsSfx,
                                  onChanged: (v) => settings.sfxVolume = v,
                                ),
                              ),
                              _Row(
                                icon: Icons.vibration_rounded,
                                label: l10n.settingsHaptics,
                                child: PawSwitch(
                                  value: settings.haptics,
                                  label: l10n.settingsHaptics,
                                  onChanged: (v) => settings.haptics = v,
                                ),
                              ),
                              _Row(
                                icon: Icons.timeline_rounded,
                                label: l10n.settingsAimGuide,
                                child: PawSwitch(
                                  value: settings.showAimGuide,
                                  label: l10n.settingsAimGuide,
                                  onChanged: (v) => settings.showAimGuide = v,
                                ),
                              ),
                              _Row(
                                icon: Icons.speed_rounded,
                                label: l10n.settingsShowFps,
                                child: PawSwitch(
                                  value: settings.showFps,
                                  label: l10n.settingsShowFps,
                                  onChanged: (v) => settings.showFps = v,
                                ),
                              ),
                              _Row(
                                icon: Icons.school_rounded,
                                label: l10n.settingsTutorial,
                                last: true,
                                child: PawButton(
                                  label: l10n.settingsReplay,
                                  fill: Paw.green,
                                  height: 40,
                                  fontSize: 14,
                                  shadow: 3,
                                  radius: 12,
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
  const _Row({
    required this.icon,
    required this.label,
    required this.child,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final Widget child;
  final bool last;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 52),
    decoration: BoxDecoration(
      border: last
          ? null
          : const Border(bottom: BorderSide(color: Paw.peach, width: 2)),
    ),
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        PawIcon(icon, size: 22, color: Paw.ink),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: Paw.text(16))),
        Flexible(
          flex: 2,
          child: Align(
            alignment: Alignment.centerRight,
            child: FittedBox(fit: BoxFit.scaleDown, child: child),
          ),
        ),
      ],
    ),
  );
}

class _Volume extends StatelessWidget {
  const _Volume({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final double value;
  final String label;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      PawSlider(value: value, onChanged: onChanged, label: label, width: 180),
      SizedBox(
        width: 44,
        child: Text(
          '${(value * 100).round()}',
          textAlign: TextAlign.right,
          style: Paw.title(16, weight: 800),
        ),
      ),
    ],
  );
}
