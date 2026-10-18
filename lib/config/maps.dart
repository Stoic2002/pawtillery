/// Map data. Colours are plain ints (0xAARRGGBB) so this stays pure Dart.
class MapDef {
  const MapDef({
    required this.id,
    required this.nameKey,
    required this.maskAsset,
    required this.waterLevel,
    required this.skyTopArgb,
    required this.skyBottomArgb,
    required this.dirtArgb,
    required this.grassArgb,
    required this.waterArgb,
    this.grassThickness = 6,
  });

  final String id;
  final String nameKey;

  /// PNG whose alpha channel is the terrain mask (alpha > 128 = ground).
  final String maskAsset;

  /// World y of the water surface; everything below is water.
  final int waterLevel;

  final int skyTopArgb;
  final int skyBottomArgb;
  final int dirtArgb;
  final int grassArgb;
  final int waterArgb;

  /// Grass band drawn on exposed top edges, px.
  final int grassThickness;
}

abstract final class Maps {
  /// M1 test bench; replaced by the three themed maps in M4.
  static const sandbox = MapDef(
    id: 'sandbox',
    nameKey: 'mapSandbox',
    maskAsset: 'assets/maps/sandbox/mask.png',
    waterLevel: 1120,
    skyTopArgb: 0xFF6EC6FF,
    skyBottomArgb: 0xFFD8F1FF,
    dirtArgb: 0xFF8A5A35,
    grassArgb: 0xFF5DBB3F,
    waterArgb: 0xB02F7FD8,
  );

  static const all = [sandbox];
}
