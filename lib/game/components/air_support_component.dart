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
  AirSupportComponent(this.sim, {required this.teamColors})
    : super(priority: 6);

  final SimWorld sim;
  final List<int> teamColors;

  /// Heights the satellite and the storm cloud sit at (world y).
  static const double satelliteY = 40;
  static const double cloudY = 70;

  /// Ticks the satellite or cloud spends arriving; then it charges.
  static const int _arriveTicks = 36;

  /// How far away (px) they start.
  static const double _arriveDistance = 420;

  /// 0 → 1 over the arrival, eased.
  static double _arrival(SimWorld sim, PendingStrike s) {
    final t = ((sim.tick - s.firedTick) / _arriveTicks).clamp(0.0, 1.0);
    return 1 - (1 - t) * (1 - t);
  }

  /// Where the satellite or storm cloud of [s] is now (also followed by
  /// the camera).
  static double strikeSourceX(SimWorld sim, PendingStrike s) =>
      s.x + s.fromDir * _arriveDistance * (1 - _arrival(sim, s));

  static double strikeSourceY(PendingStrike s) =>
      s.weapon.delivery is Lightning ? cloudY : satelliteY;

  final ui.Paint _sight = ui.Paint()..strokeWidth = 2;
  final ui.Paint _ring = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..color = const ui.Color(0xFFE5484D);
  final ui.Paint _shadow = ui.Paint()..color = const ui.Color(0x33000000);
  final ui.Paint _glow = ui.Paint();

  double _time = 0;

  @override
  void update(double dt) => _time += dt;

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
    final blink = (_time * (left < 30 ? 16 : 6)).floor().isEven;
    _sight.color = ui.Color(blink ? 0xCCE5484D : 0x66E5484D);
    canvas
      ..drawLine(ui.Offset(x, strikeSourceY(s)), ui.Offset(x, y), _sight)
      ..drawCircle(ui.Offset(x, y), 10 + left * 0.35, _ring)
      ..drawCircle(ui.Offset(x, y), 3, _ring);
  }

  /// The satellite glides in, then its dish charges: a cold glow that
  /// grows until the beam fires.
  void _drawSatellite(ui.Canvas canvas, PendingStrike s) {
    final x = strikeSourceX(sim, s);
    final total = (s.dueTick - s.firedTick).clamp(1, 600);
    final charge =
        ((sim.tick - s.firedTick - _arriveTicks) /
                (total - _arriveTicks).clamp(1, 600))
            .clamp(0.0, 1.0);
    canvas
      ..save()
      ..translate(x, satelliteY + math.sin(_time * 2) * 1.2);
    if (charge > 0) {
      final flicker = 0.85 + 0.15 * math.sin(_time * 40);
      _glow.color = ui.Color.fromARGB(
        (90 * charge * flicker).round(),
        127,
        211,
        255,
      );
      canvas.drawCircle(const ui.Offset(0, 9), 6 + 22 * charge, _glow);
      _glow.color = ui.Color.fromARGB((230 * charge).round(), 244, 251, 255);
      canvas.drawCircle(const ui.Offset(0, 9), 2 + 6 * charge, _glow);
    }
    WeaponArt.satellite(canvas);
    canvas.restore();
  }

  /// The storm cloud rides in, then darkens and flickers before the bolt.
  void _drawCloud(ui.Canvas canvas, PendingStrike s) {
    final x = strikeSourceX(sim, s);
    final arrived = _arrival(sim, s) >= 1;
    canvas
      ..save()
      ..translate(x, cloudY + math.sin(_time * 1.5) * 2);
    WeaponArt.stormCloud(canvas);
    if (arrived && (_time * 9).floor() % 3 == 0) {
      // Lightning flickering inside the cloud.
      _glow.color = const ui.Color(0x55FFF6C8);
      canvas.drawOval(const ui.Rect.fromLTWH(-40, -20, 80, 36), _glow);
    }
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
