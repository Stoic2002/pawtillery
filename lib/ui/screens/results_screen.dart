import 'package:flutter/material.dart';

import '../../app/match_config.dart';
import '../../l10n/app_localizations.dart';
import '../../app/field_palette.dart';
import '../widgets/field/paper.dart';
import '../widgets/field/stamp.dart';
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
/// Utama) as a field report, the winner stamped across it in the team's
/// ink. Sits where the arena was, so "Change teams" is simply going back to
/// the setup screen underneath.
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.result, required this.config});

  final MatchResult result;
  final MatchConfig config;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final winner = result.winnerTeam;
    final topTeam = result.topUnitTeam;
    final winnerInk = winner == null
        ? FieldPalette.inkSoft
        : Color(result.teamColors[winner]);

    final report = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SpacedTitle(l10n.resultReport, size: 22, spacing: 6),
        Text(
          l10n.resultTurns(result.turns),
          style: const TextStyle(
            fontStyle: FontStyle.italic,
            color: FieldPalette.inkSoft,
          ),
        ),
        const SizedBox(height: 6),
        const LeafRule(width: 240),
        const SizedBox(height: 14),
        StampMark(
          label: winner == null
              ? l10n.resultDraw
              : l10n.resultWinner(result.teamNames[winner]),
          color: winnerInk,
          fontSize: 24,
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: 420,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ReportLine(
                label: l10n.resultMostDamage,
                value: topTeam == null
                    ? l10n.resultNoDamage
                    : l10n.resultMostDamageValue(
                        result.topUnitName ?? '',
                        result.teamNames[topTeam],
                        result.topDamage ?? 0,
                      ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.resultKills,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: FieldPalette.inkSoft,
                ),
              ),
              for (var t = 0; t < result.teamNames.length; t++)
                _ReportLine(
                  label: result.teamNames[t],
                  value: '${result.knockouts[t]}',
                  ink: Color(result.teamColors[t]),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StampButton(
              label: l10n.resultPlayAgain,
              minWidth: 150,
              fontSize: 16,
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => ArenaScreen(config: config),
                ),
              ),
            ),
            InkButton(
              label: l10n.resultChangeTeams,
              onPressed: () => Navigator.of(context).pop(),
            ),
            InkButton(
              label: l10n.resultMainMenu,
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
            ),
          ],
        ),
      ],
    );

    return Scaffold(
      body: PaperAtmosphere(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: report,
            ),
          ),
        ),
      ),
    );
  }
}

/// One line of the report: label, dot leaders, value.
class _ReportLine extends StatelessWidget {
  const _ReportLine({required this.label, required this.value, this.ink});

  final String label;
  final String value;
  final Color? ink;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (ink != null) ...[
          Container(width: 9, height: 9, color: ink),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '·························································',
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: TextStyle(color: FieldPalette.pencil),
            ),
          ),
        ),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    ),
  );
}
