import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_services.dart';
import '../../app/paw_palette.dart';
import '../../config/app_info.dart';
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
                              _Row(
                                icon: Icons.info_rounded,
                                label: l10n.menuAbout,
                                last: true,
                                child: PawButton(
                                  label: l10n.menuAbout,
                                  height: 40,
                                  fontSize: 14,
                                  shadow: 3,
                                  radius: 12,
                                  onPressed: () => showAbout(context),
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

/// About (PRD: versi, kredit aset, tautan kebijakan privasi) as a card over
/// Settings.
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
