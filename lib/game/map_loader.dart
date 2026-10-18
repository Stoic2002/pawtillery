import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../config/maps.dart';
import '../sim/terrain_mask.dart';

/// A decoded map: the collision mask for the sim, plus a material per pixel
/// that only the renderer uses.
class MapData {
  const MapData(this.mask, this.materials);
  final TerrainMask mask;

  /// [TerrainMaterial] index per pixel (soil where not encoded).
  final Uint8List materials;
}

/// Decodes a map PNG: alpha > 128 = ground; the red channel carries the
/// material when green is 200 (see tool/gen_maps.py).
Future<MapData> loadMapData(String asset) async {
  final data = await rootBundle.load(asset);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  final image = frame.image;
  try {
    final bytes =
        (await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba))!
            .buffer
            .asUint8List();
    final mask = TerrainMask.fromRgba(image.width, image.height, bytes);
    final materials = Uint8List(image.width * image.height);
    final maxMaterial = TerrainMaterial.values.length - 1;
    for (var i = 0; i < materials.length; i++) {
      final p = i * 4;
      if (bytes[p + 3] > 128 && bytes[p + 1] == 200) {
        final m = bytes[p] ~/ 32;
        materials[i] = m > maxMaterial ? 0 : m;
      }
    }
    return MapData(mask, materials);
  } finally {
    image.dispose();
    codec.dispose();
  }
}

/// Just the collision mask (tests, tools).
Future<TerrainMask> loadTerrainMask(String asset) async =>
    (await loadMapData(asset)).mask;
