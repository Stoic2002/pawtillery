import 'package:flutter/material.dart';

import '../../app/toon_palette.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/toon/toon_icons.dart';
import '../widgets/toon/toon_panel.dart';

/// First-match tutorial (PRD: tooltip bertahap — jalan, buka senjata,
/// bidik, tembak — sekali di giliran pertama, bisa dilewati).
enum TutorialStep { walk, weapons, aim, fire, done }

/// Steps advance when the player actually does the thing; doing a later
/// step first skips the earlier ones.
class TutorialController extends ValueNotifier<TutorialStep> {
  TutorialController() : super(TutorialStep.walk);

  bool get isDone => value == TutorialStep.done;

  void complete(TutorialStep step) {
    if (isDone || step.index < value.index) return;
    value = TutorialStep.values[step.index + 1];
  }

  void skip() => value = TutorialStep.done;
}

/// A speech card for the current step near the control it is about, with
/// a yellow arrow pointing at it. Only Skip takes touches; everything
/// else passes through to the game.
class TutorialOverlay extends StatelessWidget {
  const TutorialOverlay({
    super.key,
    required this.controller,
    required this.visible,
  });

  final TutorialController controller;

  /// Shown only while the player can act (not during banners or flights).
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ValueListenableBuilder<TutorialStep>(
      valueListenable: controller,
      builder: (context, step, _) {
        if (!visible || step == TutorialStep.done) {
          return const SizedBox.shrink();
        }
        // Arrow angle: the back arrow points left; rotate it towards the
        // control.
        final (alignment, text, angle) = switch (step) {
          TutorialStep.walk =>
            (const Alignment(-0.95, 0.35), l10n.tutorialWalk, -0.8),
          TutorialStep.weapons =>
            (const Alignment(0.95, 0.1), l10n.tutorialWeapons, -2.35),
          TutorialStep.aim =>
            (const Alignment(0, 0.25), l10n.tutorialAim, -1.57),
          TutorialStep.fire =>
            (const Alignment(0.6, 0.35), l10n.tutorialFire, -2.35),
          TutorialStep.done => throw StateError('unreachable'),
        };
        return SafeArea(
          child: Align(
            alignment: alignment,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: ToonPanel(
                  style: ToonPanelStyle.night,
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      IgnorePointer(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                text,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: ToonPalette.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Transform.rotate(
                              angle: angle,
                              child: const ToonIcon(
                                ToonGlyph.back,
                                size: 32,
                                color: ToonPalette.sun,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: controller.skip,
                        child: Text(l10n.tutorialSkip,
                            style: const TextStyle(
                                fontSize: 15, color: ToonPalette.sky)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
