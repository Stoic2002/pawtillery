import 'link.dart';
import 'protocol.dart';

/// A room heard on the network.
class FoundRoom {
  const FoundRoom({
    required this.address,
    required this.beacon,
    required this.lastSeen,
  });

  final String address;
  final RoomBeacon beacon;
  final DateTime lastSeen;
}

/// The host's TCP listener.
abstract class LanServer {
  int get port;

  /// One link per guest that connects.
  Stream<NetLink> get connections;

  Future<void> close();
}

/// Sends the room beacon every [NetConfig.beaconInterval].
abstract class LanBeacon {
  void update(RoomBeacon beacon);

  Future<void> close();
}

/// Listens for room beacons.
abstract class LanDiscovery {
  /// The rooms currently heard, newest list on every change.
  Stream<List<FoundRoom>> get rooms;

  Future<void> close();
}
