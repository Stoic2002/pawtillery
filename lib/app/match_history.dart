import '../config/cpu.dart';

/// One team in a finished match.
class TeamRecord {
  const TeamRecord({
    required this.name,
    required this.styleIndex,
    required this.damage,
    required this.knockouts,
    required this.unitsLeft,
    this.cpu,
  });

  final String name;
  final int styleIndex;

  /// Played by the computer at this level; null = a person.
  final CpuLevel? cpu;

  /// Enemy damage dealt.
  final int damage;
  final int knockouts;
  final int unitsLeft;

  Map<String, Object?> toJson() => {
    'name': name,
    'style': styleIndex,
    'cpu': cpu?.name,
    'damage': damage,
    'ko': knockouts,
    'left': unitsLeft,
  };

  static TeamRecord? fromJson(Object? json) {
    if (json is! Map) return null;
    final name = json['name'];
    final style = json['style'];
    final damage = json['damage'];
    final ko = json['ko'];
    final left = json['left'];
    if (name is! String ||
        style is! int ||
        damage is! int ||
        ko is! int ||
        left is! int) {
      return null;
    }
    return TeamRecord(
      name: name,
      styleIndex: style,
      cpu: CpuLevel.values.asNameMap()[json['cpu']],
      damage: damage,
      knockouts: ko,
      unitsLeft: left,
    );
  }
}

/// A finished match, as kept in the history (on this phone only).
class MatchRecord {
  const MatchRecord({
    required this.playedAt,
    required this.mapId,
    required this.teams,
    required this.winnerTeam,
    required this.turns,
    this.wifi = false,
    this.randomWeapons = false,
    this.topUnitName,
    this.topDamage,
  });

  final DateTime playedAt;
  final String mapId;
  final List<TeamRecord> teams;

  /// null = draw.
  final int? winnerTeam;
  final int turns;
  final bool wifi;
  final bool randomWeapons;
  final String? topUnitName;
  final int? topDamage;

  /// The highest CPU level in the match, or null with no CPU team.
  CpuLevel? get cpuLevel {
    CpuLevel? best;
    for (final t in teams) {
      final c = t.cpu;
      if (c != null && (best == null || c.index > best.index)) best = c;
    }
    return best;
  }

  /// Whether a team played by a person won (null without CPU teams or
  /// people: nothing to count against the CPU).
  bool? get peopleBeatCpu {
    if (cpuLevel == null || teams.every((t) => t.cpu != null)) return null;
    final w = winnerTeam;
    return w != null && teams[w].cpu == null;
  }

  Map<String, Object?> toJson() => {
    'at': playedAt.toIso8601String(),
    'map': mapId,
    'teams': [for (final t in teams) t.toJson()],
    'winner': winnerTeam,
    'turns': turns,
    'wifi': wifi,
    'random': randomWeapons,
    'topName': topUnitName,
    'topDamage': topDamage,
  };

  static MatchRecord? fromJson(Object? json) {
    if (json is! Map) return null;
    final at = DateTime.tryParse('${json['at']}');
    final map = json['map'];
    final teamsJson = json['teams'];
    final winner = json['winner'];
    final turns = json['turns'];
    if (at == null ||
        map is! String ||
        teamsJson is! List ||
        (winner != null && winner is! int) ||
        turns is! int) {
      return null;
    }
    final teams = [for (final t in teamsJson) TeamRecord.fromJson(t)];
    if (teams.contains(null) || teams.length < 2) return null;
    if (winner is int && (winner < 0 || winner >= teams.length)) return null;
    final topName = json['topName'];
    final topDamage = json['topDamage'];
    return MatchRecord(
      playedAt: at,
      mapId: map,
      teams: teams.cast<TeamRecord>(),
      winnerTeam: winner as int?,
      turns: turns,
      wifi: json['wifi'] == true,
      randomWeapons: json['random'] == true,
      topUnitName: topName is String ? topName : null,
      topDamage: topDamage is int ? topDamage : null,
    );
  }
}

/// Totals over every match ever recorded, kept apart from the (capped)
/// list so they never shrink.
class HistoryTotals {
  const HistoryTotals({
    this.matches = 0,
    this.cpuWins = const {},
    this.cpuLosses = const {},
    this.weaponUses = const {},
    this.bestHit,
    this.bestHitBy,
  });

  final int matches;

  /// Matches people won / lost against the CPU, by its (highest) level.
  final Map<CpuLevel, int> cpuWins;
  final Map<CpuLevel, int> cpuLosses;

  /// How often people used each weapon.
  final Map<String, int> weaponUses;

  /// Biggest single hit by a person's pet, and that pet's name.
  final int? bestHit;
  final String? bestHitBy;

  /// The weapon people use most, other than the everyday rock and skip.
  String? get favoriteWeapon {
    String? best;
    var most = 0;
    for (final MapEntry(:key, :value) in weaponUses.entries) {
      if (key == 'rock' || key == 'skip') continue;
      if (value > most) (best, most) = (key, value);
    }
    return best;
  }

  /// [record] added; [uses] are the weapons people used in it and [hit]
  /// their biggest single hit.
  HistoryTotals add(
    MatchRecord record, {
    Map<String, int> uses = const {},
    (int, String)? hit,
  }) {
    final level = record.cpuLevel;
    final beat = record.peopleBeatCpu;
    final best = bestHit;
    final newBest = hit != null && (best == null || hit.$1 > best);
    return HistoryTotals(
      matches: matches + 1,
      cpuWins: beat == true && level != null ? _inc(cpuWins, level) : cpuWins,
      cpuLosses: beat == false && level != null
          ? _inc(cpuLosses, level)
          : cpuLosses,
      weaponUses: {
        ...weaponUses,
        for (final MapEntry(:key, :value) in uses.entries)
          key: (weaponUses[key] ?? 0) + value,
      },
      bestHit: newBest ? hit.$1 : bestHit,
      bestHitBy: newBest ? hit.$2 : bestHitBy,
    );
  }

  static Map<CpuLevel, int> _inc(Map<CpuLevel, int> m, CpuLevel k) => {
    ...m,
    k: (m[k] ?? 0) + 1,
  };

  Map<String, Object?> toJson() => {
    'matches': matches,
    'cpuWins': {for (final e in cpuWins.entries) e.key.name: e.value},
    'cpuLosses': {for (final e in cpuLosses.entries) e.key.name: e.value},
    'weapons': weaponUses,
    'bestHit': bestHit,
    'bestHitBy': bestHitBy,
  };

  static HistoryTotals fromJson(Object? json) {
    if (json is! Map) return const HistoryTotals();
    Map<CpuLevel, int> levels(Object? m) => {
      if (m is Map)
        for (final e in m.entries)
          if (CpuLevel.values.asNameMap()[e.key] case final level?)
            if (e.value case final int n) level: n,
    };
    final weapons = json['weapons'];
    final matches = json['matches'];
    final bestHit = json['bestHit'];
    final bestHitBy = json['bestHitBy'];
    return HistoryTotals(
      matches: matches is int ? matches : 0,
      cpuWins: levels(json['cpuWins']),
      cpuLosses: levels(json['cpuLosses']),
      weaponUses: {
        if (weapons is Map)
          for (final e in weapons.entries)
            if (e.key case final String k)
              if (e.value case final int n) k: n,
      },
      bestHit: bestHit is int ? bestHit : null,
      bestHitBy: bestHitBy is String ? bestHitBy : null,
    );
  }
}
