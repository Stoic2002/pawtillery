import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../config/weapons.dart';
import '../../sim/projectile.dart';
import '../../sim/world.dart';

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
  final ui.Paint _dark = ui.Paint()..color = const ui.Color(0xFF263238);
  final ui.Paint _orange = ui.Paint()..color = const ui.Color(0xFFFF9800);
  final ui.Paint _light = ui.Paint();
  final ui.Paint _shaft = ui.Paint()
    ..strokeWidth = 6
    ..strokeCap = ui.StrokeCap.round;
  final ui.Paint _leaf = ui.Paint()..color = const ui.Color(0xFF66BB6A);

  double _time = 0;

  @override
  void update(double dt) => _time += dt;

  @override
  void render(ui.Canvas canvas) {
    for (final p in sim.projectiles) {
      _fill.color = ui.Color(p.weapon.placeholderArgb);
      final flight = p.weapon.flight;
      if (p.body != null) {
        _drawWalker(canvas, p);
      } else if (flight is Boomerang) {
        _drawBone(canvas, p);
      } else if (flight is Drill) {
        _drawCarrot(canvas, p);
      } else {
        final r = (p.weapon.radius * 0.25).clamp(5.0, 12.0);
        final c = ui.Offset(p.x, p.y);
        canvas
          ..drawCircle(c, r, _fill)
          ..drawCircle(c, r, _outline);
      }
    }
    _drawMines(canvas);
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

  void _drawBone(ui.Canvas canvas, Projectile p) {
    canvas
      ..save()
      ..translate(p.x, p.y)
      ..rotate(p.ageTicks * 0.45);
    _shaft.color = _fill.color;
    canvas
      ..drawLine(const ui.Offset(-12, 0), const ui.Offset(12, 0), _shaft)
      ..drawCircle(const ui.Offset(-13, -3), 4, _fill)
      ..drawCircle(const ui.Offset(-13, 3), 4, _fill)
      ..drawCircle(const ui.Offset(13, -3), 4, _fill)
      ..drawCircle(const ui.Offset(13, 3), 4, _fill)
      ..restore();
  }

  void _drawCarrot(ui.Canvas canvas, Projectile p) {
    final angle = math.atan2(p.vy, p.vx);
    canvas
      ..save()
      ..translate(p.x, p.y)
      ..rotate(angle)
      ..drawPath(
        ui.Path()
          ..moveTo(12, 0)
          ..lineTo(-8, -6)
          ..lineTo(-8, 6)
          ..close(),
        _fill,
      )
      ..drawCircle(const ui.Offset(-10, 0), 4, _leaf)
      ..restore();
  }

  void _drawMines(ui.Canvas canvas) {
    for (final m in sim.mines) {
      final c = ui.Offset(m.x, m.centerY);
      final small = m.weapon.radius < Weapons.mine.radius;
      final r = small ? 4.5 : 6.5;
      _fill.color = ui.Color(m.weapon.placeholderArgb);
      canvas
        ..drawCircle(c, r + 1.5, _dark)
        ..drawCircle(c, r, _fill);
      final armed = sim.turn.turnNumber >= m.armedOnTurn;
      final rate = m.countdown != null ? 14.0 : 2.0;
      if (armed && (_time * rate).floor().isEven) {
        _light.color = const ui.Color(0xFFFF1744);
        canvas.drawCircle(c + ui.Offset(0, -r - 1), 2.5, _light);
      }
    }
  }
}
