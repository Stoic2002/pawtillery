import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../app/match_config.dart';
import '../config/app_info.dart';
import '../config/net.dart';
import '../sim/inputs.dart';
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

  /// Every tick's inputs of the running match, as sent and received, and
  /// whether its last producer had stopped: what a rejoining phone needs.
  final List<List<SimInput>> _log = [];
  bool _logEnd = true;

  /// Ticks of the running match this phone has inputs for.
  int get knownTicks => _log.length;

  void _record(TicksMsg m) {
    if (m.from != _log.length + 1) return;
    _log.addAll(m.frames);
    _logEnd = m.end;
  }

  /// What a phone that has [known] ticks is missing from this one: the
  /// later ticks, or at the same count a hand-over it may not have heard
  /// (a stopped producer only ever stops once per count, so "stopped"
  /// wins).
  List<TicksMsg> _missingAfter(int known) =>
      known < _log.length || (known == _log.length && _logEnd)
      ? _logFrom(known + 1)
      : const [];

  /// Ticks [from] onwards out of the log, a few hundred per message (the
  /// decoder's limit), the last one carrying the hand-over state; just
  /// that state if there are none.
  List<TicksMsg> _logFrom(int from) {
    const chunk = 500;
    if (from > _log.length) {
      return [TicksMsg(from: from, frames: const [], end: _logEnd)];
    }
    return [
      for (var i = from; i <= _log.length; i += chunk)
        TicksMsg(
          from: i,
          frames: _log.sublist(i - 1, min(_log.length, i - 1 + chunk)),
          end: i - 1 + chunk >= _log.length && _logEnd,
        ),
    ];
  }

  void _beginMatch(StartMsg start) {
    _backlog.clear();
    _log.clear();
    _logEnd = true;
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

  /// Each guest's key for rejoining a match, and the guests whose
  /// connection was lost mid-match (their slot waits for them).
  final Map<int, int> _keys = {};
  final Set<int> _away = {};
  final _keyRng = Random();

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
        if (m is RejoinMsg) {
          timeout.cancel();
          if (_canRejoin(m, link)) id = m.playerId;
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
        final key = _keys[newId] = _keyRng.nextInt(1 << 31);
        link.send(WelcomeMsg(newId, key: key));
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

  /// A guest coming back mid-match: let it in if its slot is waiting and
  /// the key fits, send it what it missed, and tell everyone.
  bool _canRejoin(RejoinMsg m, NetLink link) {
    final id = m.playerId;
    if (m.protocol != NetConfig.protocolVersion ||
        m.appVersion != appVersion ||
        !_inMatch ||
        !_away.contains(id) ||
        _keys[id] != m.key) {
      // Not (yet) known as gone: the guest tries again shortly.
      link
        ..send(const RejectMsg(RejectReason.started))
        ..close();
      return false;
    }
    _away.remove(id);
    _guests[id] = link;
    // After a restart the guest knows nothing of the match yet.
    if (m.fresh) link.send(_match!);
    link
      ..send(WelcomeMsg(id, key: m.key))
      ..send(LobbyMsg(_lobby));
    // What it missed comes before the resume, so a guest back from a
    // restart has the whole match so far the moment it is let in. The
    // guest may instead have ticks the host never got; it sends those.
    (m.fresh ? _logFrom(1) : _missingAfter(m.known)).forEach(link.send);
    link.send(ResumeMsg(_log.length));
    for (final other in _away) {
      link.send(PlayerLeftMsg(other));
    }
    final back = PlayerBackMsg(id);
    _broadcast(back);
    _deliver(back);
    notifyListeners();
    return true;
  }

  void _onGuestMessage(int playerId, NetMessage m) {
    switch (m) {
      case TicksMsg():
        if (!_inMatch) return;
        _record(m);
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
      // The match pauses and the slot waits for the guest to rejoin (or
      // the host to end the match); the lobby drops it afterwards.
      _away.add(playerId);
      final msg = PlayerLeftMsg(playerId);
      _broadcast(msg);
      _deliver(msg);
      notifyListeners();
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
    final gone = Set.of(_away);
    _away.clear();
    _keys.removeWhere((id, _) => gone.contains(id));
    final players = [
      for (final p in _lobby.players)
        if (!gone.contains(p.id)) p,
    ];
    final ids = {for (final p in players) p.id};
    _setLobby(
      _lobby.copyWith(players: players),
      redistribute: _lobby.owners.any((o) => !ids.contains(o)),
    );
  }

  @override
  void sendTicks(TicksMsg message) {
    _record(message);
    _broadcast(message);
  }

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
  GuestSession._(
    this._link,
    this._redial,
    this._appVersion,
    this._retry,
    this._onTicket,
  );

  /// Told this phone's player id and key when a match starts (keep them to
  /// rejoin after a restart), and id -1 when it is over or left.
  final void Function(int playerId, int key)? _onTicket;
  void _dropTicket() => _onTicket?.call(-1, 0);

  NetLink _link;
  late int _myId;
  int _key = 0;
  LobbyState? _lobby;
  bool _hostLost = false;
  bool _left = false;

  /// Opens a new connection to the host, to rejoin after losing it.
  final Future<NetLink> Function()? _redial;
  final String _appVersion;
  final Duration _retry;
  bool _reconnecting = false;
  Completer<bool>? _resumed;

  /// Lost the host mid-match and trying to rejoin.
  bool get reconnecting => _reconnecting;

  /// Came back to the match after the app was closed ([rejoin]).
  bool get rejoinedFresh => _rejoinedFresh;
  bool _rejoinedFresh = false;

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
  ///
  /// With [redial], a connection lost mid-match is reopened (every
  /// [rejoinRetry], for up to [NetConfig.rejoinWindow]) to rejoin it.
  static Future<GuestSession> join(
    NetLink link, {
    required String name,
    String appVersion = AppInfo.version,
    Future<NetLink> Function()? redial,
    Duration rejoinRetry = NetConfig.rejoinRetry,
    void Function(int playerId, int key)? onTicket,
  }) async {
    final session =
        GuestSession._(link, redial, appVersion, rejoinRetry, onTicket);
    session._listen(link);
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

  /// Comes back to a match after the app was closed: player [playerId]
  /// with [key] (from the ticket kept when it started). On success the
  /// match is set and every tick so far is on its way; throws
  /// [JoinRejected] if the host no longer waits for this player.
  static Future<GuestSession> rejoin(
    NetLink link, {
    required int playerId,
    required int key,
    String appVersion = AppInfo.version,
    Future<NetLink> Function()? redial,
    Duration rejoinRetry = NetConfig.rejoinRetry,
    void Function(int playerId, int key)? onTicket,
  }) async {
    final session =
        GuestSession._(link, redial, appVersion, rejoinRetry, onTicket)
          .._myId = playerId
          .._key = key;
    final resumed = session._resumed = Completer<bool>();
    // A refusal answers [resumed]; nobody waits on the first join here.
    session._joined.future.ignore();
    session._listen(link);
    link.send(
      RejoinMsg(
        protocol: NetConfig.protocolVersion,
        appVersion: appVersion,
        playerId: playerId,
        key: key,
        known: 0,
        fresh: true,
      ),
    );
    final ok = await resumed.future.timeout(
      NetConfig.connectTimeout,
      onTimeout: () => false,
    );
    if (!ok || session._match == null) {
      session._left = true;
      await link.close();
      throw const JoinRejected(RejectReason.started);
    }
    if (!session._joined.isCompleted) session._joined.complete();
    session._rejoinedFresh = true;
    return session;
  }

  bool _welcomed = false;

  void _listen(NetLink link) =>
      link.messages.listen(_onMessage, onDone: () => _onDone(link));

  void _onMessage(NetMessage m) {
    switch (m) {
      case WelcomeMsg(:final playerId, :final key):
        _myId = playerId;
        _key = key;
        _welcomed = true;
      case RejectMsg(:final reason):
        if (!_joined.isCompleted) _joined.completeError(JoinRejected(reason));
        _resumed?.complete(false);
        _resumed = null;
      case ResumeMsg(:final known):
        // Ticks this phone played that never reached the host.
        _missingAfter(known).forEach(_link.send);
        _resumed?.complete(true);
        _resumed = null;
      case LobbyMsg(:final lobby):
        _lobby = lobby;
        if (_welcomed && !_joined.isCompleted) _joined.complete();
        notifyListeners();
      case StartMsg():
        _beginMatch(m);
        _onTicket?.call(_myId, _key);
      case TicksMsg():
        if (!_inMatch) return;
        _record(m);
        _deliver(m);
      case DesyncMsg() || PlayerLeftMsg() || PlayerBackMsg():
        if (_inMatch) _deliver(m);
      case EndMatchMsg():
        if (!_inMatch) return;
        _deliver(m);
        _inMatch = false;
        _dropTicket();
        notifyListeners();
      case HelloMsg() || RejoinMsg() || HashMsg() || PingMsg():
        break;
    }
  }

  void _onDone(NetLink link) {
    // An old connection, or a rejoin attempt that failed.
    if (!identical(link, _link) || _reconnecting) return;
    if (!_joined.isCompleted) {
      _joined.completeError(TimeoutException('Host closed the connection'));
    }
    if (_left) return;
    if (_inMatch && _redial != null) {
      _reconnect();
      return;
    }
    _loseHost();
  }

  void _loseHost() {
    _hostLost = true;
    _dropTicket();
    if (_inMatch) _deliver(const PlayerLeftMsg(0));
    notifyListeners();
  }

  /// Lost the host mid-match: the arena pauses ("reconnecting", raised
  /// here as this phone leaving) while new connections try to rejoin.
  Future<void> _reconnect() async {
    _reconnecting = true;
    _deliver(PlayerLeftMsg(_myId));
    notifyListeners();
    final until = DateTime.now().add(NetConfig.rejoinWindow);
    while (!_left && _inMatch && DateTime.now().isBefore(until)) {
      await Future<void>.delayed(_retry);
      if (_left || !_inMatch) break;
      NetLink? link;
      try {
        link = await _redial!().timeout(NetConfig.connectTimeout);
        final resumed = _resumed = Completer<bool>();
        _link = link;
        _listen(link);
        link.send(
          RejoinMsg(
            protocol: NetConfig.protocolVersion,
            appVersion: _appVersion,
            playerId: _myId,
            key: _key,
            known: _log.length,
          ),
        );
        if (await resumed.future.timeout(
          NetConfig.connectTimeout,
          onTimeout: () => false,
        )) {
          _reconnecting = false;
          notifyListeners();
          return;
        }
      } on Object {
        // No host there yet; try again.
      }
      _resumed = null;
      await link?.close();
    }
    _reconnecting = false;
    if (!_left) _loseHost();
  }

  @override
  void sendTicks(TicksMsg message) {
    _record(message);
    _link.send(message);
  }

  @override
  void sendHash(int tick, int hash) =>
      _link.send(HashMsg(tick: tick, hash: hash));

  @override
  void matchFinished() {
    _dropTicket();
    super.matchFinished();
  }

  @override
  Future<void> leave() async {
    _left = true;
    _dropTicket();
    await _link.close();
  }
}
