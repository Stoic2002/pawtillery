import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/app/match_config.dart';
import 'package:pawtillery/config/app_info.dart';
import 'package:pawtillery/config/net.dart';
import 'package:pawtillery/net/link.dart';
import 'package:pawtillery/net/protocol.dart';
import 'package:pawtillery/net/session.dart';

import 'net_harness.dart';

const _names = ['Bolu', 'Kopi', 'Mochi', 'Tahu'];

/// A host and [guests] guests on memory links; every guest can redial,
/// and [links] holds each guest's current link so a test can cut it.
Future<(HostSession, List<GuestSession>, List<MemoryLink>)> _room(
  int guests,
) async {
  final config = MatchConfig.defaults(
    _names,
  ).withTeamCount(guests + 1, _names).withUnitsPerTeam(2, _names);
  final host = HostSession(name: 'Host', config: config);
  final links = <MemoryLink>[];
  final sessions = <GuestSession>[];
  for (var g = 0; g < guests; g++) {
    final (a, b) = MemoryLink.pair();
    host.addConnection(a);
    links.add(a);
    sessions.add(
      await GuestSession.join(
        b,
        name: 'G$g',
        rejoinRetry: const Duration(milliseconds: 5),
        redial: () async {
          final (a, b) = MemoryLink.pair();
          host.addConnection(a);
          links[g] = a;
          return b;
        },
      ),
    );
  }
  await pump();
  return (host, sessions, links);
}

/// Plays like [playAll], cutting a guest's link at the frames in [cuts]
/// (frame → guest index). Returns how often a guest was reconnecting.
Future<int> _playWithCuts(
  List<TestPhone> phones,
  List<MemoryLink> links,
  Map<int, int> cuts,
) async {
  final rng = Random(5);
  var reconnecting = 0;
  for (var f = 0; f < 400000; f++) {
    if (phones.every((p) => p.lock.isOver)) break;
    if (cuts[f] case final g?) await links[g].close();
    for (final p in phones) {
      p.frame(rng);
      if (p.session case GuestSession(reconnecting: true)) reconnecting++;
    }
    await pump();
    // Rejoining waits on real (short) timers.
    if (phones.any((p) => p.lock.paused)) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
  }
  return reconnecting;
}

void main() {
  test('a guest that drops mid-match rejoins, and the match ends the same '
      'on every phone', () async {
    final (host, guests, links) = await _room(1);
    host.startMatch(random: Random(7));
    await pump();
    final phones = [
      TestPhone(host, host.match!, lag: 0),
      TestPhone(guests[0], guests[0].match!, lag: 0.2),
    ];
    // Several cuts: in the guest's turns and in the host's.
    final waited = await _playWithCuts(phones, links, {
      300: 0,
      1500: 0,
      2600: 0,
      4100: 0,
    });
    expect(waited, greaterThan(0), reason: 'the guest had to reconnect');
    expectSame(phones);
    expect(guests[0].hostLost, isFalse);
  });

  test('a guest cut off while it is playing sends the ticks the host '
      'missed', () async {
    final config = MatchConfig.defaults(_names).withUnitsPerTeam(2, _names);
    final host = HostSession(name: 'Host', config: config);
    final (a, b) = MemoryLink.pair();
    host.addConnection(a);
    // The guest's first connection goes quiet before it closes, like Wi-Fi
    // dropping out: what the guest sends then never arrives.
    final quiet = _QuietLink(b);
    final guest = await GuestSession.join(
      quiet,
      name: 'G',
      rejoinRetry: const Duration(milliseconds: 5),
      redial: () async {
        final (a, b) = MemoryLink.pair();
        host.addConnection(a);
        return b;
      },
    );
    await pump();
    host.startMatch(random: Random(11));
    await pump();
    final guestPhone = TestPhone(guest, guest.match!, lag: 0);
    final phones = [TestPhone(host, host.match!, lag: 0), guestPhone];
    final rng = Random(1);
    var f = 0;
    while (!(guestPhone.lock.isMyTurn && guestPhone.world.turn.allowsFire)) {
      for (final p in phones) {
        p.frame(rng);
      }
      await pump();
      expect(++f, lessThan(20000));
    }
    quiet.mute = true;
    for (var i = 0; i < 40; i++) {
      for (final p in phones) {
        p.frame(rng);
      }
      await pump();
    }
    expect(guest.knownTicks - host.knownTicks, greaterThan(20));
    await a.close();
    await _playWithCuts(phones, [a], const {});
    expectSame(phones);
  });

  test('two guests: one drops, the other waits for it too', () async {
    final (host, guests, links) = await _room(2);
    host.startMatch(random: Random(3));
    await pump();
    final phones = [
      TestPhone(host, host.match!, lag: 0),
      for (final g in guests) TestPhone(g, g.match!, lag: 0.25),
    ];
    final seenPaused = <int>{};
    final rng = Random(2);
    for (var f = 0; f < 600; f++) {
      for (final p in phones) {
        p.frame(rng);
      }
      await pump();
    }
    await links[1].close();
    for (var i = 0; i < 5; i++) {
      await pump();
    }
    for (final (i, p) in phones.indexed) {
      if (p.lock.paused) seenPaused.add(i);
    }
    expect(seenPaused, {0, 1, 2}, reason: 'everyone waits');
    await _playWithCuts(phones, links, const {});
    expectSame(phones);
  });

  test('a stranger, a wrong key or a finished match cannot rejoin', () async {
    final (host, guests, _) = await _room(1);
    host.startMatch();
    await pump();

    Future<NetMessage?> attempt(RejoinMsg m) async {
      final (a, b) = MemoryLink.pair();
      host.addConnection(a);
      NetMessage? first;
      b.messages.listen((x) => first ??= x);
      b.send(m);
      await pump();
      await pump();
      return first;
    }

    RejoinMsg rejoin({int id = 1, int key = 0}) => RejoinMsg(
      protocol: NetConfig.protocolVersion,
      appVersion: AppInfo.version,
      playerId: id,
      key: key,
      known: 0,
    );

    // Not away (still connected).
    expect(await attempt(rejoin()), isA<RejectMsg>());
    // Away, but a wrong key.
    host.attachMatch((_) {});
    await guests[0].leave();
    await pump();
    expect(await attempt(rejoin(key: 12345)), isA<RejectMsg>());
    // After the host ends the match the slot is gone.
    host.endMatch();
    expect(host.lobby.players, hasLength(1));
    expect(await attempt(rejoin()), isA<RejectMsg>());
  });
}

/// A link that can go quiet: while [mute], what is sent is lost.
class _QuietLink implements NetLink {
  _QuietLink(this._inner);
  final NetLink _inner;
  bool mute = false;

  @override
  Stream<NetMessage> get messages => _inner.messages;

  @override
  void send(NetMessage message) {
    if (!mute) _inner.send(message);
  }

  @override
  Future<void> close() => _inner.close();
}
