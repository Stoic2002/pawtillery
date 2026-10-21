import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// Working title of the game.
  ///
  /// In en, this message translates to:
  /// **'Pawtillery'**
  String get appTitle;

  /// Main menu button that starts a match.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get menuPlay;

  /// Generic back button.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Current aim angle in degrees.
  ///
  /// In en, this message translates to:
  /// **'Angle {value}°'**
  String hudAngle(int value);

  /// Current shot power in percent.
  ///
  /// In en, this message translates to:
  /// **'Power {value}%'**
  String hudPower(int value);

  /// Wind strength, -10..10.
  ///
  /// In en, this message translates to:
  /// **'Wind {value}'**
  String hudWind(int value);

  /// Fire button.
  ///
  /// In en, this message translates to:
  /// **'Fire'**
  String get hudFire;

  /// Accessibility label for minus buttons.
  ///
  /// In en, this message translates to:
  /// **'Decrease'**
  String get hudDecrease;

  /// Accessibility label for plus buttons.
  ///
  /// In en, this message translates to:
  /// **'Increase'**
  String get hudIncrease;

  /// Debug-only timing readout.
  ///
  /// In en, this message translates to:
  /// **'Explosion {lastMs} ms (max {maxMs} ms)'**
  String debugExplosionTime(String lastMs, String maxMs);

  /// Basic thrown-rock weapon.
  ///
  /// In en, this message translates to:
  /// **'Rock Toss'**
  String get weaponRock;

  /// Name of the test map.
  ///
  /// In en, this message translates to:
  /// **'Test Field'**
  String get mapSandbox;

  /// Default name of team 1.
  ///
  /// In en, this message translates to:
  /// **'Red Team'**
  String get teamRed;

  /// Default name of team 2.
  ///
  /// In en, this message translates to:
  /// **'Blue Team'**
  String get teamBlue;

  /// Default name of team 3.
  ///
  /// In en, this message translates to:
  /// **'Green Team'**
  String get teamGreen;

  /// Default name of team 4.
  ///
  /// In en, this message translates to:
  /// **'Yellow Team'**
  String get teamYellow;

  /// Banner at the start of a turn.
  ///
  /// In en, this message translates to:
  /// **'{team}\'s turn'**
  String turnBanner(String team);

  /// Turn clock, whole seconds.
  ///
  /// In en, this message translates to:
  /// **'{value}s'**
  String hudSeconds(int value);

  /// Retreat clock after firing.
  ///
  /// In en, this message translates to:
  /// **'Retreat {value}s'**
  String hudRetreat(int value);

  /// Hint shown when the player may aim.
  ///
  /// In en, this message translates to:
  /// **'Drag to aim'**
  String get hudAimHint;

  /// Cancel aiming.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get hudCancel;

  /// Accessibility label.
  ///
  /// In en, this message translates to:
  /// **'Walk left'**
  String get hudWalkLeft;

  /// Accessibility label.
  ///
  /// In en, this message translates to:
  /// **'Walk right'**
  String get hudWalkRight;

  /// Forward jump button.
  ///
  /// In en, this message translates to:
  /// **'Jump'**
  String get hudJump;

  /// High jump button.
  ///
  /// In en, this message translates to:
  /// **'High jump'**
  String get hudHighJump;

  /// Accessibility label.
  ///
  /// In en, this message translates to:
  /// **'Center on active unit'**
  String get hudCenterCamera;

  /// Result title.
  ///
  /// In en, this message translates to:
  /// **'{team} wins'**
  String resultWinner(String team);

  /// Result title when nobody survives.
  ///
  /// In en, this message translates to:
  /// **'A draw'**
  String get resultDraw;

  /// Result button.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get resultPlayAgain;

  /// Result button.
  ///
  /// In en, this message translates to:
  /// **'Main menu'**
  String get resultMainMenu;

  /// Debug-only match seed readout.
  ///
  /// In en, this message translates to:
  /// **'Seed {seed}'**
  String debugSeed(int seed);

  /// Family name.
  ///
  /// In en, this message translates to:
  /// **'Cat'**
  String get familyCat;

  /// Cat passive ability name.
  ///
  /// In en, this message translates to:
  /// **'Nine Lives'**
  String get passiveCat;

  /// Cat passive ability, one line.
  ///
  /// In en, this message translates to:
  /// **'Once per match, a lethal hit leaves it at 1 HP.'**
  String get passiveCatDesc;

  /// Family name.
  ///
  /// In en, this message translates to:
  /// **'Dog'**
  String get familyDog;

  /// Dog passive ability name.
  ///
  /// In en, this message translates to:
  /// **'Tough'**
  String get passiveDog;

  /// Dog passive ability, one line.
  ///
  /// In en, this message translates to:
  /// **'Starts with 120 HP.'**
  String get passiveDogDesc;

  /// Family name.
  ///
  /// In en, this message translates to:
  /// **'Rabbit'**
  String get familyRabbit;

  /// Rabbit passive ability name.
  ///
  /// In en, this message translates to:
  /// **'Jumper'**
  String get passiveRabbit;

  /// Rabbit passive ability, one line.
  ///
  /// In en, this message translates to:
  /// **'High jump goes twice as high.'**
  String get passiveRabbitDesc;

  /// Family name.
  ///
  /// In en, this message translates to:
  /// **'Bird'**
  String get familyBird;

  /// Bird passive ability name.
  ///
  /// In en, this message translates to:
  /// **'Glider'**
  String get passiveBird;

  /// Bird passive ability, one line.
  ///
  /// In en, this message translates to:
  /// **'Floats down slowly after jumping; no fall damage.'**
  String get passiveBirdDesc;

  /// Family name.
  ///
  /// In en, this message translates to:
  /// **'Hamster'**
  String get familyHamster;

  /// Hamster passive ability name.
  ///
  /// In en, this message translates to:
  /// **'Tiny'**
  String get passiveHamster;

  /// Hamster passive ability, one line.
  ///
  /// In en, this message translates to:
  /// **'30% smaller target, 85 HP.'**
  String get passiveHamsterDesc;

  /// Family name.
  ///
  /// In en, this message translates to:
  /// **'Duck'**
  String get familyDuck;

  /// Duck passive ability name.
  ///
  /// In en, this message translates to:
  /// **'Swimmer'**
  String get passiveDuck;

  /// Duck passive ability, one line.
  ///
  /// In en, this message translates to:
  /// **'Once per match, survives the water for 25 HP and climbs out on the nearest land.'**
  String get passiveDuckDesc;

  /// Family name.
  ///
  /// In en, this message translates to:
  /// **'Chicken'**
  String get familyChicken;

  /// Chicken passive ability name.
  ///
  /// In en, this message translates to:
  /// **'Flapper'**
  String get passiveChicken;

  /// Chicken passive ability, one line.
  ///
  /// In en, this message translates to:
  /// **'Can jump again in mid-air.'**
  String get passiveChickenDesc;

  /// Family name.
  ///
  /// In en, this message translates to:
  /// **'Turtle'**
  String get familyTurtle;

  /// Turtle passive ability name.
  ///
  /// In en, this message translates to:
  /// **'Shell'**
  String get passiveTurtle;

  /// Turtle passive ability, one line.
  ///
  /// In en, this message translates to:
  /// **'Takes 25% less blast damage, walks 30% slower.'**
  String get passiveTurtleDesc;

  /// Family name.
  ///
  /// In en, this message translates to:
  /// **'Goat'**
  String get familyGoat;

  /// Goat passive ability name.
  ///
  /// In en, this message translates to:
  /// **'Climber'**
  String get passiveGoat;

  /// Goat passive ability, one line.
  ///
  /// In en, this message translates to:
  /// **'Climbs steps up to 14 px high.'**
  String get passiveGoatDesc;

  /// Family name.
  ///
  /// In en, this message translates to:
  /// **'Monkey'**
  String get familyMonkey;

  /// Monkey passive ability name.
  ///
  /// In en, this message translates to:
  /// **'Strong Arm'**
  String get passiveMonkey;

  /// Monkey passive ability, one line.
  ///
  /// In en, this message translates to:
  /// **'Throws up to 20% harder.'**
  String get passiveMonkeyDesc;

  /// Weapon name.
  ///
  /// In en, this message translates to:
  /// **'Bouncy Grenade'**
  String get weaponGrenade;

  /// Weapon name.
  ///
  /// In en, this message translates to:
  /// **'Cluster Bomb'**
  String get weaponCluster;

  /// Weapon name.
  ///
  /// In en, this message translates to:
  /// **'Twin Slingshot'**
  String get weaponTwinSling;

  /// Weapon name.
  ///
  /// In en, this message translates to:
  /// **'Punch'**
  String get weaponPunch;

  /// Weapon name.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get weaponMine;

  /// Weapon name.
  ///
  /// In en, this message translates to:
  /// **'Teleport'**
  String get weaponTeleport;

  /// Weapon name.
  ///
  /// In en, this message translates to:
  /// **'Skip Turn'**
  String get weaponSkip;

  /// Weapon name.
  ///
  /// In en, this message translates to:
  /// **'Hairball Cluster'**
  String get weaponHairball;

  /// Weapon name.
  ///
  /// In en, this message translates to:
  /// **'Boomerang Bone'**
  String get weaponBoneBoomerang;

  /// Weapon name.
  ///
  /// In en, this message translates to:
  /// **'Drill Carrot'**
  String get weaponDrillCarrot;

  /// Weapon name.
  ///
  /// In en, this message translates to:
  /// **'Egg Strike'**
  String get weaponEggStrike;

  /// Weapon name.
  ///
  /// In en, this message translates to:
  /// **'Seed Mines'**
  String get weaponSeedMines;

  /// Weapon name.
  ///
  /// In en, this message translates to:
  /// **'Boom Duck'**
  String get weaponBoomDuck;

  /// Weapon name.
  ///
  /// In en, this message translates to:
  /// **'Startle Crow'**
  String get weaponStartleCrow;

  /// Weapon name.
  ///
  /// In en, this message translates to:
  /// **'Fortress'**
  String get weaponFortress;

  /// Weapon name.
  ///
  /// In en, this message translates to:
  /// **'Headbutt'**
  String get weaponHeadbutt;

  /// Weapon name.
  ///
  /// In en, this message translates to:
  /// **'Falling Coconut'**
  String get weaponCoconut;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Kampung'**
  String get breedCatKampung;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Anggora'**
  String get breedCatAngora;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'British Shorthair'**
  String get breedCatBritishShorthair;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Siberian'**
  String get breedCatSiberian;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Persia'**
  String get breedCatPersia;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Maine Coon'**
  String get breedCatMaineCoon;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Bengal'**
  String get breedCatBengal;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Sphynx'**
  String get breedCatSphynx;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Golden Retriever'**
  String get breedDogGoldenRetriever;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'German Shepherd'**
  String get breedDogGermanShepherd;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Alaskan Malamute'**
  String get breedDogAlaskanMalamute;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Husky'**
  String get breedDogHusky;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Corgi'**
  String get breedDogCorgi;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Shiba Inu'**
  String get breedDogShibaInu;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Pomeranian'**
  String get breedDogPomeranian;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Dachshund'**
  String get breedDogDachshund;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Holland Lop'**
  String get breedRabbitHollandLop;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Rex'**
  String get breedRabbitRex;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Lionhead'**
  String get breedRabbitLionhead;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Angora'**
  String get breedRabbitAngora;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Netherland Dwarf'**
  String get breedRabbitNetherlandDwarf;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Merpati'**
  String get breedBirdMerpati;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Kakatua'**
  String get breedBirdKakatua;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Lovebird'**
  String get breedBirdLovebird;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Jalak Bali'**
  String get breedBirdJalakBali;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Beo'**
  String get breedBirdBeo;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Syrian'**
  String get breedHamsterSyrian;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Winter White'**
  String get breedHamsterWinterWhite;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Campbell'**
  String get breedHamsterCampbell;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Roborovski'**
  String get breedHamsterRoborovski;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Peking'**
  String get breedDuckPeking;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Mallard'**
  String get breedDuckMallard;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Indian Runner'**
  String get breedDuckIndianRunner;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Mandarin'**
  String get breedDuckMandarin;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Call Duck'**
  String get breedDuckCallDuck;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Kampung'**
  String get breedChickenKampung;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Pelung'**
  String get breedChickenPelung;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Cemani'**
  String get breedChickenCemani;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Bangkok'**
  String get breedChickenBangkok;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Silkie'**
  String get breedChickenSilkie;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Sulcata'**
  String get breedTurtleSulcata;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Brazil'**
  String get breedTurtleBrazil;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Ambon'**
  String get breedTurtleAmbon;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Leopard'**
  String get breedTurtleLeopard;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Etawa'**
  String get breedGoatEtawa;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Kacang'**
  String get breedGoatKacang;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Boer'**
  String get breedGoatBoer;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Saanen'**
  String get breedGoatSaanen;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Ekor Panjang'**
  String get breedMonkeyEkorPanjang;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Bekantan'**
  String get breedMonkeyBekantan;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Lutung'**
  String get breedMonkeyLutung;

  /// Breed name (common breed name, usually untranslated).
  ///
  /// In en, this message translates to:
  /// **'Kapusin'**
  String get breedMonkeyKapusin;

  /// Weapon menu title and button label.
  ///
  /// In en, this message translates to:
  /// **'Weapons'**
  String get hudWeapons;

  /// Badge on a family signature weapon.
  ///
  /// In en, this message translates to:
  /// **'Signature'**
  String get hudSignature;

  /// Signature weapon already used.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get hudUsed;

  /// Remaining ammo.
  ///
  /// In en, this message translates to:
  /// **'×{count}'**
  String hudAmmoLeft(int count);

  /// Unlimited ammo.
  ///
  /// In en, this message translates to:
  /// **'∞'**
  String get hudAmmoUnlimited;

  /// Grenade fuse selector.
  ///
  /// In en, this message translates to:
  /// **'Fuse {seconds}s'**
  String hudFuse(int seconds);

  /// Hint for target weapons.
  ///
  /// In en, this message translates to:
  /// **'Tap a target on the map'**
  String get hudTapTarget;

  /// Target not allowed.
  ///
  /// In en, this message translates to:
  /// **'Can’t use it there'**
  String get hudInvalidTarget;

  /// Action button for weapons that are not thrown.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get hudUse;

  /// Hint for direction-only weapons.
  ///
  /// In en, this message translates to:
  /// **'Drag to pick a direction'**
  String get hudDirectionHint;

  /// Splash screen.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get splashLoading;

  /// Main menu button.
  ///
  /// In en, this message translates to:
  /// **'How to Play'**
  String get menuHowToPlay;

  /// Main menu / pause button.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get menuSettings;

  /// Main menu button.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get menuAbout;

  /// Main menu button that closes the app (Android).
  ///
  /// In en, this message translates to:
  /// **'Quit game'**
  String get menuQuit;

  /// Title of the confirmation shown before the app closes.
  ///
  /// In en, this message translates to:
  /// **'Quit Pawtillery?'**
  String get quitAppTitle;

  /// Body of the confirmation shown before the app closes.
  ///
  /// In en, this message translates to:
  /// **'Your pets will be waiting for the next match.'**
  String get quitAppBody;

  /// Default name of a purple team.
  ///
  /// In en, this message translates to:
  /// **'Purple Team'**
  String get teamPurple;

  /// Default name of an orange team.
  ///
  /// In en, this message translates to:
  /// **'Orange Team'**
  String get teamOrange;

  /// Map name.
  ///
  /// In en, this message translates to:
  /// **'Haunted Keep'**
  String get mapCastle;

  /// Map name.
  ///
  /// In en, this message translates to:
  /// **'Shipwreck Cove'**
  String get mapWreck;

  /// Map name.
  ///
  /// In en, this message translates to:
  /// **'Ruined Village'**
  String get mapRuins;

  /// Comma-separated names the Random button picks from. Keep them short.
  ///
  /// In en, this message translates to:
  /// **'Milo,Luna,Bobo,Kiki,Coco,Momo,Pip,Nala,Toby,Ziggy,Biscuit,Pepper,Mochi,Tofu,Nugget,Peanut,Waffle,Pixel'**
  String get unitNamePool;

  /// Setup screen title.
  ///
  /// In en, this message translates to:
  /// **'New Match'**
  String get setupTitle;

  /// Number of teams option.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get setupTeams;

  /// Option label.
  ///
  /// In en, this message translates to:
  /// **'Units per team'**
  String get setupUnitsPerTeam;

  /// Option label.
  ///
  /// In en, this message translates to:
  /// **'Turn time'**
  String get setupTurnTime;

  /// Option label.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get setupMap;

  /// Random map choice.
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get setupMapRandom;

  /// Option label.
  ///
  /// In en, this message translates to:
  /// **'Sudden death'**
  String get setupSuddenDeath;

  /// Sudden death disabled.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get setupOff;

  /// Sudden death start time.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String setupMinutes(int minutes);

  /// Fills every unit with a random family, breed and name.
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get setupRandomAll;

  /// Tooltip.
  ///
  /// In en, this message translates to:
  /// **'Randomize this unit'**
  String get setupRandomUnit;

  /// Starts the match.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get setupStart;

  /// Text field label.
  ///
  /// In en, this message translates to:
  /// **'Team name'**
  String get setupTeamName;

  /// Unit name field label.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get setupUnitName;

  /// Unit family dropdown label.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get setupFamily;

  /// Unit breed dropdown label.
  ///
  /// In en, this message translates to:
  /// **'Breed'**
  String get setupBreed;

  /// Colour picker label.
  ///
  /// In en, this message translates to:
  /// **'Team colour'**
  String get setupColor;

  /// Section title.
  ///
  /// In en, this message translates to:
  /// **'Match options'**
  String get setupOptions;

  /// Pause button tooltip.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get hudPause;

  /// Shown while sudden death is on.
  ///
  /// In en, this message translates to:
  /// **'Sudden death'**
  String get hudSuddenDeath;

  /// Pause dialog title.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get pauseTitle;

  /// Pause dialog button.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get pauseResume;

  /// Pause dialog button.
  ///
  /// In en, this message translates to:
  /// **'Exit to menu'**
  String get pauseExit;

  /// Confirmation title.
  ///
  /// In en, this message translates to:
  /// **'Leave the match?'**
  String get pauseExitConfirmTitle;

  /// Confirmation text.
  ///
  /// In en, this message translates to:
  /// **'This match will be lost.'**
  String get pauseExitConfirmBody;

  /// Generic dialog button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dialogCancel;

  /// Confirms leaving the match.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get dialogLeave;

  /// Results button: back to setup.
  ///
  /// In en, this message translates to:
  /// **'Change teams'**
  String get resultChangeTeams;

  /// Results stat title.
  ///
  /// In en, this message translates to:
  /// **'Most damage'**
  String get resultMostDamage;

  /// Best unit and its damage.
  ///
  /// In en, this message translates to:
  /// **'{name} ({team}): {damage} HP'**
  String resultMostDamageValue(String name, String team, int damage);

  /// No damage was dealt.
  ///
  /// In en, this message translates to:
  /// **'Nobody landed a hit'**
  String get resultNoDamage;

  /// Results stat title.
  ///
  /// In en, this message translates to:
  /// **'Knockouts per team'**
  String get resultKills;

  /// Match length.
  ///
  /// In en, this message translates to:
  /// **'Over {count} turns'**
  String resultTurns(int count);

  /// How-to-play next page.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get howNext;

  /// How-to-play last page.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get howDone;

  /// How-to-play page title.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get howMoveTitle;

  /// How-to-play text.
  ///
  /// In en, this message translates to:
  /// **'Hold the arrow buttons to walk. Two jump buttons: a forward hop and a high jump. Falling far hurts; water and the map edges are deadly.'**
  String get howMoveBody;

  /// How-to-play page title.
  ///
  /// In en, this message translates to:
  /// **'Aim and fire'**
  String get howAimTitle;

  /// How-to-play text.
  ///
  /// In en, this message translates to:
  /// **'Drag anywhere with one finger, like a slingshot: pull back to aim, pull further for more power. Fine-tune with the ± buttons, then press Fire. Drag back to the start to cancel.'**
  String get howAimBody;

  /// How-to-play page title.
  ///
  /// In en, this message translates to:
  /// **'Weapons'**
  String get howWeaponsTitle;

  /// How-to-play text.
  ///
  /// In en, this message translates to:
  /// **'Open the weapon menu to switch. Some weapons have limited ammo per team. Every family has one signature weapon each unit can use once per match.'**
  String get howWeaponsBody;

  /// How-to-play page title.
  ///
  /// In en, this message translates to:
  /// **'Wind and turns'**
  String get howWindTitle;

  /// How-to-play text.
  ///
  /// In en, this message translates to:
  /// **'Wind changes every turn and pushes most thrown weapons. You get one shot per turn, then 3 seconds to run before the next team plays.'**
  String get howWindBody;

  /// How-to-play page title.
  ///
  /// In en, this message translates to:
  /// **'Families'**
  String get howFamiliesTitle;

  /// How-to-play text.
  ///
  /// In en, this message translates to:
  /// **'Each family has a passive ability: cats survive one lethal hit, dogs are tougher, rabbits jump higher, birds glide, and more. Breeds only change the look.'**
  String get howFamiliesBody;

  /// How-to-play page title.
  ///
  /// In en, this message translates to:
  /// **'Winning'**
  String get howWinTitle;

  /// How-to-play text.
  ///
  /// In en, this message translates to:
  /// **'The last team with units standing wins. Two fingers move and zoom the camera. If sudden death starts, everyone drops to 1 HP and the water rises every round.'**
  String get howWinBody;

  /// Settings label.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Follow the phone language.
  ///
  /// In en, this message translates to:
  /// **'Device language'**
  String get settingsLanguageSystem;

  /// Language name (in that language).
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Language name (in that language).
  ///
  /// In en, this message translates to:
  /// **'Bahasa Indonesia'**
  String get languageIndonesian;

  /// Settings label.
  ///
  /// In en, this message translates to:
  /// **'Music volume'**
  String get settingsMusic;

  /// Settings label.
  ///
  /// In en, this message translates to:
  /// **'Sound effects volume'**
  String get settingsSfx;

  /// Settings label.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get settingsHaptics;

  /// Settings label: turns background music on or off.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get settingsMusicOn;

  /// Settings label: shows the frame rate during a match.
  ///
  /// In en, this message translates to:
  /// **'Show FPS'**
  String get settingsShowFps;

  /// Settings label.
  ///
  /// In en, this message translates to:
  /// **'Show aim guide'**
  String get settingsAimGuide;

  /// Settings action.
  ///
  /// In en, this message translates to:
  /// **'Show the tutorial again'**
  String get settingsTutorial;

  /// Confirmation snackbar.
  ///
  /// In en, this message translates to:
  /// **'The tutorial will show in your next match.'**
  String get settingsTutorialReset;

  /// About screen.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String aboutVersion(String version);

  /// About screen tagline.
  ///
  /// In en, this message translates to:
  /// **'A turn-based animal artillery game for friends sharing one phone.'**
  String get aboutDescription;

  /// About screen section.
  ///
  /// In en, this message translates to:
  /// **'Asset credits'**
  String get aboutCredits;

  /// About screen section.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get aboutPrivacy;

  /// About screen text.
  ///
  /// In en, this message translates to:
  /// **'This game collects no data. Full policy:'**
  String get aboutPrivacyNote;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get aboutCopyLink;

  /// Snackbar.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get aboutLinkCopied;

  /// Tutorial step 1.
  ///
  /// In en, this message translates to:
  /// **'Hold an arrow to walk'**
  String get tutorialWalk;

  /// Tutorial step 2.
  ///
  /// In en, this message translates to:
  /// **'Tap here to choose a weapon'**
  String get tutorialWeapons;

  /// Tutorial step 3.
  ///
  /// In en, this message translates to:
  /// **'Drag anywhere to aim, like a slingshot'**
  String get tutorialAim;

  /// Tutorial step 4.
  ///
  /// In en, this message translates to:
  /// **'Press Fire'**
  String get tutorialFire;

  /// Tutorial skip button.
  ///
  /// In en, this message translates to:
  /// **'Skip tutorial'**
  String get tutorialSkip;

  /// Debug-only frame rate readout.
  ///
  /// In en, this message translates to:
  /// **'{fps} fps · worst {worstMs} ms'**
  String debugFps(int fps, String worstMs);

  /// Scientific name, shown in italic. Not translated.
  ///
  /// In en, this message translates to:
  /// **'Felis catus'**
  String get familyCatLatin;

  /// Scientific name, shown in italic. Not translated.
  ///
  /// In en, this message translates to:
  /// **'Canis familiaris'**
  String get familyDogLatin;

  /// Scientific name, shown in italic. Not translated.
  ///
  /// In en, this message translates to:
  /// **'Oryctolagus cuniculus'**
  String get familyRabbitLatin;

  /// Scientific name, shown in italic. Not translated.
  ///
  /// In en, this message translates to:
  /// **'Aves'**
  String get familyBirdLatin;

  /// Scientific name, shown in italic. Not translated.
  ///
  /// In en, this message translates to:
  /// **'Cricetinae'**
  String get familyHamsterLatin;

  /// Scientific name, shown in italic. Not translated.
  ///
  /// In en, this message translates to:
  /// **'Anas platyrhynchos'**
  String get familyDuckLatin;

  /// Scientific name, shown in italic. Not translated.
  ///
  /// In en, this message translates to:
  /// **'Gallus gallus'**
  String get familyChickenLatin;

  /// Scientific name, shown in italic. Not translated.
  ///
  /// In en, this message translates to:
  /// **'Testudines'**
  String get familyTurtleLatin;

  /// Scientific name, shown in italic. Not translated.
  ///
  /// In en, this message translates to:
  /// **'Capra hircus'**
  String get familyGoatLatin;

  /// Scientific name, shown in italic. Not translated.
  ///
  /// In en, this message translates to:
  /// **'Primates'**
  String get familyMonkeyLatin;

  /// Italic line under the title.
  ///
  /// In en, this message translates to:
  /// **'Animal artillery after dark'**
  String get menuSubtitle;

  /// Catalogue dialog title.
  ///
  /// In en, this message translates to:
  /// **'Choose a family'**
  String get setupChooseFamily;

  /// Catalogue dialog title.
  ///
  /// In en, this message translates to:
  /// **'Choose a breed'**
  String get setupChooseBreed;

  /// Heading of the match options.
  ///
  /// In en, this message translates to:
  /// **'Match rules'**
  String get setupConditions;

  /// Results page heading.
  ///
  /// In en, this message translates to:
  /// **'Match stats'**
  String get resultReport;

  /// Checkbox state.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get settingsOn;

  /// No description provided for @setupTabTeams.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get setupTabTeams;

  /// No description provided for @setupTabRules.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get setupTabRules;

  /// No description provided for @setupAddTeam.
  ///
  /// In en, this message translates to:
  /// **'Add team'**
  String get setupAddTeam;

  /// No description provided for @setupRandomTeam.
  ///
  /// In en, this message translates to:
  /// **'Randomize team'**
  String get setupRandomTeam;

  /// No description provided for @setupDeleteTeam.
  ///
  /// In en, this message translates to:
  /// **'Delete team'**
  String get setupDeleteTeam;

  /// No description provided for @setupDeleteTeamTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this team?'**
  String get setupDeleteTeamTitle;

  /// No description provided for @setupDeleteTeamBody.
  ///
  /// In en, this message translates to:
  /// **'Its units will be removed too.'**
  String get setupDeleteTeamBody;

  /// No description provided for @setupEditUnit.
  ///
  /// In en, this message translates to:
  /// **'Edit unit'**
  String get setupEditUnit;

  /// No description provided for @setupRandomize.
  ///
  /// In en, this message translates to:
  /// **'Randomize'**
  String get setupRandomize;

  /// No description provided for @setupPassive.
  ///
  /// In en, this message translates to:
  /// **'Passive'**
  String get setupPassive;

  /// No description provided for @setupSignatureWeapon.
  ///
  /// In en, this message translates to:
  /// **'Signature'**
  String get setupSignatureWeapon;

  /// Setup screen button in a Wi-Fi room: keep the setup and go back to the lobby.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get setupDone;

  /// No description provided for @setupStartMatch.
  ///
  /// In en, this message translates to:
  /// **'Start match'**
  String get setupStartMatch;

  /// No description provided for @setupTeamCount.
  ///
  /// In en, this message translates to:
  /// **'Number of teams'**
  String get setupTeamCount;

  /// No description provided for @setupSummary.
  ///
  /// In en, this message translates to:
  /// **'{teams} teams · {units} units · {seconds} s · {map}'**
  String setupSummary(int teams, int units, int seconds, String map);

  /// No description provided for @hudConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get hudConfirm;

  /// No description provided for @hudRetreatNow.
  ///
  /// In en, this message translates to:
  /// **'Retreat!'**
  String get hudRetreatNow;

  /// No description provided for @hudWindLabel.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get hudWindLabel;

  /// No description provided for @hudAngleLabel.
  ///
  /// In en, this message translates to:
  /// **'Angle'**
  String get hudAngleLabel;

  /// No description provided for @hudPowerLabel.
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get hudPowerLabel;

  /// No description provided for @hudFuseLabel.
  ///
  /// In en, this message translates to:
  /// **'Fuse (seconds)'**
  String get hudFuseLabel;

  /// No description provided for @hudStepOf.
  ///
  /// In en, this message translates to:
  /// **'{step} / {total}'**
  String hudStepOf(int step, int total);

  /// No description provided for @resultBestShot.
  ///
  /// In en, this message translates to:
  /// **'Best shot'**
  String get resultBestShot;

  /// No description provided for @resultBestShotValue.
  ///
  /// In en, this message translates to:
  /// **'{name} · {damage} damage'**
  String resultBestShotValue(String name, int damage);

  /// No description provided for @resultColumnDamage.
  ///
  /// In en, this message translates to:
  /// **'Damage'**
  String get resultColumnDamage;

  /// No description provided for @resultColumnKnockouts.
  ///
  /// In en, this message translates to:
  /// **'Defeated'**
  String get resultColumnKnockouts;

  /// No description provided for @resultColumnLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get resultColumnLeft;

  /// No description provided for @resultDrawTitle.
  ///
  /// In en, this message translates to:
  /// **'It\'s a draw!'**
  String get resultDrawTitle;

  /// No description provided for @aboutDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get aboutDeveloper;

  /// No description provided for @aboutArt.
  ///
  /// In en, this message translates to:
  /// **'Art'**
  String get aboutArt;

  /// No description provided for @aboutArtValue.
  ///
  /// In en, this message translates to:
  /// **'Drawn in code'**
  String get aboutArtValue;

  /// No description provided for @aboutFonts.
  ///
  /// In en, this message translates to:
  /// **'Fonts'**
  String get aboutFonts;

  /// No description provided for @dialogClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get dialogClose;

  /// No description provided for @settingsReplay.
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get settingsReplay;

  /// No description provided for @pauseQuitBody.
  ///
  /// In en, this message translates to:
  /// **'Progress will be lost.'**
  String get pauseQuitBody;

  /// No description provided for @pauseQuit.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get pauseQuit;

  /// No description provided for @weaponRockDesc.
  ///
  /// In en, this message translates to:
  /// **'A plain stone. Pushed by the wind.'**
  String get weaponRockDesc;

  /// No description provided for @weaponGrenadeDesc.
  ///
  /// In en, this message translates to:
  /// **'Bounces, then explodes when the fuse runs out.'**
  String get weaponGrenadeDesc;

  /// No description provided for @weaponClusterDesc.
  ///
  /// In en, this message translates to:
  /// **'Bursts into small bomblets.'**
  String get weaponClusterDesc;

  /// No description provided for @weaponTwinSlingDesc.
  ///
  /// In en, this message translates to:
  /// **'Two quick stones in a row.'**
  String get weaponTwinSlingDesc;

  /// No description provided for @weaponPunchDesc.
  ///
  /// In en, this message translates to:
  /// **'Knock a neighbour away.'**
  String get weaponPunchDesc;

  /// No description provided for @weaponMineDesc.
  ///
  /// In en, this message translates to:
  /// **'Drop a mine that waits for someone to come close.'**
  String get weaponMineDesc;

  /// No description provided for @weaponTeleportDesc.
  ///
  /// In en, this message translates to:
  /// **'Jump to any spot you pick.'**
  String get weaponTeleportDesc;

  /// No description provided for @weaponSkipDesc.
  ///
  /// In en, this message translates to:
  /// **'Pass this turn.'**
  String get weaponSkipDesc;

  /// No description provided for @weaponHairballDesc.
  ///
  /// In en, this message translates to:
  /// **'A hairball that splits into sticky clumps.'**
  String get weaponHairballDesc;

  /// No description provided for @weaponBoneBoomerangDesc.
  ///
  /// In en, this message translates to:
  /// **'Flies out and comes back.'**
  String get weaponBoneBoomerangDesc;

  /// No description provided for @weaponDrillCarrotDesc.
  ///
  /// In en, this message translates to:
  /// **'Digs a tunnel through the ground.'**
  String get weaponDrillCarrotDesc;

  /// No description provided for @weaponEggStrikeDesc.
  ///
  /// In en, this message translates to:
  /// **'Eggs rain down on a spot you pick.'**
  String get weaponEggStrikeDesc;

  /// No description provided for @weaponSeedMinesDesc.
  ///
  /// In en, this message translates to:
  /// **'Scatters small seed mines.'**
  String get weaponSeedMinesDesc;

  /// No description provided for @weaponBoomDuckDesc.
  ///
  /// In en, this message translates to:
  /// **'A duck waddles off and explodes.'**
  String get weaponBoomDuckDesc;

  /// No description provided for @weaponStartleCrowDesc.
  ///
  /// In en, this message translates to:
  /// **'A crow that scares and pushes.'**
  String get weaponStartleCrowDesc;

  /// No description provided for @weaponFortressDesc.
  ///
  /// In en, this message translates to:
  /// **'Builds a wall in front of you.'**
  String get weaponFortressDesc;

  /// No description provided for @weaponHeadbuttDesc.
  ///
  /// In en, this message translates to:
  /// **'A strong charge that sends foes flying.'**
  String get weaponHeadbuttDesc;

  /// No description provided for @weaponCoconutDesc.
  ///
  /// In en, this message translates to:
  /// **'A coconut falls on a spot you pick.'**
  String get weaponCoconutDesc;

  /// No description provided for @mapBackyard.
  ///
  /// In en, this message translates to:
  /// **'Backyard'**
  String get mapBackyard;

  /// Weapon name.
  ///
  /// In en, this message translates to:
  /// **'Bottle Rocket'**
  String get weaponBottleRocket;

  /// Weapon name.
  ///
  /// In en, this message translates to:
  /// **'Sniffer Rocket'**
  String get weaponSnifferRocket;

  /// Weapon name.
  ///
  /// In en, this message translates to:
  /// **'Laser Pointer'**
  String get weaponLaserPointer;

  /// Weapon name.
  ///
  /// In en, this message translates to:
  /// **'Thunder Cloud'**
  String get weaponThunderCloud;

  /// Weapon name.
  ///
  /// In en, this message translates to:
  /// **'Seed Spitter'**
  String get weaponSeedSpitter;

  /// Weapon name.
  ///
  /// In en, this message translates to:
  /// **'Firecracker'**
  String get weaponFirecracker;

  /// Weapon name.
  ///
  /// In en, this message translates to:
  /// **'Flowerpot Rain'**
  String get weaponFlowerpotRain;

  /// Weapon name.
  ///
  /// In en, this message translates to:
  /// **'Dig Claws'**
  String get weaponDigClaws;

  /// No description provided for @weaponBottleRocketDesc.
  ///
  /// In en, this message translates to:
  /// **'Fast and flat. Still pushed by the wind.'**
  String get weaponBottleRocketDesc;

  /// No description provided for @weaponSnifferRocketDesc.
  ///
  /// In en, this message translates to:
  /// **'Its motor kicks in, then it chases the nearest foe.'**
  String get weaponSnifferRocketDesc;

  /// No description provided for @weaponLaserPointerDesc.
  ///
  /// In en, this message translates to:
  /// **'A beam that burns straight through the ground.'**
  String get weaponLaserPointerDesc;

  /// No description provided for @weaponThunderCloudDesc.
  ///
  /// In en, this message translates to:
  /// **'Lightning strikes a spot you pick.'**
  String get weaponThunderCloudDesc;

  /// No description provided for @weaponSeedSpitterDesc.
  ///
  /// In en, this message translates to:
  /// **'Five seeds at once. Best up close.'**
  String get weaponSeedSpitterDesc;

  /// No description provided for @weaponFirecrackerDesc.
  ///
  /// In en, this message translates to:
  /// **'Set it down and run: a big bang in 4 s.'**
  String get weaponFirecrackerDesc;

  /// No description provided for @weaponFlowerpotRainDesc.
  ///
  /// In en, this message translates to:
  /// **'Flowerpots fall on a spot you pick.'**
  String get weaponFlowerpotRainDesc;

  /// No description provided for @weaponDigClawsDesc.
  ///
  /// In en, this message translates to:
  /// **'Dig mode: steer a tunnel any way you like with the joystick for 4 s.'**
  String get weaponDigClawsDesc;

  /// No description provided for @setupTabWeapons.
  ///
  /// In en, this message translates to:
  /// **'Weapons'**
  String get setupTabWeapons;

  /// No description provided for @setupWeaponsPreset.
  ///
  /// In en, this message translates to:
  /// **'Preset'**
  String get setupWeaponsPreset;

  /// No description provided for @setupPresetStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get setupPresetStandard;

  /// No description provided for @setupPresetClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get setupPresetClassic;

  /// No description provided for @setupPresetChaos.
  ///
  /// In en, this message translates to:
  /// **'Chaos'**
  String get setupPresetChaos;

  /// No description provided for @setupPresetCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get setupPresetCustom;

  /// No description provided for @setupWeaponsSignatures.
  ///
  /// In en, this message translates to:
  /// **'Family weapons'**
  String get setupWeaponsSignatures;

  /// No description provided for @setupWeaponsSignaturesNote.
  ///
  /// In en, this message translates to:
  /// **'Each pet\'s own weapon, once per pet.'**
  String get setupWeaponsSignaturesNote;

  /// No description provided for @setupWeaponsHint.
  ///
  /// In en, this message translates to:
  /// **'Ammo per team, per match. Skip Turn is always on.'**
  String get setupWeaponsHint;

  /// No description provided for @setupAmmoOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get setupAmmoOff;

  /// No description provided for @setupAmmoLess.
  ///
  /// In en, this message translates to:
  /// **'Less ammo'**
  String get setupAmmoLess;

  /// No description provided for @setupAmmoMore.
  ///
  /// In en, this message translates to:
  /// **'More ammo'**
  String get setupAmmoMore;

  /// Main menu button for local-network multiplayer.
  ///
  /// In en, this message translates to:
  /// **'Play on Wi-Fi'**
  String get menuPlayWifi;

  /// Title of the screen to host or join a local-network room.
  ///
  /// In en, this message translates to:
  /// **'Play on Wi-Fi'**
  String get lanTitle;

  /// Label of the player name field.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get lanYourName;

  /// Button that opens a room other phones can join.
  ///
  /// In en, this message translates to:
  /// **'Host a room'**
  String get lanHost;

  /// Hint under the host button.
  ///
  /// In en, this message translates to:
  /// **'Phones on the same Wi-Fi or on your hotspot can join.'**
  String get lanHostHint;

  /// Heading of the list of rooms found on the network.
  ///
  /// In en, this message translates to:
  /// **'Rooms nearby'**
  String get lanRooms;

  /// Shown while no room has been found.
  ///
  /// In en, this message translates to:
  /// **'Looking for rooms… All phones must be on the same Wi-Fi.'**
  String get lanSearching;

  /// Players in a room found on the network.
  ///
  /// In en, this message translates to:
  /// **'{count} of {max} players'**
  String lanRoomPlayers(int count, int max);

  /// A room found on the network is in a match.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get lanRoomBusy;

  /// Button to join a room.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get lanJoin;

  /// Heading of the field to join a room by IP address.
  ///
  /// In en, this message translates to:
  /// **'Or join by address'**
  String get lanJoinByAddress;

  /// Placeholder of the IP address field.
  ///
  /// In en, this message translates to:
  /// **'e.g. 192.168.1.5'**
  String get lanAddressHint;

  /// Shown while joining a room.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get lanConnecting;

  /// Joining a room failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach that room.'**
  String get lanErrorConnect;

  /// Joining failed: game versions differ.
  ///
  /// In en, this message translates to:
  /// **'That phone has a different version of the game.'**
  String get lanErrorVersion;

  /// Joining failed: the room is full.
  ///
  /// In en, this message translates to:
  /// **'That room is full.'**
  String get lanErrorFull;

  /// Joining failed: a match is running.
  ///
  /// In en, this message translates to:
  /// **'That room is already playing.'**
  String get lanErrorStarted;

  /// Hosting failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open a room on this network.'**
  String get lanErrorHost;

  /// Lobby title with the host's name.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s room'**
  String lobbyTitle(String name);

  /// Lobby heading of the player list.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get lobbyPlayers;

  /// Marks this phone's player in the lobby.
  ///
  /// In en, this message translates to:
  /// **'you'**
  String get lobbyYou;

  /// Marks the host player in the lobby.
  ///
  /// In en, this message translates to:
  /// **'host'**
  String get lobbyHost;

  /// A player who controls no team.
  ///
  /// In en, this message translates to:
  /// **'watching'**
  String get lobbyWatching;

  /// This phone's IP address, for joining by hand.
  ///
  /// In en, this message translates to:
  /// **'Address: {address}'**
  String lobbyAddress(String address);

  /// Lobby heading of the team list.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get lobbyTeams;

  /// Host hint under the team list.
  ///
  /// In en, this message translates to:
  /// **'Tap a player\'s name to give the team to someone else.'**
  String get lobbyOwnerHint;

  /// Host button that opens the match setup.
  ///
  /// In en, this message translates to:
  /// **'Match setup'**
  String get lobbyEditSetup;

  /// Host lobby with no guest yet.
  ///
  /// In en, this message translates to:
  /// **'Waiting for another phone to join…'**
  String get lobbyNeedPlayers;

  /// Guest lobby status.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the host to start…'**
  String get lobbyWaitingHost;

  /// Confirm leaving the lobby.
  ///
  /// In en, this message translates to:
  /// **'Leave the room?'**
  String get lobbyLeaveTitle;

  /// Confirm text when the host leaves the lobby.
  ///
  /// In en, this message translates to:
  /// **'Everyone in the room will be disconnected.'**
  String get lobbyLeaveHostBody;

  /// Confirm text when a guest leaves the lobby.
  ///
  /// In en, this message translates to:
  /// **'You can join again later.'**
  String get lobbyLeaveGuestBody;

  /// Leave the room.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get lobbyLeave;

  /// Shown on the other phones while a player takes their turn.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s turn'**
  String netTurnOf(String name);

  /// The match is waiting for a player's phone.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name}…'**
  String netWaiting(String name);

  /// A player's phone left the match.
  ///
  /// In en, this message translates to:
  /// **'{name} disconnected.'**
  String netPlayerLeft(String name);

  /// Host text after a player left.
  ///
  /// In en, this message translates to:
  /// **'The match is paused. You can end it.'**
  String get netPausedHost;

  /// Guest text after a player left.
  ///
  /// In en, this message translates to:
  /// **'The match is paused until the host ends it.'**
  String get netPausedGuest;

  /// Host button that calls the match off.
  ///
  /// In en, this message translates to:
  /// **'End match'**
  String get netEndMatch;

  /// A guest lost the host.
  ///
  /// In en, this message translates to:
  /// **'Lost the connection to the host.'**
  String get netHostLost;

  /// The phones' matches no longer agree.
  ///
  /// In en, this message translates to:
  /// **'Out of sync'**
  String get netDesyncTitle;

  /// Explains a desync.
  ///
  /// In en, this message translates to:
  /// **'The phones no longer agree on this match, so it has to stop. Check that every phone runs the same version.'**
  String get netDesyncBody;

  /// Return to the Wi-Fi room's lobby.
  ///
  /// In en, this message translates to:
  /// **'Back to lobby'**
  String get netBackToLobby;

  /// Weapon: a bomber plane drops a carpet of bombs.
  ///
  /// In en, this message translates to:
  /// **'Bomber'**
  String get weaponBomber;

  /// Weapon: a laser from orbit burns down a column.
  ///
  /// In en, this message translates to:
  /// **'Satellite Strike'**
  String get weaponSatellite;

  /// Weapon: a missile that chases a target you pick.
  ///
  /// In en, this message translates to:
  /// **'Homing Missile'**
  String get weaponHomingMissile;

  /// Weapon menu description.
  ///
  /// In en, this message translates to:
  /// **'A bomber flies over and drops five bombs on a spot you pick.'**
  String get weaponBomberDesc;

  /// Weapon menu description.
  ///
  /// In en, this message translates to:
  /// **'Marks a spot, then a satellite fires three slanted lasers around it, one after another. They only burn a short way into the ground.'**
  String get weaponSatelliteDesc;

  /// Weapon menu description.
  ///
  /// In en, this message translates to:
  /// **'Tap a target: a fighter jet flies in and fires a missile that chases that spot until its fuel runs out.'**
  String get weaponHomingMissileDesc;

  /// Setup option: starter barrels, crates and mines on the map.
  ///
  /// In en, this message translates to:
  /// **'Map objects'**
  String get setupMapObjects;

  /// Map objects option.
  ///
  /// In en, this message translates to:
  /// **'A few'**
  String get setupObjectsFew;

  /// Map objects option.
  ///
  /// In en, this message translates to:
  /// **'Lots'**
  String get setupObjectsMany;

  /// Starter map object that explodes.
  ///
  /// In en, this message translates to:
  /// **'Fuel Barrel'**
  String get weaponBarrel;

  /// Dig mode: the joystick hint.
  ///
  /// In en, this message translates to:
  /// **'Drag to dig'**
  String get hudDigHint;

  /// Dig mode: stop digging and retreat.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get hudDigDone;

  /// Weapon: pulls units in, then collapses.
  ///
  /// In en, this message translates to:
  /// **'Black Hole'**
  String get weaponBlackHole;

  /// Weapon menu description.
  ///
  /// In en, this message translates to:
  /// **'Lands, pulls everyone nearby towards it for two seconds, then collapses with a bang.'**
  String get weaponBlackHoleDesc;

  /// Weapon: sticks to what it hits.
  ///
  /// In en, this message translates to:
  /// **'Sticky Bomb'**
  String get weaponStickyBomb;

  /// Weapon menu description.
  ///
  /// In en, this message translates to:
  /// **'Sticks to the first pet (or ground) it touches and goes off after 3 s, wherever it is carried.'**
  String get weaponStickyBombDesc;

  /// Weapon: adds ground where it lands.
  ///
  /// In en, this message translates to:
  /// **'Clay'**
  String get weaponClay;

  /// Weapon menu description.
  ///
  /// In en, this message translates to:
  /// **'Builds a lump of ground where it lands: bridges, walls, or a pet stuck in a hole.'**
  String get weaponClayDesc;

  /// Weapon: trade places with a unit.
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get weaponSwap;

  /// Weapon menu description.
  ///
  /// In en, this message translates to:
  /// **'Tap any pet: you trade places with it.'**
  String get weaponSwapDesc;

  /// Weapon: burning meteors rain down around a spot.
  ///
  /// In en, this message translates to:
  /// **'Meteor Shower'**
  String get weaponMeteorShower;

  /// Weapon menu description.
  ///
  /// In en, this message translates to:
  /// **'Tap a spot: six burning meteors rain down around it, one after another, slanting with the wind.'**
  String get weaponMeteorShowerDesc;

  /// Weapon: a hook on a rope that pulls the pet to the ground it catches.
  ///
  /// In en, this message translates to:
  /// **'Grappling Hook'**
  String get weaponGrapple;

  /// Weapon menu description.
  ///
  /// In en, this message translates to:
  /// **'Aim and shoot the hook: if it catches the ground you\'re reeled up to it, then you can still fire. A miss costs nothing.'**
  String get weaponGrappleDesc;

  /// Weapon: a firebomb that leaves burning ground.
  ///
  /// In en, this message translates to:
  /// **'Napalm'**
  String get weaponNapalm;

  /// Weapon menu description.
  ///
  /// In en, this message translates to:
  /// **'Bursts into patches of fire that burn for 4 turns. Any pet touching the fire loses 8 HP each turn.'**
  String get weaponNapalmDesc;

  /// Weapon: freezes pets so they miss a turn.
  ///
  /// In en, this message translates to:
  /// **'Ice Bomb'**
  String get weaponIceBomb;

  /// Weapon menu description.
  ///
  /// In en, this message translates to:
  /// **'Freezes every pet in the burst: they miss their next turn. Fire thaws them and the cold puts fire out.'**
  String get weaponIceBombDesc;

  /// Arena: the active pet is frozen by an ice bomb and sits this turn out.
  ///
  /// In en, this message translates to:
  /// **'Frozen! Turn skipped'**
  String get hudFrozenSkip;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
