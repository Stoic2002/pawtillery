import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../config/weapons.dart';
import '../../sim/projectile.dart';
import '../../sim/world.dart';
import '../art/weapon_art.dart';

/// Draws projectiles and mines from the sim, between the last two sim
/// ticks ([alpha]) so they move smoothly at any refresh rate.
class ProjectilesComponent extends Component {
  ProjectilesComponent(this.sim, {required this.alpha}) : super(priority: 5);

  final SimWorld sim;
  final double Function() alpha;

  /// Turn of each projectile, kept here (it is only for show): a tumbling
  /// one spins with its speed and stops when it stops, one that points
  /// along its flight holds its heading while it is too slow to have one.
  final Map<int, double> _angles = {};

  final ui.Paint _fill = ui.Paint();
  final ui.Paint _outline = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..color = const ui.Color(0xFFFFFFFF);
  final ui.Paint _orange = ui.Paint()..color = const ui.Color(0xFFFF9800);
  final ui.Paint _light = ui.Paint();

  double _time = 0;

  @override
  void update(double dt) {
    _time += dt;
    for (final p in sim.projectiles) {
      final flight = p.weapon.flight;
      final speed = math.sqrt(p.vx * p.vx + p.vy * p.vy);
      if (p.weapon.id == Weapons.firecracker.id) {
        // Stands upright so its fuse stays on top.
        _angles[p.id] = 0;
      } else if (flight is Drill || WeaponArt.pointsAlongFlight(p.weapon.id)) {
        if (speed >= _minHeadingSpeed || !_angles.containsKey(p.id)) {
          _angles[p.id] = math.atan2(p.vy, p.vx);
        }
      } else if (!p.resting && speed >= _minSpinSpeed) {
        final rate = flight is Boomerang
            ? 27.0
            : (speed / 60).clamp(_minSpin, _maxSpin);
        _angles[p.id] =
            (_angles[p.id] ?? p.id * 1.3) + (p.vx < 0 ? -rate : rate) * dt;
      }
    }
    if (_angles.length > sim.projectiles.length) {
      final live = {for (final p in sim.projectiles) p.id};
      _angles.removeWhere((id, _) => !live.contains(id));
    }
  }

  static const double _minHeadingSpeed = 25;
  static const double _minSpinSpeed = 14;

  /// Tumbling speed, radians/s.
  static const double _minSpin = 2.5;
  static const double _maxSpin = 8;

  @override
  void render(ui.Canvas canvas) {
    final t = alpha();
    for (final p in sim.projectiles) {
      if (p.body != null) {
        _drawWalker(canvas, p);
        continue;
      }
      final flight = p.weapon.flight;
      if (flight is Vortex && p.mode == 1) {
        _drawVortex(canvas, p, flight);
        continue;
      }
      if (p.weapon.id == Weapons.meteor.id) _meteorTail(canvas, p);
      canvas
        ..save()
        ..translate(p.prevX + (p.x - p.prevX) * t, p.prevY + (p.y - p.prevY) * t)
        ..rotate(_angles[p.id] ?? 0);
      // Rockets show their motor: small before a homing motor starts, gone
      // once a guided missile has burnt out.
      if (WeaponArt.hasMotor(p.weapon.id) &&
          !(flight is Homing && p.mode == 2)) {
        _flame(
          canvas,
          p.mode == 1 || flight is! Homing,
          WeaponArt.motorX(p.weapon.id),
        );
      }
      WeaponArt.projectile(canvas, p.weapon.id);
      canvas.restore();
      if (p.weapon.id == Weapons.firecracker.id) _fuseSpark(canvas, p);
      if (flight is Sticky && (_time * 8).floor().isEven) {
        _light.color = const ui.Color(0xCCFF5A4E);
        canvas.drawCircle(ui.Offset(p.x, p.y + 3), 3.4, _light);
      }
    }
    _drawMines(canvas);
  }

  /// A meteor's flaming tail streaming back along its fall, flickering.
  void _meteorTail(ui.Canvas canvas, Projectile p) {
    final speed = math.sqrt(p.vx * p.vx + p.vy * p.vy);
    if (speed < 1) return;
    final bx = -p.vx / speed;
    final by = -p.vy / speed;
    final flicker = 0.85 + 0.15 * math.sin(_time * 40 + p.id);
    for (final (len, width, argb) in const [
      (70.0, 11.0, 0x66FF6A1A),
      (48.0, 7.5, 0xAAFF9A3A),
      (26.0, 4.5, 0xEEFFE08A),
    ]) {
      final l = len * flicker;
      final tail = ui.Path()
        ..moveTo(p.x - by * width, p.y + bx * width)
        ..lineTo(p.x + bx * l, p.y + by * l)
        ..lineTo(p.x + by * width, p.y - bx * width)
        ..close();
      _light.color = ui.Color(argb);
      canvas.drawPath(tail, _light);
    }
  }

  /// The black hole at work: a dark core, a swirl of violet arms turning
  /// faster as it nears collapse, and the faint edge of its pull.
  void _drawVortex(ui.Canvas canvas, Projectile p, Vortex spec) {
    final t = p.traveled / spec.pullTicks;
    final spin = _time * (4 + 10 * t);
    canvas
      ..save()
      ..translate(p.x, p.y);
    _light
      ..color = const ui.Color(0x223B2A5C)
      ..style = ui.PaintingStyle.fill;
    canvas.drawCircle(ui.Offset.zero, spec.pullRadius, _light);
    final arm = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeCap = ui.StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final a = spin + i * math.pi / 2;
      arm
        ..strokeWidth = 4 - i * 0.5
        ..color = ui.Color.fromARGB(200 - i * 30, 185, 140, 255);
      canvas.drawArc(
        ui.Rect.fromCircle(center: ui.Offset.zero, radius: 30 - i * 5),
        a,
        1.9,
        false,
        arm,
      );
    }
    final core = 9 + 4 * math.sin(_time * 12) * t;
    canvas
      ..drawCircle(
        ui.Offset.zero,
        core + 4,
        _light..color = const ui.Color(0x88B98CFF),
      )
      ..drawCircle(
        ui.Offset.zero,
        core,
        _light..color = const ui.Color(0xFF0B0612),
      )
      ..restore();
  }

  /// A flickering motor flame behind a rocket (drawn pointing right), from
  /// its tail at [tail]; small before a homing rocket's motor starts.
  void _flame(ui.Canvas canvas, bool burning, double tail) {
    final flicker = 0.8 + 0.2 * math.sin(_time * 50);
    final len = (burning ? 22.0 : 7.0) * flicker;
    final flame = ui.Path()
      ..moveTo(tail, -4)
      ..quadraticBezierTo(tail - len * 0.6, -3, tail - len, 0)
      ..quadraticBezierTo(tail - len * 0.6, 3, tail, 4)
      ..close();
    _light.color = const ui.Color(0xCCFF8A2A);
    canvas.drawPath(flame, _light);
    _light.color = const ui.Color(0xEEFFE08A);
    canvas.drawOval(
      ui.Rect.fromLTWH(tail - len * 0.45, -1.8, len * 0.45, 3.6),
      _light,
    );
  }

  /// The lit fuse on a firecracker blinks faster as it runs out.
  void _fuseSpark(ui.Canvas canvas, Projectile p) {
    final left = (p.fuseTicks ?? 0) / 60;
    if ((_time * (left < 1.5 ? 14 : 5)).floor().isEven) {
      _light.color = const ui.Color(0xFFFFD25A);
      canvas.drawCircle(ui.Offset(p.x, p.y - 16), 2.8, _light);
    }
  }

  void _drawWalker(ui.Canvas canvas, Projectile p) {
    final body = p.body!;
    final r = body.stats.hitRadius;
    final c = ui.Offset(body.centerX, body.centerY);
    final f = body.facing.toDouble();
    canvas
      ..drawCircle(c, r, _fill)
      ..drawCircle(c, r, _outline)
      ..drawRRect(
        ui.RRect.fromRectAndRadius(
          ui.Rect.fromLTWH(
            f > 0 ? c.dx + r * 0.6 : c.dx - r * 1.6,
            c.dy - r * 0.1,
            r,
            r * 0.45,
          ),
          ui.Radius.circular(r * 0.2),
        ),
        _orange,
      );
    // Fuse spark blinks faster as it runs out.
    final left = (p.fuseTicks ?? 0) / 60;
    if ((_time * (left < 1.5 ? 12 : 4)).floor().isEven) {
      _light.color = const ui.Color(0xFFFF1744);
      canvas.drawCircle(c + ui.Offset(-f * r * 0.3, -r * 1.1), 3, _light);
    }
  }

  void _drawMines(ui.Canvas canvas) {
    for (final m in sim.mines) {
      final small = m.weapon.radius < Weapons.mine.radius;
      canvas
        ..save()
        ..translate(m.x, m.y);
      WeaponArt.mine(canvas, small: small);
      canvas.restore();
      final armed = sim.turn.turnNumber >= m.armedOnTurn;
      final rate = m.countdown != null ? 14.0 : 2.0;
      if (armed && (_time * rate).floor().isEven) {
        _light.color = const ui.Color(0xFFFF1744);
        canvas.drawCircle(ui.Offset(m.x, m.y - (small ? 13 : 16)), 2.2, _light);
      }
    }
  }
}
