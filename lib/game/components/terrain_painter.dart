import 'dart:math' as math;
import 'dart:typed_data';

import '../../config/maps.dart';
import '../../sim/terrain_mask.dart';

/// Builds RGBA pixels for one terrain chunk straight from the mask, in the
/// painted-cartoon look (docs/art_style_guide.md):
/// - a dark outline wherever ground meets air;
/// - a cap on exposed tops (grass blades or a soft snow layer) with a
///   shadow line under it, or a lit rim on materials without a cap;
/// - brush-stroke texture (stretched value noise), slightly posterised so
///   it reads as painted rather than photographic;
/// - ground that darkens with depth and under overhangs;
/// - a texture per material (planks, shingles, straw, faceted rock, sand
///   ripples, ice glints, bricks…), from [materials].
/// Returns `null` when the chunk has no ground.
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
  const deep = 140;
  final capArgb = map.grassArgb;
  var any = false;

  bool air(int x, int y) => !mask.isSolid(x, y);

  for (var lx = 0; lx < w; lx++) {
    final x = x0 + lx;
    // Depth of ground directly above the chunk (for continuity).
    var run = 0;
    while (run < deep && mask.isSolid(x, y0 - 1 - run)) {
      run++;
    }
    int? lastMaterial = materials == null || y0 == 0
        ? null
        : materials[(y0 - 1) * mask.width + x];
    // Uneven bottom edge of the cap.
    final capDepth =
        map.grassThickness +
        (map.cap == CapStyle.grass
            ? _hash(x, 7) % 4 + (math.sin(x / 5.0) * 1.5).round()
            : (math.sin(x / 11.0) * 2 + math.sin(x / 4.3)).round());

    for (var ly = 0; ly < h; ly++) {
      final y = y0 + ly;
      if (air(x, y)) {
        run = 0;
        lastMaterial = null;
        continue;
      }
      any = true;
      final materialIndex = materials?[y * mask.width + x];
      // A new material starts its own depth: ground under a barn or a
      // tree trunk is not "deep" just because the object stands on it.
      if (materialIndex != lastMaterial && lastMaterial != null) run = 0;
      lastMaterial = materialIndex;
      if (run < deep) run++;
      final material = materialIndex == null
          ? map.baseMaterial
          : TerrainMaterial.values[materialIndex];

      // Distance to air: outline within ~2 px, rim light just inside.
      final edge =
          air(x, y - 1) ||
          air(x - 1, y) ||
          air(x + 1, y) ||
          air(x, y + 1) ||
          air(x, y - 2) ||
          air(x - 2, y) ||
          air(x + 2, y) ||
          air(x, y + 2) ||
          air(x - 1, y - 1) ||
          air(x + 1, y - 1) ||
          air(x - 1, y + 1) ||
          air(x + 1, y + 1);
      final airBelow = !edge && (air(x, y + 3) || air(x, y + 5));
      final airSide = !edge && (air(x - 4, y) || air(x + 4, y));

      final capped = _takesCap(map.cap, material) && run <= capDepth;
      var (r, g, b) = capped
          ? _cap(map.cap, capArgb, x, y, run, capDepth)
          : _material(material, map, x, y, run);

      if (!capped) {
        final natural = _natural(material);
        // Depth: deep ground is darker, more so for natural ground.
        var k = -math.min(run, deep) / deep * (natural ? 0.3 : 0.12);
        // Brush strokes: long horizontal dabs plus a finer layer.
        k += (_vnoise(x / 23, y / 8, 3) - 0.5) * 0.12;
        k += (_vnoise(x / 6, y / 4, 5) - 0.5) * 0.06;
        // Just under a cap: its shadow line.
        if (_takesCap(map.cap, material) &&
            run > capDepth &&
            run <= capDepth + 3) {
          k -= 0.22;
        } else if (!_takesCap(map.cap, material) && run > 2 && run <= 5) {
          k += 0.16; // lit rim on top faces
        }
        if (airBelow) k -= 0.2;
        if (airSide) k -= 0.08;
        (r, g, b) = _shade((r, g, b), _posterise(k));
      }

      if (edge) {
        (r, g, b) = _shade((r, g, b), -0.62);
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

bool _natural(TerrainMaterial m) =>
    m == TerrainMaterial.soil ||
    m == TerrainMaterial.rock ||
    m == TerrainMaterial.sand ||
    m == TerrainMaterial.concrete;

/// Grass grows on soil and rock; snow settles on everything but ice.
bool _takesCap(CapStyle cap, TerrainMaterial m) => switch (cap) {
  CapStyle.grass => m == TerrainMaterial.soil || m == TerrainMaterial.rock,
  CapStyle.snow => m != TerrainMaterial.ice,
};

double _posterise(double k) => (k / 0.045).round() * 0.045;

/// The cap band: bright tips fading to a darker base; snow gets a cool
/// blue shade towards its bottom edge.
(double, double, double) _cap(
  CapStyle cap,
  int argb,
  int x,
  int y,
  int run,
  int depth,
) {
  final t = run / (depth + 1);
  switch (cap) {
    case CapStyle.grass:
      var k = 0.22 - t * 0.42;
      // Blade streaks.
      if ((x + (y >> 1)) % 5 == 0) k -= 0.1;
      return _shade(_rgb(argb), _posterise(k));
    case CapStyle.snow:
      final base = _rgb(argb);
      final k = -t * t * 0.22 + (_vnoise(x / 9, y / 3, 11) - 0.5) * 0.05;
      final (r, g, b) = _shade(base, _posterise(k));
      // Shade towards blue rather than grey.
      return (r - t * 18, g - t * 8, b);
  }
}

/// Base colour and pattern of a material (before depth and brush noise).
(double, double, double) _material(
  TerrainMaterial m,
  MapDef map,
  int x,
  int y,
  int run,
) {
  switch (m) {
    case TerrainMaterial.soil:
      // Embedded stones: one candidate per cell, with its own rim.
      final cx = x ~/ 26;
      final cy = y ~/ 20;
      final hsh = _hash(cx, cy * 31 + 5);
      if (hsh % 4 == 0 && run > 14) {
        final sx = cx * 26 + 6 + hsh % 14;
        final sy = cy * 20 + 5 + (hsh >> 4) % 10;
        final rx = 4.0 + (hsh >> 8) % 5;
        final ry = rx * 0.7;
        final d = math.pow((x - sx) / rx, 2) + math.pow((y - sy) / ry, 2);
        if (d < 1) {
          final stone = (0x9C, 0x92, 0x86);
          if (d > 0.62) return _shade(stone, -0.5);
          return _shade(stone, (y < sy ? 0.15 : -0.05));
        }
      }
      return _rgbD(map.dirtArgb);
    case TerrainMaterial.rock:
      // Faceted: posterised low-frequency noise reads as flat planes.
      final v = _vnoise(x / 38, y / 30, 21);
      final facet = (v * 4).floor() / 4;
      var k = facet * 0.22 - 0.1;
      final crack = (_vnoise(x / 17, y / 13, 23) - 0.5).abs();
      if (crack < 0.015) k -= 0.35;
      return _shade(_rgb(map.dirtArgb), k);
    case TerrainMaterial.sand:
      final ripple = math.sin(y * 0.55 + _vnoise(x / 30, y / 12, 31) * 6);
      var k = ripple > 0.82 ? -0.07 : 0.03;
      if (_hash(x, y) % 53 == 0) k -= 0.18; // grains
      return _shade((0xEE, 0xD3, 0x92), k);
    case TerrainMaterial.wood:
      // Horizontal planks with staggered joints, grain and nails.
      final row = y ~/ 14;
      var k = (_hash(row, 77) % 9 - 4) * 0.025;
      if (y % 14 == 0) k -= 0.4;
      final joint = (x + (row.isEven ? 0 : 45)) % 90;
      if (joint == 0) k -= 0.4;
      if ((joint == 4 || joint == 86) && y % 14 == 7) k -= 0.5; // nails
      k += math.sin(x * 0.21 + _vnoise(x / 40, y / 3, 41) * 5) * 0.05;
      return _shade((0xA8, 0x6E, 0x3E), k);
    case TerrainMaterial.roof:
      // Scalloped shingles in rows.
      final row = y ~/ 11;
      final sx = (x + (row.isEven ? 0 : 9)) % 18;
      final sy = y % 11;
      final arc = 11 - 6 * math.sqrt(math.max(0, 1 - math.pow((sx - 9) / 9, 2)));
      var k = (_hash(x ~/ 18, row) % 7 - 3) * 0.03;
      if (sy > arc) k -= 0.28;
      if (sx == 0) k -= 0.2;
      return _shade((0xD2, 0x4B, 0x34), k);
    case TerrainMaterial.hay:
      // Straw: short dark strokes at a slant.
      final s = (x + y * 2 + (_hash(x ~/ 5, y ~/ 9) % 7)) % 9;
      var k = s == 0 ? -0.22 : (s == 4 ? 0.12 : 0.0);
      k += (_vnoise(x / 12, y / 20, 51) - 0.5) * 0.12;
      return _shade((0xF2, 0xC2, 0x4A), k);
    case TerrainMaterial.leaves:
      // Clumps lit from the top left.
      final v = _vnoise(x / 14, y / 12, 61);
      final w = _vnoise(x / 6, y / 6, 63);
      var k = (v > 0.55 ? 0.14 : (v < 0.35 ? -0.16 : 0)) + (w - 0.5) * 0.1;
      k -= math.min(run, 60) / 60 * 0.2;
      return _shade((0x3E, 0x9B, 0x3A), k);
    case TerrainMaterial.stone:
      // Bricks with light mortar.
      final row = y ~/ 13;
      final bx = (x + (row.isEven ? 0 : 12)) % 24;
      if (y % 13 == 0 || bx == 0) return (0xD8, 0xD2, 0xC6);
      final tint = (_hash((x + (row.isEven ? 0 : 12)) ~/ 24, row) % 9 - 4) * 0.03;
      return _shade((0xE6, 0xE0, 0xD6), tint - (y % 13 > 10 ? 0.1 : 0));
    case TerrainMaterial.metal:
      var k = math.sin(x * 0.18) * 0.1;
      if (x % 24 == 0 || y % 40 == 0) k -= 0.25; // panels
      if (x % 24 == 4 && y % 10 == 5) k += 0.4; // rivets
      return _shade((0x5C, 0x6E, 0x80), k);
    case TerrainMaterial.crate:
      var k = math.sin(x * 0.7 + y * 0.02) * 0.05;
      if (y % 14 == 0) k -= 0.28;
      if ((x + y) % 47 == 0) k -= 0.12;
      return _shade((0xB6, 0x86, 0x52), k);
    case TerrainMaterial.concrete:
      var k = 0.0;
      final offset = (y ~/ 80).isEven ? 0 : 60;
      if ((x + offset) % 120 == 0 || y % 80 == 0) k -= 0.18;
      return _shade(_rgb(map.dirtArgb), k);
    case TerrainMaterial.ice:
      // Pale cyan, lighter at the top, with diagonal glints.
      var k = 0.12 - math.min(run, 40) / 40 * 0.2;
      final glint = (x + y) % 29;
      if (glint < 2) k += 0.3;
      if ((x - y) % 41 == 0) k -= 0.15;
      return _shade((0x9E, 0xDE, 0xF2), k);
    case TerrainMaterial.snow:
      final k = -math.min(run, 50) / 50 * 0.16 +
          (_vnoise(x / 10, y / 6, 71) - 0.5) * 0.06;
      final (r, g, b) = _shade((0xF2, 0xF8, 0xFF), k);
      return (r - run * 0.2, g - run * 0.08, b);
  }
}

/// Smooth value noise in 0..1 (bilinear with smoothstep).
double _vnoise(double x, double y, int seed) {
  final xi = x.floor();
  final yi = y.floor();
  final fx = x - xi;
  final fy = y - yi;
  final u = fx * fx * (3 - 2 * fx);
  final v = fy * fy * (3 - 2 * fy);
  double h(int a, int b) => (_hash(a + seed * 7919, b - seed * 104729) & 1023) / 1023;
  final a = h(xi, yi);
  final b = h(xi + 1, yi);
  final c = h(xi, yi + 1);
  final d = h(xi + 1, yi + 1);
  return a + (b - a) * u + (c - a) * v + (a - b - c + d) * u * v;
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

(double, double, double) _rgbD(int argb) {
  final (r, g, b) = _rgb(argb);
  return (r.toDouble(), g.toDouble(), b.toDouble());
}

/// Lighten (k > 0) or darken (k < 0); works on ints or doubles.
(double, double, double) _shade((num, num, num) c, double k) {
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
