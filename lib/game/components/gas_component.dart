import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../config/weapons.dart';
import '../../sim/world.dart';

/// Draws poison gas as the sim's puffs: soft overlapping blobs that swell
/// and breathe, with a few bubbles and wisps rising off the top. Thinner
/// as it runs out of turns. Drawn behind the terrain, so gas lying in a
/// hollow or against a wall is cut off by the ground, never over it.
class GasComponent extends Component {
  GasComponent(this.sim) : super(priority: -1);

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
      final swell = 1 - math.pow(1 - (age / 1.2).clamp(0.0, 1.0), 3);
      final strength =
          (0.5 + 0.5 * c.turnsLeft / GasConfig.turns) *
          (age / 0.25).clamp(0.0, 1.0);
      final r = c.spacing * (0.7 + 0.65 * swell);
      // Fallout is a sicklier yellow-green than plain gas.
      final tones = c.fallout
          ? const [(205, 225, 70), (165, 178, 52), (228, 236, 140)]
          : const [(140, 208, 84), (98, 150, 58), (186, 228, 128)];

      for (var i = 0; i < c.puffs.length; i++) {
        final p = c.puffs[i];
        final phase = i * 1.9 + c.id;
        final center = ui.Offset(
          p.x + math.sin(_time * 0.5 + phase) * r * 0.1,
          p.y - r * 0.1 + math.cos(_time * 0.4 + phase) * r * 0.07,
        );
        final pr = r * (0.95 + 0.1 * math.sin(_time * 0.8 + phase));
        _blob(canvas, center, pr, 0.85, tones[i % 3], 130 * strength);

        // Every third puff lets a wisp and a bubble rise off it.
        if (i % 3 != 0) continue;
        final t = (_time * 0.2 + i * 0.37 + c.id * 0.37) % 1;
        _blob(
          canvas,
          ui.Offset(
            p.x + wind * t * 1.5 + math.sin(t * 5 + i) * r * 0.2,
            p.y - r * (0.4 + t * 1.1),
          ),
          r * 0.35 * (0.7 + t),
          0.7,
          tones[2],
          80 * math.sin(t * math.pi) * strength,
        );
        final rise = (_time * 0.5 + i * 0.61) % 1;
        _puff
          ..shader = null
          ..color = ui.Color.fromARGB(
            (150 * (1 - rise) * strength).round(),
            tones[2].$1,
            tones[2].$2,
            tones[2].$3,
          );
        canvas.drawCircle(
          ui.Offset(p.x + math.sin(rise * 6 + i) * 3, p.y - rise * r * 1.4),
          1.5 + (i % 3) * 0.5,
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
