import 'package:flutter/material.dart';

import '../../app/toon_palette.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/toon/toon_button.dart';
import '../widgets/toon/toon_icons.dart';
import '../widgets/toon/toon_panel.dart';

enum PauseChoice { resume, settings, exit }

/// Pause menu (PRD: Jeda — Lanjut, Settings, Keluar ke menu): a card that
/// pops in with three big buttons. Closing it any other way (back gesture,
/// tap outside) resumes.
Future<PauseChoice> showPauseDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final choice = await showToonDialog<PauseChoice>(
    context: context,
    title: l10n.pauseTitle.toUpperCase(),
    maxWidth: 340,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (c, label, glyph, tone) in [
          (PauseChoice.resume, l10n.pauseResume, ToonGlyph.play, ToonTone.leaf),
          (PauseChoice.settings, l10n.menuSettings, ToonGlyph.gear, ToonTone.sky),
          (PauseChoice.exit, l10n.pauseExit, ToonGlyph.home, ToonTone.tomato),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ToonButton(
              label: label,
              icon: glyph,
              tone: tone,
              fontSize: 18,
              onPressed: () => Navigator.of(context).pop(c),
            ),
          ),
      ],
    ),
  );
  return choice ?? PauseChoice.resume;
}

/// "Leave the match?" confirmation.
Future<bool> confirmExit(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showToonDialog<bool>(
    context: context,
    title: l10n.pauseExitConfirmTitle.toUpperCase(),
    titleTone: ToonTone.tomato,
    maxWidth: 420,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.pauseExitConfirmBody,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 17, color: ToonPalette.bark),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            ToonButton(
              label: l10n.dialogCancel,
              tone: ToonTone.sky,
              fontSize: 17,
              minWidth: 120,
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ToonButton(
              label: l10n.dialogLeave,
              tone: ToonTone.tomato,
              icon: ToonGlyph.home,
              fontSize: 17,
              minWidth: 120,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ],
    ),
  );
  return ok ?? false;
}
