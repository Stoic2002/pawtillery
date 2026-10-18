// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Pawtillery';

  @override
  String get menuPlay => 'Main';

  @override
  String get arenaPlaceholder => 'Lapangan uji';

  @override
  String get back => 'Kembali';

  @override
  String hudAngle(int value) {
    return 'Sudut $value°';
  }

  @override
  String hudPower(int value) {
    return 'Kekuatan $value%';
  }

  @override
  String hudWind(int value) {
    return 'Angin $value';
  }

  @override
  String get hudFire => 'Tembak';

  @override
  String get hudDecrease => 'Kurangi';

  @override
  String get hudIncrease => 'Tambah';

  @override
  String get hudTapHint => 'Ketuk peta untuk meledakkan tanah';

  @override
  String debugExplosionTime(String lastMs, String maxMs) {
    return 'Ledakan $lastMs ms (maks $maxMs ms)';
  }

  @override
  String get weaponRock => 'Batu Lempar';

  @override
  String get mapSandbox => 'Lapangan Uji';
}
