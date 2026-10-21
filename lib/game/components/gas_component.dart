import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../config/weapons.dart';
import '../../sim/world.dart';

/// Draws poison gas: each cloud a slowly churning knot of sickly green
/// puffs, thinner as it runs out of turns.
class GasComponent extends Component {
  GasComponent(this.sim) : super(priority: 7);

  final SimWorld sim;
  double _time = 0;
  final ui.Paint _puff = ui.Paint();

  @override
  void update(double dt) => _time += dt;

  @override
  void render(ui.Canvas canvas) {
    for (final c in sim.clouds) {
      final strength = 0.45 + 0.55 * c.turnsLeft / GasConfig.turns;
      final r = c.radius.toDouble();
      for (var i = 0; i < 9; i++) {
        final a = i * 2.4 + _time * (0.25 + 0.04 * i) + c.id;
        final d = r * (0.2 + 0.5 * ((i * 37) % 10) / 10);
        final center = ui.Offset(
          c.x + math.cos(a) * d,
          c.y + math.sin(a) * d * 0.6,
        );
        final pr = r * (0.42 + 0.12 * math.sin(_time * 1.3 + i));
        _puff.shader = ui.Gradient.radial(center, pr, [
          ui.Color.fromARGB((120 * strength).round(), 150, 214, 90),
          ui.Color.fromARGB(0, 120, 190, 70),
        ]);
        canvas.drawCircle(center, pr, _puff);
      }
      // A few bubbles rising out of it.
      for (var i = 0; i < 4; i++) {
        final t = (_time * 0.6 + i * 0.25) % 1;
        _puff
          ..shader = null
          ..color = ui.Color.fromARGB(
            (170 * (1 - t) * strength).round(),
            190,
            240,
            120,
          );
        canvas.drawCircle(
          ui.Offset(c.x + (i - 1.5) * r * 0.35, c.y - r * 0.2 - t * r * 0.8),
          2.2,
          _puff,
        );
      }
    }
  }
}
