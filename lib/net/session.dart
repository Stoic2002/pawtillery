import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../app/match_config.dart';
import '../config/app_info.dart';
import '../config/net.dart';
import 'link.dart';
import 'protocol.dart';

/// One phone's side of a Play on Wi-Fi room: the lobby it shows and the
/// messages of the running match. [HostSession] owns the room and relays;
/// [GuestSession] talks to the host only. Transport-agnostic: links come
/// from sockets on a phone and from memory in tests.
abstract class NetSession extends ChangeNotifier {
  int get myId;
  bool get isHost;
  LobbyState get lobby;

  /// The match being played, set when it starts; the lobby screen opens
  /// the arena when this changes.
  StartMsg? get match => _match;
  StartMsg? _match;

  bool get inMatch => _inMatch;
  bool _inMatch = false;

  /// Guest: the connection to the host is gone.
  bool get hostLost => false;

  void Function(NetMessage message)? _sink;
  final List<NetMessage> _backlog = [];

  /// Routes match messages (ticks, desync, player left, end) to the arena.
  /// Messages that arrived before it attached are delivered first.
  void attachMatch(void Function(NetMessage message) sink) {
    _sink = sink;
    final waiting = List.of(_backlog);
    _backlog.clear();
    waiting.forEach(sink);
  }

  void detachMatch() => _sink = null;

  void _deliver(NetMessage message) {
    final sink = _sink;
    if (sink == null) {
      _backlog.add(message);
    } else {
      sink(message);
    }
  }

  void _beginMatch(StartMsg start) {
    _backlog.clear();
    _match = start;
    _inMatch = true;
    notifyListeners();
  }

  /// Frames this phone produced (it controls the active team).
  void sendTicks(TicksMsg message);

  /// This phone's state hash after [tick].
  void sendHash(int tick, int hash);

  /// The match on this phone reached its result.
  void matchFinished() {
    if (!_inMatch) return;
    _inMatch = false;
    notifyListeners();
  }

  Future<void> leave();
}

class HostSession extends NetSession {
  HostSession({
    required String name,
    required MatchConfig config,
    this.appVersion = AppInfo.version,
  }) : _lobby = LobbyState(
         players: [NetPlayer(id: 0, name: name)],
         config: config,
         owners: List.filled(config.teams.length, 0),
       );

  final String appVersion;

  @override
  int get myId => 0;
  @override
  bool get isHost => true;

  LobbyState _lobby;
  @override
  LobbyState get lobby => _lobby;

  final Map<int, NetLink> _guests = {};
  int _nextId = 1;
  bool _closed = false;

  /// Hashes after a tick: this phone's, and guests' not yet compared.
  final Map<int, int> _myHashes = {};
  final Map<int, List<int>> _guestHashes = {};
  bool _desynced = false;

  bool get isFull => _lobby.players.length >= NetConfig.maxPlayers;

  /// A guest's connection; it is admitted once it says hello.
  void addConnection(NetLink link) {
    if (_closed) {
      link.close();
      return;
    }
    int? id;
    final timeout = Timer(NetConfig.connectTimeout, () {
      if (id == null) link.close();
    });
    link.messages.listen(
      (m) {
        final playerId = id;
        if (playerId != null) {
          _onGuestMessage(playerId, m);
          return;
        }
        if (m is! HelloMsg) return;
        timeout.cancel();
        final reason =
            m.protocol != NetConfig.protocolVersion ||
                m.appVersion != appVersion
            ? RejectReason.version
            : _inMatch
            ? RejectReason.started
            : isFull
            ? RejectReason.full
            : null;
        if (reason != null) {
          link
            ..send(RejectMsg(reason))
            ..close();
          return;
        }
        final newId = id = _nextId++;
        _guests[newId] = link;
        final name = m.name.isEmpty ? 'P${newId + 1}' : m.name;
        link.send(WelcomeMsg(newId));
        _setLobby(
          _lobby.copyWith(
            players: [
              ..._lobby.players,
              NetPlayer(id: newId, name: name),
            ],
          ),
          redistribute: true,
        );
      },
      onDone: () {
        timeout.cancel();
        final playerId = id;
        if (playerId != null) _onGuestGone(playerId);
      },
    );
  }

  void _onGuestMessage(int playerId, NetMessage m) {
    switch (m) {
      case TicksMsg():
        if (!_inMatch) return;
        _broadcast(m, except: playerId);
        _deliver(m);
      case HashMsg(:final tick, :final hash):
        if (!_inMatch) return;
        _guestHashes.putIfAbsent(tick, () => []).add(hash);
        _compare(tick);
      default:
        break;
    }
  }

  void _onGuestGone(int playerId) {
    if (_guests.remove(playerId) == null || _closed) return;
    final players = [
      for (final p in _lobby.players)
        if (p.id != playerId) p,
    ];
    if (_inMatch) {
      // Owners stay as they are: the match is paused until the host ends
      // it, and the lobby fixes them afterwards.
      final msg = PlayerLeftMsg(playerId);
      _broadcast(msg);
      _deliver(msg);
      _setLobby(_lobby.copyWith(players: players));
    } else {
      _setLobby(_lobby.copyWith(players: players), redistribute: true);
    }
  }

  /// Setup changed (host's Setup screen). Teams keep their controller;
  /// new teams are shared out.
  void updateConfig(MatchConfig config) {
    if (_inMatch) return;
    final owners = [
      for (var t = 0; t < config.teams.length; t++)
        t < _lobby.owners.length
            ? _lobby.owners[t]
            : _lobby.players[t % _lobby.players.length].id,
    ];
    _setLobby(_lobby.copyWith(config: config, owners: owners));
  }

  /// Gives team [team] to player [playerId].
  void setOwner(int team, int playerId) {
    if (_inMatch || !_lobby.players.any((p) => p.id == playerId)) return;
    _setLobby(_lobby.copyWith(owners: [..._lobby.owners]..[team] = playerId));
  }

  /// Teams in turn to each player: with 2 players and 2 teams, one each.
  static List<int> _shareOut(int teams, List<NetPlayer> players) => [
    for (var t = 0; t < teams; t++) players[t % players.length].id,
  ];

  void _setLobby(LobbyState lobby, {bool redistribute = false}) {
    _lobby = redistribute
        ? lobby.copyWith(
            owners: _shareOut(lobby.config.teams.length, lobby.players),
          )
        : lobby;
    _broadcast(LobbyMsg(_lobby));
    notifyListeners();
  }

  /// Everyone may start once at least one guest is in.
  bool get canStart => !_inMatch && _lobby.players.length >= 2;

  void startMatch({Random? random}) {
    if (!canStart) return;
    final rng = random ?? Random();
    final seed = rng.nextInt(1 << 31);
    final start = StartMsg(
      seed: seed,
      mapId: _lobby.config.resolveMap(rng).id,
      config: _lobby.config,
      owners: _lobby.owners,
      players: _lobby.players,
    );
    _myHashes.clear();
    _guestHashes.clear();
    _desynced = false;
    _broadcast(start);
    _beginMatch(start);
  }

  /// Calls the match off for everyone (after a player left).
  void endMatch() {
    if (!_inMatch) return;
    const end = EndMatchMsg();
    _broadcast(end);
    _deliver(end);
    _backToLobby();
  }

  @override
  void matchFinished() {
    if (_inMatch) _backToLobby();
  }

  void _backToLobby() {
    _inMatch = false;
    final ids = {for (final p in _lobby.players) p.id};
    _setLobby(_lobby, redistribute: _lobby.owners.any((o) => !ids.contains(o)));
  }

  @override
  void sendTicks(TicksMsg message) => _broadcast(message);

  @override
  void sendHash(int tick, int hash) {
    _myHashes[tick] = hash;
    _myHashes.removeWhere((t, _) => t < tick - 3600);
    _compare(tick);
  }

  void _compare(int tick) {
    final mine = _myHashes[tick];
    if (mine == null || _desynced) return;
    final theirs = _guestHashes.remove(tick);
    if (theirs == null || theirs.every((h) => h == mine)) return;
    _desynced = true;
    final msg = DesyncMsg(tick);
    _broadcast(msg);
    _deliver(msg);
  }

  void _broadcast(NetMessage m, {int? except}) {
    for (final MapEntry(:key, :value) in _guests.entries) {
      if (key != except) value.send(m);
    }
  }

  @override
  Future<void> leave() async {
    _closed = true;
    final links = List.of(_guests.values);
    _guests.clear();
    await Future.wait([for (final l in links) l.close()]);
  }
}

/// The host turned a guest away.
class JoinRejected implements Exception {
  const JoinRejected(this.reason);
  final RejectReason reason;
}

class GuestSession extends NetSession {
  GuestSession._(this._link);

  final NetLink _link;
  late int _myId;
  LobbyState? _lobby;
  bool _hostLost = false;
  bool _left = false;

  final _joined = Completer<void>();

  @override
  int get myId => _myId;
  @override
  bool get isHost => false;
  @override
  LobbyState get lobby => _lobby!;
  @override
  bool get hostLost => _hostLost;

  /// Says hello on [link] and waits to be let in (welcome plus the first
  /// lobby). Throws [JoinRejected] or [TimeoutException]; the link is
  /// closed on failure.
  static Future<GuestSession> join(
    NetLink link, {
    required String name,
    String appVersion = AppInfo.version,
  }) async {
    final session = GuestSession._(link);
    link.messages.listen(session._onMessage, onDone: session._onDone);
    link.send(
      HelloMsg(
        protocol: NetConfig.protocolVersion,
        appVersion: appVersion,
        name: name,
      ),
    );
    try {
      await session._joined.future.timeout(NetConfig.connectTimeout);
    } catch (_) {
      session._left = true;
      await link.close();
      rethrow;
    }
    return session;
  }

  bool _welcomed = false;

  void _onMessage(NetMessage m) {
    switch (m) {
      case WelcomeMsg(:final playerId):
        _myId = playerId;
        _welcomed = true;
      case RejectMsg(:final reason):
        if (!_joined.isCompleted) _joined.completeError(JoinRejected(reason));
      case LobbyMsg(:final lobby):
        _lobby = lobby;
        if (_welcomed && !_joined.isCompleted) _joined.complete();
        notifyListeners();
      case StartMsg():
        _beginMatch(m);
      case TicksMsg() || DesyncMsg() || PlayerLeftMsg():
        if (_inMatch) _deliver(m);
      case EndMatchMsg():
        if (!_inMatch) return;
        _deliver(m);
        _inMatch = false;
        notifyListeners();
      case HelloMsg() || HashMsg() || PingMsg():
        break;
    }
  }

  void _onDone() {
    if (!_joined.isCompleted) {
      _joined.completeError(TimeoutException('Host closed the connection'));
    }
    if (_left) return;
    _hostLost = true;
    if (_inMatch) _deliver(const PlayerLeftMsg(0));
    notifyListeners();
  }

  @override
  void sendTicks(TicksMsg message) => _link.send(message);

  @override
  void sendHash(int tick, int hash) =>
      _link.send(HashMsg(tick: tick, hash: hash));

  @override
  Future<void> leave() async {
    _left = true;
    await _link.close();
  }
}
