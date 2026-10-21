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
    return '$team menang';
  }

  @override
  String get resultDraw => 'Seri';

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

  @override
  String get splashLoading => 'Memuat…';

  @override
  String get menuHowToPlay => 'Cara Bermain';

  @override
  String get menuSettings => 'Pengaturan';

  @override
  String get menuAbout => 'Tentang';

  @override
  String get menuQuit => 'Keluar game';

  @override
  String get quitAppTitle => 'Keluar dari Pawtillery?';

  @override
  String get quitAppBody =>
      'Hewan-hewanmu akan menunggu pertandingan berikutnya.';

  @override
  String get teamPurple => 'Tim Ungu';

  @override
  String get teamOrange => 'Tim Oranye';

  @override
  String get mapCastle => 'Benteng Berhantu';

  @override
  String get mapWreck => 'Teluk Kapal Karam';

  @override
  String get mapRuins => 'Desa Reruntuhan';

  @override
  String get unitNamePool =>
      'Milo,Luna,Bobo,Kiki,Coco,Momo,Pipi,Nala,Tobi,Oyen,Belang,Gembul,Mochi,Tahu,Kacang,Cimol,Onde,Kerupuk';

  @override
  String get setupTitle => 'Pertandingan Baru';

  @override
  String get setupTeams => 'Tim';

  @override
  String get setupUnitsPerTeam => 'Unit per tim';

  @override
  String get setupTurnTime => 'Waktu giliran';

  @override
  String get setupMap => 'Peta';

  @override
  String get setupMapRandom => 'Acak';

  @override
  String get setupSuddenDeath => 'Mati mendadak';

  @override
  String get setupOff => 'Nonaktif';

  @override
  String setupMinutes(int minutes) {
    return '$minutes menit';
  }

  @override
  String get setupRandomAll => 'Acak';

  @override
  String get setupRandomUnit => 'Acak unit ini';

  @override
  String get setupStart => 'Mulai';

  @override
  String get setupTeamName => 'Nama tim';

  @override
  String get setupUnitName => 'Nama';

  @override
  String get setupFamily => 'Jenis';

  @override
  String get setupBreed => 'Ras';

  @override
  String get setupColor => 'Warna tim';

  @override
  String get setupOptions => 'Opsi pertandingan';

  @override
  String get hudPause => 'Jeda';

  @override
  String get hudSuddenDeath => 'Mati mendadak';

  @override
  String get pauseTitle => 'Jeda';

  @override
  String get pauseResume => 'Lanjut';

  @override
  String get pauseExit => 'Keluar ke menu';

  @override
  String get pauseExitConfirmTitle => 'Tinggalkan pertandingan?';

  @override
  String get pauseExitConfirmBody => 'Pertandingan ini tidak akan disimpan.';

  @override
  String get dialogCancel => 'Batal';

  @override
  String get dialogLeave => 'Keluar';

  @override
  String get resultChangeTeams => 'Ubah tim';

  @override
  String get resultMostDamage => 'Damage terbanyak';

  @override
  String resultMostDamageValue(String name, String team, int damage) {
    return '$name ($team): $damage HP';
  }

  @override
  String get resultNoDamage => 'Belum ada yang kena';

  @override
  String get resultKills => 'Kill per tim';

  @override
  String resultTurns(int count) {
    return 'Selama $count giliran';
  }

  @override
  String get howNext => 'Lanjut';

  @override
  String get howDone => 'Mengerti';

  @override
  String get howMoveTitle => 'Bergerak';

  @override
  String get howMoveBody =>
      'Tahan tombol panah untuk berjalan. Ada dua tombol lompat: lompat maju dan lompat tinggi. Jatuh terlalu tinggi melukai; air dan tepi peta mematikan.';

  @override
  String get howAimTitle => 'Bidik dan tembak';

  @override
  String get howAimBody =>
      'Seret satu jari di mana saja seperti ketapel: tarik ke belakang untuk membidik, tarik lebih jauh untuk tenaga lebih besar. Atur halus dengan tombol ±, lalu tekan Tembak. Seret kembali ke titik awal untuk batal.';

  @override
  String get howWeaponsTitle => 'Senjata';

  @override
  String get howWeaponsBody =>
      'Buka menu senjata untuk mengganti. Beberapa senjata punya amunisi terbatas per tim. Setiap jenis hewan punya satu senjata khas yang bisa dipakai sekali per unit per pertandingan.';

  @override
  String get howWindTitle => 'Angin dan giliran';

  @override
  String get howWindBody =>
      'Angin berubah setiap giliran dan mendorong sebagian besar senjata lempar. Kamu menembak sekali per giliran, lalu punya 3 detik untuk menjauh sebelum tim berikutnya bermain.';

  @override
  String get howFamiliesTitle => 'Jenis hewan';

  @override
  String get howFamiliesBody =>
      'Setiap jenis hewan punya kemampuan pasif: kucing selamat dari satu serangan mematikan, anjing lebih tangguh, kelinci lompat lebih tinggi, burung melayang, dan lainnya. Ras hanya mengubah tampilan.';

  @override
  String get howWinTitle => 'Menang';

  @override
  String get howWinBody =>
      'Tim terakhir yang masih punya unit menang. Dua jari menggeser dan memperbesar kamera. Saat mati mendadak dimulai, semua unit tinggal 1 HP dan air naik setiap ronde.';

  @override
  String get settingsLanguage => 'Bahasa';

  @override
  String get settingsLanguageSystem => 'Bahasa perangkat';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageIndonesian => 'Bahasa Indonesia';

  @override
  String get settingsMusic => 'Volume musik';

  @override
  String get settingsSfx => 'Volume efek suara';

  @override
  String get settingsHaptics => 'Getaran';

  @override
  String get settingsMusicOn => 'Musik';

  @override
  String get settingsShowFps => 'Tampilkan FPS';

  @override
  String get settingsAimGuide => 'Tampilkan garis bidikan';

  @override
  String get settingsTutorial => 'Tampilkan tutorial lagi';

  @override
  String get settingsTutorialReset =>
      'Tutorial akan muncul di pertandingan berikutnya.';

  @override
  String aboutVersion(String version) {
    return 'Versi $version';
  }

  @override
  String get aboutDescription =>
      'Game artileri hewan bergiliran untuk dimainkan bersama teman di satu HP.';

  @override
  String get aboutCredits => 'Kredit aset';

  @override
  String get aboutPrivacy => 'Kebijakan privasi';

  @override
  String get aboutPrivacyNote =>
      'Game ini tidak mengumpulkan data apa pun. Kebijakan lengkap:';

  @override
  String get aboutCopyLink => 'Salin tautan';

  @override
  String get aboutLinkCopied => 'Tautan disalin';

  @override
  String get tutorialWalk => 'Tahan tombol panah untuk berjalan';

  @override
  String get tutorialWeapons => 'Ketuk di sini untuk memilih senjata';

  @override
  String get tutorialAim =>
      'Seret di mana saja untuk membidik, seperti ketapel';

  @override
  String get tutorialFire => 'Tekan Tembak';

  @override
  String get tutorialSkip => 'Lewati tutorial';

  @override
  String debugFps(int fps, String worstMs) {
    return '$fps fps · terburuk $worstMs ms';
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
  String get menuSubtitle => 'Artileri hewan saat malam tiba';

  @override
  String get setupChooseFamily => 'Pilih jenis hewan';

  @override
  String get setupChooseBreed => 'Pilih ras';

  @override
  String get setupConditions => 'Aturan main';

  @override
  String get resultReport => 'Statistik';

  @override
  String get settingsOn => 'Nyala';

  @override
  String get setupTabTeams => 'Tim';

  @override
  String get setupTabRules => 'Aturan';

  @override
  String get setupAddTeam => 'Tambah tim';

  @override
  String get setupRandomTeam => 'Acak tim';

  @override
  String get setupDeleteTeam => 'Hapus tim';

  @override
  String get setupDeleteTeamTitle => 'Hapus tim ini?';

  @override
  String get setupDeleteTeamBody => 'Unitnya juga akan dihapus.';

  @override
  String get setupEditUnit => 'Ubah unit';

  @override
  String get setupRandomize => 'Acak';

  @override
  String get setupPassive => 'Pasif';

  @override
  String get setupSignatureWeapon => 'Senjata khas';

  @override
  String get setupDone => 'Selesai';

  @override
  String get setupStartMatch => 'Mulai pertandingan';

  @override
  String get setupTeamCount => 'Jumlah tim';

  @override
  String setupSummary(int teams, int units, int seconds, String map) {
    return '$teams tim · $units unit · $seconds detik · $map';
  }

  @override
  String get hudConfirm => 'Konfirmasi';

  @override
  String get hudRetreatNow => 'Mundur!';

  @override
  String get hudWindLabel => 'Angin';

  @override
  String get hudAngleLabel => 'Sudut';

  @override
  String get hudPowerLabel => 'Kekuatan';

  @override
  String get hudFuseLabel => 'Sumbu (detik)';

  @override
  String hudStepOf(int step, int total) {
    return '$step / $total';
  }

  @override
  String get resultBestShot => 'Tembakan terbaik';

  @override
  String resultBestShotValue(String name, int damage) {
    return '$name · $damage damage';
  }

  @override
  String get resultColumnDamage => 'Damage';

  @override
  String get resultColumnKnockouts => 'Dikalahkan';

  @override
  String get resultColumnLeft => 'Sisa';

  @override
  String get resultDrawTitle => 'Seri!';

  @override
  String get aboutDeveloper => 'Pengembang';

  @override
  String get aboutArt => 'Gambar';

  @override
  String get aboutArtValue => 'Digambar dengan kode';

  @override
  String get aboutFonts => 'Font';

  @override
  String get dialogClose => 'Tutup';

  @override
  String get settingsReplay => 'Ulangi';

  @override
  String get pauseQuitBody => 'Progres akan hilang.';

  @override
  String get pauseQuit => 'Keluar';

  @override
  String get weaponRockDesc => 'Batu biasa. Terdorong angin.';

  @override
  String get weaponGrenadeDesc => 'Memantul, lalu meledak saat sumbu habis.';

  @override
  String get weaponClusterDesc => 'Pecah jadi bom-bom kecil.';

  @override
  String get weaponTwinSlingDesc => 'Dua batu cepat berturut-turut.';

  @override
  String get weaponPunchDesc => 'Pukul tetangga sampai terpental.';

  @override
  String get weaponMineDesc => 'Pasang ranjau yang menunggu musuh mendekat.';

  @override
  String get weaponTeleportDesc => 'Pindah ke titik mana pun yang kamu pilih.';

  @override
  String get weaponSkipDesc => 'Lewati giliran ini.';

  @override
  String get weaponHairballDesc =>
      'Bola bulu yang pecah jadi gumpalan lengket.';

  @override
  String get weaponBoneBoomerangDesc => 'Terbang keluar lalu kembali.';

  @override
  String get weaponDrillCarrotDesc => 'Menggali terowongan di tanah.';

  @override
  String get weaponEggStrikeDesc => 'Hujan telur di titik yang kamu pilih.';

  @override
  String get weaponSeedMinesDesc => 'Menebar ranjau biji kecil.';

  @override
  String get weaponBoomDuckDesc => 'Bebek berjalan pergi lalu meledak.';

  @override
  String get weaponStartleCrowDesc => 'Gagak yang mengagetkan dan mendorong.';

  @override
  String get weaponFortressDesc => 'Membangun tembok di depanmu.';

  @override
  String get weaponHeadbuttDesc => 'Seruduk kuat yang melempar musuh.';

  @override
  String get weaponCoconutDesc => 'Kelapa jatuh di titik yang kamu pilih.';

  @override
  String get mapBackyard => 'Halaman Belakang';

  @override
  String get weaponBottleRocket => 'Roket Botol';

  @override
  String get weaponSnifferRocket => 'Roket Pelacak';

  @override
  String get weaponLaserPointer => 'Laser Pointer';

  @override
  String get weaponThunderCloud => 'Awan Petir';

  @override
  String get weaponSeedSpitter => 'Penyembur Biji';

  @override
  String get weaponFirecracker => 'Petasan';

  @override
  String get weaponFlowerpotRain => 'Hujan Pot Bunga';

  @override
  String get weaponDigClaws => 'Cakar Gali';

  @override
  String get weaponBottleRocketDesc =>
      'Cepat dan lurus. Tetap terdorong angin.';

  @override
  String get weaponSnifferRocketDesc =>
      'Mesinnya menyala, lalu mengejar musuh terdekat.';

  @override
  String get weaponLaserPointerDesc => 'Sinar yang membakar tembus tanah.';

  @override
  String get weaponThunderCloudDesc => 'Petir menyambar titik yang kamu pilih.';

  @override
  String get weaponSeedSpitterDesc =>
      'Lima biji sekaligus. Paling kuat dari dekat.';

  @override
  String get weaponFirecrackerDesc =>
      'Taruh lalu lari: ledakan besar dalam 4 detik.';

  @override
  String get weaponFlowerpotRainDesc =>
      'Pot bunga berjatuhan di titik yang kamu pilih.';

  @override
  String get weaponDigClawsDesc =>
      'Mode gali: arahkan terowongan ke mana saja dengan joystick selama 4 detik.';

  @override
  String get setupTabWeapons => 'Senjata';

  @override
  String get setupWeaponsPreset => 'Preset';

  @override
  String get setupPresetStandard => 'Standar';

  @override
  String get setupPresetClassic => 'Klasik';

  @override
  String get setupPresetChaos => 'Kacau';

  @override
  String get setupPresetCustom => 'Kustom';

  @override
  String get setupWeaponsSignatures => 'Senjata khas keluarga';

  @override
  String get setupWeaponsSignaturesNote =>
      'Senjata khas tiap hewan, sekali per hewan.';

  @override
  String get setupWeaponsHint =>
      'Amunisi per tim, per pertandingan. Lewati Giliran selalu ada.';

  @override
  String get setupAmmoOff => 'Mati';

  @override
  String get setupAmmoLess => 'Kurangi amunisi';

  @override
  String get setupAmmoMore => 'Tambah amunisi';

  @override
  String get menuPlayWifi => 'Main di Wi-Fi';

  @override
  String get lanTitle => 'Main di Wi-Fi';

  @override
  String get lanYourName => 'Nama kamu';

  @override
  String get lanHost => 'Buat room';

  @override
  String get lanHostHint =>
      'HP di Wi-Fi yang sama atau di hotspot-mu bisa gabung.';

  @override
  String get lanRooms => 'Room di sekitar';

  @override
  String get lanSearching => 'Mencari room… Semua HP harus di Wi-Fi yang sama.';

  @override
  String lanRoomPlayers(int count, int max) {
    return '$count dari $max pemain';
  }

  @override
  String get lanRoomBusy => 'Sedang main';

  @override
  String get lanJoin => 'Gabung';

  @override
  String get lanJoinByAddress => 'Atau gabung lewat alamat';

  @override
  String get lanAddressHint => 'mis. 192.168.1.5';

  @override
  String get lanConnecting => 'Menyambung…';

  @override
  String get lanErrorConnect => 'Room itu tidak bisa dihubungi.';

  @override
  String get lanErrorVersion => 'HP itu memakai versi game yang berbeda.';

  @override
  String get lanErrorFull => 'Room itu sudah penuh.';

  @override
  String get lanErrorStarted => 'Room itu sedang bermain.';

  @override
  String get lanErrorHost => 'Tidak bisa membuat room di jaringan ini.';

  @override
  String lobbyTitle(String name) {
    return 'Room $name';
  }

  @override
  String get lobbyPlayers => 'Pemain';

  @override
  String get lobbyYou => 'kamu';

  @override
  String get lobbyHost => 'host';

  @override
  String get lobbyWatching => 'menonton';

  @override
  String lobbyAddress(String address) {
    return 'Alamat: $address';
  }

  @override
  String get lobbyTeams => 'Tim';

  @override
  String get lobbyOwnerHint =>
      'Ketuk nama pemain untuk memberi tim ke pemain lain.';

  @override
  String get lobbyEditSetup => 'Atur pertandingan';

  @override
  String get lobbyNeedPlayers => 'Menunggu HP lain bergabung…';

  @override
  String get lobbyWaitingHost => 'Menunggu host memulai…';

  @override
  String get lobbyLeaveTitle => 'Keluar dari room?';

  @override
  String get lobbyLeaveHostBody => 'Semua pemain di room akan terputus.';

  @override
  String get lobbyLeaveGuestBody => 'Kamu bisa gabung lagi nanti.';

  @override
  String get lobbyLeave => 'Keluar';

  @override
  String netTurnOf(String name) {
    return 'Giliran $name';
  }

  @override
  String netWaiting(String name) {
    return 'Menunggu $name…';
  }

  @override
  String netPlayerLeft(String name) {
    return '$name terputus.';
  }

  @override
  String get netPausedHost => 'Match dijeda. Kamu bisa mengakhirinya.';

  @override
  String get netPausedGuest => 'Match dijeda sampai host mengakhirinya.';

  @override
  String get netEndMatch => 'Akhiri match';

  @override
  String get netHostLost => 'Koneksi ke host terputus.';

  @override
  String get netDesyncTitle => 'Tidak sinkron';

  @override
  String get netDesyncBody =>
      'HP-HP tidak lagi sepakat soal match ini, jadi match harus berhenti. Pastikan semua HP memakai versi yang sama.';

  @override
  String get netBackToLobby => 'Kembali ke lobby';

  @override
  String get weaponBomber => 'Pesawat Pengebom';

  @override
  String get weaponSatellite => 'Serangan Satelit';

  @override
  String get weaponHomingMissile => 'Rudal Pemburu';

  @override
  String get weaponBomberDesc =>
      'Pesawat terbang melintas dan menjatuhkan lima bom di titik yang kamu pilih.';

  @override
  String get weaponSatelliteDesc =>
      'Menandai satu titik, lalu satelit menembakkan tiga laser miring di sekitarnya satu per satu. Lasernya hanya membakar sedikit ke dalam tanah.';

  @override
  String get weaponHomingMissileDesc =>
      'Ketuk target: jet tempur datang dan menembakkan rudal yang mengejar titik itu sampai bahan bakarnya habis.';

  @override
  String get setupMapObjects => 'Objek di peta';

  @override
  String get setupObjectsFew => 'Sedikit';

  @override
  String get setupObjectsMany => 'Banyak';

  @override
  String get weaponBarrel => 'Tong Bahan Bakar';

  @override
  String get hudDigHint => 'Geser untuk menggali';

  @override
  String get hudDigDone => 'Selesai';

  @override
  String get weaponBlackHole => 'Lubang Hitam';

  @override
  String get weaponBlackHoleDesc =>
      'Mendarat, menyedot semua yang di dekatnya selama dua detik, lalu meledak.';

  @override
  String get weaponStickyBomb => 'Bom Lengket';

  @override
  String get weaponStickyBombDesc =>
      'Menempel di peliharaan (atau tanah) pertama yang disentuh dan meledak setelah 3 detik, ke mana pun ia terbawa.';

  @override
  String get weaponClay => 'Tanah Liat';

  @override
  String get weaponClayDesc =>
      'Membuat gundukan tanah di tempat mendarat: jembatan, tembok, atau mengurung lawan.';

  @override
  String get weaponSwap => 'Tukar Tempat';

  @override
  String get weaponSwapDesc =>
      'Ketuk peliharaan mana saja: kalian bertukar tempat.';

  @override
  String get weaponMeteorShower => 'Hujan Meteor';

  @override
  String get weaponMeteorShowerDesc =>
      'Ketuk satu titik: enam meteor membara berjatuhan di sekitarnya satu per satu, miring terbawa angin.';

  @override
  String get weaponGrapple => 'Tali Pengait';

  @override
  String get weaponGrappleDesc =>
      'Bidik dan tembakkan kait: kalau menancap di tanah, kamu ditarik ke sana, lalu masih bisa menembak. Meleset tidak mengurangi jatah.';

  @override
  String get weaponNapalm => 'Napalm';

  @override
  String get weaponNapalmDesc =>
      'Pecah jadi beberapa titik api yang menyala selama 4 giliran. Pet yang menyentuh api kehilangan 8 HP tiap giliran.';

  @override
  String get weaponIceBomb => 'Bom Es';

  @override
  String get weaponIceBombDesc =>
      'Membekukan semua pet di area ledakan: giliran berikutnya mereka terlewat. Api mencairkan es, dan dinginnya memadamkan api.';

  @override
  String get hudFrozenSkip => 'Beku! Giliran terlewat';

  @override
  String get weaponShield => 'Gelembung Perisai';

  @override
  String get weaponShieldDesc =>
      'Gelembung yang menahan satu serangan berikutnya (bukan jatuh atau air). Bertahan sampai giliranmu berikutnya.';

  @override
  String get weaponShotgun => 'Shotgun';

  @override
  String get weaponShotgunDesc =>
      'Dua tembakan per giliran, bidik masing-masing. Langsung mengenai benda pertama di garis tembak, tanpa angin.';

  @override
  String get hudShotgunMore => 'Satu tembakan lagi: bidik dan tembak';

  @override
  String get weaponPoisonGas => 'Gas Beracun';

  @override
  String get weaponPoisonGasDesc =>
      'Melepaskan awan gas yang terbawa angin selama 3 giliran. Pet di dalamnya teracun: kehilangan 5 HP di awal tiap gilirannya (tidak sampai HP terakhir) sampai disembuhkan.';

  @override
  String get weaponFirstAid => 'Kotak P3K';

  @override
  String get weaponFirstAidDesc =>
      'Memulihkan 25 HP dan menyembuhkan racun. Menghabiskan giliranmu.';
}
