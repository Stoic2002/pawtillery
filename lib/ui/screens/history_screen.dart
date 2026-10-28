import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../app/match_history.dart';
import '../../app/paw_palette.dart';
import '../../config/cpu.dart';
import '../../config/maps.dart';
import '../../config/teams.dart';
import '../../config/weapons.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_lookup.g.dart';
import '../hud/weapon_menu.dart' show WeaponIcon;
import '../widgets/paw/paw_backdrop.dart';
import '../widgets/paw/paw_widgets.dart';

/// Match history (kept on this phone only): a card of totals on the left
/// (matches, wins and losses against each CPU level, favourite weapon,
/// biggest hit) and the latest matches on the right.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = AppServices.of(context).settings;
    return Scaffold(
      body: PawBackdrop(
        clouds: false,
        child: SafeArea(
          child: ListenableBuilder(
            listenable: settings,
            builder: (context, _) {
              final history = settings.history;
              final totals = settings.historyTotals;
              return Column(
                children: [
                  PawHeader(
                    title: l10n.menuHistory,
                    backLabel: l10n.back,
                    trailing: totals.matches == 0
                        ? null
                        : PawButton(
                            label: l10n.historyClear,
                            icon: Icons.delete_rounded,
                            height: 44,
                            fontSize: 14,
                            shadow: 3,
                            padding: 14,
                            onPressed: () async {
                              if (await showPawConfirm(
                                context: context,
                                title: l10n.historyClearTitle,
                                body: l10n.historyClearBody,
                                ok: l10n.historyClear,
                                cancel: l10n.dialogCancel,
                              )) {
                                settings.clearHistory();
                              }
                            },
                          ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 6, 24, 16),
                      child: totals.matches == 0
                          ? Center(
                              child: PawCard(
                                child: Text(
                                  l10n.historyEmpty,
                                  style: Paw.text(16),
                                ),
                              ),
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  width: 270,
                                  child: _Totals(totals: totals),
                                ),
                                const SizedBox(width: 14),
                                Expanded(child: _Matches(history: history)),
                              ],
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

String cpuLevelLabel(AppLocalizations l10n, CpuLevel level) =>
    switch (level) {
      CpuLevel.easy => l10n.setupCpuEasy,
      CpuLevel.normal => l10n.setupCpuNormal,
      CpuLevel.hard => l10n.setupCpuHard,
    };

class _Totals extends StatelessWidget {
  const _Totals({required this.totals});
  final HistoryTotals totals;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final favorite = totals.favoriteWeapon;
    final levels = [
      for (final level in CpuLevel.values)
        if ((totals.cpuWins[level] ?? 0) + (totals.cpuLosses[level] ?? 0) > 0)
          level,
    ];
    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 2),
      child: Text(text, style: Paw.text(12, weight: 700, color: Paw.muted)),
    );
    return PawCard(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: ListView(
        children: [
          label(l10n.historyMatches),
          Text('${totals.matches}', style: Paw.title(28, height: 1)),
          if (levels.isNotEmpty) ...[
            label(l10n.historyVsCpu),
            for (final level in levels)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.smart_toy_rounded,
                        size: 18, color: Paw.ink),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        cpuLevelLabel(l10n, level),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Paw.text(13),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        l10n.historyWinLoss(
                          totals.cpuWins[level] ?? 0,
                          totals.cpuLosses[level] ?? 0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Paw.text(13, weight: 700),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (favorite != null) ...[
            label(l10n.historyFavorite),
            Row(
              children: [
                WeaponIcon(weapon: Weapons.byId(favorite), size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.byKey(Weapons.byId(favorite).nameKey),
                    style: Paw.text(14),
                  ),
                ),
              ],
            ),
          ],
          if (totals.bestHit case final hit?) ...[
            label(l10n.historyBestHit),
            Text(
              l10n.historyBestHitValue(hit, totals.bestHitBy ?? ''),
              style: Paw.text(14),
            ),
          ],
        ],
      ),
    );
  }
}

class _Matches extends StatelessWidget {
  const _Matches({required this.history});
  final List<MatchRecord> history;

  @override
  Widget build(BuildContext context) => PawCard(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: ListView.separated(
      itemCount: history.length,
      separatorBuilder: (_, _) => const Divider(color: Paw.line, height: 1),
      itemBuilder: (context, i) => _MatchRow(record: history[i]),
    ),
  );
}

class _MatchRow extends StatelessWidget {
  const _MatchRow({required this.record});
  final MatchRecord record;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final material = MaterialLocalizations.of(context);
    final at = record.playedAt;
    final when =
        '${material.formatShortDate(at)} · '
        '${material.formatTimeOfDay(TimeOfDay.fromDateTime(at), alwaysUse24HourFormat: true)}';
    final map = Maps.all.where((m) => m.id == record.mapId).firstOrNull;
    final details = [
      when,
      if (map != null) l10n.byKey(map.nameKey),
      l10n.historyTurns(record.turns),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (record.wifi)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(Icons.wifi_rounded, size: 16, color: Paw.muted),
                ),
              if (record.randomWeapons)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(Icons.casino_rounded, size: 16, color: Paw.muted),
                ),
              Expanded(
                child: Text(
                  details,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Paw.text(12, weight: 700, color: Paw.muted),
                ),
              ),
              if (record.winnerTeam == null)
                Flexible(
                  child: Text(
                    l10n.resultDraw,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Paw.text(12, weight: 700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: [
              for (final (i, t) in record.teams.indexed)
                _TeamChip(team: t, won: record.winnerTeam == i),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeamChip extends StatelessWidget {
  const _TeamChip({required this.team, required this.won});
  final TeamRecord team;
  final bool won;

  @override
  Widget build(BuildContext context) {
    final style = Teams.styles[team.styleIndex.clamp(0, Teams.styles.length - 1)];
    return Container(
      padding: const EdgeInsets.fromLTRB(3, 3, 10, 3),
      decoration: BoxDecoration(
        color: won ? Paw.yellow : Paw.peachLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Paw.ink, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TeamBadge(
            color: Color(style.colorArgb),
            symbol: style.symbol,
            size: 22,
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              team.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Paw.text(13),
            ),
          ),
          if (team.cpu != null) ...[
            const SizedBox(width: 4),
            const Icon(Icons.smart_toy_rounded, size: 16, color: Paw.ink),
          ],
          if (won) ...[
            const SizedBox(width: 4),
            const Icon(Icons.emoji_events_rounded, size: 16, color: Paw.ink),
          ],
        ],
      ),
    );
  }
}
