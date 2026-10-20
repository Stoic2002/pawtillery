import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/app/match_config.dart';
import 'package:pawtillery/config/families.dart';
import 'package:pawtillery/config/maps.dart';
import 'package:pawtillery/config/weapons.dart';
import 'package:pawtillery/game/map_loader.dart';
import 'package:pawtillery/game/match_stats.dart';
import 'package:pawtillery/sim/inputs.dart';
import 'package:pawtillery/sim/terrain_mask.dart';
import 'package:pawtillery/sim/turn_manager.dart';
import 'package:pawtillery/sim/world.dart';

/// PRD M5: 20 matches in a row without a crash. A bot plays full matches on
/// every map with random team sizes, families and weapons (all of them),
/// with sudden death on so every match ends.
void main() {
  testWidgets('20 bot matches finish cleanly', (tester) async {
    final masks = <String, TerrainMask>{};
    await tester.runAsync(() async {
      for (final m in Maps.all) {
        masks[m.id] = await loadTerrainMask(m.maskAsset);
      }
    });

    final rng = Random(2026);
    final used = <String>{};
    var totalTurns = 0;

    for (var match = 0; match < 20; match++) {
      final map = Maps.all[match % Maps.all.length];
      final source = masks[map.id]!;
      final terrain = TerrainMask(source.width, source.height)
        ..data.setAll(0, source.data);
      final config = MatchConfig.defaults(const ['A'])
          .withTeamCount(2 + rng.nextInt(3), const ['A'])
          .withUnitsPerTeam(1 + rng.nextInt(4), const ['A'])
          .randomized(rng, const ['A']);

      final w = SimWorld.newMatch(
        seed: rng.nextInt(1 << 31),
        terrain: terrain,
        waterLevel: map.waterLevel,
        rosters: config.rosters(),
        timings: const TurnTimings(turnTicks: 300, settleTimeoutTicks: 900),
        suddenDeathAfterTicks: 3000,
      );
      final stats = MatchStats(w);

      var ticks = 0;
      while (w.turn.phase != TurnPhase.matchOver) {
        final inputs = <SimInput>[];
        if (w.turn.phase == TurnPhase.action && w.turn.allowsFire) {
          final fire = _botFire(w, rng);
          if (w.turn.phaseTicks < 20) {
            inputs.add(Walk(rng.nextBool() ? 1 : -1));
          } else if (fire != null) {
            inputs.add(fire);
            used.add(fire.weaponId);
          }
          if (rng.nextInt(40) == 0) inputs.add(const Jump(JumpKind.high));
        }
        for (final e in w.step(inputs)) {
          stats.record(e);
        }
        ticks++;
        expect(ticks, lessThan(400000), reason: 'match $match never ended');
      }

      final teamsLeft = {
        for (final u in w.units)
          if (u.alive) u.team,
      };
      expect(teamsLeft.length, lessThanOrEqualTo(1), reason: 'match $match');
      expect(w.turn.winnerTeam, teamsLeft.isEmpty ? null : teamsLeft.first);
      expect(stats.knockouts.reduce((a, b) => a + b),
          lessThanOrEqualTo(w.units.length));
      totalTurns += w.turn.turnNumber;
    }

    // ignore: avoid_print
    print('soak: $totalTurns turns, ${used.length} weapons: $used');
    // The bot really exercised the arsenal.
    expect(used.length, greaterThanOrEqualTo(14), reason: '$used');
    expect(totalTurns, greaterThan(40));
  }, timeout: const Timeout(Duration(minutes: 5)));
}

/// A random usable weapon with a random aim; a valid random target for
/// target weapons.
Fire? _botFire(SimWorld w, Random rng) {
  final unit = w.activeUnit!;
  final family =
      unit.familyId == null ? null : Families.byId(unit.familyId!);
  final options = [
    ...Weapons.shared,
    if (family != null) Weapons.byId(family.signatureWeaponId),
  ].where((weapon) => w.canUse(unit, weapon) && weapon.id != 'skip').toList();
  final weapon = options[rng.nextInt(options.length)];
  if (weapon.aim == AimMode.target) {
    for (var i = 0; i < 30; i++) {
      final x = rng.nextInt(w.terrain.width);
      final y = rng.nextInt(w.waterLevel);
      if (w.isValidTarget(unit, weapon, x, y)) {
        return Fire(weaponId: weapon.id, targetX: x, targetY: y);
      }
    }
    return const Fire(weaponId: 'rock', angleDeg: 60, powerPercent: 60);
  }
  return Fire(
    weaponId: weapon.id,
    angleDeg: 20 + rng.nextInt(141),
    powerPercent: 30 + rng.nextInt(71),
    fuseTicks: (1 + rng.nextInt(5)) * 60,
  );
}
