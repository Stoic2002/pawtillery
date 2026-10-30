import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../config/physics.dart';
import '../../config/weapons.dart';
import '../../sim/air_support.dart';
import '../../sim/physics.dart';
import '../../sim/world.dart';
import '../art/animal_art.dart';
import '../art/weapon_art.dart';

/// Draws what the sim has in the sky, so every "external" weapon is seen
/// arriving: bombers, fighter jets and bird flocks crossing the map; the
/// satellite and the storm cloud coming down from high in the sky to their
/// place over the target (fixed in the world, not the screen), charging,
/// and their beam or bolt shooting down to the ground. A red sighting line
/// and a closing ring mark where a strike from the sky will land.
///
/// The sim strikes at once at its due tick; the bolt or beam is drawn
/// leaving [travelTicks] earlier, so it reaches the ground just as the
/// blast (and its sound) happens.
class AirSupportComponent extends Component {
  AirSupportComponent(
    this.sim, {
    required this.teamColors,
    required this.viewHeight,
    required this.alpha,
    required this.showTarget,
  }) : super(priority: 6);

  final SimWorld sim;
  final List<int> teamColors;

  /// Height of the visible world (px).
  final double Function() viewHeight;

  /// How far real time is between the last two sim ticks (see
  /// PawtilleryGame.renderAlpha).
  final double Function() alpha;

  /// Whether team [team]'s strike shows where it will land.
  final bool Function(int team) showTarget;

  /// How far the storm cloud sits above what its bolt will hit, and above
  /// the highest ground under its width.
  static const double _cloudAbove = 290;
  static const double _cloudClear = 110;
  static const int _cloudHalfWidth = 150;

  /// Ticks the bolt or beam is drawn travelling down before it lands.
  static const int travelTicks = 10;

  /// Ticks the satellite or cloud spends coming down; then it charges.
  static const int _arriveTicks = 72;

  /// How far above its place (px) it starts.
  static const double _dropFrom = 460;

  /// The first ground or pet straight down column [x] (what a bolt hits).
  double columnImpactY(int x) {
    final t = sim.terrain;
    final cx = x.clamp(0, t.width - 1);
    var y = 0;
    while (y < sim.waterLevel && y < t.height) {
      if (t.isSolid(cx, y) ||
          ProjectilePhysics.unitAt(cx + 0.5, y + 0.5, sim.units) != null) {
        break;
      }
      y++;
    }
    return y.toDouble();
  }

  /// Where a storm cloud sits over a bolt down column [x] that lands at
  /// [impactY]: clear of the ground under all of it.
  double cloudYOver(int x, double impactY) {
    final t = sim.terrain;
    var y = impactY - _cloudAbove;
    for (var cx = x - _cloudHalfWidth;
        cx <= x + _cloudHalfWidth;
        cx += 16) {
      for (var row = 0; row < y + _cloudClear; row++) {
        if (t.isSolid(cx, row)) {
          y = math.min(y, row - _cloudClear);
          break;
        }
      }
    }
    return y;
  }

  bool _isBolt(PendingStrike s) => s.weapon.delivery is Lightning;

  /// Where the storm cloud ends up over what its bolt will hit, or the
  /// satellite parks to fire (the sim's own firing point).
  (double, double) strikeSource(PendingStrike s) => _isBolt(s)
      ? (s.x.toDouble(), cloudYOver(s.x, columnImpactY(s.x)))
      : SimWorld.satelliteAim(s).$1;

  /// Where it is now: coming down from high in the sky over the arrival.
  (double, double) sourceNow(PendingStrike s) {
    final (x, y) = strikeSource(s);
    return (x, y - _dropFrom * (1 - _arrival(sim, s)));
  }

  /// Where the bolt or the current beam lands.
  (double, double) strikeTarget(PendingStrike s) => _isBolt(s)
      ? (s.x.toDouble(), columnImpactY(s.x))
      : SimWorld.satelliteAim(s).$2[s.shot];

  /// 0 → 1 as the bolt or beam travels down; null before it leaves.
  double? travelOf(PendingStrike s) {
    final left = s.dueTick - sim.tick;
    if (left > travelTicks) return null;
    return (1 - left / travelTicks).clamp(0.0, 1.0);
  }

  /// What the camera watches: the bolt's or beam's tip on its way down,
  /// else the middle between the cloud or satellite and its target, so
  /// both are seen.
  (double, double) cameraTarget(PendingStrike s) {
    final (sx, sy) = sourceNow(s);
    final (tx, ty) = strikeTarget(s);
    final t = travelOf(s);
    if (t != null) return (sx + (tx - sx) * t, sy + (ty - sy) * t);
    return ((sx + tx) / 2, (sy + ty) / 2);
  }

  /// Seconds the cloud or satellite stays in view after its strike.
  static const double _leaveSeconds = 1.6;

  /// 0 → 1 over the arrival, eased.
  static double _arrival(SimWorld sim, PendingStrike s) {
    final t = ((sim.tick - s.firedTick) / _arriveTicks).clamp(0.0, 1.0);
    return 1 - (1 - t) * (1 - t);
  }

  /// 0 → 1 from the end of the arrival to the strike.
  static double chargeOf(SimWorld sim, PendingStrike s) {
    final total = (s.dueTick - s.firedTick).clamp(1, 600);
    return ((sim.tick - s.firedTick - _arriveTicks) /
            (total - _arriveTicks).clamp(1, 600))
        .clamp(0.0, 1.0);
  }


  final ui.Paint _sight = ui.Paint()..strokeWidth = 2;
  final ui.Paint _ring = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..color = const ui.Color(0xFFE5484D);
  final ui.Paint _shadow = ui.Paint()..color = const ui.Color(0x33000000);
  final ui.Paint _glow = ui.Paint();
  final ui.Paint _rain = ui.Paint()
    ..strokeWidth = 1.4
    ..strokeCap = ui.StrokeCap.round;
  final ui.Paint _laser = ui.Paint()..strokeCap = ui.StrokeCap.round;

  double _time = 0;

  /// Clouds and satellites whose strike has landed, leaving the sky:
  /// (lightning?, x, y, seconds since the strike, direction to leave in).
  final List<(bool, double, double, double, int)> _leaving = [];

  /// Called when a strike lands, so its cloud or satellite doesn't vanish
  /// with the beam but lingers and leaves.
  void strikeLanded({
    required bool lightning,
    required double x,
    required double y,
  }) => _leaving.add((lightning, x, y, 0, x < sim.terrain.width / 2 ? -1 : 1));

  @override
  void update(double dt) {
    _time += dt;
    for (var i = _leaving.length - 1; i >= 0; i--) {
      final (l, x, y, age, dir) = _leaving[i];
      if (age + dt >= _leaveSeconds) {
        _leaving.removeAt(i);
      } else {
        _leaving[i] = (l, x, y, age + dt, dir);
      }
    }
  }

  @override
  void render(ui.Canvas canvas) {
    for (final s in sim.pendingStrikes) {
      if (showTarget(sim.units[s.ownerId].team)) _drawMarker(canvas, s);
      _drawStreak(canvas, s);
      if (_isBolt(s)) {
        _drawCloud(canvas, s);
      } else {
        _drawSatellite(canvas, s);
      }
    }
    for (final (lightning, x, y, age, dir) in _leaving) {
      if (lightning) {
        _drawLeavingCloud(canvas, x, y, age);
      } else {
        _drawLeavingSatellite(canvas, x, y, age, dir);
      }
    }
    for (final a in sim.aircraft) {
      switch (a.craft) {
        case CraftKind.bomber:
          _drawBomber(canvas, a);
        case CraftKind.jet:
          _drawJet(canvas, a);
        case CraftKind.flock:
          _drawFlock(canvas, a);
      }
    }
  }

  void _drawMarker(ui.Canvas canvas, PendingStrike s) {
    final x = s.x.toDouble();
    final y = s.y.toDouble();
    final left = (s.dueTick - sim.tick).clamp(0, 600);
    // Blinks faster as the strike gets close.
    final blink = (_time * (left < 40 ? 16 : 6)).floor().isEven;
    _sight.color = ui.Color(blink ? 0xCCE5484D : 0x66E5484D);
    final arrived = _arrival(sim, s) >= 1;
    if (arrived && _isBolt(s) && travelOf(s) == null) {
      canvas.drawLine(
        ui.Offset(x, strikeSource(s).$2),
        ui.Offset(x, strikeTarget(s).$2),
        _sight,
      );
    }
    canvas
      ..drawCircle(ui.Offset(x, y), 10 + left * 0.2, _ring)
      ..drawCircle(ui.Offset(x, y), 3, _ring);
  }

  /// The satellite glides in to park off to one side, then its dish
  /// charges (a cold glow that grows) while red targeting lasers find the
  /// spots its beams will slant down to, flickering at first and then
  /// locking on. Each goes out as its beam fires.
  void _drawSatellite(ui.Canvas canvas, PendingStrike s) {
    final (x, sy) = sourceNow(s);
    final charge = chargeOf(sim, s);
    final bob = math.sin(_time * 2) * 1.2;
    if (charge > 0.15) {
      final lock = ((charge - 0.15) / 0.6).clamp(0.0, 1.0);
      final on = lock >= 1 || (_time * (6 + 18 * lock)).floor().isEven;
      if (on) {
        _laser
          ..strokeWidth = 1 + 1.2 * lock
          ..color = ui.Color.fromARGB((110 + 120 * lock).round(), 255, 70, 70);
        _glow.color = ui.Color.fromARGB((160 * lock).round(), 255, 90, 90);
        final aims = SimWorld.satelliteAim(s).$2;
        for (var i = s.shot; i < aims.length; i++) {
          final aim = ui.Offset(aims[i].$1, aims[i].$2);
          canvas
            ..drawLine(ui.Offset(x, sy + 12 + bob), aim, _laser)
            ..drawCircle(aim, 2 + 4 * lock, _glow);
        }
      }
    }
    canvas
      ..save()
      ..translate(x, sy + bob);
    if (charge > 0) {
      final flicker = 0.85 + 0.15 * math.sin(_time * 40);
      _glow.color = ui.Color.fromARGB(
        (90 * charge * flicker).round(),
        127,
        211,
        255,
      );
      canvas.drawCircle(const ui.Offset(0, 9), 6 + 26 * charge, _glow);
      _glow.color = ui.Color.fromARGB((230 * charge).round(), 244, 251, 255);
      canvas.drawCircle(const ui.Offset(0, 9), 2 + 7 * charge, _glow);
      // Sparks circling the dish as it nears full power.
      for (var i = 0; i < 6; i++) {
        final a = _time * 5 + i * math.pi / 3;
        final r = 30 - 18 * charge;
        _glow.color = ui.Color.fromARGB((200 * charge).round(), 200, 240, 255);
        canvas.drawCircle(
          ui.Offset(math.cos(a) * r, 9 + math.sin(a) * r * 0.5),
          1.6,
          _glow,
        );
      }
    }
    WeaponArt.satellite(canvas);
    canvas.restore();
  }

  /// The storm cloud rides in on the wind, then gathers: it rains, its
  /// shadow darkens the ground, and flashes inside it come faster and
  /// brighter until the bolt.
  void _drawCloud(ui.Canvas canvas, PendingStrike s) {
    final (x, sy) = sourceNow(s);
    final charge = chargeOf(sim, s);
    final y = sy + math.sin(_time * 1.5) * 2;
    _drawRain(canvas, x, y, _arrival(sim, s) * (0.5 + 0.5 * charge));
    canvas
      ..save()
      ..translate(x, y);
    final scale = 1 + 0.12 * charge;
    canvas.scale(scale);
    WeaponArt.stormCloud(canvas);
    final rate = 3 + 14 * charge;
    if (charge > 0 && (_time * rate).floor() % 3 == 0) {
      _glow.color = ui.Color.fromARGB(
        (50 + 90 * charge).round(),
        255,
        246,
        200,
      );
      canvas.drawOval(const ui.Rect.fromLTWH(-85, -40, 170, 76), _glow);
      if (charge > 0.5) _miniBolt(canvas, (_time * rate).floor());
    }
    canvas.restore();
  }

  /// The bolt or beam on its way down: a bright tip with a trail from the
  /// cloud or satellite, reaching the ground as the strike lands.
  void _drawStreak(ui.Canvas canvas, PendingStrike s) {
    final t = travelOf(s);
    if (t == null) return;
    final (sx, sy0) = sourceNow(s);
    final bolt = _isBolt(s);
    final sy = sy0 + (bolt ? 18 : 12);
    final (tx, ty) = strikeTarget(s);
    final hx = sx + (tx - sx) * t;
    final hy = sy + (ty - sy) * t;
    if (bolt) {
      // A jagged bolt growing downwards.
      final r = math.Random(s.dueTick);
      final path = ui.Path()..moveTo(sx, sy);
      const steps = 9;
      for (var i = 1; i <= steps; i++) {
        final f = i / steps;
        if (f > t) break;
        final y = sy + (ty - sy) * f;
        path.lineTo(sx + (i == steps ? 0 : r.nextDouble() * 22 - 11), y);
      }
      path.lineTo(hx, hy);
      _laser
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 7
        ..color = const ui.Color(0x55FFF6C8);
      canvas.drawPath(path, _laser);
      _laser
        ..strokeWidth = 2.6
        ..color = const ui.Color(0xFFFFFBE6);
      canvas.drawPath(path, _laser);
      _laser.style = ui.PaintingStyle.fill;
    } else {
      _laser
        ..strokeWidth = 9
        ..color = const ui.Color(0x557FD3FF);
      canvas.drawLine(ui.Offset(sx, sy), ui.Offset(hx, hy), _laser);
      _laser
        ..strokeWidth = 3
        ..color = const ui.Color(0xFFF4FBFF);
      canvas.drawLine(ui.Offset(sx, sy), ui.Offset(hx, hy), _laser);
    }
    _glow.color = bolt ? const ui.Color(0xCCFFF6C8) : const ui.Color(0xCCBFEFFF);
    canvas.drawCircle(ui.Offset(hx, hy), 6, _glow);
  }

  /// Rain from the cloud's underside, as streaks that loop downwards.
  void _drawRain(ui.Canvas canvas, double x, double y, double amount) {
    if (amount <= 0) return;
    _rain.color = ui.Color.fromARGB((150 * amount).round(), 170, 200, 235);
    for (var i = 0; i < 16; i++) {
      final dx = -125 + i * 16.0;
      final fall = (_time * 380 + i * 53) % 170;
      final top = y + 70 + fall;
      canvas.drawLine(
        ui.Offset(x + dx - fall * 0.08, top),
        ui.Offset(x + dx - fall * 0.08 - 2, top + 12),
        _rain,
      );
    }
  }

  /// A short forked crackle inside the cloud.
  void _miniBolt(ui.Canvas canvas, int seed) {
    final r = math.Random(seed);
    final path = ui.Path()..moveTo(-60 + r.nextDouble() * 120, 40);
    var px = 0.0;
    for (var i = 1; i <= 4; i++) {
      px = -60 + r.nextDouble() * 120;
      path.lineTo(px, 40 + i * 11.0);
    }
    _laser
      ..strokeWidth = 1.6
      ..style = ui.PaintingStyle.stroke
      ..color = const ui.Color(0xEEFFF2A8);
    canvas.drawPath(path, _laser);
    _laser.style = ui.PaintingStyle.fill;
  }

  /// After the bolt: a couple of after-flashes, then the cloud thins out.
  void _drawLeavingCloud(ui.Canvas canvas, double x, double sy, double age) {
    final fade = (1 - age / _leaveSeconds).clamp(0.0, 1.0);
    final y = sy + math.sin(_time * 1.5) * 2;
    _drawRain(canvas, x, y, fade * 0.6);
    canvas
      ..saveLayer(
        null,
        ui.Paint()..color = ui.Color.fromARGB((255 * fade).round(), 0, 0, 0),
      )
      ..translate(x, y - age * 12)
      ..scale(1.12 + age * 0.15);
    WeaponArt.stormCloud(canvas);
    if (age < 0.6 && (_time * 12).floor().isEven) {
      _glow.color = const ui.Color(0x88FFF6C8);
      canvas.drawOval(const ui.Rect.fromLTWH(-85, -40, 170, 76), _glow);
    }
    canvas.restore();
  }

  /// After the beam: the dish cools down and the satellite climbs away.
  void _drawLeavingSatellite(
    ui.Canvas canvas,
    double x,
    double sy,
    double age,
    int dir,
  ) {
    final t = (age / _leaveSeconds).clamp(0.0, 1.0);
    final ease = t * t;
    canvas
      ..save()
      ..translate(x + dir * 380 * ease, sy - 160 * ease);
    final cool = (1 - t * 2).clamp(0.0, 1.0);
    if (cool > 0) {
      _glow.color = ui.Color.fromARGB((120 * cool).round(), 127, 211, 255);
      canvas.drawCircle(const ui.Offset(0, 9), 6 + 20 * cool, _glow);
    }
    WeaponArt.satellite(canvas);
    canvas.restore();
  }

  /// Where a craft is now, between the last two sim ticks.
  double _craftX(Aircraft a) =>
      a.x - a.dir * a.speed * PhysicsConfig.dt * (1 - alpha());

  void _drawBomber(ui.Canvas canvas, Aircraft a) {
    canvas
      ..save()
      ..translate(_craftX(a), a.y + math.sin(_time * 3) * 1.5)
      ..drawOval(const ui.Rect.fromLTWH(-95, 44, 190, 10), _shadow);
    WeaponArt.bomberPlane(canvas, facingLeft: a.dir < 0);
    canvas.restore();
  }

  /// The jet, with its missile under the wing until it fires, and an
  /// afterburner flame.
  void _drawJet(ui.Canvas canvas, Aircraft a) {
    canvas
      ..save()
      ..translate(_craftX(a), a.y)
      ..scale(a.dir.toDouble(), 1);
    final flicker = 0.8 + 0.2 * math.sin(_time * 60);
    // The flame starts at the painted jet's tail.
    const tail = -WeaponArt.jetLength / 2 + 8;
    final flame = ui.Path()
      ..moveTo(tail, -6)
      ..quadraticBezierTo(tail - 22 * flicker, -4, tail - 44 * flicker, 0)
      ..quadraticBezierTo(tail - 22 * flicker, 4, tail, 6)
      ..close();
    _glow.color = const ui.Color(0xCCFF8A2A);
    canvas.drawPath(flame, _glow);
    _glow.color = const ui.Color(0xEEFFE08A);
    canvas.drawOval(ui.Rect.fromLTWH(tail - 20 * flicker, -2.5, 20, 5), _glow);
    if (a.dropped < a.dropXs.length) {
      canvas
        ..save()
        ..translate(0, 22);
      WeaponArt.projectile(canvas, a.payload.id);
      canvas.restore();
    }
    WeaponArt.fighterJet(canvas, facingLeft: false);
    canvas.restore();
  }

  /// A V of five birds of the shooter's own kind, flapping.
  void _drawFlock(ui.Canvas canvas, Aircraft a) {
    final owner = sim.units[a.ownerId];
    const formation = [
      (0.0, 0.0),
      (-26.0, -12.0),
      (-26.0, 12.0),
      (-52.0, -24.0),
      (-52.0, 24.0),
    ];
    for (var i = 0; i < formation.length; i++) {
      final (dx, dy) = formation[i];
      final flap = ((_time * 7 + i * 0.4).floor()).isEven;
      canvas
        ..save()
        ..translate(_craftX(a) + dx * a.dir, a.y + dy + math.sin(_time * 4 + i) * 2)
        ..scale(0.5 * a.dir, 0.5);
      AnimalArt.draw(
        canvas,
        familyId: owner.familyId,
        teamArgb: teamColors[owner.team],
        pose: flap ? AnimalPose.air : AnimalPose.idle,
      );
      canvas.restore();
    }
  }
}
