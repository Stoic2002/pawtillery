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

  @override
  String get familyCat => 'Kucing';

  @override
  String get passiveCat => 'Sembilan Nyawa';

  @override
  String get passiveCatDesc =>
      'Sekali per pertandingan, serangan mematikan menyisakan 1 HP.';

  @override
  String get familyDog => 'Anjing';

  @override
  String get passiveDog => 'Tangguh';

  @override
  String get passiveDogDesc => 'Mulai dengan 120 HP.';

  @override
  String get familyRabbit => 'Kelinci';

  @override
  String get passiveRabbit => 'Pelompat';

  @override
  String get passiveRabbitDesc => 'Lompat tinggi dua kali lebih tinggi.';

  @override
  String get familyBird => 'Burung';

  @override
  String get passiveBird => 'Melayang';

  @override
  String get passiveBirdDesc =>
      'Turun perlahan setelah melompat; tanpa damage jatuh.';

  @override
  String get familyHamster => 'Hamster';

  @override
  String get passiveHamster => 'Mungil';

  @override
  String get passiveHamsterDesc => 'Sasaran 30% lebih kecil, 85 HP.';

  @override
  String get familyDuck => 'Bebek';

  @override
  String get passiveDuck => 'Perenang';

  @override
  String get passiveDuckDesc =>
      'Sekali per pertandingan, selamat dari air dengan 25 damage dan naik ke daratan terdekat.';

  @override
  String get familyChicken => 'Ayam';

  @override
  String get passiveChicken => 'Kepak';

  @override
  String get passiveChickenDesc => 'Bisa melompat sekali lagi di udara.';

  @override
  String get familyTurtle => 'Kura-kura';

  @override
  String get passiveTurtle => 'Tempurung';

  @override
  String get passiveTurtleDesc =>
      'Damage ledakan yang diterima -25%, jalan 30% lebih lambat.';

  @override
  String get familyGoat => 'Kambing';

  @override
  String get passiveGoat => 'Pendaki';

  @override
  String get passiveGoatDesc => 'Bisa menaiki tanjakan hingga 14 px.';

  @override
  String get familyMonkey => 'Monyet';

  @override
  String get passiveMonkey => 'Lemparan Kuat';

  @override
  String get passiveMonkeyDesc => 'Kekuatan lempar maksimal +20%.';

  @override
  String get weaponGrenade => 'Granat Pantul';

  @override
  String get weaponCluster => 'Bom Cluster';

  @override
  String get weaponTwinSling => 'Ketapel Ganda';

  @override
  String get weaponPunch => 'Pukulan';

  @override
  String get weaponMine => 'Ranjau';

  @override
  String get weaponTeleport => 'Teleport';

  @override
  String get weaponSkip => 'Lewati Giliran';

  @override
  String get weaponHairball => 'Hairball Cluster';

  @override
  String get weaponBoneBoomerang => 'Tulang Bumerang';

  @override
  String get weaponDrillCarrot => 'Wortel Bor';

  @override
  String get weaponEggStrike => 'Serangan Telur';

  @override
  String get weaponSeedMines => 'Biji Ranjau';

  @override
  String get weaponBoomDuck => 'Bebek Peledak';

  @override
  String get weaponStartleCrow => 'Kokok Kejut';

  @override
  String get weaponFortress => 'Benteng';

  @override
  String get weaponHeadbutt => 'Seruduk';

  @override
  String get weaponCoconut => 'Kelapa Jatuh';

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
  String get hudWeapons => 'Senjata';

  @override
  String get hudSignature => 'Khas';

  @override
  String get hudUsed => 'Terpakai';

  @override
  String hudAmmoLeft(int count) {
    return '×$count';
  }

  @override
  String get hudAmmoUnlimited => '∞';

  @override
  String hudFuse(int seconds) {
    return 'Sumbu $seconds dtk';
  }

  @override
  String get hudTapTarget => 'Ketuk target di peta';

  @override
  String get hudInvalidTarget => 'Tidak bisa di situ';

  @override
  String get hudUse => 'Pakai';

  @override
  String get hudDirectionHint => 'Seret untuk memilih arah';
}
