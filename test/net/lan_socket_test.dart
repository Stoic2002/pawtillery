import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/app/match_config.dart';
import 'package:pawtillery/net/lan.dart';
import 'package:pawtillery/net/lan_room.dart';
import 'package:pawtillery/net/session.dart';

import 'net_harness.dart';

const _names = ['Bolu', 'Kopi', 'Mochi', 'Tahu'];

/// Real sockets on this machine: the guest finds the room by its beacon
/// (sent to loopback too), joins over TCP and plays a match to the end.
void main() {
  test(
    'find a room on localhost, join and play to the end',
    () async {
      final discovery = await startDiscovery();
      final config = MatchConfig.defaults(_names).withUnitsPerTeam(2, _names);
      final host = HostSession(name: 'Arul', config: config);
      final room = await LanRoom.open(host);
      addTearDown(room.close);
      addTearDown(discovery.close);

      final found = await discovery.rooms
          .expand((rooms) => rooms)
          .firstWhere((r) => r.beacon.port == room.port)
          .timeout(const Duration(seconds: 5));
      expect(found.beacon.name, 'Arul');
      expect(found.beacon.open, isTrue);

      final link = await connectLan('127.0.0.1', found.beacon.port);
      final guest = await GuestSession.join(link, name: 'Sari');
      addTearDown(guest.leave);
      expect(guest.myId, 1);
      expect(guest.lobby.nameOf(0), 'Arul');
      while (host.lobby.players.length < 2) {
        await pump();
      }
      expect(host.lobby.owners, [0, 1]);

      host.startMatch(random: Random(3));
      while (guest.match == null) {
        await pump();
      }
      final phones = [
        TestPhone(host, host.match!, lag: 0),
        TestPhone(guest, guest.match!, lag: 0.2),
      ];
      await playAll(phones);
      expectSame(phones);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
