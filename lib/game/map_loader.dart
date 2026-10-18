import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../sim/terrain_mask.dart';

/// Decodes a map PNG asset into a [TerrainMask] (alpha > 128 = ground).
Future<TerrainMask> loadTerrainMask(String asset) async {
  final data = await rootBundle.load(asset);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  final image = frame.image;
  try {
    final rgba =
        await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
    return TerrainMask.fromRgba(
        image.width, image.height, rgba!.buffer.asUint8List());
  } finally {
    image.dispose();
    codec.dispose();
  }
}
