/// Which background scenery and decorations a map gets.
enum MapTheme { backyard, park, warehouse }

/// How the ground is textured.
enum TerrainStyle {
  /// Grass on top, layered soil with pebbles below.
  soil,

  /// Concrete and wood with a dusty edge.
  concrete,
}

/// What a piece of ground is made of; only changes how it is drawn.
/// Encoded in the map PNG's red channel (see `tool/gen_maps.py`).
enum TerrainMaterial { soil, wood, leaves, stone, metal, crate, concrete }

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
    this.theme = MapTheme.backyard,
    this.terrainStyle = TerrainStyle.soil,
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
  final MapTheme theme;
  final TerrainStyle terrainStyle;
}

abstract final class Maps {
  static const backyard = MapDef(
    id: 'backyard',
    nameKey: 'mapBackyard',
    maskAsset: 'assets/maps/backyard/mask.png',
    waterLevel: 1120,
    skyTopArgb: 0xFF7EC8F5,
    skyBottomArgb: 0xFFE3F4FF,
    dirtArgb: 0xFF7B5232,
    grassArgb: 0xFF4CAF50,
    waterArgb: 0xB0337FD0,
  );

  static const park = MapDef(
    id: 'park',
    nameKey: 'mapPark',
    maskAsset: 'assets/maps/park/mask.png',
    waterLevel: 1120,
    skyTopArgb: 0xFFFFA77A,
    skyBottomArgb: 0xFFFFE8C8,
    dirtArgb: 0xFF6D4C35,
    grassArgb: 0xFF8BC34A,
    waterArgb: 0xB0296F9E,
    theme: MapTheme.park,
  );

  static const warehouse = MapDef(
    id: 'warehouse',
    nameKey: 'mapWarehouse',
    maskAsset: 'assets/maps/warehouse/mask.png',
    waterLevel: 1120,
    skyTopArgb: 0xFF37474F,
    skyBottomArgb: 0xFF78909C,
    dirtArgb: 0xFF8E8C88,
    grassArgb: 0xFFB8B2A6,
    waterArgb: 0xB0285E7A,
    grassThickness: 3,
    theme: MapTheme.warehouse,
    terrainStyle: TerrainStyle.concrete,
  );

  /// Test bench from M1; used by tests, not offered to players.
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

  /// Maps players can pick (PRD: Peta 1.0).
  static const all = [backyard, park, warehouse];

  static MapDef byId(String id) => [...all, sandbox].firstWhere(
      (m) => m.id == id,
      orElse: () => throw ArgumentError('Unknown map: $id'));
}
