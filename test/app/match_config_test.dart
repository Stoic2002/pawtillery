import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/app/match_config.dart';
import 'package:pawtillery/config/breeds.dart';
import 'package:pawtillery/config/match_defaults.dart';
import 'package:pawtillery/services/settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _names = ['Milo', 'Luna', 'Bobo', 'Kiki', 'Coco'];

void main() {
  test('defaults follow the PRD', () {
    final c = MatchConfig.defaults(_names);
    expect(c.teams, hasLength(MatchDefaults.teamCount));
    expect(c.unitsPerTeam, 3);
    expect(c.turnSeconds, 45);
    expect(c.mapId, MatchConfig.randomMap);
    expect(c.suddenDeathMinutes, 15);
    expect(c.teams.map((t) => t.styleIndex), [0, 1]);
    expect(c.teams.every((t) => t.units.length == 3), isTrue);
  });

  test('changing team and unit counts keeps existing choices', () {
    var c = MatchConfig.defaults(_names);
    final first = c.teams[0].units[0];
    c = c.withTeamCount(4, _names).withUnitsPerTeam(1, _names);
    expect(c.teams, hasLength(4));
    expect(c.teams.map((t) => t.styleIndex).toSet(), hasLength(4));
    expect(c.teams.every((t) => t.units.length == 1), isTrue);
    expect(c.teams[0].units[0].familyId, first.familyId);
    c = c.withTeamCount(2, _names).withUnitsPerTeam(4, _names);
    expect(c.teams, hasLength(2));
    expect(c.teams[0].units, hasLength(4));
  });

  test('picking a colour another team uses swaps them', () {
    final c = MatchConfig.defaults(_names).withTeamStyle(0, 1);
    expect(c.teams.map((t) => t.styleIndex), [1, 0]);
  });

  test('random fill always gives a breed of the chosen family', () {
    final rng = Random(1);
    var c = MatchConfig.defaults(_names).withTeamCount(4, _names);
    for (var i = 0; i < 50; i++) {
      c = c.randomized(rng, _names);
      for (final u in c.teams.expand((t) => t.units)) {
        expect(Breeds.byId(u.breedId).familyId, u.familyId);
        expect(_names, contains(u.name));
      }
    }
  });

  test('changing a unit family resets its breed to that family', () {
    final u = MatchConfig.defaults(_names).teams[0].units[0];
    final v = u.copyWith(familyId: 'goat');
    expect(Breeds.byId(v.breedId).familyId, 'goat');
  });

  test('round-trips through JSON; rejects broken data', () {
    final c = MatchConfig.defaults(_names)
        .withTeamCount(3, _names)
        .randomized(Random(3), _names)
        .copyWith(mapId: 'park', turnSeconds: 60, suddenDeathOff: true);
    final back = MatchConfig.fromJson(
        jsonDecode(jsonEncode(c.toJson())), _names)!;
    expect(jsonEncode(back.toJson()), jsonEncode(c.toJson()));

    final broken = c.toJson()..['map'] = 'nowhere';
    expect(MatchConfig.fromJson(broken, _names), isNull);
    expect(MatchConfig.fromJson('nonsense', _names), isNull);
  });

  test('settings and last setup persist', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await SettingsStore.load();
    expect(store.languageCode, isNull);
    expect(store.showAimGuide, isTrue);
    store
      ..languageCode = 'id'
      ..haptics = false
      ..musicVolume = 0.25;
    final c = MatchConfig.defaults(_names).copyWith(turnSeconds: 30);
    await store.saveMatch(c);

    final again = await SettingsStore.load();
    expect(again.languageCode, 'id');
    expect(again.haptics, isFalse);
    expect(again.musicVolume, 0.25);
    expect(again.lastMatch(_names)!.turnSeconds, 30);
  });
}
