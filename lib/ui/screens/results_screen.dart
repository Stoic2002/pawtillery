import 'package:flutter/material.dart';

import '../../app/match_config.dart';
import '../../app/paw_palette.dart';
import '../../config/teams.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/paw/paw_widgets.dart';
import '../widgets/paw/pet_figure.dart';
import 'arena_screen.dart';

/// What the results screen shows; computed when the match ends.
class MatchResult {
  const MatchResult({
    required this.winnerTeam,
    required this.teamNames,
    required this.teamColors,
    required this.knockouts,
    required this.turns,
    this.teamSymbols = const [],
    this.teamDamage = const [],
    this.unitsLeft = const [],
    this.topUnitName,
    this.topUnitTeam,
    this.topDamage,
  });

  /// null = draw.
  final int? winnerTeam;
  final List<String> teamNames;
  final List<int> teamColors;
  final List<TeamSymbol> teamSymbols;
  final List<int> knockouts;

  /// Enemy damage dealt, per team.
  final List<int> teamDamage;

  /// Units still standing, per team.
  final List<int> unitsLeft;
  final int turns;
  final String? topUnitName;
  final int? topUnitTeam;
  final int? topDamage;

  TeamSymbol symbol(int team) =>
      team < teamSymbols.length ? teamSymbols[team] : TeamSymbol.circle;
}

/// Results (PRD: Hasil — tim pemenang, statistik singkat, Main Lagi, Menu
/// Utama; redesign prototype): the winner's colour fills the screen with
/// confetti, the winning pets stand on a podium under the title, and a
/// stats card, the best shot and the buttons sit on the right. Sits where
/// the arena was, so "Change teams" is simply going back to the setup
/// screen underneath.
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.result, required this.config});

  final MatchResult result;
  final MatchConfig config;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final winner = result.winnerTeam;
    final teams = result.teamNames.length;
    final pets = winner == null || winner >= config.teams.length
        ? const <UnitEntry>[]
        : config.teams[winner].units;

    int at(List<int> list, int i) => i < list.length ? list[i] : 0;

    final title = Stack(
      children: [
        for (final paint in [
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 8
            ..strokeJoin = StrokeJoin.round
            ..color = Paw.ink,
        ])
          Transform.translate(
            offset: const Offset(0, 5),
            child: Text(
              winner == null
                  ? l10n.resultDrawTitle
                  : l10n.resultWinner(result.teamNames[winner]),
              textAlign: TextAlign.center,
              style: Paw.title(
                44,
                weight: 800,
                height: 1.05,
              ).copyWith(foreground: paint),
            ),
          ),
        Text(
          winner == null
              ? l10n.resultDrawTitle
              : l10n.resultWinner(result.teamNames[winner]),
          textAlign: TextAlign.center,
          style: Paw.title(44, weight: 800, height: 1.05).copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 8
              ..strokeJoin = StrokeJoin.round
              ..color = Paw.ink,
          ),
        ),
        Text(
          winner == null
              ? l10n.resultDrawTitle
              : l10n.resultWinner(result.teamNames[winner]),
          textAlign: TextAlign.center,
          style: Paw.title(44, weight: 800, height: 1.05, color: Colors.white),
        ),
      ],
    );

    final podium = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.translate(
          offset: const Offset(0, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final (i, u) in pets.indexed)
                PetFigure(
                  familyId: u.familyId,
                  breedId: u.breedId,
                  teamArgb: result.teamColors[winner!],
                  size: 64,
                  flip: i.isOdd,
                ),
            ],
          ),
        ),
        Container(
          width: 250,
          height: 58,
          decoration: BoxDecoration(
            color: Paw.cream,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
              bottom: Radius.circular(6),
            ),
            border: Border.all(color: Paw.ink, width: 3),
            boxShadow: Paw.drop(5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final t
                  in winner == null ? List.generate(teams, (i) => i) : [winner])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: TeamBadge(
                    color: Color(result.teamColors[t]),
                    symbol: result.symbol(t),
                    size: 30,
                  ),
                ),
              const SizedBox(width: 4),
              Text('1', style: Paw.title(28, weight: 800)),
            ],
          ),
        ),
      ],
    );

    Widget statRow(List<Widget> cells, {bool header = false}) => SizedBox(
      height: header ? 26 : 34,
      child: Row(
        children: [
          Expanded(child: cells[0]),
          for (final (i, w) in [62.0, 72.0, 52.0].indexed)
            SizedBox(
              width: w,
              child: Align(
                alignment: Alignment.centerRight,
                child: cells[i + 1],
              ),
            ),
        ],
      ),
    );
    final head = Paw.text(12, color: Paw.muted);
    final number = Paw.title(18, weight: 800);
    final stats = PawCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          statRow(header: true, [
            const SizedBox(),
            Text(l10n.resultColumnDamage, style: head),
            Text(l10n.resultColumnKnockouts, style: head),
            Text(l10n.resultColumnLeft, style: head),
          ]),
          const Divider(height: 2, thickness: 2, color: Paw.peach),
          for (var t = 0; t < teams; t++)
            statRow([
              Row(
                children: [
                  TeamBadge(
                    color: Color(result.teamColors[t]),
                    symbol: result.symbol(t),
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      result.teamNames[t],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Paw.text(14),
                    ),
                  ),
                ],
              ),
              Text('${at(result.teamDamage, t)}', style: number),
              Text('${at(result.knockouts, t)}', style: number),
              Text('${at(result.unitsLeft, t)}', style: number),
            ]),
        ],
      ),
    );

    final topTeam = result.topUnitTeam;
    final best = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Paw.peach,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Paw.ink, width: 3),
        boxShadow: Paw.drop(),
      ),
      child: Row(
        children: [
          const PawIconChip(Icons.star_rounded, fill: Paw.yellow, size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.resultBestShot,
                  style: Paw.text(12, color: Paw.muted),
                ),
                Text(
                  topTeam == null
                      ? l10n.resultNoDamage
                      : l10n.resultBestShotValue(
                          result.topUnitName ?? '',
                          result.topDamage ?? 0,
                        ),
                  style: Paw.text(15),
                ),
                Text(
                  l10n.resultTurns(result.turns),
                  style: Paw.text(12, weight: 700, color: Paw.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final buttons = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PawButton(
          label: l10n.resultPlayAgain,
          icon: Icons.replay_rounded,
          fill: Paw.orange,
          display: true,
          fontSize: 22,
          height: 56,
          borderWidth: 3,
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => ArenaScreen(config: config),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: PawButton(
                label: l10n.resultChangeTeams,
                height: 48,
                fontSize: 14,
                expand: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PawButton(
                label: l10n.resultMainMenu,
                height: 48,
                fontSize: 14,
                expand: true,
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ),
          ],
        ),
      ],
    );

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: winner == null ? null : Color(result.teamColors[winner]),
          gradient: winner == null
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Paw.skyTop, Paw.skyBottom],
                )
              : null,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const CustomPaint(painter: _ConfettiPainter()),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [title, const SizedBox(height: 12), podium],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            stats,
                            const SizedBox(height: 10),
                            best,
                            const SizedBox(height: 10),
                            buttons,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Outlined confetti scattered over the background (static).
class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter();

  static const _colors = [
    Paw.orange,
    Paw.yellow,
    Paw.green,
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Paw.cream,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Paw.ink;
    for (var i = 0; i < 26; i++) {
      final x = ((i * 41) % 100) / 100 * size.width;
      final y = ((i * 0.137 * 7) % 1) * size.height;
      final r = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 9, height: 14),
        const Radius.circular(3),
      );
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(i * 0.7)
        ..drawRRect(r, Paint()..color = _colors[i % _colors.length])
        ..drawRRect(r, edge)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => false;
}
