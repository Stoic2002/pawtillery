import '../config/units.dart';
import 'rng.dart';
import 'terrain_mask.dart';
import 'unit.dart';

/// Feet row of the topmost ground at column [x] with room for a body, or
/// null if the column is empty.
int? surfaceY(TerrainMask t, int x, int bodyHeight) {
  for (var y = 0; y < t.height; y++) {
    if (t.isSolid(x, y)) {
      return UnitPhysics.bodyFree(t, x, y, bodyHeight) ? y : null;
    }
  }
  return null;
}

/// Random spawn points on flat, dry ground, at least [minDistance] apart
/// (PRD: Peta 1.0). Draws only from [rng], so the result follows the seed.
/// Relaxes flatness, then distance, if the map is too crowded.
List<(int, int)> findSpawnPoints({
  required TerrainMask terrain,
  required int waterLevel,
  required int count,
  required SimRng rng,
  int bodyHeight = UnitConfig.bodyHeight,
  int minDistance = UnitConfig.spawnMinDistance,
  int flatTolerance = UnitConfig.spawnFlatTolerance,
  int margin = 40,
  int attemptsPerPass = 4000,
}) {
  final points = <(int, int)>[];
  final passes = [
    (flatTolerance, minDistance),
    (flatTolerance * 4, minDistance),
    (bodyHeight, minDistance ~/ 2),
  ];
  for (final (tolerance, distance) in passes) {
    for (var i = 0; i < attemptsPerPass && points.length < count; i++) {
      final x = rng.nextIntInRange(margin, terrain.width - margin - 1);
      final y = surfaceY(terrain, x, bodyHeight);
      if (y == null || y >= waterLevel - 2) continue;
      if (!_isFlat(terrain, x, y, bodyHeight, tolerance)) continue;
      if (!_farEnough(points, x, y, distance)) continue;
      points.add((x, y));
    }
    if (points.length == count) return points;
  }
  throw StateError('Map has room for only ${points.length} of $count units');
}

bool _isFlat(TerrainMask t, int x, int y, int bodyHeight, int tolerance) {
  for (final dx in const [-8, 8]) {
    final s = surfaceY(t, x + dx, bodyHeight);
    if (s == null || (s - y).abs() > tolerance) return false;
  }
  return true;
}

bool _farEnough(List<(int, int)> points, int x, int y, int distance) {
  for (final (px, py) in points) {
    final dx = px - x;
    final dy = py - y;
    if (dx * dx + dy * dy < distance * distance) return false;
  }
  return true;
}

/// Up to [count] points on flat, dry ground for starter objects, at least
/// [minDistance] apart and [avoidDistance] from every point in [avoid]
/// (the units). Best effort: a crowded map gets fewer objects, never an
/// error. Draws only from [rng].
List<(int, int)> findObjectPoints({
  required TerrainMask terrain,
  required int waterLevel,
  required int count,
  required SimRng rng,
  required List<(int, int)> avoid,
  required int minDistance,
  required int avoidDistance,
  int margin = 40,
  int attempts = 3000,
}) {
  final points = <(int, int)>[];
  const height = 16;
  for (var i = 0; i < attempts && points.length < count; i++) {
    final x = rng.nextIntInRange(margin, terrain.width - margin - 1);
    final y = surfaceY(terrain, x, height);
    if (y == null || y >= waterLevel - 2) continue;
    if (!_isFlat(terrain, x, y, height, 3)) continue;
    if (!_farEnough(avoid, x, y, avoidDistance)) continue;
    if (!_farEnough(points, x, y, minDistance)) continue;
    points.add((x, y));
  }
  return points;
}
