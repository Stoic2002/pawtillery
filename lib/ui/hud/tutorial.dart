import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

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

/// The tooltip for the current step, placed next to the control it is
/// about. Only the Skip button takes touches; everything else passes
/// through to the game.
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
        final (alignment, text, icon) = switch (step) {
          TutorialStep.walk =>
            (const Alignment(-0.95, 0.35), l10n.tutorialWalk, Icons.south_west),
          TutorialStep.weapons => (
              const Alignment(0.95, 0.1),
              l10n.tutorialWeapons,
              Icons.south_east
            ),
          TutorialStep.aim =>
            (const Alignment(0, 0.25), l10n.tutorialAim, Icons.touch_app),
          TutorialStep.fire =>
            (const Alignment(0.6, 0.35), l10n.tutorialFire, Icons.south_east),
          TutorialStep.done => throw StateError('unreachable'),
        };
        return SafeArea(
          child: Align(
            alignment: alignment,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Material(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  elevation: 6,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 6, 4),
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(icon, size: 28),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: controller.skip,
                          child: Text(l10n.tutorialSkip),
                        ),
                      ],
                    ),
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
