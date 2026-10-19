import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/app/match_config.dart';
import 'package:pawtillery/config/net.dart';
import 'package:pawtillery/net/link.dart';
import 'package:pawtillery/net/protocol.dart';
import 'package:pawtillery/net/session.dart';

import 'net_harness.dart';

const _names = ['Bolu', 'Kopi', 'Mochi', 'Tahu'];

Future<List<TestPhone>> _room(int guests, int Function(int) owners) async {
  final config = MatchConfig.defaults(
    _names,
  ).withTeamCount(max(2, guests + 1), _names).withUnitsPerTeam(2, _names);
  final host = HostSession(name: 'Host', config: config);
  final guestSessions = <GuestSession>[];
  for (var g = 0; g < guests; g++) {
    final (a, b) = MemoryLink.pair();
    host.addConnection(a);
    guestSessions.add(await GuestSession.join(b, name: 'G$g'));
  }
  await pump();
  for (var t = 0; t < host.lobby.config.teams.length; t++) {
    host.setOwner(t, owners(t));
  }
  host.startMatch(random: Random(99));
  await pump();
  for (final g in guestSessions) {
    expect(g.match, isNotNull);
    expect(g.match!.seed, host.match!.seed);
    expect(g.match!.owners, host.match!.owners);
  }
  return [
    TestPhone(host, host.match!, lag: 0),
    for (final g in guestSessions) TestPhone(g, g.match!, lag: 0.3),
  ];
}

void main() {
  test('two phones, one team each, end the match with equal hashes', () async {
    final phones = await _room(1, (t) => t);
    await playAll(phones);
    expectSame(phones);
    // Both phones really produced inputs (walking, jumping, firing).
    final damaged = phones.first.world.units.where((u) => u.hp < 100);
    expect(damaged, isNotEmpty);
  });

  test('three phones; the host owns two teams and the hand-over skips '
      'between them', () async {
    // Teams: host, guest 1, host, guest 2.
    final phones = await _room(3, (t) => const [0, 1, 0, 2][t]);
    // Three guests joined but only two own a team: one watches.
    await playAll(phones);
    expectSame(phones);
  });

  test('a different state is reported as desync to everyone', () async {
    final phones = await _room(1, (t) => t);
    // Corrupt the guest's world: one unit stands a pixel to the left.
    phones[1].world.units.last.x -= 1;
    for (var f = 0; f < 400; f++) {
      for (final p in phones) {
        p.frame(Random(f));
      }
      await pump();
      if (phones.every((p) => p.desynced)) break;
    }
    expect(phones.every((p) => p.desynced), isTrue);
  });

  test('turned away: wrong version, full room, match running', () async {
    final config = MatchConfig.defaults(_names);
    final host = HostSession(name: 'Host', config: config);
    Future<Object?> tryJoin({String version = '1.0.0'}) async {
      final (a, b) = MemoryLink.pair();
      host.addConnection(a);
      try {
        await GuestSession.join(b, name: 'X', appVersion: version);
        return null;
      } on JoinRejected catch (e) {
        return e.reason;
      }
    }

    final hostVersion = host.appVersion;
    expect(await tryJoin(version: '0.0.1'), RejectReason.version);
    for (var i = 0; i < 3; i++) {
      expect(await tryJoin(version: hostVersion), isNull);
    }
    expect(host.lobby.players.length, NetConfig.maxPlayers);
    expect(await tryJoin(version: hostVersion), RejectReason.full);

    final small = HostSession(name: 'H', config: config);
    final (a, b) = MemoryLink.pair();
    small.addConnection(a);
    await GuestSession.join(b, name: 'G', appVersion: small.appVersion);
    small.startMatch();
    final (c, d) = MemoryLink.pair();
    small.addConnection(c);
    await expectLater(
      GuestSession.join(d, name: 'Late', appVersion: small.appVersion),
      throwsA(
        isA<JoinRejected>().having(
          (e) => e.reason,
          'reason',
          RejectReason.started,
        ),
      ),
    );
  });

  test('lobby: teams are shared out and a lost guest is reported', () async {
    final config = MatchConfig.defaults(_names).withTeamCount(3, _names);
    final host = HostSession(name: 'Host', config: config);
    expect(host.lobby.owners, [0, 0, 0]);
    expect(host.canStart, isFalse);
    final (a, b) = MemoryLink.pair();
    host.addConnection(a);
    final guest = await GuestSession.join(b, name: 'Sari');
    await pump();
    expect(host.lobby.owners, [0, 1, 0]);
    expect(guest.lobby.owners, [0, 1, 0]);
    expect(guest.lobby.nameOf(1), 'Sari');
    host.setOwner(2, 1);
    await pump();
    expect(guest.lobby.owners, [0, 1, 1]);
    host.updateConfig(host.lobby.config.withTeamCount(4, _names));
    await pump();
    expect(guest.lobby.owners, [0, 1, 1, 1]);
    expect(guest.lobby.config.teams.length, 4);

    // In a match, the host hears about the lost guest and can call it off.
    host.startMatch();
    await pump();
    final hostSaw = <NetMessage>[];
    host.attachMatch(hostSaw.add);
    final guestSaw = <NetMessage>[];
    guest.attachMatch(guestSaw.add);
    await guest.leave();
    await pump();
    expect(hostSaw.whereType<PlayerLeftMsg>().single.playerId, 1);
    expect(guest.hostLost, isFalse, reason: 'it left on purpose');
    host.endMatch();
    expect(host.inMatch, isFalse);
    expect(host.lobby.players.length, 1);
    expect(host.lobby.owners, [0, 0, 0, 0]);
  });

  test('a guest that loses the host is told so', () async {
    final host = HostSession(
      name: 'Host',
      config: MatchConfig.defaults(_names),
    );
    final (a, b) = MemoryLink.pair();
    host.addConnection(a);
    final guest = await GuestSession.join(b, name: 'G');
    host.startMatch();
    await pump();
    final saw = <NetMessage>[];
    guest.attachMatch(saw.add);
    await host.leave();
    await pump();
    expect(guest.hostLost, isTrue);
    expect(saw.whereType<PlayerLeftMsg>().single.playerId, 0);
  });
}
