import 'dart:typed_data';

import '../../config/maps.dart';
import '../../sim/terrain_mask.dart';

/// Builds RGBA pixels for one terrain chunk straight from the mask: flat
/// dirt with a little per-pixel shading, and a grass band on exposed tops.
/// Returns `null` when the chunk has no ground at all.
Uint8List? buildChunkPixels(
  TerrainMask mask,
  MapDef map,
  int x0,
  int y0,
  int w,
  int h,
) {
  final dirt = _shades(map.dirtArgb);
  final grass = _shades(map.grassArgb);
  final grassDepth = map.grassThickness;
  final out = Uint8List(w * h * 4);
  var any = false;

  for (var lx = 0; lx < w; lx++) {
    final x = x0 + lx;
    // Ground pixels directly above the chunk, for grass continuity.
    var run = 0;
    while (run < grassDepth && mask.isSolid(x, y0 - 1 - run)) {
      run++;
    }
    for (var ly = 0; ly < h; ly++) {
      final y = y0 + ly;
      if (!mask.isSolid(x, y)) {
        run = 0;
        continue;
      }
      any = true;
      run++;
      final shade = ((x * 374761393 + y * 668265263) >> 13) % 3;
      final c = run <= grassDepth ? grass[shade] : dirt[shade];
      final i = (ly * w + lx) * 4;
      out[i] = c[0];
      out[i + 1] = c[1];
      out[i + 2] = c[2];
      out[i + 3] = 255;
    }
  }
  return any ? out : null;
}

/// Base colour plus a slightly darker and lighter variant, as [r, g, b].
List<List<int>> _shades(int argb) {
  final r = (argb >> 16) & 0xFF;
  final g = (argb >> 8) & 0xFF;
  final b = argb & 0xFF;
  List<int> scaled(double f) => [
        (r * f).round().clamp(0, 255),
        (g * f).round().clamp(0, 255),
        (b * f).round().clamp(0, 255),
      ];
  return [scaled(1), scaled(0.94), scaled(1.06)];
}
