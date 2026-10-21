import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../config/weapons.dart';
import '../../sim/world.dart';

/// Draws napalm fire on the ground: each patch a small cluster of
/// flickering flame tongues over a glowing ember bed, lower as it burns
/// out, with a warm glow around it.
class FireComponent extends Component {
  FireComponent(this.sim) : super(priority: 5);

  final SimWorld sim;
  double _time = 0;

  final ui.Paint _paint = ui.Paint();
  final ui.Paint _glow = ui.Paint();

  @override
  void update(double dt) => _time += dt;

  @override
  void render(ui.Canvas canvas) {
    for (final f in sim.fires) {
      // Smaller as it burns out.
      final life = 0.55 + 0.45 * f.turnsLeft / FireConfig.turns;
      final x = f.x.toDouble();
      final y = f.y.toDouble() + 1;
      final glow = ui.Offset(x, y - 6);
      canvas.drawCircle(
        glow,
        20 * life,
        _glow
          ..shader = ui.Gradient.radial(glow, 20 * life, const [
            ui.Color(0x55FFB04A),
            ui.Color(0x00FFB04A),
          ]),
      );
      _paint.color = const ui.Color(0xFFB8321A);
      canvas.drawOval(
        ui.Rect.fromCenter(center: ui.Offset(x, y), width: 20, height: 5),
        _paint,
      );
      for (var i = 0; i < 3; i++) {
        final phase = _time * (7 + i) + f.id * 1.7 + i * 2.1;
        final dx = (i - 1) * 6.0;
        final h = (13 + 5 * math.sin(phase)) * life * (i == 1 ? 1.25 : 0.9);
        final sway = math.sin(phase * 1.3) * 2.2;
        _tongue(canvas, x + dx, y, h, 4.6 * life, sway, 0xFFFF6A1A);
        _tongue(
          canvas,
          x + dx,
          y,
          h * 0.62,
          2.8 * life,
          sway * 0.6,
          0xFFFFC23A,
        );
        _tongue(canvas, x + dx, y, h * 0.3, 1.5 * life, 0, 0xFFFFF2B0);
      }
    }
  }

  /// One flame tongue [h] tall and [w] wide at its base, tip leaning by
  /// [sway].
  void _tongue(
    ui.Canvas canvas,
    double x,
    double y,
    double h,
    double w,
    double sway,
    int argb,
  ) {
    final path = ui.Path()
      ..moveTo(x - w, y)
      ..quadraticBezierTo(x - w * 1.1, y - h * 0.55, x + sway, y - h)
      ..quadraticBezierTo(x + w * 1.1, y - h * 0.55, x + w, y)
      ..close();
    _paint.color = ui.Color(argb);
    canvas.drawPath(path, _paint);
  }
}
