import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../config/units.dart';
import '../../sim/unit.dart';
import '../../sim/world.dart';
import '../art/animal_art.dart';

/// "-25" rising over a unit that just took damage, so every hit shows where
/// it landed: thrown shots, beams, lightning and orbital strikes alike.
/// Hits on the same unit within a moment add up into one number.
class DamageNumbersComponent extends Component {
  DamageNumbersComponent(this.sim) : super(priority: 21);

  final SimWorld sim;

  static const double _life = 1.3;

  /// Hits closer together than this (s) merge into one number.
  static const double _merge = 0.35;

  final List<_Number> _numbers = [];
  final TextPaint _text = TextPaint(
    style: const TextStyle(
      fontFamily: 'Baloo2',
      fontVariations: [ui.FontVariation('wght', 800)],
      fontWeight: FontWeight.w800,
      fontSize: 17,
      height: 1,
      color: Color(0xFFFF5A4E),
      shadows: [
        Shadow(color: Color(0xFF2B2118), blurRadius: 0, offset: Offset(1, 1)),
        Shadow(color: Color(0xFF2B2118), blurRadius: 2),
      ],
    ),
  );
  final ui.Paint _layer = ui.Paint();

  void show(int unitId, int amount) {
    if (amount <= 0) return;
    for (final n in _numbers) {
      if (n.unitId == unitId && n.age < _merge) {
        n
          ..amount += amount
          ..age = 0;
        return;
      }
    }
    final u = sim.units[unitId];
    _numbers.add(_Number(unitId, amount, u.centerX, _tagTop(u)));
  }

  /// Top of the unit's name tag (see UnitsComponent): numbers rise from
  /// just above it.
  static double _tagTop(Unit u) =>
      u.y - AnimalArt.height * u.stats.hitRadius / UnitConfig.hitRadius - 22;

  @override
  void update(double dt) {
    for (final n in _numbers) {
      n.age += dt;
      // Follow the unit while it is knocked back, until it is gone.
      final u = sim.units[n.unitId];
      if (u.alive) {
        n
          ..x = u.centerX
          ..y = _tagTop(u);
      }
    }
    _numbers.removeWhere((n) => n.age > _life);
  }

  @override
  void render(ui.Canvas canvas) {
    for (final n in _numbers) {
      final t = n.age / _life;
      // Pops up fast, then drifts and fades.
      final rise = 10 + 22 * (1 - math.pow(1 - t, 3));
      final alpha = t < 0.7 ? 1.0 : (1 - (t - 0.7) / 0.3);
      final pop = t < 0.08 ? 0.6 + 0.4 * t / 0.08 : 1.0;
      _layer.color = Color.fromRGBO(0, 0, 0, alpha.clamp(0.0, 1.0));
      // A small layer around the number only: a full-screen one per number
      // is costly on phones.
      final at = ui.Offset(n.x, n.y - rise);
      canvas
        ..saveLayer(
            ui.Rect.fromCenter(center: at, width: 90, height: 34), _layer)
        ..translate(at.dx, at.dy)
        ..scale(pop);
      _text.render(canvas, '-${n.amount}', Vector2.zero(),
          anchor: Anchor.center);
      canvas.restore();
    }
  }
}

class _Number {
  _Number(this.unitId, this.amount, this.x, this.y);
  final int unitId;
  int amount;
  double x;
  double y;
  double age = 0;
}
