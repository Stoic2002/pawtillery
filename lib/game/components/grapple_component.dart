import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../sim/world.dart';
import '../art/weapon_art.dart';

/// Draws grappling hook ropes: taut from a unit being reeled in to its
/// hook in the ground, and for a shot that fell short, the hook flying out
/// to the end of the rope and being pulled back.
class GrappleComponent extends Component {
  GrappleComponent(this.sim) : super(priority: 4);

  final SimWorld sim;

  /// Seconds a missed hook takes to fly out, then to come back.
  static const double _outSeconds = 0.14;
  static const double _backSeconds = 0.26;

  /// Missed shots: (x0, y0, x1, y1, seconds since the shot).
  final List<(double, double, double, double, double)> _misses = [];

  final ui.Paint _ropeDark = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 3.4
    ..strokeCap = ui.StrokeCap.round
    ..color = const ui.Color(0xFF5A3D24);
  final ui.Paint _rope = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1.8
    ..strokeCap = ui.StrokeCap.round
    ..color = const ui.Color(0xFFC9A66B);

  void missed(double x0, double y0, double x1, double y1) =>
      _misses.add((x0, y0, x1, y1, 0));

  @override
  void update(double dt) {
    for (var i = _misses.length - 1; i >= 0; i--) {
      final (x0, y0, x1, y1, age) = _misses[i];
      if (age + dt >= _outSeconds + _backSeconds) {
        _misses.removeAt(i);
      } else {
        _misses[i] = (x0, y0, x1, y1, age + dt);
      }
    }
  }

  @override
  void render(ui.Canvas canvas) {
    for (final u in sim.units) {
      if (!u.alive || !u.isGrappling) continue;
      _line(
        canvas,
        ui.Offset(u.centerX, u.centerY),
        ui.Offset(u.grappleX, u.grappleY),
      );
    }
    for (final (x0, y0, x1, y1, age) in _misses) {
      final t = age < _outSeconds
          ? age / _outSeconds
          : 1 - (age - _outSeconds) / _backSeconds;
      final from = ui.Offset(x0, y0);
      _line(canvas, from, ui.Offset.lerp(from, ui.Offset(x1, y1), t)!);
    }
  }

  /// The rope from [from] to [to] with the hook at [to], pointing away.
  void _line(ui.Canvas canvas, ui.Offset from, ui.Offset to) {
    canvas
      ..drawLine(from, to, _ropeDark)
      ..drawLine(from, to, _rope)
      ..save()
      ..translate(to.dx, to.dy)
      ..rotate(math.atan2(to.dy - from.dy, to.dx - from.dx))
      // The hook's points sit in the ground, the rope tied on behind.
      ..translate(-14, 0);
    WeaponArt.grappleHook(canvas);
    canvas.restore();
  }
}
