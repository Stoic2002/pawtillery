import 'package:flutter/material.dart';

import '../../app/match_config.dart';
import '../../app/toon_palette.dart';
import '../../config/teams.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/toon/toon_backdrop.dart';
import '../widgets/toon/toon_button.dart';
import '../widgets/toon/toon_controls.dart';
import '../widgets/toon/toon_icons.dart';
import '../widgets/toon/toon_panel.dart';
import '../widgets/toon/toon_text.dart';
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
/// Utama): the winners cheer on the hill under a big banner in their
/// colour, with a stats card beside them. Sits where the arena was, so
/// "Change teams" is simply going back to the setup screen underneath.
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.result, required this.config});

  final MatchResult result;
  final MatchConfig config;

  static const _groundLine = 0.84;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final winner = result.winnerTeam;
    final topTeam = result.topUnitTeam;
    final winnerColor = winner == null
        ? ToonPalette.stoneDeep
        : Color(result.teamColors[winner]);
    final winners = winner == null || winner >= config.teams.length
        ? const <UnitEntry>[]
        : config.teams[winner].units;

    final stats = ToonPanel(
      title: l10n.resultReport.toUpperCase(),
      titleTone: ToonTone.sky,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.resultTurns(result.turns),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: ToonPalette.bark),
          ),
          const SizedBox(height: 8),
          Text(l10n.resultMostDamage, style: const TextStyle(fontSize: 15)),
          Text(
            topTeam == null
                ? l10n.resultNoDamage
                : l10n.resultMostDamageValue(
                    result.topUnitName ?? '',
                    result.teamNames[topTeam],
                    result.topDamage ?? 0,
                  ),
            style: const TextStyle(fontSize: 17, color: ToonPalette.tomatoDeep),
          ),
          const SizedBox(height: 10),
          Text(l10n.resultKills, style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 4),
          for (var t = 0; t < result.teamNames.length; t++)
            _KnockoutLine(
              name: result.teamNames[t],
              count: result.knockouts[t],
              color: Color(result.teamColors[t]),
            ),
        ],
      ),
    );

    final actions = Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        ToonButton(
          label: l10n.resultPlayAgain,
          icon: ToonGlyph.replay,
          fontSize: 18,
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => ArenaScreen(config: config),
            ),
          ),
        ),
        ToonButton(
          label: l10n.resultChangeTeams,
          icon: ToonGlyph.people,
          tone: ToonTone.sky,
          fontSize: 16,
          height: 46,
          onPressed: () => Navigator.of(context).pop(),
        ),
        ToonButton(
          label: l10n.resultMainMenu,
          icon: ToonGlyph.home,
          tone: ToonTone.sky,
          fontSize: 16,
          height: 46,
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ],
    );

    return Scaffold(
      body: ToonBackdrop(
        groundLine: _groundLine,
        child: LayoutBuilder(
          builder: (context, box) {
            final ground = box.maxHeight * _groundLine;
            final size = box.maxHeight * 0.27;
            return Stack(
              children: [
                for (final (i, u) in winners.indexed)
                  Positioned(
                    left: box.maxWidth * 0.06 +
                        i * size * 0.62 -
                        (i.isOdd ? 0 : size * 0.05),
                    top: ground - size * 0.94 - (i.isOdd ? size * 0.12 : 0),
                    child: AnimalFigure(
                      familyId: u.familyId,
                      breedId: u.breedId,
                      teamArgb: winner == null
                          ? Teams.styles.first.colorArgb
                          : result.teamColors[winner],
                      size: size,
                      facing: i.isEven ? 1 : -1,
                    ),
                  ),
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ToonIcon(
                              ToonGlyph.trophy,
                              size: 46,
                              color: winner == null
                                  ? ToonPalette.stone
                                  : ToonPalette.sun,
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: ToonText(
                                winner == null
                                    ? l10n.resultDraw.toUpperCase()
                                    : l10n
                                          .resultWinner(
                                            result.teamNames[winner],
                                          )
                                          .toUpperCase(),
                                size: 40,
                                color: winnerColor,
                                outlineWidth: 4,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: const Alignment(0.9, 0),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: Column(
                              children: [
                                stats,
                                const SizedBox(height: 14),
                                actions,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A team's knockouts: colour dot, name, count in a badge.
class _KnockoutLine extends StatelessWidget {
  const _KnockoutLine({
    required this.name,
    required this.count,
    required this.color,
  });

  final String name;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: ToonPalette.outline, width: 2.5),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 34),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: ToonPalette.outline, width: 2.5),
          ),
          child: ToonText('$count', size: 16),
        ),
      ],
    ),
  );
}
