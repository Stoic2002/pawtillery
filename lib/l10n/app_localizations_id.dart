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
  String debugExplosionTime(String lastMs, String maxMs) {
    return 'Ledakan $lastMs ms (maks $maxMs ms)';
  }

  @override
  String get weaponRock => 'Batu Lempar';

  @override
  String get mapSandbox => 'Lapangan Uji';

  @override
  String get teamRed => 'Tim Merah';

  @override
  String get teamBlue => 'Tim Biru';

  @override
  String get teamGreen => 'Tim Hijau';

  @override
  String get teamYellow => 'Tim Kuning';

  @override
  String turnBanner(String team) {
    return 'Giliran $team';
  }

  @override
  String hudSeconds(int value) {
    return '$value dtk';
  }

  @override
  String hudRetreat(int value) {
    return 'Mundur $value dtk';
  }

  @override
  String get hudAimHint => 'Seret untuk membidik';

  @override
  String get hudCancel => 'Batal';

  @override
  String get hudWalkLeft => 'Jalan ke kiri';

  @override
  String get hudWalkRight => 'Jalan ke kanan';

  @override
  String get hudJump => 'Lompat';

  @override
  String get hudHighJump => 'Lompat tinggi';

  @override
  String get hudCenterCamera => 'Pusatkan ke unit aktif';

  @override
  String resultWinner(String team) {
    return '$team menang!';
  }

  @override
  String get resultDraw => 'Seri!';

  @override
  String get resultPlayAgain => 'Main lagi';

  @override
  String get resultMainMenu => 'Menu utama';

  @override
  String debugSeed(int seed) {
    return 'Seed $seed';
  }
}
