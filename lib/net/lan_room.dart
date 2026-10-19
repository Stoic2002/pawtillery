import 'dart:async';
import 'dart:math';

import '../config/net.dart';
import 'lan.dart';
import 'protocol.dart';
import 'session.dart';

/// A [HostSession] on the local network: accepts guests on a TCP port and
/// announces the room with a beacon while it is open.
class LanRoom {
  LanRoom._(this.session, this._server, this._room);

  final HostSession session;
  final LanServer _server;
  final int _room;
  LanBeacon? _beacon;
  StreamSubscription<void>? _accept;

  int get port => _server.port;

  static Future<LanRoom> open(HostSession session) async {
    final server = await startLanServer();
    final room = LanRoom._(session, server, Random().nextInt(1 << 30));
    room._accept = server.connections.listen(session.addConnection);
    room._beacon = await startBeacon(room._beaconInfo());
    session.addListener(room._onChanged);
    return room;
  }

  RoomBeacon _beaconInfo() => RoomBeacon(
    protocol: NetConfig.protocolVersion,
    appVersion: session.appVersion,
    room: _room,
    name: session.lobby.players.first.name,
    port: _server.port,
    players: session.lobby.players.length,
    open: !session.inMatch && !session.isFull,
  );

  void _onChanged() => _beacon?.update(_beaconInfo());

  Future<void> close() async {
    session.removeListener(_onChanged);
    await _accept?.cancel();
    await _beacon?.close();
    await _server.close();
    await session.leave();
  }
}
