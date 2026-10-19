/// Which backdrop, decorations and weather a map gets.
enum MapTheme { castle, wreck, ruins }

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
    this.ambientArgb = 0xFFFFFFFF,
    this.theme = MapTheme.castle,
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

  /// Light falling on the terrain (multiplied in): moonlight, storm grey,
  /// fire glow. Units are never tinted, so they stay readable.
  final int ambientArgb;
  final MapTheme theme;
  final CapStyle cap;

  /// What unencoded ground is made of.
  final TerrainMaterial baseMaterial;
}

abstract final class Maps {
  static const castle = MapDef(
    id: 'castle',
    nameKey: 'mapCastle',
    maskAsset: 'assets/maps/castle/mask.png',
    waterLevel: 1120,
    skyTopArgb: 0xFF0B1226,
    skyBottomArgb: 0xFF3A4170,
    dirtArgb: 0xFF6A4E3A,
    grassArgb: 0xFF5C7A44,
    waterArgb: 0xFF16314A,
    ambientArgb: 0xFF9AA6D6,
    baseMaterial: TerrainMaterial.soil,
  );

  static const wreck = MapDef(
    id: 'wreck',
    nameKey: 'mapWreck',
    maskAsset: 'assets/maps/wreck/mask.png',
    waterLevel: 1120,
    skyTopArgb: 0xFF1E252E,
    skyBottomArgb: 0xFF7D7A72,
    dirtArgb: 0xFF6B7078,
    grassArgb: 0xFF667E4C,
    waterArgb: 0xFF1D4E58,
    ambientArgb: 0xFFC2C4C6,
    theme: MapTheme.wreck,
    baseMaterial: TerrainMaterial.rock,
  );

  static const ruins = MapDef(
    id: 'ruins',
    nameKey: 'mapRuins',
    maskAsset: 'assets/maps/ruins/mask.png',
    waterLevel: 1120,
    skyTopArgb: 0xFF2A1C24,
    skyBottomArgb: 0xFFB8643C,
    dirtArgb: 0xFF6E5440,
    grassArgb: 0xFF6E7A3E,
    waterArgb: 0xFF2C3E3A,
    ambientArgb: 0xFFE2B496,
    theme: MapTheme.ruins,
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
  static const all = [castle, wreck, ruins];

  static MapDef byId(String id) => [...all, sandbox].firstWhere(
    (m) => m.id == id,
    orElse: () => throw ArgumentError('Unknown map: $id'),
  );
}
