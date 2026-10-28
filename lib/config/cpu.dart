/// Computer-controlled teams (hotseat only). Pure Dart.
library;

/// How well a CPU team plays.
enum CpuLevel { easy, normal, hard }

/// Tuning for one [CpuLevel].
class CpuTuning {
  const CpuTuning({
    required this.windSense,
    required this.angleError,
    required this.powerError,
    required this.limitedWeapons,
    required this.ammoCostScale,
    required this.thinkTicks,
  });

  /// Share of the turn's wind it plans with (1 = reads it exactly).
  final double windSense;

  /// The planned aim is off by up to this many degrees / power points.
  final int angleError;
  final int powerError;

  /// Uses weapons with limited ammo (and air support); off = only the
  /// unlimited ones and its signature weapon.
  final bool limitedWeapons;

  /// How much it holds back limited ammo; lower spends it more freely.
  final double ammoCostScale;

  /// Pause at the start of the action phase before it aims.
  final int thinkTicks;

  static CpuTuning of(CpuLevel level) => switch (level) {
    CpuLevel.easy => easy,
    CpuLevel.normal => normal,
    CpuLevel.hard => hard,
  };

  static const easy = CpuTuning(
    windSense: 0.5,
    angleError: 5,
    powerError: 6,
    limitedWeapons: false,
    ammoCostScale: 1,
    thinkTicks: 60,
  );

  static const normal = CpuTuning(
    windSense: 1,
    angleError: 3,
    powerError: 4,
    limitedWeapons: true,
    ammoCostScale: 1,
    thinkTicks: 45,
  );

  static const hard = CpuTuning(
    windSense: 1,
    angleError: 1,
    powerError: 1,
    limitedWeapons: true,
    ammoCostScale: 0.6,
    thinkTicks: 30,
  );
}

/// Shared CPU numbers.
abstract final class CpuConfig {
  /// Aim search grid: angles and powers tried in the first pass, then a
  /// finer pass around the best few.
  static const int angleMin = 5;
  static const int angleMax = 175;
  static const int angleStep = 4;
  static const int powerMin = 15;
  static const int powerMax = 100;
  static const int powerStep = 4;
  static const int refineSpots = 4;
  static const int refineReach = 2;

  /// The best this many throws are flown again at the edges of the aim
  /// error; a plan loses [riskWeight] of the value it would lose there.
  static const int verifyThrows = 8;
  static const double riskWeight = 0.5;

  /// A planned flight is cut off after this long, or once it is this far
  /// above the map (most land far sooner; slow lobs make poor shots, and
  /// near-weightless ones would fly on for ages).
  static const int maxFlightTicks = 360;
  static const double maxFlightAbove = 600;

  /// Time spent planning per sim tick, so a frame never stalls.
  static const Duration planBudget = Duration(milliseconds: 2);

  /// Score: own and allied damage counts this much worse than enemy
  /// damage, and a knockout is worth this much extra.
  static const double friendlyFireWeight = 1.6;
  static const double knockoutBonus = 25;

  /// Its own team counts as this much (px) closer to a blast than it is,
  /// so an aim that is a little off still keeps clear of them.
  static const double safetyMargin = 30;

  /// Score cost of spending a weapon with 1, 2 or more shots left.
  static const double costLastShot = 18;
  static const double costTwoLeft = 12;
  static const double costMore = 8;
  static const double costSignature = 4;

  /// A plan worth less than this makes the CPU walk towards an enemy
  /// first (once a turn) and plan again.
  static const double walkIfBelow = 12;
  static const int walkTicks = 90;

  /// Ticks spent swinging the aim to the planned one, and showing a target
  /// before it is called in.
  static const int aimTicks = 40;
  static const int targetTicks = 45;

  /// Fire with the best plan so far once the turn clock is this low.
  static const int hurryTicks = 4 * 60;
}
