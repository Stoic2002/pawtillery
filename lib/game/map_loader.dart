import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../config/maps.dart';
import '../sim/terrain_mask.dart';

/// A decoded map: the collision mask for the sim, plus a material per pixel
/// and (for a painted map) the painting, which only the renderer uses.
class MapData {
  const MapData(this.mask, this.materials, [this.art]);
  final TerrainMask mask;

  /// [TerrainMaterial] index per pixel (soil where not encoded).
  final Uint8List materials;

  /// The painted map as straight RGBA, the mask's size; null if none.
  final Uint8List? art;
}

/// Decodes a map PNG: alpha > 128 = ground; the red channel carries the
/// material when green is 200 (R = material * 16 + 8, see tool/gen_maps.py).
///
/// With [artAsset], the painting is decoded too (see [MapDef.artAsset]).
Future<MapData> loadMapData(String asset, {String? artAsset}) async {
  final art = artAsset == null ? null : await _loadRgba(artAsset);
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
        final m = bytes[p] ~/ 16;
        materials[i] = m > maxMaterial ? 0 : m;
      }
    }
    if (art != null && art.$1 != image.width) {
      throw StateError('$artAsset is not the size of $asset');
    }
    return MapData(mask, materials, art?.$2);
  } finally {
    image.dispose();
    codec.dispose();
  }
}

/// A painted background (see [MapDef.backgroundAsset]), ready to draw.
Future<ui.Image> loadBackground(String asset) async {
  final data = await rootBundle.load(asset);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  try {
    return (await codec.getNextFrame()).image;
  } finally {
    codec.dispose();
  }
}

/// (width, straight RGBA bytes) of an image asset.
Future<(int, Uint8List)> _loadRgba(String asset) async {
  final data = await rootBundle.load(asset);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  final image = frame.image;
  try {
    final bytes =
        (await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba))!
            .buffer
            .asUint8List();
    return (image.width, bytes);
  } finally {
    image.dispose();
    codec.dispose();
  }
}

/// Just the collision mask (tests, tools).
Future<TerrainMask> loadTerrainMask(String asset) async =>
    (await loadMapData(asset)).mask;
