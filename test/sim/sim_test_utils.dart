import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/sim/events.dart';
import 'package:pawtillery/sim/inputs.dart';
import 'package:pawtillery/sim/match_setup.dart';
import 'package:pawtillery/sim/terrain_mask.dart';
import 'package:pawtillery/sim/turn_manager.dart';
import 'package:pawtillery/sim/world.dart';

const testTimings = TurnTimings(
  bannerTicks: 2,
  turnTicks: 600,
  retreatTicks: 30,
  settleTimeoutTicks: 1200,
);

/// [w] × [h] map, flat ground with its surface at y = [ground].
TerrainMask flatMap({int w = 2000, int h = 600, int ground = 400}) =>
    TerrainMask(w, h)..fillRect(0, ground, w, h - ground);

SimWorld world(
  List<UnitPlacement> placements, {
  TerrainMask? terrain,
  int water = 560,
  int teams = 2,
}) =>
    SimWorld.withUnits(
      seed: 3,
      terrain: terrain ?? flatMap(),
      waterLevel: water,
      teamCount: teams,
      placements: placements,
      timings: testTimings,
    );

/// Steps with no input until [done]; returns all events.
List<SimEvent> runUntil(SimWorld w, bool Function() done, {int limit = 5000}) {
  final events = <SimEvent>[];
  for (var i = 0; i < limit && !done(); i++) {
    events.addAll(w.step(const []));
  }
  expect(done(), isTrue, reason: 'condition not reached in $limit ticks');
  return events;
}

void toAction(SimWorld w) =>
    runUntil(w, () => w.turn.phase == TurnPhase.action);

/// Moves on to the next turn (or match end).
List<SimEvent> toNextTurn(SimWorld w) {
  final n = w.turn.turnNumber;
  return runUntil(
      w, () => w.turn.turnNumber > n || w.turn.phase == TurnPhase.matchOver);
}

/// Waits for the action phase, uses [fire], then runs until the turn has
/// played out. Returns every event from the fire tick on.
List<SimEvent> fireAndSettle(SimWorld w, Fire fire) {
  toAction(w);
  final events = <SimEvent>[...w.step([fire])];
  final n = w.turn.turnNumber;
  events.addAll(runUntil(w,
      () => w.turn.turnNumber > n || w.turn.phase == TurnPhase.matchOver));
  return events;
}

Iterable<ExplosionEvent> explosions(List<SimEvent> e) =>
    e.whereType<ExplosionEvent>();

Iterable<UnitDamaged> damageTo(List<SimEvent> e, int unitId) =>
    e.whereType<UnitDamaged>().where((d) => d.unitId == unitId);

int solidCount(TerrainMask t) => t.data.where((v) => v == 1).length;
