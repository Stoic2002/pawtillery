// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Pawtillery';

  @override
  String get menuPlay => 'Play';

  @override
  String get back => 'Back';

  @override
  String hudAngle(int value) {
    return 'Angle $value°';
  }

  @override
  String hudPower(int value) {
    return 'Power $value%';
  }

  @override
  String hudWind(int value) {
    return 'Wind $value';
  }

  @override
  String get hudFire => 'Fire';

  @override
  String get hudDecrease => 'Decrease';

  @override
  String get hudIncrease => 'Increase';

  @override
  String debugExplosionTime(String lastMs, String maxMs) {
    return 'Explosion $lastMs ms (max $maxMs ms)';
  }

  @override
  String get weaponRock => 'Rock Toss';

  @override
  String get mapSandbox => 'Test Field';

  @override
  String get teamRed => 'Red Team';

  @override
  String get teamBlue => 'Blue Team';

  @override
  String get teamGreen => 'Green Team';

  @override
  String get teamYellow => 'Yellow Team';

  @override
  String turnBanner(String team) {
    return '$team\'s turn';
  }

  @override
  String hudSeconds(int value) {
    return '${value}s';
  }

  @override
  String hudRetreat(int value) {
    return 'Retreat ${value}s';
  }

  @override
  String get hudAimHint => 'Drag to aim';

  @override
  String get hudCancel => 'Cancel';

  @override
  String get hudWalkLeft => 'Walk left';

  @override
  String get hudWalkRight => 'Walk right';

  @override
  String get hudJump => 'Jump';

  @override
  String get hudHighJump => 'High jump';

  @override
  String get hudCenterCamera => 'Center on active unit';

  @override
  String resultWinner(String team) {
    return '$team wins!';
  }

  @override
  String get resultDraw => 'Draw!';

  @override
  String get resultPlayAgain => 'Play again';

  @override
  String get resultMainMenu => 'Main menu';

  @override
  String debugSeed(int seed) {
    return 'Seed $seed';
  }

  @override
  String get familyCat => 'Cat';

  @override
  String get passiveCat => 'Nine Lives';

  @override
  String get passiveCatDesc =>
      'Once per match, a lethal hit leaves it at 1 HP.';

  @override
  String get familyDog => 'Dog';

  @override
  String get passiveDog => 'Tough';

  @override
  String get passiveDogDesc => 'Starts with 120 HP.';

  @override
  String get familyRabbit => 'Rabbit';

  @override
  String get passiveRabbit => 'Jumper';

  @override
  String get passiveRabbitDesc => 'High jump goes twice as high.';

  @override
  String get familyBird => 'Bird';

  @override
  String get passiveBird => 'Glider';

  @override
  String get passiveBirdDesc =>
      'Floats down slowly after jumping; no fall damage.';

  @override
  String get familyHamster => 'Hamster';

  @override
  String get passiveHamster => 'Tiny';

  @override
  String get passiveHamsterDesc => '30% smaller target, 85 HP.';

  @override
  String get familyDuck => 'Duck';

  @override
  String get passiveDuck => 'Swimmer';

  @override
  String get passiveDuckDesc =>
      'Once per match, survives the water for 25 HP and climbs out on the nearest land.';

  @override
  String get familyChicken => 'Chicken';

  @override
  String get passiveChicken => 'Flapper';

  @override
  String get passiveChickenDesc => 'Can jump again in mid-air.';

  @override
  String get familyTurtle => 'Turtle';

  @override
  String get passiveTurtle => 'Shell';

  @override
  String get passiveTurtleDesc =>
      'Takes 25% less blast damage, walks 30% slower.';

  @override
  String get familyGoat => 'Goat';

  @override
  String get passiveGoat => 'Climber';

  @override
  String get passiveGoatDesc => 'Climbs steps up to 14 px high.';

  @override
  String get familyMonkey => 'Monkey';

  @override
  String get passiveMonkey => 'Strong Arm';

  @override
  String get passiveMonkeyDesc => 'Throws up to 20% harder.';

  @override
  String get weaponGrenade => 'Bouncy Grenade';

  @override
  String get weaponCluster => 'Cluster Bomb';

  @override
  String get weaponTwinSling => 'Twin Slingshot';

  @override
  String get weaponPunch => 'Punch';

  @override
  String get weaponMine => 'Mine';

  @override
  String get weaponTeleport => 'Teleport';

  @override
  String get weaponSkip => 'Skip Turn';

  @override
  String get weaponHairball => 'Hairball Cluster';

  @override
  String get weaponBoneBoomerang => 'Boomerang Bone';

  @override
  String get weaponDrillCarrot => 'Drill Carrot';

  @override
  String get weaponEggStrike => 'Egg Strike';

  @override
  String get weaponSeedMines => 'Seed Mines';

  @override
  String get weaponBoomDuck => 'Boom Duck';

  @override
  String get weaponStartleCrow => 'Startle Crow';

  @override
  String get weaponFortress => 'Fortress';

  @override
  String get weaponHeadbutt => 'Headbutt';

  @override
  String get weaponCoconut => 'Falling Coconut';

  @override
  String get breedCatKampung => 'Kampung';

  @override
  String get breedCatAngora => 'Anggora';

  @override
  String get breedCatBritishShorthair => 'British Shorthair';

  @override
  String get breedCatSiberian => 'Siberian';

  @override
  String get breedCatPersia => 'Persia';

  @override
  String get breedCatMaineCoon => 'Maine Coon';

  @override
  String get breedCatBengal => 'Bengal';

  @override
  String get breedCatSphynx => 'Sphynx';

  @override
  String get breedDogGoldenRetriever => 'Golden Retriever';

  @override
  String get breedDogGermanShepherd => 'German Shepherd';

  @override
  String get breedDogAlaskanMalamute => 'Alaskan Malamute';

  @override
  String get breedDogHusky => 'Husky';

  @override
  String get breedDogCorgi => 'Corgi';

  @override
  String get breedDogShibaInu => 'Shiba Inu';

  @override
  String get breedDogPomeranian => 'Pomeranian';

  @override
  String get breedDogDachshund => 'Dachshund';

  @override
  String get breedRabbitHollandLop => 'Holland Lop';

  @override
  String get breedRabbitRex => 'Rex';

  @override
  String get breedRabbitLionhead => 'Lionhead';

  @override
  String get breedRabbitAngora => 'Angora';

  @override
  String get breedRabbitNetherlandDwarf => 'Netherland Dwarf';

  @override
  String get breedBirdMerpati => 'Merpati';

  @override
  String get breedBirdKakatua => 'Kakatua';

  @override
  String get breedBirdLovebird => 'Lovebird';

  @override
  String get breedBirdJalakBali => 'Jalak Bali';

  @override
  String get breedBirdBeo => 'Beo';

  @override
  String get breedHamsterSyrian => 'Syrian';

  @override
  String get breedHamsterWinterWhite => 'Winter White';

  @override
  String get breedHamsterCampbell => 'Campbell';

  @override
  String get breedHamsterRoborovski => 'Roborovski';

  @override
  String get breedDuckPeking => 'Peking';

  @override
  String get breedDuckMallard => 'Mallard';

  @override
  String get breedDuckIndianRunner => 'Indian Runner';

  @override
  String get breedDuckMandarin => 'Mandarin';

  @override
  String get breedDuckCallDuck => 'Call Duck';

  @override
  String get breedChickenKampung => 'Kampung';

  @override
  String get breedChickenPelung => 'Pelung';

  @override
  String get breedChickenCemani => 'Cemani';

  @override
  String get breedChickenBangkok => 'Bangkok';

  @override
  String get breedChickenSilkie => 'Silkie';

  @override
  String get breedTurtleSulcata => 'Sulcata';

  @override
  String get breedTurtleBrazil => 'Brazil';

  @override
  String get breedTurtleAmbon => 'Ambon';

  @override
  String get breedTurtleLeopard => 'Leopard';

  @override
  String get breedGoatEtawa => 'Etawa';

  @override
  String get breedGoatKacang => 'Kacang';

  @override
  String get breedGoatBoer => 'Boer';

  @override
  String get breedGoatSaanen => 'Saanen';

  @override
  String get breedMonkeyEkorPanjang => 'Ekor Panjang';

  @override
  String get breedMonkeyBekantan => 'Bekantan';

  @override
  String get breedMonkeyLutung => 'Lutung';

  @override
  String get breedMonkeyKapusin => 'Kapusin';

  @override
  String get hudWeapons => 'Weapons';

  @override
  String get hudSignature => 'Signature';

  @override
  String get hudUsed => 'Used';

  @override
  String hudAmmoLeft(int count) {
    return '×$count';
  }

  @override
  String get hudAmmoUnlimited => '∞';

  @override
  String hudFuse(int seconds) {
    return 'Fuse ${seconds}s';
  }

  @override
  String get hudTapTarget => 'Tap a target on the map';

  @override
  String get hudInvalidTarget => 'Can’t use it there';

  @override
  String get hudUse => 'Use';

  @override
  String get hudDirectionHint => 'Drag to pick a direction';
}
