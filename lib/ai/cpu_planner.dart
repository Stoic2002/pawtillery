import 'dart:math' show max, min, sqrt;

import '../config/cpu.dart';
import '../config/families.dart';
import '../config/weapons.dart';
import '../sim/damage.dart';
import '../sim/inputs.dart';
import '../sim/physics.dart';
import '../sim/rng.dart';
import '../sim/trig.dart';
import '../sim/unit.dart';
import '../sim/world.dart';

/// The shot a CPU settled on, and how good it looked.
class CpuPlan {
  const CpuPlan({required this.fire, required this.score});

  final Fire fire;

  /// Expected enemy damage (plus knockouts), minus friendly damage and the
  /// cost of the ammo spent.
  final double score;
}

/// Plans one shot for the active unit of [world], the way a player would:
/// it tries aims with the real projectile physics and scores where each
/// lands, and scores air support and beams at every enemy. Only reads the
/// world. The search runs in small slices ([work]) so a frame never stalls.
///
/// Pure Dart like the sim, and seeded, so the same world and seed give the
/// same plan.
class CpuPlanner {
  CpuPlanner(this.world, this.tuning, {required int seed})
    : _rng = SimRng(seed),
      _me = world.activeUnit!;

  final SimWorld world;
  final CpuTuning tuning;
  final SimRng _rng;
  final Unit _me;

  late final Iterator<void> _steps = _search().iterator;
  bool _done = false;

  /// Best plan without a thrown weapon, and the best few thrown ones.
  CpuPlan? _best;
  final List<_Throw> _throws = [];
  CpuPlan? _result;

  bool get done => _done;

  /// The plan, with this level's aim error; null until [done], or if no
  /// weapon can be used at all.
  CpuPlan? get result => _result;

  /// The best plan found so far (no aim error), e.g. when time runs out.
  CpuPlan? get bestSoFar {
    var best = _best;
    for (final t in _throws) {
      if (best == null || t.score > best.score) {
        best = CpuPlan(fire: t.fire, score: t.score);
      }
    }
    return best;
  }

  /// Runs up to [flights] planned flights; returns whether planning is done.
  bool work([int flights = CpuConfig.flightsPerTick]) {
    for (var i = 0; i < flights && !_done; i++) {
      if (!_steps.moveNext()) finish();
    }
    return _done;
  }

  /// Plans to the end at once (tests and tools).
  CpuPlan? planNow() {
    while (!work(1 << 20)) {}
    return _result;
  }

  /// Stops searching and settles on the best plan so far.
  void finish() {
    if (_done) return;
    _done = true;
    final best = bestSoFar;
    _result = best == null ? null : _withError(best);
  }

  // -------------------------------------------------------------- search

  Iterable<void> _search() sync* {
    final usable = _usableWeapons();
    final ballistic = <_Group>[];
    for (final w in usable) {
      switch (w.aim) {
        case AimMode.target:
          yield* _scoreTarget(w);
        case AimMode.none:
          _scoreInPlace(w);
        case AimMode.direction:
          yield* _searchDirection(w);
        case AimMode.angleAndPower when _isThrown(w):
          final key = _Group.keyOf(w, tuning.windSense > 0);
          final group = ballistic.where((g) => g.key == key).firstOrNull;
          if (group == null) {
            ballistic.add(_Group(key, [w]));
          } else {
            group.weapons.add(w);
          }
        case AimMode.angleAndPower:
          break;
      }
    }

    // Coarse pass over every aim, then a finer one around the best spots.
    final spots = <_Spot>[];
    for (final g in ballistic) {
      for (var a = CpuConfig.angleMin; a <= CpuConfig.angleMax;
          a += CpuConfig.angleStep) {
        for (var p = CpuConfig.powerMin; p <= CpuConfig.powerMax;
            p += CpuConfig.powerStep) {
          final s = _tryThrow(g, a, p);
          if (s != null) _keepTop(spots, s);
          yield null;
        }
      }
    }
    const reach = CpuConfig.refineReach;
    for (final s in [...spots]) {
      for (var a = s.angle - reach; a <= s.angle + reach; a++) {
        for (var p = s.power - reach; p <= s.power + reach; p++) {
          if (p < 0 || p > 100 || (a == s.angle && p == s.power)) continue;
          _tryThrow(s.group, a, p);
          yield null;
        }
      }
    }

    // A good plan should still be good when this level's aim is off: fly
    // the best throws again at the edges of its error, and mark them down
    // by how much worse those land (on itself, say).
    final ae = tuning.angleError;
    final pe = tuning.powerError;
    if (ae > 0 || pe > 0) {
      for (final t in [..._throws]) {
        var worst = t.value;
        for (final (da, dp) in [(-ae, 0), (ae, 0), (0, -pe), (0, pe)]) {
          final at = _fly(
            t.group,
            t.fire.angleDeg + da,
            (t.fire.powerPercent + dp).clamp(0, 100),
          );
          worst = min(worst, at == null ? 0 : _impactValue(t.weapon, at.$1, at.$2));
          yield null;
        }
        t.score -= CpuConfig.riskWeight * (t.value - worst);
      }
    }

    // Nothing better: skip the turn rather than stand idle.
    if (bestSoFar == null && world.canUse(_me, Weapons.skip)) {
      _offer(const Fire(weaponId: 'skip'), -100);
    }
  }

  List<WeaponDef> _usableWeapons() {
    final family = _me.familyId == null ? null : Families.byId(_me.familyId!);
    return [
      for (final w in [
        ...Weapons.shared,
        if (family != null) Weapons.byId(family.signatureWeaponId),
      ])
        if (world.canUse(_me, w) &&
            (tuning.limitedWeapons ||
                world.randomWeapons ||
                w.isSignature ||
                world.ammoLeft(_me.team, w) == null))
          w,
    ];
  }

  /// Thrown weapons whose landing the planner can predict: a single arc
  /// that reacts where it first touches something.
  static bool _isThrown(WeaponDef w) =>
      w.delivery is Launch &&
      switch (w.flight) {
        Ballistic(:final onImpact) => switch (onImpact) {
          Explode() || Split() || Ignite() || Freeze() || GasCloud() ||
          Nuke() => true,
          AddGround() || ScatterMines() => false,
        },
        Sticky() => true,
        _ => false,
      };

  /// Flies one aim for [g]'s physics and scores the landing for each of its
  /// weapons. Returns the best of them, or null if it lands nowhere useful.
  _Spot? _tryThrow(_Group g, int angle, int power) {
    final at = _fly(g, angle, power);
    if (at == null) return null;
    final (x, y) = at;
    _Spot? best;
    for (final w in g.weapons) {
      final value = _impactValue(w, x, y);
      final score = value + _nearEnemyBonus(x, y) - _cost(w);
      _keepThrow(_Throw(
        g,
        w,
        Fire(weaponId: w.id, angleDeg: angle, powerPercent: power),
        value,
        score,
      ));
      if (best == null || score > best.score) {
        best = _Spot(g, angle, power, score);
      }
    }
    return best;
  }

  /// Where an aim for [g]'s physics first touches ground or a unit; null
  /// if it ends in the water or off the map.
  (double, double)? _fly(_Group g, int angle, int power) {
    final rep = g.weapons.first;
    final (x, y) = SimWorld.launchOrigin(_me, angle);
    final p = ProjectilePhysics.launch(
      id: -1,
      weapon: rep,
      x: x,
      y: y,
      angleDeg: angle,
      powerPercent: power,
      speedScale: _me.stats.firePowerScale * rep.launchSpeedScale,
    );
    final wind = (world.wind * tuning.windSense).round();
    var o = FlightOutcome.flying;
    for (var t = 0; t < CpuConfig.maxFlightTicks && o == FlightOutcome.flying;
        t++) {
      o = ProjectilePhysics.step(p, world.terrain,
          wind: wind, waterLevel: world.waterLevel, units: world.units);
    }
    if (o != FlightOutcome.hitTerrain && o != FlightOutcome.hitUnit) {
      return null;
    }
    return (p.x, p.y);
  }

  void _keepThrow(_Throw t) {
    if (_throws.length == CpuConfig.verifyThrows &&
        t.score <= _throws.last.score) {
      return;
    }
    final same = _throws.indexWhere((o) =>
        o.weapon == t.weapon &&
        o.fire.angleDeg == t.fire.angleDeg &&
        o.fire.powerPercent == t.fire.powerPercent);
    if (same >= 0) return;
    _throws
      ..add(t)
      ..sort((a, b) => b.score.compareTo(a.score));
    if (_throws.length > CpuConfig.verifyThrows) _throws.removeLast();
  }

  void _keepTop(List<_Spot> spots, _Spot s) {
    spots.add(s);
    spots.sort((a, b) => b.score.compareTo(a.score));
    if (spots.length > CpuConfig.refineSpots) spots.removeLast();
  }

  /// Air support: tried on every enemy.
  Iterable<void> _scoreTarget(WeaponDef w) sync* {
    for (final e in _enemies.toList()) {
      yield null;
      final tx = e.centerX.round();
      final ty = e.centerY.round();
      if (!world.isValidTarget(_me, w, tx, ty)) continue;
      final double value;
      switch (w.delivery) {
        case AirStrike(:final childId, :final count, :final spacing) ||
            AirRaid(:final childId, :final count, :final spacing,
                releaseAhead: null):
          final child = Weapons.byId(childId);
          var sum = 0.0;
          for (var i = 0; i < count; i++) {
            final cx = tx + (i * 2 - (count - 1)) * spacing / 2;
            if (_skyImpact(cx) case (final ix, final iy)) {
              sum += _impactValue(child, ix, iy);
            }
          }
          // Drops drift a little and blasts overlap: not all of it lands.
          value = sum * 0.7;
        case AirRaid(:final childId):
          // A guided missile: steers to the spot unless a hill is in the way.
          final child = Weapons.byId(childId);
          value = _skyImpact(tx.toDouble()) == null
              ? 0
              : _impactValue(child, e.centerX, e.centerY) * 0.8;
        case MeteorShower(:final childId, :final count, :final spread):
          final child = Weapons.byId(childId);
          var sum = 0.0;
          for (var i = -2; i <= 2; i++) {
            if (_skyImpact(tx + i * spread / 2) case (final ix, final iy)) {
              sum += _impactValue(child, ix, iy);
            }
          }
          value = sum / 5 * count * 0.6;
        case Lightning():
          final hit = _skyImpact(tx.toDouble());
          value = hit == null ? 0 : _blastValue(hit.$1, hit.$2, w);
        case OrbitalStrike(:final beams, :final spread, :final depth):
          var sum = 0.0;
          for (var i = 0; i < beams; i++) {
            final bx = tx + (i * 2 - (beams - 1)) * spread / 2;
            final hit = _skyImpact(bx);
            if (hit == null) continue;
            for (final u in _living) {
              if ((u.centerX - bx).abs() > w.radius + u.stats.hitRadius) {
                continue;
              }
              final dy = u.centerY - hit.$2;
              if (dy < -u.stats.hitRadius || dy > depth) continue;
              sum += _unitValue(u, w.maxDamage);
            }
          }
          value = sum * 0.8;
        default:
          return;
      }
      _offer(Fire(weaponId: w.id, targetX: tx, targetY: ty), value - _cost(w));
    }
  }

  /// Weapons used where the unit stands.
  void _scoreInPlace(WeaponDef w) {
    final double value;
    switch (w.delivery) {
      case Heal(:final amount):
        final healed = min(amount, _me.stats.maxHp - _me.hp);
        value = healed * 0.8 + (_me.poisoned ? 8 : 0);
      case AreaHit(reach: 0):
        value = _blastValue(_me.centerX, _me.centerY, w, sparesMe: true);
      default:
        return;
    }
    _offer(Fire(weaponId: w.id), value - _cost(w));
  }

  /// Beams, the shotgun and punches: every direction.
  Iterable<void> _searchDirection(WeaponDef w) sync* {
    for (var a = 0; a < 360; a += 2) {
      final double value;
      switch (w.delivery) {
        case Beam(:final length):
          var sum = 0.0;
          for (final u in _living) {
            if (u.id == _me.id) continue;
            if (_distToRay(u, a, length) <= u.stats.hitRadius) {
              sum += _unitValue(u, w.maxDamage);
            }
          }
          value = sum;
        case Shotgun(:final range):
          final u = _firstUnitOnRay(a, range);
          value = u == null ? 0 : _unitValue(u, w.maxDamage);
        case AreaHit(:final reach) when reach > 0:
          value = _blastValue(
            _me.centerX + SimTrig.cosDeg(a) * reach,
            _me.centerY - SimTrig.sinDeg(a) * reach,
            w,
            sparesMe: true,
          );
        default:
          return;
      }
      _offer(Fire(weaponId: w.id, angleDeg: a), value - _cost(w));
      if (a % 20 == 0) yield null;
    }
  }

  void _offer(Fire fire, double score) {
    if (_best == null || score > _best!.score) {
      _best = CpuPlan(fire: fire, score: score);
    }
  }

  // ------------------------------------------------------------- scoring

  Iterable<Unit> get _living => world.units.where((u) => u.alive);
  Iterable<Unit> get _enemies => _living.where((u) => u.team != _me.team);

  /// What [w] going off at ([x], [y]) is worth, by what it does on impact.
  double _impactValue(WeaponDef w, double x, double y) {
    final flight = w.flight;
    final impact = flight is Ballistic ? flight.onImpact : const Explode();
    return switch (impact) {
      Explode() => _blastValue(x, y, w),
      Split(:final childId, :final count, :final explodeSelf) =>
        (explodeSelf ? _blastValue(x, y, w) : 0) +
            // The pieces scatter around; about a third land near the spot.
            _blastValue(x, y, Weapons.byId(childId)) * count * 0.3,
      Ignite(:final spread) =>
        _blastValue(x, y, w) +
            _areaValue(x, y, spread / 2 + FireConfig.reach, FireConfig.damage * 2),
      Freeze(:final radius) =>
        _areaValue(x, y, radius.toDouble(), w.maxDamage + 15),
      GasCloud(:final radius) =>
        _areaValue(x, y, radius.toDouble(), GasConfig.damage * 2.5),
      Nuke(:final falloutRadius) =>
        _blastValue(x, y, w) +
            _areaValue(x, y, falloutRadius.toDouble(), GasConfig.damage * 2.5),
      AddGround() || ScatterMines() => 0,
    };
  }

  /// A blast of [w] at ([x], [y]), with the sim's falloff.
  double _blastValue(double x, double y, WeaponDef w, {bool sparesMe = false}) {
    var sum = 0.0;
    for (final u in _living) {
      if (sparesMe && u.id == _me.id) continue;
      final dx = u.centerX - x;
      final dy = u.centerY - y;
      var edge = sqrt(dx * dx + dy * dy) - u.stats.hitRadius;
      if (u.team == _me.team) edge -= CpuConfig.safetyMargin;
      final dmg = Damage.explosion(
        maxDamage: w.maxDamage,
        radius: w.radius,
        distance: max(0, edge),
      );
      sum += _unitValue(
        u,
        (dmg * u.stats.explosionDamageScale).round(),
      );
    }
    return sum;
  }

  /// Every unit within [radius] of ([x], [y]) counts as hit for [value]
  /// (fire, frost, gas).
  double _areaValue(double x, double y, double radius, double value) {
    var sum = 0.0;
    for (final u in _living) {
      final dx = u.centerX - x;
      final dy = u.centerY - y;
      final r = radius +
          u.stats.hitRadius +
          (u.team == _me.team ? CpuConfig.safetyMargin : 0);
      if (dx * dx + dy * dy <= r * r) sum += _unitValue(u, value.round());
    }
    return sum;
  }

  /// [dmg] to [u]: positive for enemies, negative (and weighted) for the
  /// CPU's own team, itself included.
  double _unitValue(Unit u, int dmg) {
    if (dmg <= 0) return 0;
    double v;
    if (u.shielded) {
      v = 6; // Only pops the bubble.
    } else {
      v = min(dmg, u.hp).toDouble();
      if (dmg >= u.hp && u.lethalSavesLeft == 0) v += CpuConfig.knockoutBonus;
    }
    return u.team == _me.team ? -v * CpuConfig.friendlyFireWeight : v;
  }

  /// A little credit for landing near an enemy, so a turn with no hit in
  /// reach still shoots the right way.
  double _nearEnemyBonus(double x, double y) {
    var best = double.infinity;
    for (final e in _enemies) {
      final dx = e.centerX - x;
      final dy = e.centerY - y;
      best = min(best, dx * dx + dy * dy);
    }
    if (best == double.infinity) return 0;
    return 5 * max(0, 1 - sqrt(best) / 600);
  }

  double _cost(WeaponDef w) {
    if (world.randomWeapons) return 0; // Drawn weapons are free.
    if (w.isSignature) return CpuConfig.costSignature * tuning.ammoCostScale;
    final left = world.ammoLeft(_me.team, w);
    final cost = switch (left) {
      null => 0.0,
      1 => CpuConfig.costLastShot,
      2 => CpuConfig.costTwoLeft,
      _ => CpuConfig.costMore,
    };
    return cost * tuning.ammoCostScale;
  }

  // ------------------------------------------------------------ geometry

  /// The first ground or unit straight down column [x] from the top of the
  /// map, or null if it falls into the water (or off the map).
  (double, double)? _skyImpact(double x) {
    final ix = x.round();
    if (ix < 0 || ix >= world.terrain.width) return null;
    var ground = 0;
    while (ground < world.waterLevel && !world.terrain.isSolid(ix, ground)) {
      ground++;
    }
    // A unit standing in the column above that ground is hit first.
    Unit? top;
    for (final u in _living) {
      final r = u.stats.hitRadius;
      if ((u.centerX - ix).abs() > r || u.centerY - r >= ground) continue;
      if (top == null || u.centerY < top.centerY) top = u;
    }
    if (top != null) return (top.centerX, top.centerY);
    return ground < world.waterLevel
        ? (ix.toDouble(), ground.toDouble())
        : null;
  }

  /// Distance from [u]'s centre to the segment from the CPU's unit along
  /// [angle] for [length] px.
  double _distToRay(Unit u, int angle, int length) {
    final dx = SimTrig.cosDeg(angle);
    final dy = -SimTrig.sinDeg(angle);
    final rx = u.centerX - _me.centerX;
    final ry = u.centerY - _me.centerY;
    final t = (rx * dx + ry * dy).clamp(0, length.toDouble());
    final px = rx - dx * t;
    final py = ry - dy * t;
    return sqrt(px * px + py * py);
  }

  /// The first unit along the aim before any ground, within [range] px.
  Unit? _firstUnitOnRay(int angle, int range) {
    final dx = SimTrig.cosDeg(angle);
    final dy = -SimTrig.sinDeg(angle);
    final start = _me.stats.hitRadius + 2;
    final others = [for (final u in _living) if (u.id != _me.id) u];
    for (var d = start; d <= range; d++) {
      final x = _me.centerX + dx * d;
      final y = _me.centerY + dy * d;
      if (x < 0 || x >= world.terrain.width || y < 0 || y >= world.waterLevel) {
        return null;
      }
      if (ProjectilePhysics.unitAt(x, y, others) case final u?) return u;
      if (world.terrain.isSolid(x.floor(), y.floor())) return null;
    }
    return null;
  }

  // --------------------------------------------------------------- error

  /// [plan] as this level would actually aim it.
  CpuPlan _withError(CpuPlan plan) {
    final f = plan.fire;
    final w = Weapons.byId(f.weaponId);
    int jitter(int reach) =>
        reach == 0 ? 0 : _rng.nextIntInRange(-reach, reach);
    final Fire aimed;
    switch (w.aim) {
      case AimMode.angleAndPower:
        aimed = Fire(
          weaponId: f.weaponId,
          angleDeg: f.angleDeg + jitter(tuning.angleError),
          powerPercent:
              (f.powerPercent + jitter(tuning.powerError)).clamp(0, 100),
        );
      case AimMode.direction:
        aimed = Fire(
          weaponId: f.weaponId,
          angleDeg: (f.angleDeg + jitter(tuning.angleError)) % 360,
        );
      case AimMode.target:
        final tx = (f.targetX! + jitter(tuning.angleError * 4))
            .clamp(0, world.terrain.width - 1);
        aimed = Fire(weaponId: f.weaponId, targetX: tx, targetY: f.targetY);
      case AimMode.none:
        aimed = f;
    }
    return CpuPlan(fire: aimed, score: plan.score);
  }
}

/// Thrown weapons that fly the same way share their aim search.
class _Group {
  _Group(this.key, this.weapons);

  final (double, double, bool) key;
  final List<WeaponDef> weapons;

  static (double, double, bool) keyOf(WeaponDef w, bool readsWind) =>
      (w.gravityScale, w.launchSpeedScale, readsWind && w.affectedByWind);
}

/// A thrown-weapon plan: [value] is what its landing is worth, [score]
/// also counts the ammo and (once checked) the risk of a shaky aim.
class _Throw {
  _Throw(this.group, this.weapon, this.fire, this.value, this.score);
  final _Group group;
  final WeaponDef weapon;
  final Fire fire;
  final double value;
  double score;
}

class _Spot {
  const _Spot(this.group, this.angle, this.power, this.score);
  final _Group group;
  final int angle;
  final int power;
  final double score;
}
