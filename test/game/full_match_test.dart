import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/config/maps.dart';
import 'package:pawtillery/config/weapons.dart';
import 'package:pawtillery/game/map_loader.dart';
import 'package:pawtillery/sim/inputs.dart';
import 'package:pawtillery/sim/match_setup.dart';
import 'package:pawtillery/sim/physics.dart';
import 'package:pawtillery/sim/terrain_mask.dart';
import 'package:pawtillery/sim/turn_manager.dart';
import 'package:pawtillery/sim/unit.dart';
import 'package:pawtillery/sim/world.dart';

/// M2 acceptance: a 2 × 2 hotseat match on the real map can be played to a
/// result with Rock Toss alone. A simple bot stands in for the players.
void main() {
  testWidgets('2×2 matches on the sandbox map reach a result',
      (tester) async {
    late TerrainMask original;
    await tester.runAsync(() async {
      original = await loadTerrainMask(Maps.sandbox.maskAsset);
    });

    for (final seed in [1, 2, 3]) {
      final terrain = TerrainMask(original.width, original.height)
        ..data.setAll(0, original.data);
      final w = SimWorld.newMatch(
        seed: seed,
        terrain: terrain,
        waterLevel: Maps.sandbox.waterLevel,
        rosters: const [
          [
            UnitSpec(familyId: 'cat'),
            UnitSpec(familyId: 'bird'),
          ],
          [
            UnitSpec(familyId: 'dog'),
            UnitSpec(familyId: 'rabbit'),
          ],
        ],
      );
      var turnsPlayed = 0;
      for (var tick = 0; tick < 200000; tick++) {
        if (w.turn.phase == TurnPhase.matchOver) break;
        final inputs = <SimInput>[];
        if (w.turn.phase == TurnPhase.action && w.turn.allowsFire) {
          inputs.add(_bestShot(w));
          turnsPlayed++;
        }
        w.step(inputs);
      }
      expect(w.turn.phase, TurnPhase.matchOver, reason: 'seed $seed');
      final survivors = w.units.where((u) => u.alive).map((u) => u.team);
      if (w.turn.winnerTeam == null) {
        expect(survivors, isEmpty);
      } else {
        expect(survivors.toSet(), {w.turn.winnerTeam});
      }
      expect(turnsPlayed, greaterThan(1));
    }
  });
}

/// Tries a grid of aims with the real physics (including wind) and picks
/// the one landing closest to the nearest enemy.
Fire _bestShot(SimWorld w) {
  final me = w.activeUnit!;
  final enemies = w.units.where((u) => u.alive && u.team != me.team).toList();
  var best = (double.infinity, 45, 50);
  for (var angle = 10; angle <= 170; angle += 4) {
    for (var power = 20; power <= 100; power += 4) {
      final (x, y) = SimWorld.launchOrigin(me, angle);
      final p = ProjectilePhysics.launch(
        id: -1,
        weapon: Weapons.rock,
        x: x,
        y: y,
        angleDeg: angle,
        powerPercent: power,
        speedScale: me.stats.firePowerScale,
      );
      FlightOutcome o;
      do {
        o = ProjectilePhysics.step(p, w.terrain,
            wind: w.wind, waterLevel: w.waterLevel, units: enemies);
      } while (o == FlightOutcome.flying);
      if (o != FlightOutcome.hitTerrain && o != FlightOutcome.hitUnit) {
        continue;
      }
      final d = enemies.map((e) => _dist2(e, p.x, p.y)).reduce(
          (a, b) => a < b ? a : b);
      if (d < best.$1) best = (d, angle, power);
    }
  }
  return Fire(angleDeg: best.$2, powerPercent: best.$3, weaponId: 'rock');
}

double _dist2(Unit u, double x, double y) {
  final dx = u.centerX - x, dy = u.centerY - y;
  return dx * dx + dy * dy;
}
