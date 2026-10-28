import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/config/net.dart';
import 'package:pawtillery/net/lockstep.dart';
import 'package:pawtillery/net/protocol.dart';
import 'package:pawtillery/net/session.dart';
import 'package:pawtillery/sim/inputs.dart';
import 'package:pawtillery/sim/terrain_mask.dart';
import 'package:pawtillery/sim/turn_manager.dart';
import 'package:pawtillery/sim/world.dart';

/// Shared by the lockstep tests (memory links) and the socket test.

/// Lets queued link messages through.
Future<void> pump() => Future<void>.delayed(Duration.zero);

/// One phone: its session, its own world and its lockstep, with a bot
/// playing whenever this phone controls the active team.
class TestPhone {
  TestPhone(this.session, StartMsg start, {required this.lag}) {
    world = SimWorld.newMatch(
      seed: start.seed,
      // 2000 × 600, flat ground at y = 400.
      terrain: TerrainMask(2000, 600)..fillRect(0, 400, 2000, 200),
      waterLevel: 560,
      rosters: start.config.rosters(),
      timings: const TurnTimings(
        bannerTicks: 10,
        turnTicks: 150,
        retreatTicks: 30,
        settleTimeoutTicks: 600,
      ),
      // Water rises every turn after this, so every match ends.
      suddenDeathAfterTicks: 4000,
      loadout: start.config.weapons,
    );
    lock = Lockstep(
      owners: start.owners,
      me: session.myId,
      send: session.sendTicks,
      onHash: (tick, hash) {
        hashes[tick] = hash;
        session.sendHash(tick, hash);
      },
    )..attach(world);
    session.attachMatch((m) {
      switch (m) {
        case TicksMsg():
          lock.receive(m);
        case DesyncMsg():
          desynced = true;
        // Like the arena: wait while a player's connection is lost.
        case PlayerLeftMsg(:final playerId):
          away.add(playerId);
          lock.paused = true;
        case PlayerBackMsg(:final playerId):
          away.remove(playerId);
          if (away.isEmpty) lock.paused = false;
        default:
          break;
      }
    });
  }

  final NetSession session;

  /// Chance of missing a frame (a slow phone), to exercise the catch-up.
  final double lag;
  late final SimWorld world;
  late final Lockstep lock;
  final Map<int, int> hashes = {};
  bool desynced = false;

  /// Players whose connection is lost right now.
  final Set<int> away = {};
  int _firedTurn = -1;
  int steps = 0;

  /// One tick of real time, like the game's fixed-step loop.
  void frame(Random rng) {
    if (rng.nextDouble() < lag) return;
    var walk = 0;
    final queued = <SimInput>[];
    final turn = world.turn;
    if (lock.isMyTurn && turn.phase == TurnPhase.action && turn.allowsFire) {
      final me = world.activeUnit!;
      final enemy = world.units.firstWhere((u) => u.alive && u.team != me.team);
      final dir = enemy.centerX > me.centerX ? 1 : -1;
      if (turn.phaseTicks < 25) {
        walk = dir;
        if (turn.phaseTicks == 10) queued.add(const Jump(JumpKind.forward));
      } else if (_firedTurn != turn.turnNumber) {
        _firedTurn = turn.turnNumber;
        final power = 45 + (turn.turnNumber * 17) % 50;
        queued.add(
          Fire(
            weaponId: 'rock',
            angleDeg: dir > 0 ? 50 : 130,
            powerPercent: power,
          ),
        );
      }
    }
    lock.produce([if (walk != 0) Walk(walk)], queued);
    var n = 0;
    while (n < 5 && lock.step() != null) {
      n++;
      steps++;
      if (lock.buffered <= NetConfig.catchUpTicks) break;
    }
  }
}

Future<void> playAll(List<TestPhone> phones) async {
  final rng = Random(5);
  for (var f = 0; f < 200000; f++) {
    if (phones.every((p) => p.lock.isOver)) break;
    for (final p in phones) {
      p.frame(rng);
    }
    await pump();
  }
}

void expectSame(List<TestPhone> phones) {
  final first = phones.first;
  expect(first.world.turn.phase, TurnPhase.matchOver);
  expect(first.world.turn.turnNumber, greaterThan(4));
  for (final p in phones) {
    expect(p.desynced, isFalse);
    expect(p.world.turn.phase, TurnPhase.matchOver);
    expect(p.world.tick, first.world.tick);
    expect(p.world.stateHash(), first.world.stateHash());
    expect(p.hashes, first.hashes);
    expect(p.world.turn.winnerTeam, first.world.turn.winnerTeam);
  }
}
