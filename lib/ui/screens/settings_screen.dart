import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../app/field_palette.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/field/paper.dart';
import '../widgets/field/stamp.dart';
import '../widgets/field/catalogue.dart';

/// Settings as a printed form: labels in italic, inked boxes, hairline
/// sliders. Changes are saved immediately.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = AppServices.of(context).settings;
    return Scaffold(
      body: PaperAtmosphere(
        child: SafeArea(
          child: Column(
            children: [
              PageHeader(title: l10n.menuSettings),
              Expanded(
                child: ListenableBuilder(
                  listenable: settings,
                  builder: (context, _) => ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 8,
                    ),
                    children: [
                      _Row(
                        label: l10n.settingsLanguage,
                        child: SegmentedButton<String>(
                          showSelectedIcon: false,
                          segments: [
                            ButtonSegment(
                              value: '',
                              label: Text(l10n.settingsLanguageSystem),
                            ),
                            ButtonSegment(
                              value: 'en',
                              label: Text(l10n.languageEnglish),
                            ),
                            ButtonSegment(
                              value: 'id',
                              label: Text(l10n.languageIndonesian),
                            ),
                          ],
                          selected: {settings.languageCode ?? ''},
                          onSelectionChanged: (s) => settings.languageCode =
                              s.first.isEmpty ? null : s.first,
                        ),
                      ),
                      _Row(
                        label: l10n.settingsMusic,
                        child: Slider(
                          value: settings.musicVolume,
                          divisions: 10,
                          label: '${(settings.musicVolume * 100).round()}%',
                          onChanged: (v) => settings.musicVolume = v,
                        ),
                      ),
                      _Row(
                        label: l10n.settingsSfx,
                        child: Slider(
                          value: settings.sfxVolume,
                          divisions: 10,
                          label: '${(settings.sfxVolume * 100).round()}%',
                          onChanged: (v) => settings.sfxVolume = v,
                        ),
                      ),
                      _Row(
                        label: l10n.settingsHaptics,
                        child: _InkBox(
                          value: settings.haptics,
                          onChanged: (v) => settings.haptics = v,
                        ),
                      ),
                      _Row(
                        label: l10n.settingsAimGuide,
                        child: _InkBox(
                          value: settings.showAimGuide,
                          onChanged: (v) => settings.showAimGuide = v,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: InkButton(
                          label: l10n.settingsTutorial,
                          onPressed: () {
                            settings.tutorialDone = false;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.settingsTutorialReset),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
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
  const _Row({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: FieldPalette.paperEdge)),
    ),
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        SizedBox(
          width: 220,
          child: Text(
            label,
            style: const TextStyle(fontSize: 17, fontStyle: FontStyle.italic),
          ),
        ),
        Expanded(
          child: Align(alignment: Alignment.centerLeft, child: child),
        ),
      ],
    ),
  );
}

/// A checkbox drawn as an inked square with a pen cross.
class _InkBox extends StatelessWidget {
  const _InkBox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      checked: value,
      label: l10n.settingsOn,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: SizedBox.square(
          dimension: 48,
          child: Center(
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                border: Border.all(color: FieldPalette.ink, width: 1.4),
              ),
              child: value ? CustomPaint(painter: _CrossPainter()) : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _CrossPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = FieldPalette.ink
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(
        const Offset(4, 4),
        Offset(size.width - 4, size.height - 4),
        pen,
      )
      ..drawLine(Offset(size.width - 4, 4), Offset(4, size.height - 4), pen);
  }

  @override
  bool shouldRepaint(_CrossPainter old) => false;
}
