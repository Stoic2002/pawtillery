import 'package:flutter/material.dart';

import '../../app/paw_palette.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/paw/paw_widgets.dart';

enum PauseChoice { resume, settings, exit }

/// Pause menu (PRD: Jeda — Lanjut, Settings, Keluar ke menu; redesign
/// prototype): a card with Resume, Settings and a red Quit. Closing it any
/// other way (back gesture, tap outside) resumes.
Future<PauseChoice> showPauseDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final choice = await showPawDialog<PauseChoice>(
    context: context,
    width: 300,
    builder: (context) => PawCard(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.pauseTitle,
            textAlign: TextAlign.center,
            style: Paw.title(28),
          ),
          const SizedBox(height: 12),
          PawButton(
            label: l10n.pauseResume,
            icon: Icons.play_arrow_rounded,
            fill: Paw.orange,
            display: true,
            fontSize: 20,
            height: 56,
            borderWidth: 3,
            onPressed: () => Navigator.of(context).pop(PauseChoice.resume),
          ),
          const SizedBox(height: 12),
          PawButton(
            label: l10n.menuSettings,
            icon: Icons.settings_rounded,
            height: 48,
            fontSize: 15,
            onPressed: () => Navigator.of(context).pop(PauseChoice.settings),
          ),
          const SizedBox(height: 12),
          PawButton(
            label: l10n.pauseExit,
            icon: Icons.logout_rounded,
            height: 48,
            fontSize: 15,
            border: Paw.red,
            foreground: Paw.redText,
            onPressed: () => Navigator.of(context).pop(PauseChoice.exit),
          ),
        ],
      ),
    ),
  );
  return choice ?? PauseChoice.resume;
}

/// "Leave the match?" confirmation.
Future<bool> confirmExit(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showPawConfirm(
    context: context,
    title: l10n.pauseExitConfirmTitle,
    body: l10n.pauseQuitBody,
    ok: l10n.pauseQuit,
    cancel: l10n.dialogCancel,
  );
}
