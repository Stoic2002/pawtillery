import 'dart:math';

import '../config/cpu.dart';
import '../config/families.dart';
import '../config/map_objects.dart';
import '../config/maps.dart';
import '../config/match_defaults.dart';
import '../config/teams.dart';
import '../config/weapons.dart';
import '../sim/match_setup.dart';

/// One unit on the setup screen.
class UnitEntry {
  const UnitEntry({
    required this.familyId,
    required this.name,
  });

  final String familyId;
  final String name;

  UnitEntry copyWith({String? familyId, String? name}) => UnitEntry(
    familyId: familyId ?? this.familyId,
    name: name ?? this.name,
  );

  Map<String, Object?> toJson() => {'family': familyId, 'name': name};

  static UnitEntry? fromJson(Object? json) {
    if (json is! Map) return null;
    final family = json['family'];
    final name = json['name'];
    if (family is! String || name is! String) return null;
    try {
      Families.byId(family);
    } on ArgumentError {
      return null;
    }
    return UnitEntry(familyId: family, name: name);
  }
}

/// One team on the setup screen. [customName] null = the default name of
/// its colour ("Red Team" / "Tim Merah"). [cpu] null = played by a person.
class TeamEntry {
  const TeamEntry({
    required this.styleIndex,
    required this.units,
    this.customName,
    this.cpu,
  });

  final int styleIndex;
  final String? customName;
  final List<UnitEntry> units;

  /// The computer plays this team, at this level (hotseat only).
  final CpuLevel? cpu;

  TeamEntry copyWith({
    int? styleIndex,
    String? customName,
    bool clearName = false,
    List<UnitEntry>? units,
    CpuLevel? cpu,
    bool human = false,
  }) =>
      TeamEntry(
        styleIndex: styleIndex ?? this.styleIndex,
        customName: clearName ? null : (customName ?? this.customName),
        units: units ?? this.units,
        cpu: human ? null : (cpu ?? this.cpu),
      );

  Map<String, Object?> toJson() => {
        'style': styleIndex,
        'name': customName,
        'units': [for (final u in units) u.toJson()],
        'cpu': cpu?.name,
      };
}

/// Everything chosen on the setup screen; saved and restored between
/// launches (PRD: konfigurasi tim terakhir disimpan lokal).
class MatchConfig {
  const MatchConfig({
    required this.teams,
    required this.unitsPerTeam,
    required this.turnSeconds,
    required this.mapId,
    required this.suddenDeathMinutes,
    this.weapons = WeaponLoadout.standard,
    this.objects = ObjectAmount.few,
    this.randomWeapons = false,
  });

  /// [mapId] value meaning "pick one at random".
  static const randomMap = 'random';

  final List<TeamEntry> teams;
  final int unitsPerTeam;
  final int turnSeconds;
  final String mapId;
  final int? suddenDeathMinutes;

  /// Weapons on and their ammo (setup's Weapons tab).
  final WeaponLoadout weapons;

  /// Starter objects on the map (barrels, crates, mines).
  final ObjectAmount objects;

  /// Random weapons rule: one drawn weapon per turn.
  final bool randomWeapons;

  /// PRD defaults: 2 teams × 3 units, 45 s, random map, sudden death 15 min.
  factory MatchConfig.defaults(List<String> namePool) {
    const config = MatchConfig(
      teams: [],
      unitsPerTeam: MatchDefaults.unitsPerTeam,
      turnSeconds: MatchDefaults.turnSeconds,
      mapId: randomMap,
      suddenDeathMinutes: MatchDefaults.suddenDeathMinutes,
    );
    return config.withTeamCount(MatchDefaults.teamCount, namePool);
  }

  MatchConfig copyWith({
    List<TeamEntry>? teams,
    int? unitsPerTeam,
    int? turnSeconds,
    String? mapId,
    int? suddenDeathMinutes,
    bool suddenDeathOff = false,
    WeaponLoadout? weapons,
    ObjectAmount? objects,
    bool? randomWeapons,
  }) =>
      MatchConfig(
        teams: teams ?? this.teams,
        unitsPerTeam: unitsPerTeam ?? this.unitsPerTeam,
        turnSeconds: turnSeconds ?? this.turnSeconds,
        mapId: mapId ?? this.mapId,
        suddenDeathMinutes: suddenDeathOff
            ? null
            : (suddenDeathMinutes ?? this.suddenDeathMinutes),
        weapons: weapons ?? this.weapons,
        objects: objects ?? this.objects,
        randomWeapons: randomWeapons ?? this.randomWeapons,
      );

  /// Adds or removes teams; new teams get the first unused colour and
  /// default units.
  MatchConfig withTeamCount(int count, List<String> namePool) {
    final teams = [...this.teams.take(count)];
    while (teams.length < count) {
      final used = {for (final t in teams) t.styleIndex};
      final style = List.generate(Teams.styles.length, (i) => i)
          .firstWhere((i) => !used.contains(i));
      teams.add(TeamEntry(
        styleIndex: style,
        units: [
          for (var k = 0; k < unitsPerTeam; k++)
            _defaultUnit(teams.length * 4 + k, namePool),
        ],
      ));
    }
    return copyWith(teams: teams);
  }

  /// Same unit count for every team (PRD).
  MatchConfig withUnitsPerTeam(int count, List<String> namePool) {
    return copyWith(
      unitsPerTeam: count,
      teams: [
        for (var t = 0; t < teams.length; t++)
          teams[t].copyWith(units: [
            ...teams[t].units.take(count),
            for (var k = teams[t].units.length; k < count; k++)
              _defaultUnit(t * 4 + k, namePool),
          ]),
      ],
    );
  }

  /// Gives team [team] colour [style]; a team already using it swaps.
  MatchConfig withTeamStyle(int team, int style) {
    final teams = [...this.teams];
    final other = teams.indexWhere((t) => t.styleIndex == style);
    if (other >= 0 && other != team) {
      teams[other] = teams[other].copyWith(styleIndex: teams[team].styleIndex);
    }
    teams[team] = teams[team].copyWith(styleIndex: style);
    return copyWith(teams: teams);
  }

  MatchConfig withTeam(int team, TeamEntry entry) =>
      copyWith(teams: [...teams]..[team] = entry);

  /// Removes team [team] (setup's "Delete team"); at least two remain.
  MatchConfig withoutTeam(int team) => teams.length <= 2
      ? this
      : copyWith(teams: [...teams]..removeAt(team));

  /// Random family and name for every unit of one team.
  MatchConfig withRandomTeam(int team, Random rng, List<String> namePool) =>
      withTeam(
        team,
        teams[team].copyWith(units: [
          for (var k = 0; k < teams[team].units.length; k++)
            randomUnit(rng, namePool),
        ]),
      );

  /// The "Acak" button: random family and name for every unit.
  MatchConfig randomized(Random rng, List<String> namePool) => copyWith(
        teams: [
          for (final t in teams)
            t.copyWith(units: [
              for (var k = 0; k < t.units.length; k++)
                randomUnit(rng, namePool),
            ]),
        ],
      );

  static UnitEntry randomUnit(Random rng, List<String> namePool) {
    final family = Families.all[rng.nextInt(Families.all.length)];
    return UnitEntry(
      familyId: family.id,
      name: namePool.isEmpty ? '' : namePool[rng.nextInt(namePool.length)],
    );
  }

  /// Default unit #[i]: families in order, a name from the pool.
  static UnitEntry _defaultUnit(int i, List<String> namePool) {
    final family = Families.all[i % Families.all.length];
    return UnitEntry(
      familyId: family.id,
      name: namePool.isEmpty ? '' : namePool[i % namePool.length],
    );
  }

  /// The map to play: the chosen one, or a random one for [randomMap].
  MapDef resolveMap(Random rng) => mapId == randomMap
      ? Maps.all[rng.nextInt(Maps.all.length)]
      : Maps.byId(mapId);

  /// Level of each computer-controlled team, by team index.
  Map<int, CpuLevel> cpuTeams() => {
        for (var t = 0; t < teams.length; t++)
          t: ?teams[t].cpu,
      };

  /// Every team played by a person (Play on Wi-Fi has no CPU teams).
  MatchConfig withoutCpu() =>
      copyWith(teams: [for (final t in teams) t.copyWith(human: true)]);

  List<List<UnitSpec>> rosters() => [
        for (final t in teams)
          [
            for (final u in t.units)
              UnitSpec(familyId: u.familyId),
          ],
      ];

  Map<String, Object?> toJson() => {
        'teams': [for (final t in teams) t.toJson()],
        'unitsPerTeam': unitsPerTeam,
        'turnSeconds': turnSeconds,
        'map': mapId,
        'suddenDeath': suddenDeathMinutes,
        'weapons': weapons.toJson(),
        'objects': objects.name,
        'randomWeapons': randomWeapons,
      };

  /// Restores a saved config; anything invalid (old data)
  /// falls back to null so the caller can use the defaults.
  static MatchConfig? fromJson(Object? json, List<String> namePool) {
    if (json is! Map) return null;
    final teamsJson = json['teams'];
    final unitsPerTeam = json['unitsPerTeam'];
    final turnSeconds = json['turnSeconds'];
    final mapId = json['map'];
    final suddenDeath = json['suddenDeath'];
    if (teamsJson is! List ||
        unitsPerTeam is! int ||
        !MatchDefaults.unitsPerTeamOptions.contains(unitsPerTeam) ||
        !MatchDefaults.teamCountOptions.contains(teamsJson.length) ||
        turnSeconds is! int ||
        !MatchDefaults.turnSecondsOptions.contains(turnSeconds) ||
        mapId is! String ||
        (mapId != randomMap && !Maps.all.any((m) => m.id == mapId)) ||
        (suddenDeath != null && suddenDeath is! int) ||
        !MatchDefaults.suddenDeathOptions.contains(suddenDeath)) {
      return null;
    }
    final teams = <TeamEntry>[];
    final usedStyles = <int>{};
    for (final t in teamsJson) {
      if (t is! Map) return null;
      final style = t['style'];
      final name = t['name'];
      final units = t['units'];
      final cpu = t['cpu'];
      if (style is! int ||
          style < 0 ||
          style >= Teams.styles.length ||
          !usedStyles.add(style) ||
          (name != null && name is! String) ||
          (cpu != null && cpu is! String) ||
          units is! List ||
          units.length != unitsPerTeam) {
        return null;
      }
      final entries = [for (final u in units) UnitEntry.fromJson(u)];
      if (entries.contains(null)) return null;
      teams.add(TeamEntry(
        styleIndex: style,
        customName: name as String?,
        units: entries.cast<UnitEntry>(),
        // Saved before CPU teams existed (or an unknown level): a player.
        cpu: CpuLevel.values.asNameMap()[cpu],
      ));
    }
    return MatchConfig(
      teams: teams,
      unitsPerTeam: unitsPerTeam,
      turnSeconds: turnSeconds,
      mapId: mapId,
      suddenDeathMinutes: suddenDeath as int?,
      // Saved before the Weapons tab existed (or damaged): the standard set.
      weapons:
          WeaponLoadout.fromJson(json['weapons']) ?? WeaponLoadout.standard,
      // Saved before map objects existed: the default.
      objects: ObjectAmount.values.asNameMap()[json['objects']] ??
          ObjectAmount.few,
      randomWeapons: json['randomWeapons'] == true,
    );
  }
}
