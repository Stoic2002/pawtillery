/// Breeds (PRD: Breed per family). Purely cosmetic: a breed never changes
/// a gameplay number. Pure Dart; colours are 0xAARRGGBB.
library;

class BreedDef {
  const BreedDef({
    required this.id,
    required this.familyId,
    required this.nameKey,
    required this.primaryArgb,
    required this.secondaryArgb,
    this.spritePath,
  });

  final String id;
  final String familyId;

  /// ARB key; breed names are common breed names and mostly identical in
  /// both languages.
  final String nameKey;
  final int primaryArgb;
  final int secondaryArgb;

  /// Sprite folder under `assets/units/<family>/<breed>/`, once art exists.
  final String? spritePath;
}

abstract final class Breeds {
  static const all = [
    BreedDef(
      id: 'catKampung',
      familyId: 'cat',
      nameKey: 'breedCatKampung',
      primaryArgb: 0xFFE0A050,
      secondaryArgb: 0xFFFFFFFF,
    ),
    BreedDef(
      id: 'catAngora',
      familyId: 'cat',
      nameKey: 'breedCatAngora',
      primaryArgb: 0xFFF5F5F5,
      secondaryArgb: 0xFFD7CCC8,
    ),
    BreedDef(
      id: 'catBritishShorthair',
      familyId: 'cat',
      nameKey: 'breedCatBritishShorthair',
      primaryArgb: 0xFF90A4AE,
      secondaryArgb: 0xFF607D8B,
    ),
    BreedDef(
      id: 'catSiberian',
      familyId: 'cat',
      nameKey: 'breedCatSiberian',
      primaryArgb: 0xFFA1887F,
      secondaryArgb: 0xFFEFEBE9,
    ),
    BreedDef(
      id: 'catPersia',
      familyId: 'cat',
      nameKey: 'breedCatPersia',
      primaryArgb: 0xFFFFF3E0,
      secondaryArgb: 0xFFFFCC80,
    ),
    BreedDef(
      id: 'catMaineCoon',
      familyId: 'cat',
      nameKey: 'breedCatMaineCoon',
      primaryArgb: 0xFF8D6E63,
      secondaryArgb: 0xFF4E342E,
    ),
    BreedDef(
      id: 'catBengal',
      familyId: 'cat',
      nameKey: 'breedCatBengal',
      primaryArgb: 0xFFFFB74D,
      secondaryArgb: 0xFF5D4037,
    ),
    BreedDef(
      id: 'catSphynx',
      familyId: 'cat',
      nameKey: 'breedCatSphynx',
      primaryArgb: 0xFFF8BBD0,
      secondaryArgb: 0xFFEC407A,
    ),
    BreedDef(
      id: 'dogGoldenRetriever',
      familyId: 'dog',
      nameKey: 'breedDogGoldenRetriever',
      primaryArgb: 0xFFFFCA28,
      secondaryArgb: 0xFFFFA000,
    ),
    BreedDef(
      id: 'dogGermanShepherd',
      familyId: 'dog',
      nameKey: 'breedDogGermanShepherd',
      primaryArgb: 0xFF8D6E63,
      secondaryArgb: 0xFF212121,
    ),
    BreedDef(
      id: 'dogAlaskanMalamute',
      familyId: 'dog',
      nameKey: 'breedDogAlaskanMalamute',
      primaryArgb: 0xFF9E9E9E,
      secondaryArgb: 0xFFFFFFFF,
    ),
    BreedDef(
      id: 'dogHusky',
      familyId: 'dog',
      nameKey: 'breedDogHusky',
      primaryArgb: 0xFF78909C,
      secondaryArgb: 0xFFFFFFFF,
    ),
    BreedDef(
      id: 'dogCorgi',
      familyId: 'dog',
      nameKey: 'breedDogCorgi',
      primaryArgb: 0xFFFF8A65,
      secondaryArgb: 0xFFFFFFFF,
    ),
    BreedDef(
      id: 'dogShibaInu',
      familyId: 'dog',
      nameKey: 'breedDogShibaInu',
      primaryArgb: 0xFFFF9800,
      secondaryArgb: 0xFFFFF3E0,
    ),
    BreedDef(
      id: 'dogPomeranian',
      familyId: 'dog',
      nameKey: 'breedDogPomeranian',
      primaryArgb: 0xFFFFB74D,
      secondaryArgb: 0xFFFFE0B2,
    ),
    BreedDef(
      id: 'dogDachshund',
      familyId: 'dog',
      nameKey: 'breedDogDachshund',
      primaryArgb: 0xFF6D4C41,
      secondaryArgb: 0xFF3E2723,
    ),
    BreedDef(
      id: 'rabbitHollandLop',
      familyId: 'rabbit',
      nameKey: 'breedRabbitHollandLop',
      primaryArgb: 0xFFD7CCC8,
      secondaryArgb: 0xFF8D6E63,
    ),
    BreedDef(
      id: 'rabbitRex',
      familyId: 'rabbit',
      nameKey: 'breedRabbitRex',
      primaryArgb: 0xFFBCAAA4,
      secondaryArgb: 0xFF6D4C41,
    ),
    BreedDef(
      id: 'rabbitLionhead',
      familyId: 'rabbit',
      nameKey: 'breedRabbitLionhead',
      primaryArgb: 0xFFFFE0B2,
      secondaryArgb: 0xFFFFB74D,
    ),
    BreedDef(
      id: 'rabbitAngora',
      familyId: 'rabbit',
      nameKey: 'breedRabbitAngora',
      primaryArgb: 0xFFFAFAFA,
      secondaryArgb: 0xFFE0E0E0,
    ),
    BreedDef(
      id: 'rabbitNetherlandDwarf',
      familyId: 'rabbit',
      nameKey: 'breedRabbitNetherlandDwarf',
      primaryArgb: 0xFF757575,
      secondaryArgb: 0xFFBDBDBD,
    ),
    BreedDef(
      id: 'birdMerpati',
      familyId: 'bird',
      nameKey: 'breedBirdMerpati',
      primaryArgb: 0xFFB0BEC5,
      secondaryArgb: 0xFF546E7A,
    ),
    BreedDef(
      id: 'birdKakatua',
      familyId: 'bird',
      nameKey: 'breedBirdKakatua',
      primaryArgb: 0xFFFFFFFF,
      secondaryArgb: 0xFFFFEB3B,
    ),
    BreedDef(
      id: 'birdLovebird',
      familyId: 'bird',
      nameKey: 'breedBirdLovebird',
      primaryArgb: 0xFF66BB6A,
      secondaryArgb: 0xFFFF7043,
    ),
    BreedDef(
      id: 'birdJalakBali',
      familyId: 'bird',
      nameKey: 'breedBirdJalakBali',
      primaryArgb: 0xFFFFFFFF,
      secondaryArgb: 0xFF1E88E5,
    ),
    BreedDef(
      id: 'birdBeo',
      familyId: 'bird',
      nameKey: 'breedBirdBeo',
      primaryArgb: 0xFF263238,
      secondaryArgb: 0xFFFFC107,
    ),
    BreedDef(
      id: 'hamsterSyrian',
      familyId: 'hamster',
      nameKey: 'breedHamsterSyrian',
      primaryArgb: 0xFFFFCC80,
      secondaryArgb: 0xFFFFFFFF,
    ),
    BreedDef(
      id: 'hamsterWinterWhite',
      familyId: 'hamster',
      nameKey: 'breedHamsterWinterWhite',
      primaryArgb: 0xFFECEFF1,
      secondaryArgb: 0xFF90A4AE,
    ),
    BreedDef(
      id: 'hamsterCampbell',
      familyId: 'hamster',
      nameKey: 'breedHamsterCampbell',
      primaryArgb: 0xFFBCAAA4,
      secondaryArgb: 0xFF795548,
    ),
    BreedDef(
      id: 'hamsterRoborovski',
      familyId: 'hamster',
      nameKey: 'breedHamsterRoborovski',
      primaryArgb: 0xFFFFE0B2,
      secondaryArgb: 0xFFFFFFFF,
    ),
    BreedDef(
      id: 'duckPeking',
      familyId: 'duck',
      nameKey: 'breedDuckPeking',
      primaryArgb: 0xFFFFFDE7,
      secondaryArgb: 0xFFFFA726,
    ),
    BreedDef(
      id: 'duckMallard',
      familyId: 'duck',
      nameKey: 'breedDuckMallard',
      primaryArgb: 0xFF8D6E63,
      secondaryArgb: 0xFF2E7D32,
    ),
    BreedDef(
      id: 'duckIndianRunner',
      familyId: 'duck',
      nameKey: 'breedDuckIndianRunner',
      primaryArgb: 0xFFD7CCC8,
      secondaryArgb: 0xFFFFFFFF,
    ),
    BreedDef(
      id: 'duckMandarin',
      familyId: 'duck',
      nameKey: 'breedDuckMandarin',
      primaryArgb: 0xFFFF7043,
      secondaryArgb: 0xFF3949AB,
    ),
    BreedDef(
      id: 'duckCallDuck',
      familyId: 'duck',
      nameKey: 'breedDuckCallDuck',
      primaryArgb: 0xFFFAFAFA,
      secondaryArgb: 0xFFFFB300,
    ),
    BreedDef(
      id: 'chickenKampung',
      familyId: 'chicken',
      nameKey: 'breedChickenKampung',
      primaryArgb: 0xFFA1887F,
      secondaryArgb: 0xFFD84315,
    ),
    BreedDef(
      id: 'chickenPelung',
      familyId: 'chicken',
      nameKey: 'breedChickenPelung',
      primaryArgb: 0xFF6D4C41,
      secondaryArgb: 0xFFFFB300,
    ),
    BreedDef(
      id: 'chickenCemani',
      familyId: 'chicken',
      nameKey: 'breedChickenCemani',
      primaryArgb: 0xFF212121,
      secondaryArgb: 0xFF424242,
    ),
    BreedDef(
      id: 'chickenBangkok',
      familyId: 'chicken',
      nameKey: 'breedChickenBangkok',
      primaryArgb: 0xFF8D6E63,
      secondaryArgb: 0xFFBF360C,
    ),
    BreedDef(
      id: 'chickenSilkie',
      familyId: 'chicken',
      nameKey: 'breedChickenSilkie',
      primaryArgb: 0xFFFFFFFF,
      secondaryArgb: 0xFF90A4AE,
    ),
    BreedDef(
      id: 'turtleSulcata',
      familyId: 'turtle',
      nameKey: 'breedTurtleSulcata',
      primaryArgb: 0xFFD7CCC8,
      secondaryArgb: 0xFF8D6E63,
    ),
    BreedDef(
      id: 'turtleBrazil',
      familyId: 'turtle',
      nameKey: 'breedTurtleBrazil',
      primaryArgb: 0xFF66BB6A,
      secondaryArgb: 0xFFFFEB3B,
    ),
    BreedDef(
      id: 'turtleAmbon',
      familyId: 'turtle',
      nameKey: 'breedTurtleAmbon',
      primaryArgb: 0xFF5D4037,
      secondaryArgb: 0xFF8D6E63,
    ),
    BreedDef(
      id: 'turtleLeopard',
      familyId: 'turtle',
      nameKey: 'breedTurtleLeopard',
      primaryArgb: 0xFFFFE082,
      secondaryArgb: 0xFF4E342E,
    ),
    BreedDef(
      id: 'goatEtawa',
      familyId: 'goat',
      nameKey: 'breedGoatEtawa',
      primaryArgb: 0xFFFFFFFF,
      secondaryArgb: 0xFF795548,
    ),
    BreedDef(
      id: 'goatKacang',
      familyId: 'goat',
      nameKey: 'breedGoatKacang',
      primaryArgb: 0xFF6D4C41,
      secondaryArgb: 0xFF3E2723,
    ),
    BreedDef(
      id: 'goatBoer',
      familyId: 'goat',
      nameKey: 'breedGoatBoer',
      primaryArgb: 0xFFFFFFFF,
      secondaryArgb: 0xFF8D6E63,
    ),
    BreedDef(
      id: 'goatSaanen',
      familyId: 'goat',
      nameKey: 'breedGoatSaanen',
      primaryArgb: 0xFFFAFAFA,
      secondaryArgb: 0xFFE0E0E0,
    ),
    BreedDef(
      id: 'monkeyEkorPanjang',
      familyId: 'monkey',
      nameKey: 'breedMonkeyEkorPanjang',
      primaryArgb: 0xFFA1887F,
      secondaryArgb: 0xFFD7CCC8,
    ),
    BreedDef(
      id: 'monkeyBekantan',
      familyId: 'monkey',
      nameKey: 'breedMonkeyBekantan',
      primaryArgb: 0xFFFF8A65,
      secondaryArgb: 0xFFEFEBE9,
    ),
    BreedDef(
      id: 'monkeyLutung',
      familyId: 'monkey',
      nameKey: 'breedMonkeyLutung',
      primaryArgb: 0xFF424242,
      secondaryArgb: 0xFFBDBDBD,
    ),
    BreedDef(
      id: 'monkeyKapusin',
      familyId: 'monkey',
      nameKey: 'breedMonkeyKapusin',
      primaryArgb: 0xFF5D4037,
      secondaryArgb: 0xFFFFF3E0,
    ),
  ];

  static List<BreedDef> ofFamily(String familyId) =>
      all.where((b) => b.familyId == familyId).toList();

  static final Map<String, BreedDef> _byId = {for (final b in all) b.id: b};

  static BreedDef byId(String id) =>
      _byId[id] ?? (throw ArgumentError('Unknown breed: $id'));
}
