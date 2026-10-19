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
    return '$team wins';
  }

  @override
  String get resultDraw => 'A draw';

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

  @override
  String get splashLoading => 'Loading…';

  @override
  String get menuHowToPlay => 'How to Play';

  @override
  String get menuSettings => 'Settings';

  @override
  String get menuAbout => 'About';

  @override
  String get teamPurple => 'Purple Team';

  @override
  String get teamOrange => 'Orange Team';

  @override
  String get mapCastle => 'Haunted Keep';

  @override
  String get mapWreck => 'Shipwreck Cove';

  @override
  String get mapRuins => 'Ruined Village';

  @override
  String get unitNamePool =>
      'Milo,Luna,Bobo,Kiki,Coco,Momo,Pip,Nala,Toby,Ziggy,Biscuit,Pepper,Mochi,Tofu,Nugget,Peanut,Waffle,Pixel';

  @override
  String get setupTitle => 'New Match';

  @override
  String get setupTeams => 'Teams';

  @override
  String get setupUnitsPerTeam => 'Units per team';

  @override
  String get setupTurnTime => 'Turn time';

  @override
  String get setupMap => 'Map';

  @override
  String get setupMapRandom => 'Random';

  @override
  String get setupSuddenDeath => 'Sudden death';

  @override
  String get setupOff => 'Off';

  @override
  String setupMinutes(int minutes) {
    return 'After $minutes min';
  }

  @override
  String get setupRandomAll => 'Random';

  @override
  String get setupRandomUnit => 'Randomize this unit';

  @override
  String get setupStart => 'Start';

  @override
  String get setupTeamName => 'Team name';

  @override
  String get setupUnitName => 'Name';

  @override
  String get setupFamily => 'Family';

  @override
  String get setupBreed => 'Breed';

  @override
  String get setupColor => 'Team colour';

  @override
  String get setupOptions => 'Match options';

  @override
  String get hudPause => 'Pause';

  @override
  String get hudSuddenDeath => 'Sudden death';

  @override
  String get pauseTitle => 'Paused';

  @override
  String get pauseResume => 'Resume';

  @override
  String get pauseExit => 'Exit to menu';

  @override
  String get pauseExitConfirmTitle => 'Leave the match?';

  @override
  String get pauseExitConfirmBody => 'This match will be lost.';

  @override
  String get dialogCancel => 'Cancel';

  @override
  String get dialogLeave => 'Leave';

  @override
  String get resultChangeTeams => 'Change teams';

  @override
  String get resultMostDamage => 'Most damage';

  @override
  String resultMostDamageValue(String name, String team, int damage) {
    return '$name ($team): $damage HP';
  }

  @override
  String get resultNoDamage => 'Nobody landed a hit';

  @override
  String get resultKills => 'Knockouts per team';

  @override
  String resultTurns(int count) {
    return 'Over $count turns';
  }

  @override
  String get howNext => 'Next';

  @override
  String get howDone => 'Got it';

  @override
  String get howMoveTitle => 'Move';

  @override
  String get howMoveBody =>
      'Hold the arrow buttons to walk. Two jump buttons: a forward hop and a high jump. Falling far hurts; water and the map edges are deadly.';

  @override
  String get howAimTitle => 'Aim and fire';

  @override
  String get howAimBody =>
      'Drag anywhere with one finger, like a slingshot: pull back to aim, pull further for more power. Fine-tune with the ± buttons, then press Fire. Drag back to the start to cancel.';

  @override
  String get howWeaponsTitle => 'Weapons';

  @override
  String get howWeaponsBody =>
      'Open the weapon menu to switch. Some weapons have limited ammo per team. Every family has one signature weapon each unit can use once per match.';

  @override
  String get howWindTitle => 'Wind and turns';

  @override
  String get howWindBody =>
      'Wind changes every turn and pushes most thrown weapons. You get one shot per turn, then 3 seconds to run before the next team plays.';

  @override
  String get howFamiliesTitle => 'Families';

  @override
  String get howFamiliesBody =>
      'Each family has a passive ability: cats survive one lethal hit, dogs are tougher, rabbits jump higher, birds glide, and more. Breeds only change the look.';

  @override
  String get howWinTitle => 'Winning';

  @override
  String get howWinBody =>
      'The last team with units standing wins. Two fingers move and zoom the camera. If sudden death starts, everyone drops to 1 HP and the water rises every round.';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'Device language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageIndonesian => 'Bahasa Indonesia';

  @override
  String get settingsMusic => 'Music volume';

  @override
  String get settingsSfx => 'Sound effects volume';

  @override
  String get settingsHaptics => 'Vibration';

  @override
  String get settingsAimGuide => 'Show aim guide';

  @override
  String get settingsTutorial => 'Show the tutorial again';

  @override
  String get settingsTutorialReset =>
      'The tutorial will show in your next match.';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutDescription =>
      'A turn-based animal artillery game for friends sharing one phone.';

  @override
  String get aboutCredits => 'Asset credits';

  @override
  String get aboutPrivacy => 'Privacy policy';

  @override
  String get aboutPrivacyNote => 'This game collects no data. Full policy:';

  @override
  String get aboutCopyLink => 'Copy link';

  @override
  String get aboutLinkCopied => 'Link copied';

  @override
  String get tutorialWalk => 'Hold an arrow to walk';

  @override
  String get tutorialWeapons => 'Tap here to choose a weapon';

  @override
  String get tutorialAim => 'Drag anywhere to aim, like a slingshot';

  @override
  String get tutorialFire => 'Press Fire';

  @override
  String get tutorialSkip => 'Skip tutorial';

  @override
  String debugFps(int fps, String worstMs) {
    return '$fps fps · worst $worstMs ms';
  }

  @override
  String get familyCatLatin => 'Felis catus';

  @override
  String get familyDogLatin => 'Canis familiaris';

  @override
  String get familyRabbitLatin => 'Oryctolagus cuniculus';

  @override
  String get familyBirdLatin => 'Aves';

  @override
  String get familyHamsterLatin => 'Cricetinae';

  @override
  String get familyDuckLatin => 'Anas platyrhynchos';

  @override
  String get familyChickenLatin => 'Gallus gallus';

  @override
  String get familyTurtleLatin => 'Testudines';

  @override
  String get familyGoatLatin => 'Capra hircus';

  @override
  String get familyMonkeyLatin => 'Primates';

  @override
  String get menuSubtitle => 'Animal artillery after dark';

  @override
  String get setupChooseFamily => 'Choose a family';

  @override
  String get setupChooseBreed => 'Choose a breed';

  @override
  String get setupConditions => 'Match rules';

  @override
  String get resultReport => 'Match stats';

  @override
  String get settingsOn => 'On';
}
