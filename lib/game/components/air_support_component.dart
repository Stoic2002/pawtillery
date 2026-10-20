import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../sim/world.dart';
import '../art/weapon_art.dart';

/// Draws what the sim has in the sky: bombers crossing the map, and the
/// marker of a satellite strike that is about to fire (a red sighting
/// line down the column and a ring that closes in until the beam hits).
class AirSupportComponent extends Component {
  AirSupportComponent(this.sim) : super(priority: 6);

  final SimWorld sim;

  final ui.Paint _sight = ui.Paint()
    ..strokeWidth = 2
    ..color = const ui.Color(0x99E5484D);
  final ui.Paint _ring = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..color = const ui.Color(0xFFE5484D);
  final ui.Paint _shadow = ui.Paint()..color = const ui.Color(0x33000000);

  double _time = 0;

  @override
  void update(double dt) => _time += dt;

  @override
  void render(ui.Canvas canvas) {
    for (final strike in sim.pendingStrikes) {
      final x = strike.x.toDouble();
      final y = strike.y.toDouble();
      final left = (strike.dueTick - sim.tick).clamp(0, 600);
      // Blinks faster as the beam gets close.
      final blink = (_time * (left < 30 ? 16 : 6)).floor().isEven;
      _sight.color = ui.Color(blink ? 0xCCE5484D : 0x66E5484D);
      canvas
        ..drawLine(ui.Offset(x, -400), ui.Offset(x, y), _sight)
        ..drawCircle(ui.Offset(x, y), 10 + left * 0.35, _ring)
        ..drawCircle(ui.Offset(x, y), 3, _ring);
    }
    for (final b in sim.bombers) {
      canvas
        ..save()
        ..translate(b.x, b.y + math.sin(_time * 3) * 1.5);
      // A soft shadow under the plane reads it against the sky.
      canvas.drawOval(const ui.Rect.fromLTWH(-40, 14, 80, 6), _shadow);
      WeaponArt.bomberPlane(canvas, facingLeft: b.dir < 0);
      canvas.restore();
    }
  }
}
