import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

enum PauseChoice { resume, settings, exit }

/// Pause menu (PRD: Jeda — Lanjut, Settings, Keluar ke menu). Closing it
/// any other way (back gesture, tap outside) resumes.
Future<PauseChoice> showPauseDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final choice = await showDialog<PauseChoice>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(l10n.pauseTitle),
      children: [
        for (final (c, label, icon) in [
          (PauseChoice.resume, l10n.pauseResume, Icons.play_arrow),
          (PauseChoice.settings, l10n.menuSettings, Icons.settings),
          (PauseChoice.exit, l10n.pauseExit, Icons.logout),
        ])
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(c),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              children: [
                Icon(icon),
                const SizedBox(width: 16),
                Text(label),
              ],
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
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.pauseExitConfirmTitle),
      content: Text(l10n.pauseExitConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.dialogCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.dialogLeave),
        ),
      ],
    ),
  );
  return ok ?? false;
}
