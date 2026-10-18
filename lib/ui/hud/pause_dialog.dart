import 'package:flutter/material.dart';

import '../../app/field_palette.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/field/paper.dart';
import '../widgets/field/stamp.dart';

enum PauseChoice { resume, settings, exit }

/// Pause menu (PRD: Jeda — Lanjut, Settings, Keluar ke menu) as a sheet of
/// paper taped over the field, entries like a table of contents. Closing it
/// any other way (back gesture, tap outside) resumes.
Future<PauseChoice> showPauseDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final choice = await showDialog<PauseChoice>(
    context: context,
    barrierColor: const Color(0x662B2620),
    builder: (context) => Center(
      child: Material(
        type: MaterialType.transparency,
        child: SizedBox(
          width: 320,
          child: PaperPanel(
            tilt: -0.8,
            tape: true,
            frame: PanelFrame.double,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SpacedTitle(l10n.pauseTitle, size: 20, spacing: 6),
                const SizedBox(height: 4),
                const Center(child: LeafRule(width: 150)),
                const SizedBox(height: 6),
                for (final (i, (c, label)) in [
                  (PauseChoice.resume, l10n.pauseResume),
                  (PauseChoice.settings, l10n.menuSettings),
                  (PauseChoice.exit, l10n.pauseExit),
                ].indexed)
                  ContentsEntry(
                    numeral: '${['I', 'II', 'III'][i]}.',
                    label: label,
                    onTap: () => Navigator.of(context).pop(c),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  return choice ?? PauseChoice.resume;
}

/// "Leave the match?" confirmation, on paper.
Future<bool> confirmExit(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    barrierColor: const Color(0x662B2620),
    builder: (context) => Center(
      child: Material(
        type: MaterialType.transparency,
        child: SizedBox(
          width: 360,
          child: PaperPanel(
            tilt: 0.6,
            tape: true,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SpacedTitle(l10n.pauseExitConfirmTitle, size: 17, spacing: 3),
                const SizedBox(height: 8),
                Text(
                  l10n.pauseExitConfirmBody,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: FieldPalette.inkSoft,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    InkButton(
                      label: l10n.dialogCancel,
                      minWidth: 100,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                    StampButton(
                      label: l10n.dialogLeave,
                      minWidth: 100,
                      fontSize: 15,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  return ok ?? false;
}
