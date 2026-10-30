import 'package:flutter/material.dart';

import '../../app/paw_palette.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/paw/paw_widgets.dart';

/// First-match tutorial (PRD: tooltip bertahap — jalan, buka senjata,
/// bidik, tembak — sekali di giliran pertama, bisa dilewati).
enum TutorialStep { walk, weapons, aim, fire, done }

/// Steps advance when the player actually does the thing (or presses
/// Next); doing a later step first skips the earlier ones.
class TutorialController extends ValueNotifier<TutorialStep> {
  TutorialController() : super(TutorialStep.walk);

  bool get isDone => value == TutorialStep.done;

  void complete(TutorialStep step) {
    if (isDone || step.index < value.index) return;
    value = TutorialStep.values[step.index + 1];
  }

  void skip() => value = TutorialStep.done;
}

/// The redesign's tutorial card: a step counter, the tip, "Skip tutorial"
/// and Next, placed near the control it is about with a little pointer.
/// Only the card takes touches; everything else passes through.
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
        final (alignment, text) = switch (step) {
          TutorialStep.walk => (
            const Alignment(-0.95, 0.35),
            l10n.tutorialWalk,
          ),
          TutorialStep.weapons => (
            const Alignment(0.6, 0.3),
            l10n.tutorialWeapons,
          ),
          TutorialStep.aim => (const Alignment(0, -0.1), l10n.tutorialAim),
          TutorialStep.fire => (const Alignment(0.85, 0.2), l10n.tutorialFire),
          TutorialStep.done => throw StateError('unreachable'),
        };
        return SafeArea(
          child: Align(
            alignment: alignment,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: 260,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    gradient: Paw.paper(Paw.cream),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Paw.ink, width: 3),
                    boxShadow: Paw.drop(),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 22,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Paw.ink,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          l10n.hudStepOf(step.index + 1, 4),
                          style: Paw.text(12, color: Paw.cream),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        text,
                        style: Paw.text(16, weight: 700, height: 1.35),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: controller.skip,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                l10n.tutorialSkip,
                                style: Paw.text(13, color: Paw.muted).copyWith(
                                  decoration: TextDecoration.underline,
                                  decorationColor: Paw.muted,
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          PawButton(
                            label: l10n.howNext,
                            fill: Paw.green,
                            height: 44,
                            fontSize: 14,
                            radius: 12,
                            shadow: 3,
                            padding: 16,
                            onPressed: () => controller.complete(step),
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
      },
    );
  }
}
