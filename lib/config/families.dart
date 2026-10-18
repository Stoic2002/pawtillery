/// Family data (PRD: Family dan breed). A family decides gameplay through
/// one passive — expressed purely as modifiers on [UnitConfig] numbers — and
/// one signature weapon. Pure Dart. Adding a family = adding data here.
library;

/// One family's passive, as parameters. Anything left at its default means
/// "same as the base unit".
class PassiveDef {
  const PassiveDef({
    required this.nameKey,
    required this.descriptionKey,
    this.maxHp,
    this.hitboxScale = 1,
    this.walkSpeedScale = 1,
    this.maxClimb,
    this.highJumpHeightScale = 1,
    this.glide = false,
    this.fallDamage = true,
    this.airJumps = 0,
    this.explosionDamageTakenScale = 1,
    this.firePowerScale = 1,
    this.lethalSaves = 0,
    this.waterSaves = 0,
    this.waterSaveDamage = 25,
  });

  final String nameKey;
  final String descriptionKey;

  /// Replaces the base starting HP.
  final int? maxHp;

  /// Scales body height and hit radius.
  final double hitboxScale;
  final double walkSpeedScale;

  /// Replaces the base climbable step height.
  final int? maxClimb;

  /// High-jump peak height multiplier.
  final double highJumpHeightScale;

  /// Falls slowly after jumping.
  final bool glide;
  final bool fallDamage;

  /// Extra jumps allowed in mid-air.
  final int airJumps;
  final double explosionDamageTakenScale;

  /// Multiplies launch speed, so 100 % power goes further.
  final double firePowerScale;

  /// Times per match lethal damage leaves the unit at 1 HP instead.
  final int lethalSaves;

  /// Times per match falling in water costs [waterSaveDamage] HP and puts
  /// the unit back on the nearest land instead of drowning it.
  final int waterSaves;
  final int waterSaveDamage;
}

/// Which distinguishing feature the placeholder body gets.
enum PlaceholderFeature {
  pointyEars,
  floppyEars,
  longEars,
  beak,
  roundEars,
  bill,
  comb,
  shell,
  horns,
  sideEars,
}

class FamilyDef {
  const FamilyDef({
    required this.id,
    required this.nameKey,
    required this.latinKey,
    required this.passive,
    required this.signatureWeaponId,
    required this.feature,
  });

  final String id;
  final String nameKey;

  /// ARB key of the scientific name (field-guide voice).
  final String latinKey;
  final PassiveDef passive;
  final String signatureWeaponId;
  final PlaceholderFeature feature;
}

abstract final class Families {
  static const cat = FamilyDef(
    id: 'cat',
    nameKey: 'familyCat',
    latinKey: 'familyCatLatin',
    signatureWeaponId: 'hairball',
    feature: PlaceholderFeature.pointyEars,
    passive: PassiveDef(
      nameKey: 'passiveCat',
      descriptionKey: 'passiveCatDesc',
      lethalSaves: 1,
    ),
  );

  static const dog = FamilyDef(
    id: 'dog',
    nameKey: 'familyDog',
    latinKey: 'familyDogLatin',
    signatureWeaponId: 'boneBoomerang',
    feature: PlaceholderFeature.floppyEars,
    passive: PassiveDef(
      nameKey: 'passiveDog',
      descriptionKey: 'passiveDogDesc',
      maxHp: 120,
    ),
  );

  static const rabbit = FamilyDef(
    id: 'rabbit',
    nameKey: 'familyRabbit',
    latinKey: 'familyRabbitLatin',
    signatureWeaponId: 'drillCarrot',
    feature: PlaceholderFeature.longEars,
    passive: PassiveDef(
      nameKey: 'passiveRabbit',
      descriptionKey: 'passiveRabbitDesc',
      highJumpHeightScale: 2,
    ),
  );

  static const bird = FamilyDef(
    id: 'bird',
    nameKey: 'familyBird',
    latinKey: 'familyBirdLatin',
    signatureWeaponId: 'eggStrike',
    feature: PlaceholderFeature.beak,
    passive: PassiveDef(
      nameKey: 'passiveBird',
      descriptionKey: 'passiveBirdDesc',
      glide: true,
      fallDamage: false,
    ),
  );

  static const hamster = FamilyDef(
    id: 'hamster',
    nameKey: 'familyHamster',
    latinKey: 'familyHamsterLatin',
    signatureWeaponId: 'seedMines',
    feature: PlaceholderFeature.roundEars,
    passive: PassiveDef(
      nameKey: 'passiveHamster',
      descriptionKey: 'passiveHamsterDesc',
      hitboxScale: 0.7,
      maxHp: 85,
    ),
  );

  static const duck = FamilyDef(
    id: 'duck',
    nameKey: 'familyDuck',
    latinKey: 'familyDuckLatin',
    signatureWeaponId: 'boomDuck',
    feature: PlaceholderFeature.bill,
    passive: PassiveDef(
      nameKey: 'passiveDuck',
      descriptionKey: 'passiveDuckDesc',
      waterSaves: 1,
      waterSaveDamage: 25,
    ),
  );

  static const chicken = FamilyDef(
    id: 'chicken',
    nameKey: 'familyChicken',
    latinKey: 'familyChickenLatin',
    signatureWeaponId: 'startleCrow',
    feature: PlaceholderFeature.comb,
    passive: PassiveDef(
      nameKey: 'passiveChicken',
      descriptionKey: 'passiveChickenDesc',
      airJumps: 1,
    ),
  );

  static const turtle = FamilyDef(
    id: 'turtle',
    nameKey: 'familyTurtle',
    latinKey: 'familyTurtleLatin',
    signatureWeaponId: 'fortress',
    feature: PlaceholderFeature.shell,
    passive: PassiveDef(
      nameKey: 'passiveTurtle',
      descriptionKey: 'passiveTurtleDesc',
      explosionDamageTakenScale: 0.75,
      walkSpeedScale: 0.7,
    ),
  );

  static const goat = FamilyDef(
    id: 'goat',
    nameKey: 'familyGoat',
    latinKey: 'familyGoatLatin',
    signatureWeaponId: 'headbutt',
    feature: PlaceholderFeature.horns,
    passive: PassiveDef(
      nameKey: 'passiveGoat',
      descriptionKey: 'passiveGoatDesc',
      maxClimb: 14,
    ),
  );

  static const monkey = FamilyDef(
    id: 'monkey',
    nameKey: 'familyMonkey',
    latinKey: 'familyMonkeyLatin',
    signatureWeaponId: 'coconut',
    feature: PlaceholderFeature.sideEars,
    passive: PassiveDef(
      nameKey: 'passiveMonkey',
      descriptionKey: 'passiveMonkeyDesc',
      firePowerScale: 1.2,
    ),
  );

  static const all = [
    cat,
    dog,
    rabbit,
    bird,
    hamster,
    duck,
    chicken,
    turtle,
    goat,
    monkey,
  ];

  static final Map<String, FamilyDef> _byId = {for (final f in all) f.id: f};

  static FamilyDef byId(String id) =>
      _byId[id] ?? (throw ArgumentError('Unknown family: $id'));
}
