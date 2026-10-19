import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config/net.dart';
import 'lan_api.dart';
import 'link.dart';
import 'protocol.dart';

bool get lanSupported => true;

/// JSON lines over a TCP socket, with a heartbeat: it pings when it has
/// sent nothing for [NetConfig.heartbeat] and closes after hearing
/// nothing for [NetConfig.peerTimeout] (a phone that walked out of Wi-Fi
/// range never sends a FIN).
class SocketLink implements NetLink {
  SocketLink(this._socket) {
    _socket.setOption(SocketOption.tcpNoDelay, true);
    utf8.decoder
        .bind(_socket)
        .transform(const LineSplitter())
        .listen(_onLine, onError: (Object _) => close(), onDone: close);
    _socket.done.then((_) {}, onError: (Object _) => close());
    _timer = Timer.periodic(NetConfig.heartbeat, (_) => _beat());
  }

  final Socket _socket;
  final _in = StreamController<NetMessage>();
  late final Timer _timer;
  final _sinceSent = Stopwatch()..start();
  final _sinceHeard = Stopwatch()..start();
  bool _closed = false;

  @override
  Stream<NetMessage> get messages => _in.stream;

  void _onLine(String line) {
    _sinceHeard.reset();
    final m = decodeMessage(line);
    if (m != null && m is! PingMsg) _in.add(m);
  }

  void _beat() {
    if (_sinceHeard.elapsed > NetConfig.peerTimeout) {
      close();
    } else if (_sinceSent.elapsed >= NetConfig.heartbeat) {
      send(const PingMsg());
    }
  }

  @override
  void send(NetMessage message) {
    if (_closed) return;
    _sinceSent.reset();
    try {
      _socket.write('${encodeMessage(message)}\n');
    } on Object {
      close();
    }
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _timer.cancel();
    try {
      // Flush what was sent (a reject, the last frames), but don't hang on
      // a peer that is gone.
      await _socket.close().timeout(const Duration(seconds: 1));
    } on Object {
      // Already broken.
    }
    _socket.destroy();
    await _in.close();
  }
}

Future<LanServer> startLanServer() async {
  ServerSocket server;
  try {
    server = await ServerSocket.bind(
      InternetAddress.anyIPv4,
      NetConfig.gamePort,
    );
  } on SocketException {
    // Taken (a second copy of the game on this machine): any free port;
    // the beacon tells guests which.
    server = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
  }
  return _IoServer(server);
}

class _IoServer implements LanServer {
  _IoServer(this._server);
  final ServerSocket _server;

  @override
  int get port => _server.port;

  @override
  late final Stream<NetLink> connections = _server.map(SocketLink.new);

  @override
  Future<void> close() => _server.close();
}

Future<LanBeacon> startBeacon(RoomBeacon beacon) async {
  final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  socket.broadcastEnabled = true;
  return _IoBeacon(socket, beacon).._start();
}

class _IoBeacon implements LanBeacon {
  _IoBeacon(this._socket, this._beacon);

  final RawDatagramSocket _socket;
  RoomBeacon _beacon;
  Timer? _timer;
  List<InternetAddress> _targets = [InternetAddress('255.255.255.255')];
  int _beats = 0;

  void _start() {
    _send();
    _timer = Timer.periodic(NetConfig.beaconInterval, (_) => _send());
  }

  @override
  void update(RoomBeacon beacon) {
    _beacon = beacon;
    _send();
  }

  /// To the limited broadcast address, each interface's /24 broadcast
  /// address (a phone hotspot often doesn't route 255.255.255.255 onto its
  /// own network; Dart doesn't expose netmasks, and phones and home
  /// routers use /24) and loopback (a second copy on this machine).
  Future<void> _refreshTargets() async {
    final targets = {
      InternetAddress('255.255.255.255'),
      InternetAddress.loopbackIPv4,
    };
    try {
      for (final ni in await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      )) {
        for (final a in ni.addresses) {
          final b = a.rawAddress;
          targets.add(InternetAddress('${b[0]}.${b[1]}.${b[2]}.255'));
        }
      }
    } on SocketException {
      // Keep the basic targets.
    }
    _targets = targets.toList();
  }

  void _send() {
    if (_beats++ % 5 == 0) _refreshTargets();
    final bytes = utf8.encode(encodeBeacon(_beacon));
    for (final t in _targets) {
      try {
        _socket.send(bytes, t, NetConfig.discoveryPort);
      } on SocketException {
        // That network is unreachable right now.
      }
    }
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    _socket.close();
  }
}

Future<LanDiscovery> startDiscovery() async {
  RawDatagramSocket socket;
  try {
    socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      NetConfig.discoveryPort,
      reusePort: true,
    );
  } on Object {
    socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      NetConfig.discoveryPort,
    );
  }
  return _IoDiscovery(socket);
}

class _IoDiscovery implements LanDiscovery {
  _IoDiscovery(this._socket) {
    _socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      final d = _socket.receive();
      if (d == null) return;
      final beacon = decodeBeacon(utf8.decode(d.data, allowMalformed: true));
      if (beacon == null) return;
      final known = _rooms[beacon.room];
      // One host heard over Wi-Fi and loopback: keep the Wi-Fi address.
      final address = known != null && d.address.isLoopback
          ? known.address
          : d.address.address;
      _rooms[beacon.room] = FoundRoom(
        address: address,
        beacon: beacon,
        lastSeen: DateTime.now(),
      );
      _emit();
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final cutoff = DateTime.now().subtract(NetConfig.roomTimeout);
      final before = _rooms.length;
      _rooms.removeWhere((_, r) => r.lastSeen.isBefore(cutoff));
      if (_rooms.length != before) _emit();
    });
  }

  final RawDatagramSocket _socket;
  late final Timer _timer;
  final Map<int, FoundRoom> _rooms = {};
  final _out = StreamController<List<FoundRoom>>.broadcast();

  void _emit() => _out.add(List.unmodifiable(_rooms.values));

  @override
  Stream<List<FoundRoom>> get rooms => _out.stream;

  @override
  Future<void> close() async {
    _timer.cancel();
    _socket.close();
    await _out.close();
  }
}

Future<NetLink> connectLan(String host, int port) async {
  final socket = await Socket.connect(
    host,
    port,
    timeout: NetConfig.connectTimeout,
  );
  return SocketLink(socket);
}

/// This phone's IPv4 addresses, shown in the lobby for joining by hand.
Future<List<String>> localAddresses() async {
  try {
    return [
      for (final ni in await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      ))
        for (final a in ni.addresses) a.address,
    ];
  } on SocketException {
    return const [];
  }
}
