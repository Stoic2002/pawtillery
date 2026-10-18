import 'dart:math' as math;
import 'dart:typed_data';

import '../../config/maps.dart';
import '../../sim/terrain_mask.dart';

/// Builds RGBA pixels for one terrain chunk straight from the mask, with a
/// texture that suggests depth:
/// - soil: an uneven grass edge, soil that darkens with depth, faint
///   strata and pebbles;
/// - concrete: dusty top edge, slab joints and fine grain;
/// and for both, shading under overhangs and along side walls.
/// Non-ground materials (wood, leaves, stone, metal, crates) get their own
/// textures from [materials]. Returns `null` when the chunk has no ground.
Uint8List? buildChunkPixels(
  TerrainMask mask,
  MapDef map,
  Uint8List? materials,
  int x0,
  int y0,
  int w,
  int h,
) {
  final out = Uint8List(w * h * 4);
  final soil = map.terrainStyle == TerrainStyle.soil;
  final dirt = _rgb(map.dirtArgb);
  final grass = _rgb(map.grassArgb);
  const deep = 90;
  var any = false;

  for (var lx = 0; lx < w; lx++) {
    final x = x0 + lx;
    // Depth of ground directly above the chunk (for continuity).
    var run = 0;
    while (run < deep && mask.isSolid(x, y0 - 1 - run)) {
      run++;
    }
    final blade = _hash(x, 7) % 4; // uneven grass edge
    int? lastMaterial = materials == null || y0 == 0
        ? null
        : materials[(y0 - 1) * mask.width + x];
    for (var ly = 0; ly < h; ly++) {
      final y = y0 + ly;
      if (!mask.isSolid(x, y)) {
        run = 0;
        lastMaterial = null;
        continue;
      }
      any = true;
      final materialIndex = materials?[y * mask.width + x];
      // A new material starts its own depth: ground under a crate or a
      // tree trunk is not "deep" just because the object stands on it.
      if (materialIndex != lastMaterial && lastMaterial != null) run = 0;
      lastMaterial = materialIndex;
      if (run < deep) run++;
      final noise = (_hash(x, y) % 1000) / 1000.0 - 0.5; // -0.5..0.5
      final material = materialIndex == null
          ? (soil ? TerrainMaterial.soil : TerrainMaterial.concrete)
          : TerrainMaterial.values[materialIndex];

      double r, g, b;
      final special = _special(material, map, x, y, run, noise);
      if (special != null) {
        (r, g, b) = special;
      } else if (material == TerrainMaterial.soil) {
        if (run <= map.grassThickness + blade) {
          // Lighter tips, darker roots.
          final t = run / (map.grassThickness + blade + 1);
          final k = 0.18 - t * 0.38 + noise * 0.12;
          (r, g, b) = _shade(grass, k);
        } else {
          final depth = math.min(run, deep) / deep;
          var k = -0.38 * depth + noise * 0.1;
          // Faint strata bands that wander a little.
          final band = math.sin((y + _hash(x ~/ 24, 3) % 9) / 21.0);
          if (band > 0.86) k -= 0.1;
          (r, g, b) = _shade(dirt, k);
          // Pebbles.
          if (_hash(x ~/ 3, y ~/ 3) % 97 == 0) {
            (r, g, b) = _shade((0xA8, 0x9A, 0x88), noise * 0.2 - 0.05);
          }
        }
      } else {
        if (run <= map.grassThickness) {
          (r, g, b) = _shade(grass, 0.1 - run * 0.08 + noise * 0.1);
        } else {
          var k = noise * 0.08 - math.min(run, deep) / deep * 0.12;
          // Slab joints.
          final offset = (y ~/ 80).isEven ? 0 : 60;
          if ((x + offset) % 120 == 0 || y % 80 == 0) {
            k -= 0.18;
          }
          (r, g, b) = _shade(dirt, k);
        }
      }

      // Shadow under overhangs and along side walls.
      if (!mask.isSolid(x, y + 2) || !mask.isSolid(x, y + 4)) {
        (r, g, b) = (r * 0.72, g * 0.72, b * 0.72);
      } else if (!mask.isSolid(x - 2, y) || !mask.isSolid(x + 2, y)) {
        (r, g, b) = (r * 0.86, g * 0.86, b * 0.86);
      }

      final i = (ly * w + lx) * 4;
      out[i] = r.round().clamp(0, 255);
      out[i + 1] = g.round().clamp(0, 255);
      out[i + 2] = b.round().clamp(0, 255);
      out[i + 3] = 255;
    }
  }
  return any ? out : null;
}

/// Textures for built and natural objects; null for soil and concrete.
(double, double, double)? _special(TerrainMaterial m, MapDef map, int x,
    int y, int run, double noise) {
  switch (m) {
    case TerrainMaterial.wood:
      final grain = math.sin(x * 0.55 + math.sin(y * 0.045) * 2.2);
      var k = grain * 0.08 + noise * 0.06 - math.min(run, 30) / 30 * 0.1;
      if (_hash(x ~/ 4, y ~/ 4) % 211 == 0) k -= 0.25; // knot
      return _shade((0x8A, 0x5A, 0x34), k);
    case TerrainMaterial.crate:
      var k = math.sin(x * 0.7 + y * 0.02) * 0.05 + noise * 0.06;
      if (y % 14 == 0) k -= 0.28; // board seams
      if ((x + y) % 47 == 0) k -= 0.12;
      return _shade((0xA6, 0x7C, 0x4E), k);
    case TerrainMaterial.leaves:
      // Smooth overlapping leaf clusters rather than square blocks.
      final blob = math.sin(x * 0.31 + math.sin(y * 0.27) * 2.4) *
          math.cos(y * 0.29 + math.sin(x * 0.19) * 2.1);
      final k = 0.1 - math.min(run, 50) / 50 * 0.35 + blob * 0.13 +
          noise * 0.07;
      return _shade(_rgb(PaintKitless.toneArgb(map.grassArgb, -0.2)), k);
    case TerrainMaterial.stone:
      final patch = math.sin(x * 0.12 + math.sin(y * 0.1) * 3) *
          math.cos(y * 0.14 + math.sin(x * 0.08) * 2) * 0.5;
      var k = patch * 0.16 + noise * 0.08 + 0.05 - math.min(run, 40) / 40 * 0.15;
      if (_hash(x ~/ 2, y) % 157 == 0) k -= 0.3; // cracks
      return _shade((0x8C, 0x88, 0x82), k);
    case TerrainMaterial.metal:
      var k = math.sin(x * 0.18) * 0.14 + noise * 0.04;
      if (x % 24 == 0 && y % 10 == 0) k += 0.35; // rivets
      return _shade((0x5E, 0x6E, 0x7A), k);
    case TerrainMaterial.soil:
    case TerrainMaterial.concrete:
      return null;
  }
}

/// Colour toning without dart:ui (this file stays usable in pure tests).
abstract final class PaintKitless {
  static int toneArgb(int argb, double t) {
    final (r, g, b) = _rgb(argb);
    final (nr, ng, nb) = _shade((r, g, b), t);
    return 0xFF000000 |
        (nr.round().clamp(0, 255) << 16) |
        (ng.round().clamp(0, 255) << 8) |
        nb.round().clamp(0, 255);
  }
}

(int, int, int) _rgb(int argb) =>
    ((argb >> 16) & 0xFF, (argb >> 8) & 0xFF, argb & 0xFF);

/// Lighten (k > 0) or darken (k < 0).
(double, double, double) _shade((int, int, int) c, double k) {
  final (r, g, b) = c;
  if (k >= 0) {
    return (r + (255 - r) * k, g + (255 - g) * k, b + (255 - b) * k);
  }
  final f = 1 + k;
  return (r * f, g * f, b * f);
}

int _hash(int x, int y) {
  var h = x * 374761393 + y * 668265263;
  h = (h ^ (h >> 13)) * 1274126177;
  return (h ^ (h >> 16)) & 0x7FFFFFFF;
}
