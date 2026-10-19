import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/app/match_config.dart';
import 'package:pawtillery/config/weapons.dart';
import 'package:pawtillery/net/protocol.dart';
import 'package:pawtillery/sim/inputs.dart';

T _roundTrip<T extends NetMessage>(T m) {
  final line = encodeMessage(m);
  expect(line, isNot(contains('\n')), reason: 'one message per line');
  final back = decodeMessage(line);
  expect(back, isA<T>());
  return back as T;
}

MatchConfig _config() => MatchConfig.defaults(const ['Bolu', 'Kopi', 'Mochi'])
    .withTeamCount(3, const ['Bolu', 'Kopi', 'Mochi'])
    .copyWith(turnSeconds: 30, mapId: 'castle', weapons: WeaponLoadout.chaos);

void main() {
  test('inputs survive encoding', () {
    const inputs = <SimInput>[
      Walk(-1),
      Walk(1),
      Jump(JumpKind.forward),
      Jump(JumpKind.high),
      Fire(weaponId: 'rock', angleDeg: 135, powerPercent: 72),
      Fire(weaponId: 'grenade', angleDeg: 10, powerPercent: 40, fuseTicks: 180),
      Fire(weaponId: 'teleport', targetX: 812, targetY: -3),
    ];
    final m = _roundTrip(
      const TicksMsg(
        from: 61,
        frames: [
          [],
          inputs,
          [],
          [Walk(1)],
        ],
      ),
    );
    expect(m.from, 61);
    expect(m.end, isFalse);
    expect(m.frames.length, 4);
    expect(m.frames[0], isEmpty);
    expect(m.frames[2], isEmpty);
    final got = m.frames[1];
    expect(got.length, inputs.length);
    expect((got[0] as Walk).direction, -1);
    expect((got[3] as Jump).kind, JumpKind.high);
    final fire = got[5] as Fire;
    expect(fire.weaponId, 'grenade');
    expect(fire.angleDeg, 10);
    expect(fire.powerPercent, 40);
    expect(fire.fuseTicks, 180);
    expect(fire.targetX, isNull);
    final tp = got[6] as Fire;
    expect((tp.targetX, tp.targetY), (812, -3));
    expect((m.frames[3].single as Walk).direction, 1);
  });

  test('empty frames stay out of the JSON; the hand-over flag is kept', () {
    final line = encodeMessage(
      const TicksMsg(from: 5, frames: [[], [], []], end: true),
    );
    expect(line, '{"t":"ticks","from":5,"n":3,"in":[],"end":true}');
    final m = decodeMessage(line)! as TicksMsg;
    expect(m.end, isTrue);
    expect(m.frames.length, 3);
  });

  test('lobby and start carry the whole setup, weapons included', () {
    final config = _config();
    const players = [
      NetPlayer(id: 0, name: 'Arul'),
      NetPlayer(id: 2, name: 'Sari'),
    ];
    final lobby = _roundTrip(
      LobbyMsg(
        LobbyState(players: players, config: config, owners: const [0, 2, 0]),
      ),
    ).lobby;
    expect(lobby.players.map((p) => (p.id, p.name)), [
      (0, 'Arul'),
      (2, 'Sari'),
    ]);
    expect(lobby.owners, [0, 2, 0]);
    expect(lobby.config.toJson(), config.toJson());
    expect(lobby.nameOf(2), 'Sari');

    final start = _roundTrip(
      StartMsg(
        seed: 123456789,
        mapId: 'castle',
        config: config,
        owners: const [0, 2, 0],
        players: players,
      ),
    );
    expect(start.seed, 123456789);
    expect(start.mapId, 'castle');
    expect(start.config.weapons.toJson(), WeaponLoadout.chaos.toJson());
    expect(start.config.turnSeconds, 30);
    expect(start.owners, [0, 2, 0]);
  });

  test('small messages', () {
    final hello = _roundTrip(
      const HelloMsg(protocol: 1, appVersion: '1.0.0', name: '  Budi  '),
    );
    expect(
      (hello.protocol, hello.appVersion, hello.name),
      (1, '1.0.0', 'Budi'),
    );
    expect(_roundTrip(const WelcomeMsg(3)).playerId, 3);
    expect(
      _roundTrip(const RejectMsg(RejectReason.full)).reason,
      RejectReason.full,
    );
    final hash = _roundTrip(const HashMsg(tick: 600, hash: 0xDEADBEEF));
    expect((hash.tick, hash.hash), (600, 0xDEADBEEF));
    expect(_roundTrip(const DesyncMsg(42)).tick, 42);
    expect(_roundTrip(const PlayerLeftMsg(1)).playerId, 1);
    _roundTrip(const EndMatchMsg());
    _roundTrip(const PingMsg());
  });

  test('bad lines are dropped, not thrown', () {
    for (final line in [
      '',
      'not json',
      '[]',
      '{"t":"nope"}',
      '{"t":"welcome"}',
      '{"t":"welcome","id":"x"}',
      '{"t":"reject","reason":"bored"}',
      '{"t":"ticks","from":1,"n":2,"in":[[5,[0,1]]]}',
      '{"t":"ticks","from":1,"n":2,"in":[[0,[0,3]]]}',
      '{"t":"ticks","from":1,"n":2,"in":[[0,[9]]]}',
      '{"t":"ticks","from":1,"n":2,"in":[[]]}',
      '{"t":"lobby","players":[],"config":{},"owners":[]}',
    ]) {
      expect(decodeMessage(line), isNull, reason: line);
    }
    // Owners must match the team count.
    final lobby = LobbyMsg(
      LobbyState(
        players: const [NetPlayer(id: 0, name: 'A')],
        config: _config(),
        owners: const [0],
      ),
    );
    expect(decodeMessage(encodeMessage(lobby)), isNull);
  });

  test('long names are cut', () {
    final m = _roundTrip(
      const HelloMsg(
        protocol: 1,
        appVersion: '1',
        name: 'ABCDEFGHIJKLMNOPQRSTU',
      ),
    );
    expect(m.name, 'ABCDEFGHIJKLMNOP');
  });

  test('room beacon', () {
    const b = RoomBeacon(
      protocol: 1,
      appVersion: '1.0.0',
      room: 77,
      name: 'Arul',
      port: 47821,
      players: 2,
      open: true,
    );
    final back = decodeBeacon(encodeBeacon(b))!;
    expect(
      (back.protocol, back.appVersion, back.room, back.name, back.port),
      (1, '1.0.0', 77, 'Arul', 47821),
    );
    expect((back.players, back.open), (2, true));
    expect(decodeBeacon('{"hello":1}'), isNull);
    expect(decodeBeacon('garbage'), isNull);
  });
}
