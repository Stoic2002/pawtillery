import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../config/weapons.dart';
import '../../sim/projectile.dart';
import '../../sim/world.dart';
import '../art/weapon_art.dart';

/// Draws projectiles and mines from the sim. Placeholder shapes: a circle
/// in the weapon colour, with a few weapons given a recognisable outline.
class ProjectilesComponent extends Component {
  ProjectilesComponent(this.sim) : super(priority: 5);

  final SimWorld sim;

  final ui.Paint _fill = ui.Paint();
  final ui.Paint _outline = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..color = const ui.Color(0xFFFFFFFF);
  final ui.Paint _orange = ui.Paint()..color = const ui.Color(0xFFFF9800);
  final ui.Paint _light = ui.Paint();

  double _time = 0;

  @override
  void update(double dt) => _time += dt;

  @override
  void render(ui.Canvas canvas) {
    for (final p in sim.projectiles) {
      if (p.body != null) {
        _drawWalker(canvas, p);
        continue;
      }
      final flight = p.weapon.flight;
      final along = WeaponArt.pointsAlongFlight(p.weapon.id);
      // Carrots and rockets point along their flight; everything else
      // tumbles.
      // The firecracker stands upright so its fuse stays on top.
      final angle = flight is Drill || along
          ? math.atan2(p.vy, p.vx)
          : p.weapon.id == Weapons.firecracker.id
          ? 0.0
          : p.ageTicks * (flight is Boomerang ? 0.45 : 0.12);
      canvas
        ..save()
        ..translate(p.x, p.y)
        ..rotate(angle);
      // Rockets show their motor: small before a homing motor starts, gone
      // once a guided missile has burnt out.
      if (WeaponArt.hasMotor(p.weapon.id) &&
          !(flight is Homing && p.mode == 2)) {
        _flame(canvas, p.mode == 1 || flight is! Homing);
      }
      WeaponArt.projectile(canvas, p.weapon.id);
      canvas.restore();
      if (p.weapon.id == Weapons.firecracker.id) _fuseSpark(canvas, p);
    }
    _drawMines(canvas);
  }

  /// A flickering motor flame behind a rocket (drawn pointing right);
  /// small before a homing rocket's motor starts.
  void _flame(ui.Canvas canvas, bool burning) {
    final flicker = 0.8 + 0.2 * math.sin(_time * 50);
    final len = (burning ? 11.0 : 4.0) * flicker;
    final flame = ui.Path()
      ..moveTo(-8, -2.6)
      ..quadraticBezierTo(-8 - len * 0.6, -2, -8 - len, 0)
      ..quadraticBezierTo(-8 - len * 0.6, 2, -8, 2.6)
      ..close();
    _light.color = const ui.Color(0xCCFF8A2A);
    canvas.drawPath(flame, _light);
    _light.color = const ui.Color(0xEEFFE08A);
    canvas.drawOval(
        ui.Rect.fromLTWH(-8 - len * 0.45, -1.2, len * 0.45, 2.4), _light);
  }

  /// The lit fuse on a firecracker blinks faster as it runs out.
  void _fuseSpark(ui.Canvas canvas, Projectile p) {
    final left = (p.fuseTicks ?? 0) / 60;
    if ((_time * (left < 1.5 ? 14 : 5)).floor().isEven) {
      _light.color = const ui.Color(0xFFFFD25A);
      canvas.drawCircle(ui.Offset(p.x, p.y - 10), 2.4, _light);
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
              f > 0 ? c.dx + r * 0.6 : c.dx - r * 1.6, c.dy - r * 0.1, r, r * 0.45),
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
        canvas.drawCircle(
            ui.Offset(m.x, m.y - (small ? 7 : 9.5)), 1.8, _light);
      }
    }
  }
}
