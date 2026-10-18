/// Breeds (PRD: Breed per family). Purely cosmetic: a breed never changes
/// a gameplay number. Pure Dart; colours are 0xAARRGGBB.
library;

/// How a breed's [BreedDef.markingArgb] is used by the drawn animal.
enum CoatPattern {
  solid,
  tabby,
  spotted,
  patches,

  /// Dark back (German Shepherd).
  saddle,

  /// Light face, chest and belly (Husky, Corgi).
  tuxedo,

  /// Head in the marking colour (Mallard, Boer goat).
  headColor,

  /// Crest or face feathers in the marking colour (birds).
  crest,

  /// Dark line along the back (hamsters).
  stripe,

  /// Tail feathers in the marking colour (chickens).
  tail,

  /// Shell in the marking colour (turtles).
  shell,
}

class BreedDef {
  const BreedDef({
    required this.id,
    required this.familyId,
    required this.nameKey,
    required this.primaryArgb,
    required this.secondaryArgb,
    required this.markingArgb,
    this.pattern = CoatPattern.solid,
    this.longFur = false,
    this.spritePath,
  });

  final String id;
  final String familyId;

  /// ARB key; breed names are common breed names and mostly identical in
  /// both languages.
  final String nameKey;

  /// Main coat / feathers / skin.
  final int primaryArgb;

  /// Belly, muzzle and other light areas.
  final int secondaryArgb;

  /// Pattern colour; what it paints depends on [pattern].
  final int markingArgb;
  final CoatPattern pattern;

  /// Fluffier outline (Persian, Pomeranian, Silkie).
  final bool longFur;

  /// Sprite folder under `assets/units/<family>/<breed>/`, once art exists.
  final String? spritePath;
}

abstract final class Breeds {
  static const all = [
    BreedDef(
      id: 'catKampung',
      familyId: 'cat',
      nameKey: 'breedCatKampung',
      primaryArgb: 0xFFD39552,
      secondaryArgb: 0xFFF3E4CC,
      markingArgb: 0xFFA2652C,
      pattern: CoatPattern.tabby,
    ),
    BreedDef(
      id: 'catAngora',
      familyId: 'cat',
      nameKey: 'breedCatAngora',
      primaryArgb: 0xFFF1EDE7,
      secondaryArgb: 0xFFFFFFFF,
      markingArgb: 0xFFD9D2C8,
      pattern: CoatPattern.solid,
      longFur: true,
    ),
    BreedDef(
      id: 'catBritishShorthair',
      familyId: 'cat',
      nameKey: 'breedCatBritishShorthair',
      primaryArgb: 0xFF8D97A3,
      secondaryArgb: 0xFFA7B0BA,
      markingArgb: 0xFF6F7884,
      pattern: CoatPattern.solid,
    ),
    BreedDef(
      id: 'catSiberian',
      familyId: 'cat',
      nameKey: 'breedCatSiberian',
      primaryArgb: 0xFF9C826A,
      secondaryArgb: 0xFFE7DCCB,
      markingArgb: 0xFF5E4B3C,
      pattern: CoatPattern.tabby,
      longFur: true,
    ),
    BreedDef(
      id: 'catPersia',
      familyId: 'cat',
      nameKey: 'breedCatPersia',
      primaryArgb: 0xFFEBD9BC,
      secondaryArgb: 0xFFF7EEDF,
      markingArgb: 0xFFD8C3A0,
      pattern: CoatPattern.solid,
      longFur: true,
    ),
    BreedDef(
      id: 'catMaineCoon',
      familyId: 'cat',
      nameKey: 'breedCatMaineCoon',
      primaryArgb: 0xFF8A6A4C,
      secondaryArgb: 0xFFE0CDB4,
      markingArgb: 0xFF4E3B2C,
      pattern: CoatPattern.tabby,
      longFur: true,
    ),
    BreedDef(
      id: 'catBengal',
      familyId: 'cat',
      nameKey: 'breedCatBengal',
      primaryArgb: 0xFFD9A75F,
      secondaryArgb: 0xFFF4E2C2,
      markingArgb: 0xFF5A3A20,
      pattern: CoatPattern.spotted,
    ),
    BreedDef(
      id: 'catSphynx',
      familyId: 'cat',
      nameKey: 'breedCatSphynx',
      primaryArgb: 0xFFE5BCAA,
      secondaryArgb: 0xFFF0D2C4,
      markingArgb: 0xFFC9988A,
      pattern: CoatPattern.solid,
    ),
    BreedDef(
      id: 'dogGoldenRetriever',
      familyId: 'dog',
      nameKey: 'breedDogGoldenRetriever',
      primaryArgb: 0xFFD9A55A,
      secondaryArgb: 0xFFEBC98F,
      markingArgb: 0xFFB9853E,
      pattern: CoatPattern.solid,
      longFur: true,
    ),
    BreedDef(
      id: 'dogGermanShepherd',
      familyId: 'dog',
      nameKey: 'breedDogGermanShepherd',
      primaryArgb: 0xFFB9824A,
      secondaryArgb: 0xFFD8B080,
      markingArgb: 0xFF2E2620,
      pattern: CoatPattern.saddle,
    ),
    BreedDef(
      id: 'dogAlaskanMalamute',
      familyId: 'dog',
      nameKey: 'breedDogAlaskanMalamute',
      primaryArgb: 0xFF7E8288,
      secondaryArgb: 0xFFF2F2F0,
      markingArgb: 0xFF4F5258,
      pattern: CoatPattern.tuxedo,
      longFur: true,
    ),
    BreedDef(
      id: 'dogHusky',
      familyId: 'dog',
      nameKey: 'breedDogHusky',
      primaryArgb: 0xFF5F6670,
      secondaryArgb: 0xFFF4F4F2,
      markingArgb: 0xFF3E434A,
      pattern: CoatPattern.tuxedo,
    ),
    BreedDef(
      id: 'dogCorgi',
      familyId: 'dog',
      nameKey: 'breedDogCorgi',
      primaryArgb: 0xFFD98B44,
      secondaryArgb: 0xFFF7F0E6,
      markingArgb: 0xFFB86A2C,
      pattern: CoatPattern.tuxedo,
    ),
    BreedDef(
      id: 'dogShibaInu',
      familyId: 'dog',
      nameKey: 'breedDogShibaInu',
      primaryArgb: 0xFFD7863F,
      secondaryArgb: 0xFFF5E8D3,
      markingArgb: 0xFFB5682A,
      pattern: CoatPattern.tuxedo,
    ),
    BreedDef(
      id: 'dogPomeranian',
      familyId: 'dog',
      nameKey: 'breedDogPomeranian',
      primaryArgb: 0xFFE3A35F,
      secondaryArgb: 0xFFF2C996,
      markingArgb: 0xFFC48440,
      pattern: CoatPattern.solid,
      longFur: true,
    ),
    BreedDef(
      id: 'dogDachshund',
      familyId: 'dog',
      nameKey: 'breedDogDachshund',
      primaryArgb: 0xFF7A4628,
      secondaryArgb: 0xFF9C5E36,
      markingArgb: 0xFF4E2A16,
      pattern: CoatPattern.solid,
    ),
    BreedDef(
      id: 'rabbitHollandLop',
      familyId: 'rabbit',
      nameKey: 'breedRabbitHollandLop',
      primaryArgb: 0xFFC9A684,
      secondaryArgb: 0xFFF0E6D8,
      markingArgb: 0xFF8C6A4A,
      pattern: CoatPattern.patches,
    ),
    BreedDef(
      id: 'rabbitRex',
      familyId: 'rabbit',
      nameKey: 'breedRabbitRex',
      primaryArgb: 0xFF8B6E5A,
      secondaryArgb: 0xFFB89C86,
      markingArgb: 0xFF6A5242,
      pattern: CoatPattern.solid,
    ),
    BreedDef(
      id: 'rabbitLionhead',
      familyId: 'rabbit',
      nameKey: 'breedRabbitLionhead',
      primaryArgb: 0xFFE0C49C,
      secondaryArgb: 0xFFF3E6D2,
      markingArgb: 0xFFC4A274,
      pattern: CoatPattern.solid,
      longFur: true,
    ),
    BreedDef(
      id: 'rabbitAngora',
      familyId: 'rabbit',
      nameKey: 'breedRabbitAngora',
      primaryArgb: 0xFFF4F1EC,
      secondaryArgb: 0xFFFFFFFF,
      markingArgb: 0xFFDCD6CC,
      pattern: CoatPattern.solid,
      longFur: true,
    ),
    BreedDef(
      id: 'rabbitNetherlandDwarf',
      familyId: 'rabbit',
      nameKey: 'breedRabbitNetherlandDwarf',
      primaryArgb: 0xFF6E6A66,
      secondaryArgb: 0xFF9A958F,
      markingArgb: 0xFF4E4A47,
      pattern: CoatPattern.solid,
    ),
    BreedDef(
      id: 'birdMerpati',
      familyId: 'bird',
      nameKey: 'breedBirdMerpati',
      primaryArgb: 0xFF9AA3AD,
      secondaryArgb: 0xFFC3CAD1,
      markingArgb: 0xFF4F8C78,
      pattern: CoatPattern.headColor,
    ),
    BreedDef(
      id: 'birdKakatua',
      familyId: 'bird',
      nameKey: 'breedBirdKakatua',
      primaryArgb: 0xFFF4F2EC,
      secondaryArgb: 0xFFFFFFFF,
      markingArgb: 0xFFF5D24A,
      pattern: CoatPattern.crest,
    ),
    BreedDef(
      id: 'birdLovebird',
      familyId: 'bird',
      nameKey: 'breedBirdLovebird',
      primaryArgb: 0xFF6DBE4E,
      secondaryArgb: 0xFFA8DC7A,
      markingArgb: 0xFFF08A3C,
      pattern: CoatPattern.headColor,
    ),
    BreedDef(
      id: 'birdJalakBali',
      familyId: 'bird',
      nameKey: 'breedBirdJalakBali',
      primaryArgb: 0xFFF6F6F2,
      secondaryArgb: 0xFFFFFFFF,
      markingArgb: 0xFF3D8BD8,
      pattern: CoatPattern.crest,
    ),
    BreedDef(
      id: 'birdBeo',
      familyId: 'bird',
      nameKey: 'breedBirdBeo',
      primaryArgb: 0xFF1F2328,
      secondaryArgb: 0xFF34393F,
      markingArgb: 0xFFF2C230,
      pattern: CoatPattern.headColor,
    ),
    BreedDef(
      id: 'hamsterSyrian',
      familyId: 'hamster',
      nameKey: 'breedHamsterSyrian',
      primaryArgb: 0xFFD9A066,
      secondaryArgb: 0xFFF4E6D2,
      markingArgb: 0xFFB27D46,
      pattern: CoatPattern.solid,
    ),
    BreedDef(
      id: 'hamsterWinterWhite',
      familyId: 'hamster',
      nameKey: 'breedHamsterWinterWhite',
      primaryArgb: 0xFFE3E4E6,
      secondaryArgb: 0xFFF6F6F6,
      markingArgb: 0xFF8D939A,
      pattern: CoatPattern.stripe,
    ),
    BreedDef(
      id: 'hamsterCampbell',
      familyId: 'hamster',
      nameKey: 'breedHamsterCampbell',
      primaryArgb: 0xFFB89A7C,
      secondaryArgb: 0xFFE9DCCB,
      markingArgb: 0xFF5C4A3A,
      pattern: CoatPattern.stripe,
    ),
    BreedDef(
      id: 'hamsterRoborovski',
      familyId: 'hamster',
      nameKey: 'breedHamsterRoborovski',
      primaryArgb: 0xFFE2C49A,
      secondaryArgb: 0xFFF7F0E4,
      markingArgb: 0xFFC9A57A,
      pattern: CoatPattern.solid,
    ),
    BreedDef(
      id: 'duckPeking',
      familyId: 'duck',
      nameKey: 'breedDuckPeking',
      primaryArgb: 0xFFF5F3EC,
      secondaryArgb: 0xFFFFFFFF,
      markingArgb: 0xFFE6E0D2,
      pattern: CoatPattern.solid,
    ),
    BreedDef(
      id: 'duckMallard',
      familyId: 'duck',
      nameKey: 'breedDuckMallard',
      primaryArgb: 0xFF8C7660,
      secondaryArgb: 0xFFB9A58E,
      markingArgb: 0xFF2F6B3F,
      pattern: CoatPattern.headColor,
    ),
    BreedDef(
      id: 'duckIndianRunner',
      familyId: 'duck',
      nameKey: 'breedDuckIndianRunner',
      primaryArgb: 0xFFD7C3A6,
      secondaryArgb: 0xFFF2ECE2,
      markingArgb: 0xFF9C8466,
      pattern: CoatPattern.headColor,
    ),
    BreedDef(
      id: 'duckMandarin',
      familyId: 'duck',
      nameKey: 'breedDuckMandarin',
      primaryArgb: 0xFFC9783E,
      secondaryArgb: 0xFFF2E6D0,
      markingArgb: 0xFF3D5AA8,
      pattern: CoatPattern.headColor,
    ),
    BreedDef(
      id: 'duckCallDuck',
      familyId: 'duck',
      nameKey: 'breedDuckCallDuck',
      primaryArgb: 0xFFF7F5EF,
      secondaryArgb: 0xFFFFFFFF,
      markingArgb: 0xFFE4DED2,
      pattern: CoatPattern.solid,
    ),
    BreedDef(
      id: 'chickenKampung',
      familyId: 'chicken',
      nameKey: 'breedChickenKampung',
      primaryArgb: 0xFF9C5A2E,
      secondaryArgb: 0xFFD9A35A,
      markingArgb: 0xFF233A2C,
      pattern: CoatPattern.tail,
    ),
    BreedDef(
      id: 'chickenPelung',
      familyId: 'chicken',
      nameKey: 'breedChickenPelung',
      primaryArgb: 0xFF6B3E22,
      secondaryArgb: 0xFFB0703A,
      markingArgb: 0xFF1E2C26,
      pattern: CoatPattern.tail,
    ),
    BreedDef(
      id: 'chickenCemani',
      familyId: 'chicken',
      nameKey: 'breedChickenCemani',
      primaryArgb: 0xFF1D1D21,
      secondaryArgb: 0xFF2A2A30,
      markingArgb: 0xFF141418,
      pattern: CoatPattern.solid,
    ),
    BreedDef(
      id: 'chickenBangkok',
      familyId: 'chicken',
      nameKey: 'breedChickenBangkok',
      primaryArgb: 0xFF5A3A28,
      secondaryArgb: 0xFFC07A3A,
      markingArgb: 0xFF1E2A24,
      pattern: CoatPattern.tail,
    ),
    BreedDef(
      id: 'chickenSilkie',
      familyId: 'chicken',
      nameKey: 'breedChickenSilkie',
      primaryArgb: 0xFFF7F5F0,
      secondaryArgb: 0xFFFFFFFF,
      markingArgb: 0xFFE6E2DA,
      pattern: CoatPattern.solid,
      longFur: true,
    ),
    BreedDef(
      id: 'turtleSulcata',
      familyId: 'turtle',
      nameKey: 'breedTurtleSulcata',
      primaryArgb: 0xFFC9B08A,
      secondaryArgb: 0xFFDCC8A4,
      markingArgb: 0xFFB08A55,
      pattern: CoatPattern.shell,
    ),
    BreedDef(
      id: 'turtleBrazil',
      familyId: 'turtle',
      nameKey: 'breedTurtleBrazil',
      primaryArgb: 0xFF6B8B4A,
      secondaryArgb: 0xFFE8D25A,
      markingArgb: 0xFF4F6B3A,
      pattern: CoatPattern.shell,
    ),
    BreedDef(
      id: 'turtleAmbon',
      familyId: 'turtle',
      nameKey: 'breedTurtleAmbon',
      primaryArgb: 0xFF8A7652,
      secondaryArgb: 0xFFE0C060,
      markingArgb: 0xFF4A3A2C,
      pattern: CoatPattern.shell,
    ),
    BreedDef(
      id: 'turtleLeopard',
      familyId: 'turtle',
      nameKey: 'breedTurtleLeopard',
      primaryArgb: 0xFFC9B08A,
      secondaryArgb: 0xFFDCC8A4,
      markingArgb: 0xFFD8C08A,
      pattern: CoatPattern.spotted,
    ),
    BreedDef(
      id: 'goatEtawa',
      familyId: 'goat',
      nameKey: 'breedGoatEtawa',
      primaryArgb: 0xFFF2EEE6,
      secondaryArgb: 0xFFFFFFFF,
      markingArgb: 0xFFB07A4E,
      pattern: CoatPattern.headColor,
      longFur: true,
    ),
    BreedDef(
      id: 'goatKacang',
      familyId: 'goat',
      nameKey: 'breedGoatKacang',
      primaryArgb: 0xFF7A5234,
      secondaryArgb: 0xFF9E7450,
      markingArgb: 0xFF4E3320,
      pattern: CoatPattern.solid,
    ),
    BreedDef(
      id: 'goatBoer',
      familyId: 'goat',
      nameKey: 'breedGoatBoer',
      primaryArgb: 0xFFF2EEE6,
      secondaryArgb: 0xFFFFFFFF,
      markingArgb: 0xFF8E4A2C,
      pattern: CoatPattern.headColor,
    ),
    BreedDef(
      id: 'goatSaanen',
      familyId: 'goat',
      nameKey: 'breedGoatSaanen',
      primaryArgb: 0xFFF6F4EF,
      secondaryArgb: 0xFFFFFFFF,
      markingArgb: 0xFFE2DED6,
      pattern: CoatPattern.solid,
    ),
    BreedDef(
      id: 'monkeyEkorPanjang',
      familyId: 'monkey',
      nameKey: 'breedMonkeyEkorPanjang',
      primaryArgb: 0xFF9C8466,
      secondaryArgb: 0xFFD8B49A,
      markingArgb: 0xFF7A6448,
      pattern: CoatPattern.solid,
    ),
    BreedDef(
      id: 'monkeyBekantan',
      familyId: 'monkey',
      nameKey: 'breedMonkeyBekantan',
      primaryArgb: 0xFFC6814A,
      secondaryArgb: 0xFFE6A07A,
      markingArgb: 0xFFE8E2D6,
      pattern: CoatPattern.solid,
    ),
    BreedDef(
      id: 'monkeyLutung',
      familyId: 'monkey',
      nameKey: 'breedMonkeyLutung',
      primaryArgb: 0xFF2C2A2A,
      secondaryArgb: 0xFF5A5450,
      markingArgb: 0xFFB0A8A0,
      pattern: CoatPattern.solid,
      longFur: true,
    ),
    BreedDef(
      id: 'monkeyKapusin',
      familyId: 'monkey',
      nameKey: 'breedMonkeyKapusin',
      primaryArgb: 0xFF5A4030,
      secondaryArgb: 0xFFF0E2CC,
      markingArgb: 0xFF3A2A20,
      pattern: CoatPattern.tuxedo,
    ),
  ];

  static List<BreedDef> ofFamily(String familyId) =>
      all.where((b) => b.familyId == familyId).toList();

  static final Map<String, BreedDef> _byId = {for (final b in all) b.id: b};

  static BreedDef byId(String id) =>
      _byId[id] ?? (throw ArgumentError('Unknown breed: $id'));
}
