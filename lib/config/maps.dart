/// Which backdrop, decorations and weather a map gets.
enum MapTheme { farm, coast, snow }

/// What grows or settles on exposed top edges.
enum CapStyle {
  /// Grass on natural ground.
  grass,

  /// Snow on everything.
  snow,
}

/// What a piece of ground is made of; only changes how it is drawn.
/// Encoded in the map PNG's red channel (see `tool/gen_maps.py`; at most
/// 16 materials).
enum TerrainMaterial {
  soil,
  wood,
  leaves,
  stone,
  metal,
  crate,
  concrete,
  hay,
  roof,
  sand,
  rock,
  ice,
  snow,
}

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
    this.grassThickness = 7,
    this.theme = MapTheme.farm,
    this.cap = CapStyle.grass,
    this.baseMaterial = TerrainMaterial.soil,
  });

  final String id;
  final String nameKey;

  /// PNG whose alpha channel is the terrain mask (alpha > 128 = ground).
  final String maskAsset;

  /// World y of the water surface; everything below is water.
  final int waterLevel;

  final int skyTopArgb;
  final int skyBottomArgb;

  /// Colour of the base ground ([baseMaterial]).
  final int dirtArgb;

  /// Colour of the cap on top edges (grass or snow).
  final int grassArgb;
  final int waterArgb;

  /// Cap drawn on exposed top edges, px.
  final int grassThickness;
  final MapTheme theme;
  final CapStyle cap;

  /// What unencoded ground is made of.
  final TerrainMaterial baseMaterial;
}

abstract final class Maps {
  static const farm = MapDef(
    id: 'farm',
    nameKey: 'mapFarm',
    maskAsset: 'assets/maps/farm/mask.png',
    waterLevel: 1120,
    skyTopArgb: 0xFF2E9BE0,
    skyBottomArgb: 0xFFC9EEFF,
    dirtArgb: 0xFF9A6236,
    grassArgb: 0xFF6CC53A,
    waterArgb: 0xC02E8FD0,
  );

  static const coast = MapDef(
    id: 'coast',
    nameKey: 'mapCoast',
    maskAsset: 'assets/maps/coast/mask.png',
    waterLevel: 1120,
    skyTopArgb: 0xFF3AA8E8,
    skyBottomArgb: 0xFFFFE9C2,
    dirtArgb: 0xFF7E8494,
    grassArgb: 0xFF8BCB45,
    waterArgb: 0xC01FA3B8,
    theme: MapTheme.coast,
    baseMaterial: TerrainMaterial.rock,
  );

  static const snow = MapDef(
    id: 'snow',
    nameKey: 'mapSnow',
    maskAsset: 'assets/maps/snow/mask.png',
    waterLevel: 1120,
    skyTopArgb: 0xFF6E9FE0,
    skyBottomArgb: 0xFFF6E3F0,
    dirtArgb: 0xFF6F7690,
    grassArgb: 0xFFF4FAFF,
    waterArgb: 0xC0245E9E,
    grassThickness: 10,
    theme: MapTheme.snow,
    cap: CapStyle.snow,
    baseMaterial: TerrainMaterial.rock,
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
  static const all = [farm, coast, snow];

  static MapDef byId(String id) => [...all, sandbox].firstWhere(
    (m) => m.id == id,
    orElse: () => throw ArgumentError('Unknown map: $id'),
  );
}
