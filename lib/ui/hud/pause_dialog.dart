import 'package:flutter/material.dart';

import '../../app/iron_palette.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/iron/iron_button.dart';
import '../widgets/iron/iron_icons.dart';
import '../widgets/iron/iron_panel.dart';

enum PauseChoice { resume, settings, exit }

/// Pause menu (PRD: Jeda — Lanjut, Settings, Keluar ke menu): a card that
/// pops in with three big buttons. Closing it any other way (back gesture,
/// tap outside) resumes.
Future<PauseChoice> showPauseDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final choice = await showIronDialog<PauseChoice>(
    context: context,
    title: l10n.pauseTitle.toUpperCase(),
    maxWidth: 340,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (c, label, glyph, tone) in [
          (PauseChoice.resume, l10n.pauseResume, IronGlyph.play, IronTone.moss),
          (PauseChoice.settings, l10n.menuSettings, IronGlyph.gear, IronTone.steel),
          (PauseChoice.exit, l10n.pauseExit, IronGlyph.home, IronTone.blood),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: IronButton(
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
  final ok = await showIronDialog<bool>(
    context: context,
    title: l10n.pauseExitConfirmTitle.toUpperCase(),
    titleTone: IronTone.blood,
    maxWidth: 420,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.pauseExitConfirmBody,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 17, color: IronPalette.mute),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            IronButton(
              label: l10n.dialogCancel,
              tone: IronTone.steel,
              fontSize: 17,
              minWidth: 120,
              onPressed: () => Navigator.of(context).pop(false),
            ),
            IronButton(
              label: l10n.dialogLeave,
              tone: IronTone.blood,
              icon: IronGlyph.home,
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
