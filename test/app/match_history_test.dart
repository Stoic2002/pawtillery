import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/app/match_history.dart';
import 'package:pawtillery/config/cpu.dart';
import 'package:pawtillery/services/settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

MatchRecord _match({int? winner = 0, CpuLevel? cpu = CpuLevel.normal, int day = 1}) =>
    MatchRecord(
      playedAt: DateTime(2026, 10, day),
      mapId: 'backyard',
      teams: [
        const TeamRecord(
            name: 'Red', styleIndex: 0, damage: 150, knockouts: 3, unitsLeft: 2),
        TeamRecord(
            name: 'Blue',
            styleIndex: 1,
            cpu: cpu,
            damage: 90,
            knockouts: 1,
            unitsLeft: 0),
      ],
      winnerTeam: winner,
      turns: 24,
      topUnitName: 'Milo',
      topDamage: 88,
    );

void main() {
  test('a match survives a JSON round trip', () {
    final m = _match();
    final back = MatchRecord.fromJson(jsonDecode(jsonEncode(m.toJson())))!;
    expect(back.playedAt, m.playedAt);
    expect(back.mapId, 'backyard');
    expect(back.teams[1].cpu, CpuLevel.normal);
    expect(back.teams[0].damage, 150);
    expect(back.winnerTeam, 0);
    expect(back.topUnitName, 'Milo');
    expect(MatchRecord.fromJson({'map': 'x'}), isNull);
  });

  test('totals count wins and losses against the CPU by level', () {
    var t = const HistoryTotals();
    t = t.add(_match(winner: 0)); // people won
    t = t.add(_match(winner: 1)); // the CPU won
    t = t.add(_match(winner: null)); // a draw counts as a loss
    t = t.add(_match(cpu: null)); // no CPU: not counted against it
    expect(t.matches, 4);
    expect(t.cpuWins, {CpuLevel.normal: 1});
    expect(t.cpuLosses, {CpuLevel.normal: 2});
  });

  test('favourite weapon skips the rock, biggest hit keeps the record', () {
    var t = const HistoryTotals();
    t = t.add(_match(), uses: {'rock': 20, 'grenade': 3}, hit: (40, 'Luna'));
    t = t.add(_match(), uses: {'miniNuke': 2, 'grenade': 1}, hit: (30, 'Kiki'));
    expect(t.favoriteWeapon, 'grenade');
    expect((t.bestHit, t.bestHitBy), (40, 'Luna'));
    final back = HistoryTotals.fromJson(jsonDecode(jsonEncode(t.toJson())));
    expect(back.weaponUses, t.weaponUses);
    expect(back.bestHitBy, 'Luna');
  });

  test('the history keeps the newest matches, the totals keep counting',
      () async {
    SharedPreferences.setMockInitialValues({});
    final s = await SettingsStore.load();
    for (var i = 0; i < SettingsStore.historyLength + 5; i++) {
      s.recordMatch(_match(day: 1 + i % 28));
    }
    expect(s.history, hasLength(SettingsStore.historyLength));
    expect(s.historyTotals.matches, SettingsStore.historyLength + 5);
    s.recordMatch(_match(day: 28, winner: 1));
    expect(s.history.first.winnerTeam, 1);

    s.clearHistory();
    await Future<void>.delayed(Duration.zero);
    expect(s.history, isEmpty);
    expect(s.historyTotals.matches, 0);
  });
}
