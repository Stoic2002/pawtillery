import 'dart:convert';

import '../app/match_config.dart';
import '../config/net.dart';
import '../sim/inputs.dart';

/// Wire format for Play on Wi-Fi: one JSON object per line over TCP, with
/// the message type in `t`. Pure Dart, so it can be tested without sockets.
///
/// Flow: a guest sends [HelloMsg]; the host answers [WelcomeMsg] or
/// [RejectMsg] and from then on sends [LobbyMsg] whenever the lobby
/// changes. [StartMsg] begins a match; the active team's phone sends
/// [TicksMsg] (relayed by the host to everyone), guests send [HashMsg] to
/// the host, and the host announces [DesyncMsg], [PlayerLeftMsg] and
/// [EndMatchMsg]. [PingMsg] keeps quiet links alive.
sealed class NetMessage {
  const NetMessage();

  Map<String, Object?> toJson();
}

/// Guest → host, first message on a new connection.
final class HelloMsg extends NetMessage {
  const HelloMsg({
    required this.protocol,
    required this.appVersion,
    required this.name,
  });

  final int protocol;

  /// Different builds may have different balance, which would desync.
  final String appVersion;
  final String name;

  @override
  Map<String, Object?> toJson() => {
    't': 'hello',
    'v': protocol,
    'app': appVersion,
    'name': name,
  };
}

/// Host → guest: accepted, with the guest's player id.
final class WelcomeMsg extends NetMessage {
  const WelcomeMsg(this.playerId);
  final int playerId;

  @override
  Map<String, Object?> toJson() => {'t': 'welcome', 'id': playerId};
}

enum RejectReason { version, full, started }

/// Host → guest: not accepted; the host closes the connection.
final class RejectMsg extends NetMessage {
  const RejectMsg(this.reason);
  final RejectReason reason;

  @override
  Map<String, Object?> toJson() => {'t': 'reject', 'reason': reason.name};
}

class NetPlayer {
  const NetPlayer({required this.id, required this.name});

  /// 0 = the host.
  final int id;
  final String name;

  Map<String, Object?> toJson() => {'id': id, 'name': name};
}

/// Everything the lobby shows: who is in, the host's setup, and which
/// player controls each team ([owners] has one player id per team).
class LobbyState {
  const LobbyState({
    required this.players,
    required this.config,
    required this.owners,
  });

  final List<NetPlayer> players;
  final MatchConfig config;
  final List<int> owners;

  String nameOf(int playerId) {
    for (final p in players) {
      if (p.id == playerId) return p.name;
    }
    return '?';
  }

  LobbyState copyWith({
    List<NetPlayer>? players,
    MatchConfig? config,
    List<int>? owners,
  }) => LobbyState(
    players: players ?? this.players,
    config: config ?? this.config,
    owners: owners ?? this.owners,
  );
}

/// Host → everyone.
final class LobbyMsg extends NetMessage {
  const LobbyMsg(this.lobby);
  final LobbyState lobby;

  @override
  Map<String, Object?> toJson() => {
    't': 'lobby',
    'players': [for (final p in lobby.players) p.toJson()],
    'config': lobby.config.toJson(),
    'owners': lobby.owners,
  };
}

/// Host → everyone: the match begins. The host has already picked the map
/// (the random choice must not be made on each phone).
final class StartMsg extends NetMessage {
  const StartMsg({
    required this.seed,
    required this.mapId,
    required this.config,
    required this.owners,
    required this.players,
  });

  final int seed;
  final String mapId;
  final MatchConfig config;
  final List<int> owners;
  final List<NetPlayer> players;

  @override
  Map<String, Object?> toJson() => {
    't': 'start',
    'seed': seed,
    'map': mapId,
    'config': config.toJson(),
    'owners': owners,
    'players': [for (final p in players) p.toJson()],
  };
}

/// Inputs for consecutive ticks [from], [from] + 1, …, sent by the phone
/// that controls the active team. [end] = that phone stops after the last
/// of these ticks and the next team's phone takes over. Ticks without
/// inputs are left out of the JSON.
final class TicksMsg extends NetMessage {
  const TicksMsg({required this.from, required this.frames, this.end = false});

  final int from;
  final List<List<SimInput>> frames;
  final bool end;

  @override
  Map<String, Object?> toJson() => {
    't': 'ticks',
    'from': from,
    'n': frames.length,
    'in': [
      for (var i = 0; i < frames.length; i++)
        if (frames[i].isNotEmpty)
          [i, for (final x in frames[i]) encodeInput(x)],
    ],
    if (end) 'end': true,
  };
}

/// Guest → host: its state hash after [tick].
final class HashMsg extends NetMessage {
  const HashMsg({required this.tick, required this.hash});
  final int tick;
  final int hash;

  @override
  Map<String, Object?> toJson() => {'t': 'hash', 'tick': tick, 'h': hash};
}

/// Host → everyone: the hashes after [tick] did not match.
final class DesyncMsg extends NetMessage {
  const DesyncMsg(this.tick);
  final int tick;

  @override
  Map<String, Object?> toJson() => {'t': 'desync', 'tick': tick};
}

/// Host → everyone: a player's connection was lost. A guest also raises
/// this locally with id 0 when it loses the host.
final class PlayerLeftMsg extends NetMessage {
  const PlayerLeftMsg(this.playerId);
  final int playerId;

  @override
  Map<String, Object?> toJson() => {'t': 'left', 'id': playerId};
}

/// Host → everyone: the match was called off; back to the lobby.
final class EndMatchMsg extends NetMessage {
  const EndMatchMsg();

  @override
  Map<String, Object?> toJson() => {'t': 'end'};
}

final class PingMsg extends NetMessage {
  const PingMsg();

  @override
  Map<String, Object?> toJson() => {'t': 'ping'};
}

String encodeMessage(NetMessage m) => jsonEncode(m.toJson());

/// The message in [line], or null if it is not valid (unknown type, wrong
/// fields). Bad lines are dropped rather than closing the connection.
NetMessage? decodeMessage(String line) {
  try {
    final json = jsonDecode(line);
    if (json is! Map) return null;
    return _decode(json);
  } on FormatException {
    return null;
  } on TypeError {
    return null;
  } on ArgumentError {
    // Unknown enum name, index out of range.
    return null;
  }
}

NetMessage? _decode(Map json) {
  switch (json['t']) {
    case 'hello':
      return HelloMsg(
        protocol: json['v'] as int,
        appVersion: json['app'] as String,
        name: _name(json['name'] as String),
      );
    case 'welcome':
      return WelcomeMsg(json['id'] as int);
    case 'reject':
      return RejectMsg(RejectReason.values.byName(json['reason'] as String));
    case 'lobby':
      final config = _config(json['config']);
      final players = _players(json['players']);
      final owners = _owners(json['owners'], config);
      if (config == null || players == null || owners == null) return null;
      return LobbyMsg(
        LobbyState(players: players, config: config, owners: owners),
      );
    case 'start':
      final config = _config(json['config']);
      final players = _players(json['players']);
      final owners = _owners(json['owners'], config);
      if (config == null || players == null || owners == null) return null;
      return StartMsg(
        seed: json['seed'] as int,
        mapId: json['map'] as String,
        config: config,
        owners: owners,
        players: players,
      );
    case 'ticks':
      final n = json['n'] as int;
      if (n < 0 || n > 600) return null;
      final frames = List.generate(n, (_) => <SimInput>[]);
      for (final entry in json['in'] as List) {
        final e = entry as List;
        final i = e[0] as int;
        if (i < 0 || i >= n) return null;
        for (final x in e.skip(1)) {
          final input = decodeInput(x);
          if (input == null) return null;
          frames[i].add(input);
        }
      }
      return TicksMsg(
        from: json['from'] as int,
        frames: frames,
        end: json['end'] == true,
      );
    case 'hash':
      return HashMsg(tick: json['tick'] as int, hash: json['h'] as int);
    case 'desync':
      return DesyncMsg(json['tick'] as int);
    case 'left':
      return PlayerLeftMsg(json['id'] as int);
    case 'end':
      return const EndMatchMsg();
    case 'ping':
      return const PingMsg();
  }
  return null;
}

String _name(String raw) {
  final name = raw.trim();
  return name.length <= NetConfig.maxNameLength
      ? name
      : name.substring(0, NetConfig.maxNameLength);
}

MatchConfig? _config(Object? json) => MatchConfig.fromJson(json, const []);

List<NetPlayer>? _players(Object? json) {
  if (json is! List) return null;
  return [
    for (final p in json)
      NetPlayer(id: (p as Map)['id'] as int, name: _name(p['name'] as String)),
  ];
}

List<int>? _owners(Object? json, MatchConfig? config) {
  if (json is! List || config == null) return null;
  if (json.length != config.teams.length) return null;
  return [for (final o in json) o as int];
}

/// Inputs as short lists: [0, dir] walk, [1, kind] jump, [2, weapon,
/// angle, power, fuse, x, y] fire (nulls for unused fields).
Object encodeInput(SimInput input) => switch (input) {
  Walk(:final direction) => [0, direction],
  Jump(:final kind) => [1, kind.index],
  Fire() => [
    2,
    input.weaponId,
    input.angleDeg,
    input.powerPercent,
    input.fuseTicks,
    input.targetX,
    input.targetY,
  ],
};

SimInput? decodeInput(Object? json) {
  if (json is! List || json.isEmpty) return null;
  switch (json[0]) {
    case 0 when json.length == 2 && (json[1] == -1 || json[1] == 1):
      return Walk(json[1] as int);
    case 1 when json.length == 2:
      final k = json[1];
      if (k is! int || k < 0 || k >= JumpKind.values.length) return null;
      return Jump(JumpKind.values[k]);
    case 2 when json.length == 7:
      return Fire(
        weaponId: json[1] as String,
        angleDeg: json[2] as int,
        powerPercent: json[3] as int,
        fuseTicks: json[4] as int?,
        targetX: json[5] as int?,
        targetY: json[6] as int?,
      );
  }
  return null;
}

/// UDP beacon a host sends while its lobby is open. Not part of the TCP
/// stream; [encodeBeacon] marks it with the game's name so other traffic
/// on the port is ignored.
class RoomBeacon {
  const RoomBeacon({
    required this.protocol,
    required this.appVersion,
    required this.room,
    required this.name,
    required this.port,
    required this.players,
    required this.open,
  });

  final int protocol;
  final String appVersion;

  /// Random id of this room, so one host heard on two addresses (Wi-Fi and
  /// loopback) is listed once.
  final int room;

  /// The host player's name.
  final String name;

  /// TCP port to connect to.
  final int port;
  final int players;

  /// False while a match is running or the room is full.
  final bool open;
}

String encodeBeacon(RoomBeacon b) => jsonEncode({
  'pawtillery': b.protocol,
  'app': b.appVersion,
  'room': b.room,
  'name': b.name,
  'port': b.port,
  'players': b.players,
  'open': b.open,
});

RoomBeacon? decodeBeacon(String text) {
  try {
    final json = jsonDecode(text);
    if (json is! Map || json['pawtillery'] is! int) return null;
    return RoomBeacon(
      protocol: json['pawtillery'] as int,
      appVersion: json['app'] as String,
      room: json['room'] as int,
      name: _name(json['name'] as String),
      port: json['port'] as int,
      players: json['players'] as int,
      open: json['open'] as bool,
    );
  } on FormatException {
    return null;
  } on TypeError {
    return null;
  } on ArgumentError {
    // Unknown enum name, index out of range.
    return null;
  }
}
