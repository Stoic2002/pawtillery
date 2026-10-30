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
  String get hudWeapons => 'Weapons';

  @override
  String get weaponGroupThrown => 'Throw';

  @override
  String get weaponGroupSky => 'Sky';

  @override
  String get weaponGroupEffects => 'Effects';

  @override
  String get weaponGroupClose => 'Close';

  @override
  String get weaponGroupTools => 'Tools';

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
  String get menuHistory => 'History';

  @override
  String get historyEmpty => 'No matches yet. Finished matches show up here.';

  @override
  String get historyMatches => 'Matches played';

  @override
  String get historyVsCpu => 'Against the CPU';

  @override
  String historyWinLoss(int won, int lost) {
    return '$won won · $lost lost';
  }

  @override
  String get historyFavorite => 'Favorite weapon';

  @override
  String get historyBestHit => 'Biggest hit';

  @override
  String historyBestHitValue(int damage, String name) {
    return '$damage by $name';
  }

  @override
  String historyTurns(int count) {
    return '$count turns';
  }

  @override
  String get historyClear => 'Clear history';

  @override
  String get historyClearTitle => 'Clear history?';

  @override
  String get historyClearBody =>
      'Every past match and total on this phone will be removed.';

  @override
  String get menuAbout => 'About';

  @override
  String get quitAppTitle => 'Quit Pawtillery?';

  @override
  String get quitAppBody => 'Your pets will be waiting for the next match.';

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
  String get setupSuddenDeath => 'Crumbling ground';

  @override
  String get setupOff => 'Off';

  @override
  String setupMinutes(int minutes) {
    return '$minutes min';
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
  String get setupFamily => 'Animal';

  @override
  String get setupColor => 'Team colour';

  @override
  String get setupOptions => 'Match options';

  @override
  String get hudPause => 'Pause';

  @override
  String get hudSuddenDeath => 'Crumbling ground';

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
      'Each animal has a passive ability: cats survive one lethal hit, dogs are tougher, rabbits jump higher, birds glide, and more.';

  @override
  String get howWinTitle => 'Winning';

  @override
  String get howWinBody =>
      'The last team with units standing wins. Two fingers move and zoom the camera. If the ground starts crumbling, it gives way after every round, in more places each time, until nobody has anywhere to stand.';

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
  String get settingsMusicOn => 'Music';

  @override
  String get settingsShowFps => 'Show FPS';

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
  String get setupConditions => 'Match rules';

  @override
  String get resultReport => 'Match stats';

  @override
  String get settingsOn => 'On';

  @override
  String get setupTabTeams => 'Teams';

  @override
  String get setupTabRules => 'Rules';

  @override
  String get setupAddTeam => 'Add team';

  @override
  String get setupRandomTeam => 'Randomize team';

  @override
  String get setupDeleteTeam => 'Delete team';

  @override
  String get setupRandomWeapons => 'Random weapons';

  @override
  String hudDrawnWeapon(String weapon) {
    return 'This turn: $weapon';
  }

  @override
  String get setupController => 'Who plays this team';

  @override
  String get setupHuman => 'Player';

  @override
  String get setupCpuEasy => 'CPU · Easy';

  @override
  String get setupCpuNormal => 'CPU · Normal';

  @override
  String get setupCpuHard => 'CPU · Hard';

  @override
  String hudCpuThinking(String name) {
    return '$name is thinking…';
  }

  @override
  String get setupDeleteTeamTitle => 'Delete this team?';

  @override
  String get setupDeleteTeamBody => 'Its units will be removed too.';

  @override
  String get setupEditUnit => 'Edit unit';

  @override
  String get setupRandomize => 'Randomize';

  @override
  String get setupPassive => 'Passive';

  @override
  String get setupSignatureWeapon => 'Signature';

  @override
  String get setupDone => 'Done';

  @override
  String get setupStartMatch => 'Start match';

  @override
  String get setupTeamCount => 'Number of teams';

  @override
  String setupSummary(int teams, int units, int seconds, String map) {
    return '$teams teams · $units units · $seconds s · $map';
  }

  @override
  String get hudConfirm => 'Confirm';

  @override
  String get hudRetreatNow => 'Retreat!';

  @override
  String get hudWindLabel => 'Wind';

  @override
  String get hudAngleLabel => 'Angle';

  @override
  String get hudPowerLabel => 'Power';

  @override
  String get hudFuseLabel => 'Fuse (seconds)';

  @override
  String hudStepOf(int step, int total) {
    return '$step / $total';
  }

  @override
  String get resultBestShot => 'Best shot';

  @override
  String resultBestShotValue(String name, int damage) {
    return '$name · $damage damage';
  }

  @override
  String get resultColumnDamage => 'Damage';

  @override
  String get resultColumnKnockouts => 'Defeated';

  @override
  String get resultColumnLeft => 'Left';

  @override
  String get resultDrawTitle => 'It\'s a draw!';

  @override
  String get aboutDeveloper => 'Developer';

  @override
  String get aboutArt => 'Art';

  @override
  String get aboutArtValue => 'Drawn in code';

  @override
  String get aboutFonts => 'Fonts';

  @override
  String get dialogClose => 'Close';

  @override
  String get settingsReplay => 'Replay';

  @override
  String get pauseQuitBody => 'Progress will be lost.';

  @override
  String get pauseQuit => 'Quit';

  @override
  String get weaponRockDesc => 'A plain stone. Pushed by the wind.';

  @override
  String get weaponGrenadeDesc =>
      'Bounces, then explodes when the fuse runs out.';

  @override
  String get weaponClusterDesc => 'Bursts into small bomblets.';

  @override
  String get weaponTwinSlingDesc =>
      'Two quick stones that go straight through pets, hitting every one in line, and burst where they reach the ground.';

  @override
  String get weaponPunchDesc => 'Knock a neighbour away.';

  @override
  String get weaponMineDesc =>
      'Drop a mine that waits for someone to come close.';

  @override
  String get weaponTeleportDesc => 'Jump to any spot you pick.';

  @override
  String get weaponSkipDesc => 'Pass this turn.';

  @override
  String get weaponHairballDesc =>
      'A hairball that bursts into sticky clumps: they cling to whatever they touch and pop 2 s later.';

  @override
  String get weaponBoneBoomerangDesc => 'Flies out and comes back.';

  @override
  String get weaponDrillCarrotDesc => 'Digs a tunnel through the ground.';

  @override
  String get weaponEggStrikeDesc =>
      'A flock drops eggs across the spot; they bounce and scatter before they burst.';

  @override
  String get weaponSeedMinesDesc => 'Scatters small seed mines.';

  @override
  String get weaponBoomDuckDesc => 'A duck waddles off and explodes.';

  @override
  String get weaponStartleCrowDesc => 'A crow that scares and pushes.';

  @override
  String get weaponFortressDesc => 'Builds a wall in front of you.';

  @override
  String get weaponHeadbuttDesc => 'A strong charge that sends foes flying.';

  @override
  String get weaponCoconutDesc =>
      'Heavy and wind-proof. Where it lands it rolls on, and bursts when it hits a pet or stops.';

  @override
  String get mapBackyard => 'Backyard';

  @override
  String get weaponBottleRocket => 'Bottle Rocket';

  @override
  String get weaponSnifferRocket => 'Sniffer Rocket';

  @override
  String get weaponLaserPointer => 'Laser Pointer';

  @override
  String get weaponThunderCloud => 'Thunder Cloud';

  @override
  String get weaponSeedSpitter => 'Seed Spitter';

  @override
  String get weaponFirecracker => 'Firecracker';

  @override
  String get weaponFlowerpotRain => 'Flowerpot Rain';

  @override
  String get weaponDigClaws => 'Dig Claws';

  @override
  String get weaponBottleRocketDesc =>
      'Fast and flat, pushed by the wind. It glances off the ground up to twice before it goes off: shoot around cover.';

  @override
  String get weaponSnifferRocketDesc =>
      'Its motor kicks in, then it chases the nearest foe.';

  @override
  String get weaponLaserPointerDesc =>
      'A beam that burns straight through the ground.';

  @override
  String get weaponThunderCloudDesc => 'Lightning strikes a spot you pick.';

  @override
  String get weaponSeedSpitterDesc => 'Five seeds at once. Best up close.';

  @override
  String get weaponFirecrackerDesc => 'Set it down and run: a big bang in 4 s.';

  @override
  String get weaponFlowerpotRainDesc =>
      'Five pots fall one after another on the very same spot, digging a deep hole.';

  @override
  String get weaponDigClawsDesc =>
      'Dig mode: steer a tunnel any way you like with the joystick for 4 s.';

  @override
  String get setupTabWeapons => 'Weapons';

  @override
  String get setupWeaponsPreset => 'Preset';

  @override
  String get setupPresetStandard => 'Standard';

  @override
  String get setupPresetClassic => 'Classic';

  @override
  String get setupPresetChaos => 'Chaos';

  @override
  String get setupPresetCustom => 'Custom';

  @override
  String get setupWeaponsSignatures => 'Family weapons';

  @override
  String get setupWeaponsSignaturesNote =>
      'Each pet\'s own weapon, once per pet.';

  @override
  String get setupWeaponsHint =>
      'Ammo per team, per match. Skip Turn is always on.';

  @override
  String get setupAmmoOff => 'Off';

  @override
  String get setupAmmoLess => 'Less ammo';

  @override
  String get setupAmmoMore => 'More ammo';

  @override
  String get menuPlayWifi => 'Play on Wi-Fi';

  @override
  String get lanTitle => 'Play on Wi-Fi';

  @override
  String get lanYourName => 'Your name';

  @override
  String get lanHost => 'Host a room';

  @override
  String get lanHostHint =>
      'Phones on the same Wi-Fi or on your hotspot can join.';

  @override
  String get lanRooms => 'Rooms nearby';

  @override
  String get lanSearching =>
      'Looking for rooms… All phones must be on the same Wi-Fi.';

  @override
  String lanRoomPlayers(int count, int max) {
    return '$count of $max players';
  }

  @override
  String get lanRoomBusy => 'Playing';

  @override
  String get lanJoin => 'Join';

  @override
  String get lanJoinByAddress => 'Or join by address';

  @override
  String get lanAddressHint => 'e.g. 192.168.1.5';

  @override
  String get lanConnecting => 'Connecting…';

  @override
  String get lanErrorConnect => 'Couldn\'t reach that room.';

  @override
  String get lanErrorVersion =>
      'That phone has a different version of the game.';

  @override
  String get lanErrorFull => 'That room is full.';

  @override
  String get lanErrorStarted => 'That room is already playing.';

  @override
  String get lanErrorHost => 'Couldn\'t open a room on this network.';

  @override
  String lobbyTitle(String name) {
    return '$name\'s room';
  }

  @override
  String get lobbyPlayers => 'Players';

  @override
  String get lobbyYou => 'you';

  @override
  String get lobbyHost => 'host';

  @override
  String get lobbyWatching => 'watching';

  @override
  String lobbyAddress(String address) {
    return 'Address: $address';
  }

  @override
  String get lobbyTeams => 'Teams';

  @override
  String get lobbyOwnerHint =>
      'Tap a player\'s name to give the team to someone else.';

  @override
  String get lobbyEditSetup => 'Match setup';

  @override
  String get lobbyNeedPlayers => 'Waiting for another phone to join…';

  @override
  String get lobbyWaitingHost => 'Waiting for the host to start…';

  @override
  String get lobbyLeaveTitle => 'Leave the room?';

  @override
  String get lobbyLeaveHostBody => 'Everyone in the room will be disconnected.';

  @override
  String get lobbyLeaveGuestBody => 'You can join again later.';

  @override
  String get lobbyLeave => 'Leave';

  @override
  String netTurnOf(String name) {
    return '$name\'s turn';
  }

  @override
  String get netRematch => 'Play again';

  @override
  String netWaiting(String name) {
    return 'Waiting for $name…';
  }

  @override
  String netPlayerLeft(String name) {
    return '$name disconnected.';
  }

  @override
  String get netPausedHost =>
      'The match waits for them to reconnect. You can also end it.';

  @override
  String get netPausedGuest =>
      'The match waits for them to reconnect, or for the host to end it.';

  @override
  String get netEndMatch => 'End match';

  @override
  String get netHostLost => 'Lost the connection to the host.';

  @override
  String get rejoinTitle => 'Match still running';

  @override
  String get rejoinBody =>
      'You left a Wi-Fi match that may still be going. Go back to it?';

  @override
  String get rejoinOk => 'Go back';

  @override
  String get rejoinForget => 'Forget it';

  @override
  String get rejoinFailed => 'That match is no longer waiting for you.';

  @override
  String get rejoinCatchingUp => 'Catching up…';

  @override
  String get netReconnectingTitle => 'Connection lost';

  @override
  String get netReconnectingBody =>
      'Reconnecting to the host… The match goes on from where it stopped.';

  @override
  String get netDesyncTitle => 'Out of sync';

  @override
  String get netDesyncBody =>
      'The phones no longer agree on this match, so it has to stop. Check that every phone runs the same version.';

  @override
  String get netBackToLobby => 'Back to lobby';

  @override
  String get weaponBomber => 'Bomber';

  @override
  String get weaponSatellite => 'Satellite Strike';

  @override
  String get weaponHomingMissile => 'Homing Missile';

  @override
  String get weaponBomberDesc =>
      'A bomber flies over and drops five bombs on a spot you pick.';

  @override
  String get weaponSatelliteDesc =>
      'Marks a spot, then a satellite fires three slanted lasers around it, one after another. They only burn a short way into the ground.';

  @override
  String get weaponHomingMissileDesc =>
      'Tap a target: a fighter jet flies in and fires a missile that chases that spot until its fuel runs out.';

  @override
  String get setupMapObjects => 'Map objects';

  @override
  String get setupObjectsFew => 'A few';

  @override
  String get setupObjectsMany => 'Lots';

  @override
  String get weaponBarrel => 'Fuel Barrel';

  @override
  String get hudDigHint => 'Drag to dig';

  @override
  String get hudDigDone => 'Done';

  @override
  String get weaponBlackHole => 'Black Hole';

  @override
  String get weaponBlackHoleDesc =>
      'Lands, pulls everyone nearby towards it for two seconds, then collapses with a bang.';

  @override
  String get weaponStickyBomb => 'Sticky Bomb';

  @override
  String get weaponStickyBombDesc =>
      'Sticks to the first pet (or ground) it touches and goes off after 3 s, wherever it is carried.';

  @override
  String get weaponClay => 'Clay';

  @override
  String get weaponClayDesc =>
      'Builds a lump of ground where it lands: bridges, walls, or a pet stuck in a hole.';

  @override
  String get weaponSwap => 'Swap';

  @override
  String get weaponSwapDesc => 'Tap any pet: you trade places with it.';

  @override
  String get weaponMeteorShower => 'Meteor Shower';

  @override
  String get weaponMeteorShowerDesc =>
      'Tap a spot: six burning meteors rain down around it, one after another, slanting with the wind. Each leaves a small fire.';

  @override
  String get weaponGrapple => 'Grappling Hook';

  @override
  String get weaponGrappleDesc =>
      'Aim and shoot the hook: if it catches the ground you\'re reeled up to it, then you can still fire. A miss costs nothing.';

  @override
  String get weaponNapalm => 'Napalm';

  @override
  String get weaponNapalmDesc =>
      'Bursts into patches of fire that burn for 4 turns. Any pet touching the fire loses 8 HP each turn.';

  @override
  String get weaponIceBomb => 'Ice Bomb';

  @override
  String get weaponIceBombDesc =>
      'Freezes every pet in the burst: they miss their next turn. Fire thaws them and the cold puts fire out.';

  @override
  String get hudFrozenSkip => 'Frozen! Turn skipped';

  @override
  String get weaponShield => 'Shield Bubble';

  @override
  String get weaponShieldDesc =>
      'A bubble that takes the next hit for you (not falls or water). It lasts until your next turn.';

  @override
  String get weaponShotgun => 'Shotgun';

  @override
  String get weaponShotgunDesc =>
      'Two shots a turn, aim each one. Hits the first thing in line straight away, no wind.';

  @override
  String get hudShotgunMore => 'One more shot: aim and fire';

  @override
  String get weaponPoisonGas => 'Poison Gas';

  @override
  String get weaponPoisonGasDesc =>
      'Releases a cloud of gas that drifts with the wind for 3 turns. Pets inside lose 3 HP every second they stay (up to 15 a turn) and are poisoned: 5 HP at the start of each of their turns until healed. Gas never takes the last HP.';

  @override
  String get weaponFirstAid => 'First-Aid Kit';

  @override
  String get weaponFirstAidDesc =>
      'Heals 25 HP and cures poison. Uses up your turn.';

  @override
  String get weaponGasRaid => 'Gas Bomber';

  @override
  String get weaponGasRaidDesc =>
      'A bomber flies over and drops three gas canisters across the spot you pick. Each leaves a poison cloud.';

  @override
  String get weaponMiniNuke => 'Mini Nuke';

  @override
  String get weaponMiniNukeDesc =>
      'Heavy and slow, but the blast is huge. Leaves a fallout cloud that poisons pets for 3 turns.';

  @override
  String get loadingTip1 =>
      'Wind pushes most shots: check the arrow before you fire.';

  @override
  String get loadingTip2 =>
      'Poison gas is heavy. It sinks into holes and pools there.';

  @override
  String get loadingTip3 => 'Fire runs downhill. Stay above it.';

  @override
  String get loadingTip4 =>
      'Water is the fastest way to lose a pet, and to win a match.';

  @override
  String get loadingTip5 =>
      'Every animal has its own ability and signature weapon.';

  @override
  String get loadingTip6 =>
      'Crates fall from the sky. Grab them before your rival does.';

  @override
  String get setupFromStart => 'From start';
}
