import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../config/weapons.dart';
import '../../sim/air_support.dart';
import '../../sim/world.dart';
import '../art/animal_art.dart';
import '../art/weapon_art.dart';

/// Draws what the sim has in the sky, so every "external" weapon is seen
/// arriving: bombers, fighter jets and bird flocks crossing the map; the
/// satellite gliding over its column and charging; the storm cloud
/// drifting in on the wind and rumbling. A red sighting line and a closing
/// ring mark where a strike from the sky will land.
class AirSupportComponent extends Component {
  AirSupportComponent(
    this.sim, {
    required this.teamColors,
    required this.viewHeight,
  }) : super(priority: 6);

  final SimWorld sim;
  final List<int> teamColors;

  /// Height of the visible world (px), so a satellite or storm cloud can
  /// sit near the top of the view over a low target rather than far above
  /// it, out of sight.
  final double Function() viewHeight;

  /// Highest the satellite and the storm cloud sit (world y).
  static const double satelliteY = 40;
  static const double cloudY = 70;

  /// Where the satellite or storm cloud over a target at [targetY] sits:
  /// near the top of a view framed on the target (see the game's camera).
  double sourceYFor({required bool lightning, required double targetY}) {
    final vh = viewHeight();
    return lightning
        ? math.max(cloudY, targetY - vh * 0.5)
        : math.max(satelliteY, targetY - vh * 0.56);
  }

  /// Where the storm cloud sits, or the satellite parks to fire (the
  /// sim's own firing point, so its beams leave from it).
  double strikeSourceY(PendingStrike s) => s.weapon.delivery is Lightning
      ? sourceYFor(lightning: true, targetY: s.y.toDouble())
      : SimWorld.satelliteAim(s).$1.$2;

  /// Ticks the satellite or cloud spends arriving; then it charges.
  static const int _arriveTicks = 72;

  /// How far away (px) they start.
  static const double _arriveDistance = 520;

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

  /// Where the satellite or storm cloud of [s] is now (also followed by
  /// the camera).
  static double strikeSourceX(SimWorld sim, PendingStrike s) =>
      (s.weapon.delivery is Lightning
          ? s.x.toDouble()
          : SimWorld.satelliteAim(s).$1.$1) +
      s.fromDir * _arriveDistance * (1 - _arrival(sim, s));

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
      _drawMarker(canvas, s);
      if (s.weapon.delivery is Lightning) {
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
    if (arrived && s.weapon.delivery is Lightning) {
      canvas.drawLine(ui.Offset(x, strikeSourceY(s)), ui.Offset(x, y), _sight);
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
    final x = strikeSourceX(sim, s);
    final sy = strikeSourceY(s);
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
    final x = strikeSourceX(sim, s);
    final charge = chargeOf(sim, s);
    final y = strikeSourceY(s) + math.sin(_time * 1.5) * 2;
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
      canvas.drawOval(const ui.Rect.fromLTWH(-44, -22, 88, 40), _glow);
      if (charge > 0.5) _miniBolt(canvas, (_time * rate).floor());
    }
    canvas.restore();
  }

  /// Rain from the cloud's underside, as streaks that loop downwards.
  void _drawRain(ui.Canvas canvas, double x, double y, double amount) {
    if (amount <= 0) return;
    _rain.color = ui.Color.fromARGB((150 * amount).round(), 170, 200, 235);
    for (var i = 0; i < 16; i++) {
      final dx = -60 + i * 8.0;
      final fall = (_time * 380 + i * 53) % 150;
      final top = y + 20 + fall;
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
    final path = ui.Path()..moveTo(-30 + r.nextDouble() * 60, -6);
    var px = 0.0;
    for (var i = 1; i <= 4; i++) {
      px = -30 + r.nextDouble() * 60;
      path.lineTo(px, -6 + i * 7.0);
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
      canvas.drawOval(const ui.Rect.fromLTWH(-44, -22, 88, 40), _glow);
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

  void _drawBomber(ui.Canvas canvas, Aircraft a) {
    canvas
      ..save()
      ..translate(a.x, a.y + math.sin(_time * 3) * 1.5)
      ..drawOval(const ui.Rect.fromLTWH(-40, 14, 80, 6), _shadow);
    WeaponArt.bomberPlane(canvas, facingLeft: a.dir < 0);
    canvas.restore();
  }

  /// The jet, with its missile under the wing until it fires, and an
  /// afterburner flame.
  void _drawJet(ui.Canvas canvas, Aircraft a) {
    canvas
      ..save()
      ..translate(a.x, a.y)
      ..scale(a.dir.toDouble(), 1);
    final flicker = 0.8 + 0.2 * math.sin(_time * 60);
    final flame = ui.Path()
      ..moveTo(-43, -3)
      ..quadraticBezierTo(-52 - 14 * flicker, -2, -60 - 16 * flicker, 0)
      ..quadraticBezierTo(-52 - 14 * flicker, 2, -43, 3)
      ..close();
    _glow.color = const ui.Color(0xCCFF8A2A);
    canvas.drawPath(flame, _glow);
    _glow.color = const ui.Color(0xEEFFE08A);
    canvas.drawOval(ui.Rect.fromLTWH(-52 - 6 * flicker, -1.4, 10, 2.8), _glow);
    if (a.dropped < a.dropXs.length) {
      canvas
        ..save()
        ..translate(-4, 9);
      WeaponArt.projectile(canvas, a.payload.id);
      canvas.restore();
    }
    WeaponArt.fighterJet(canvas, facingLeft: false);
    canvas.restore();
  }

  /// A V of five birds of the shooter's own breed, flapping.
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
        ..translate(a.x + dx * a.dir, a.y + dy + math.sin(_time * 4 + i) * 2)
        ..scale(0.5 * a.dir, 0.5);
      AnimalArt.draw(
        canvas,
        familyId: owner.familyId,
        breedId: owner.breedId,
        teamArgb: teamColors[owner.team],
        pose: flap ? AnimalPose.air : AnimalPose.idle,
      );
      canvas.restore();
    }
  }
}
