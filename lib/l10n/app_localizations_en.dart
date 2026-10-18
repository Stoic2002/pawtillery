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
  String get arenaPlaceholder => 'Test field';

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
  String get hudTapHint => 'Tap the map to blast a hole';

  @override
  String debugExplosionTime(String lastMs, String maxMs) {
    return 'Explosion $lastMs ms (max $maxMs ms)';
  }

  @override
  String get weaponRock => 'Rock Toss';

  @override
  String get mapSandbox => 'Test Field';
}
