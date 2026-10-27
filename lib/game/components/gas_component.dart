import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../config/weapons.dart';
import '../../sim/world.dart';

/// Draws poison gas: each cloud swells out from where it was released
/// into a heavy, slowly rolling mass of sickly green puffs, densest in a
/// layer that hugs the ground, with wisps peeling off downwind. Thinner
/// as it runs out of turns. Drawn out to the cloud's whole poison radius.
class GasComponent extends Component {
  GasComponent(this.sim) : super(priority: 7);

  final SimWorld sim;
  double _time = 0;
  final ui.Paint _puff = ui.Paint();

  /// When each cloud was first drawn, for its swell.
  final Map<int, double> _born = {};

  @override
  void update(double dt) {
    _time += dt;
    if (_born.length > sim.clouds.length) {
      final live = {for (final c in sim.clouds) c.id};
      _born.removeWhere((id, _) => !live.contains(id));
    }
  }

  @override
  void render(ui.Canvas canvas) {
    final wind = sim.wind.toDouble();
    for (final c in sim.clouds) {
      final age = _time - (_born[c.id] ??= _time);
      final swell = 1 - math.pow(1 - (age / 1.4).clamp(0.0, 1.0), 3);
      final strength =
          (0.5 + 0.5 * c.turnsLeft / GasConfig.turns) *
          (age / 0.25).clamp(0.0, 1.0);
      final r = c.radius * (0.3 + 0.7 * swell);
      // Fallout is a sicklier yellow-green than plain gas.
      final tones = c.fallout
          ? const [(205, 225, 70), (165, 178, 52), (228, 236, 140)]
          : const [(140, 208, 84), (98, 150, 58), (186, 228, 128)];

      // The heavy layer along the ground.
      for (var i = 0; i < 5; i++) {
        final fx = (i - 2) / 2;
        final center = ui.Offset(
          c.x +
              fx * r * 0.8 +
              math.sin(_time * 0.35 + i * 1.9 + c.id) * r * 0.06,
          c.y + r * 0.32,
        );
        _blob(
          canvas,
          center,
          r * (0.42 - 0.06 * fx.abs()),
          0.4,
          tones[i % 2],
          170 * strength,
        );
      }

      // The rolling body: puffs spread over the disc (golden angle), each
      // turning slowly and breathing; the upper ones lean downwind.
      const body = 12;
      for (var i = 0; i < body; i++) {
        final k = (i + 0.5) / body;
        final d = r * 0.68 * math.sqrt(k);
        final spin = (0.1 + 0.02 * (i % 4)) * (i.isEven ? 1 : -1);
        final a = i * 2.39996 + _time * spin + c.id;
        final dy = math.sin(a) * d * 0.62;
        final center = ui.Offset(
          c.x + math.cos(a) * d - dy / r * wind * 1.2,
          c.y + dy,
        );
        final pr = r * (0.34 + 0.07 * math.sin(_time * 0.8 + i * 1.7));
        final tone = tones[i % 3];
        // Thinner towards the top.
        final alpha = (dy > 0 ? 150 : 150 + dy / r * 90) * strength;
        _blob(canvas, center, pr, 0.75, tone, alpha);
      }

      // Wisps peel off and drift away downwind (both ways in a calm).
      for (var i = 0; i < 5; i++) {
        final t = (_time * 0.16 + i / 5 + c.id * 0.37) % 1;
        final side = wind == 0 ? (i.isEven ? 1.0 : -1.0) : wind.sign;
        final reach = r * (0.55 + t * (0.7 + wind.abs() * 0.05));
        final center = ui.Offset(
          c.x + side * reach,
          c.y - r * 0.05 + math.sin(t * 5 + i) * r * 0.12 - t * r * 0.2,
        );
        _blob(
          canvas,
          center,
          r * 0.18 * (0.7 + t),
          0.6,
          tones[2],
          110 * math.sin(t * math.pi) * strength,
        );
      }

      // A few bubbles rising out of it.
      for (var i = 0; i < 6; i++) {
        final t = (_time * 0.5 + i / 6 + c.id * 0.21) % 1;
        _puff
          ..shader = null
          ..color = ui.Color.fromARGB(
            (160 * (1 - t) * strength).round(),
            tones[2].$1,
            tones[2].$2,
            tones[2].$3,
          );
        canvas.drawCircle(
          ui.Offset(
            c.x + (i - 2.5) * r * 0.25 + math.sin(t * 6 + i) * 3,
            c.y - t * r * 0.9,
          ),
          1.6 + (i % 3) * 0.6,
          _puff,
        );
      }
    }
  }

  /// A soft round puff of radius [pr], squashed to [squash] of its height.
  void _blob(
    ui.Canvas canvas,
    ui.Offset center,
    double pr,
    double squash,
    (int, int, int) tone,
    double alpha,
  ) {
    if (alpha <= 0 || pr <= 0) return;
    final (red, green, blue) = tone;
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..scale(1, squash);
    // The paint's colour alpha scales a shader too: reset it after the
    // bubbles.
    _puff.color = const ui.Color(0xFFFFFFFF);
    _puff.shader = ui.Gradient.radial(
      ui.Offset.zero,
      pr,
      [
        ui.Color.fromARGB(alpha.round().clamp(0, 255), red, green, blue),
        ui.Color.fromARGB(
          (alpha * 0.75).round().clamp(0, 255),
          red,
          green,
          blue,
        ),
        ui.Color.fromARGB(0, red, green, blue),
      ],
      const [0, 0.55, 1],
    );
    canvas
      ..drawCircle(ui.Offset.zero, pr, _puff)
      ..restore();
  }
}
