import 'lan_api.dart';
import 'link.dart';
import 'protocol.dart';

/// No sockets on this platform (web).
bool get lanSupported => false;

Future<LanServer> startLanServer() => throw UnsupportedError('No sockets');

Future<LanBeacon> startBeacon(RoomBeacon beacon) =>
    throw UnsupportedError('No sockets');

Future<LanDiscovery> startDiscovery() => throw UnsupportedError('No sockets');

Future<NetLink> connectLan(String host, int port) =>
    throw UnsupportedError('No sockets');

Future<List<String>> localAddresses() async => const [];
