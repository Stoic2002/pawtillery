import 'package:flutter/material.dart';

import '../../app/match_config.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/menu_backdrop.dart';
import 'arena_screen.dart';

/// What the results screen shows; computed when the match ends.
class MatchResult {
  const MatchResult({
    required this.winnerTeam,
    required this.teamNames,
    required this.teamColors,
    required this.knockouts,
    required this.turns,
    this.topUnitName,
    this.topUnitTeam,
    this.topDamage,
  });

  /// null = draw.
  final int? winnerTeam;
  final List<String> teamNames;
  final List<int> teamColors;
  final List<int> knockouts;
  final int turns;
  final String? topUnitName;
  final int? topUnitTeam;
  final int? topDamage;
}

/// Results (PRD: Hasil — tim pemenang, statistik singkat, Main Lagi, Menu
/// Utama). Sits where the arena was, so "Change teams" is simply going back
/// to the setup screen underneath.
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.result, required this.config});

  final MatchResult result;
  final MatchConfig config;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final winner = result.winnerTeam;
    final topTeam = result.topUnitTeam;

    return Scaffold(
      body: MenuBackdrop(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: 56,
                      color: winner == null
                          ? Theme.of(context).colorScheme.outline
                          : Color(result.teamColors[winner]),
                    ),
                    Text(
                      winner == null
                          ? l10n.resultDraw
                          : l10n.resultWinner(result.teamNames[winner]),
                      textAlign: TextAlign.center,
                      style: text.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: winner == null
                            ? null
                            : Color(result.teamColors[winner]),
                      ),
                    ),
                    Text(l10n.resultTurns(result.turns), style: text.bodySmall),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: [
                        _StatCard(
                          title: l10n.resultMostDamage,
                          child: Text(
                            topTeam == null
                                ? l10n.resultNoDamage
                                : l10n.resultMostDamageValue(
                                    result.topUnitName ?? '',
                                    result.teamNames[topTeam],
                                    result.topDamage ?? 0,
                                  ),
                          ),
                        ),
                        _StatCard(
                          title: l10n.resultKills,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var t = 0; t < result.teamNames.length; t++)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 6,
                                      backgroundColor: Color(
                                        result.teamColors[t],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        '${result.teamNames[t]}: '
                                        '${result.knockouts[t]}',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(150, 48),
                          ),
                          onPressed: () =>
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute<void>(
                                  builder: (_) => ArenaScreen(config: config),
                                ),
                              ),
                          icon: const Icon(Icons.replay),
                          label: Text(l10n.resultPlayAgain),
                        ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(150, 48),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(l10n.resultChangeTeams),
                        ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(150, 48),
                          ),
                          onPressed: () => Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst),
                          child: Text(l10n.resultMainMenu),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 290,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    ),
  );
}
