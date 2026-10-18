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
}
