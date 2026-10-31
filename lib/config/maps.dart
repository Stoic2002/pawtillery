import 'map_objects.dart';

/// Which backdrop, decorations and weather a map gets.
enum MapTheme { backyard, castle, wreck, ruins }

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

  /// Painted wooden toy blocks with a big letter (the backyard).
  toy,

  /// A tin can: a shiny cylinder with a red label.
  can,
}

/// Map data. Colours are plain ints (0xAARRGGBB) so this stays pure Dart.
class MapDef {
  const MapDef({
    required this.id,
    required this.nameKey,
    required this.maskAsset,
    this.artAsset,
    this.backgroundAsset,
    required this.waterLevel,
    required this.skyTopArgb,
    required this.skyBottomArgb,
    required this.dirtArgb,
    required this.grassArgb,
    required this.waterArgb,
    this.grassThickness = 7,
    this.ambientArgb = 0xFFFFFFFF,
    this.rimArgb,
    this.theme = MapTheme.castle,
    this.cap = CapStyle.grass,
    this.baseMaterial = TerrainMaterial.soil,
    this.objects = const ObjectMix(
      mines: 2,
      barrels: 2,
      healthCrates: 1,
      weaponCrates: 1,
    ),
  });

  final String id;
  final String nameKey;

  /// PNG whose alpha channel is the terrain mask (alpha > 128 = ground).
  final String maskAsset;

  /// Painted map (same size as the mask, from tool/art/convert_art.py):
  /// drawn as the ground instead of the code-painted materials, and with
  /// no code-drawn decor on top. Null = code-painted.
  final String? artAsset;

  /// Painted background (a 3:1 landscape, from tool/art/convert_art.py):
  /// drawn behind the terrain instead of the code-drawn sky and scenery
  /// layers. Null = code-drawn.
  final String? backgroundAsset;

  /// The small picture on the Setup screen (tool/art/convert_art.py).
  String get thumbAsset => 'assets/maps/$id/thumb.webp';

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

  /// Warm (or cold) light catching the top edge of the ground, as in the
  /// redesign's arena; null for none.
  final int? rimArgb;
  final MapTheme theme;
  final CapStyle cap;

  /// What unencoded ground is made of.
  final TerrainMaterial baseMaterial;

  /// Starter objects at "a few" (setup: Map objects).
  final ObjectMix objects;
}

abstract final class Maps {
  /// The redesign's arena (redesign/ArenaScene.dc.html): a backyard at dusk.
  static const backyard = MapDef(
    id: 'backyard',
    nameKey: 'mapBackyard',
    maskAsset: 'assets/maps/backyard/mask.png',
    artAsset: 'assets/maps/backyard/art.webp',
    backgroundAsset: 'assets/maps/backyard/background.webp',
    waterLevel: 2160,
    skyTopArgb: 0xFF2A2652,
    skyBottomArgb: 0xFFF4AE78,
    dirtArgb: 0xFF7A563C,
    grassArgb: 0xFF4C6233,
    waterArgb: 0xFF4A3150,
    ambientArgb: 0xFFF2DCD0,
    rimArgb: 0xFFFFB27A,
    theme: MapTheme.backyard,
    // Gas canisters by the fence.
    objects: ObjectMix(mines: 2, barrels: 3, healthCrates: 1, weaponCrates: 1),
  );

  static const castle = MapDef(
    id: 'castle',
    nameKey: 'mapCastle',
    maskAsset: 'assets/maps/castle/mask.png',
    artAsset: 'assets/maps/castle/art.webp',
    backgroundAsset: 'assets/maps/castle/background.webp',
    waterLevel: 2160,
    skyTopArgb: 0xFF0B1226,
    skyBottomArgb: 0xFF3A4170,
    dirtArgb: 0xFF6A4E3A,
    grassArgb: 0xFF5C7A44,
    waterArgb: 0xFF16314A,
    ambientArgb: 0xFF9AA6D6,
    rimArgb: 0xFFAFC2FF,
    baseMaterial: TerrainMaterial.soil,
    // Powder kegs on the battlements.
    objects: ObjectMix(mines: 1, barrels: 3, healthCrates: 1, weaponCrates: 2),
  );

  static const wreck = MapDef(
    id: 'wreck',
    nameKey: 'mapWreck',
    maskAsset: 'assets/maps/wreck/mask.png',
    artAsset: 'assets/maps/wreck/art.webp',
    backgroundAsset: 'assets/maps/wreck/background.webp',
    waterLevel: 2160,
    skyTopArgb: 0xFF1E252E,
    skyBottomArgb: 0xFF7D7A72,
    dirtArgb: 0xFF6B7078,
    grassArgb: 0xFF667E4C,
    waterArgb: 0xFF1D4E58,
    ambientArgb: 0xFFC2C4C6,
    theme: MapTheme.wreck,
    baseMaterial: TerrainMaterial.rock,
    // Sea mines washed up on the hull.
    objects: ObjectMix(mines: 4, barrels: 2, healthCrates: 1, weaponCrates: 1),
  );

  static const ruins = MapDef(
    id: 'ruins',
    nameKey: 'mapRuins',
    maskAsset: 'assets/maps/ruins/mask.png',
    artAsset: 'assets/maps/ruins/art.webp',
    backgroundAsset: 'assets/maps/ruins/background.webp',
    waterLevel: 2160,
    skyTopArgb: 0xFF2A1C24,
    skyBottomArgb: 0xFFB8643C,
    dirtArgb: 0xFF6E5440,
    grassArgb: 0xFF6E7A3E,
    waterArgb: 0xFF2C3E3A,
    ambientArgb: 0xFFE2B496,
    rimArgb: 0xFFFF9A55,
    theme: MapTheme.ruins,
    // Old traps among the stones, and supplies left behind.
    objects: ObjectMix(mines: 3, barrels: 2, healthCrates: 2, weaponCrates: 1),
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
  static const all = [backyard, castle, wreck, ruins];

  static MapDef byId(String id) => [...all, sandbox].firstWhere(
    (m) => m.id == id,
    orElse: () => throw ArgumentError('Unknown map: $id'),
  );
}
