import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../sim/turn_manager.dart';
import '../../sim/world.dart';
import 'unit_painter.dart';

/// Draws every living unit with its placeholder look, its name and HP
/// above it, and a bobbing marker over the active unit.
class UnitsComponent extends Component {
  UnitsComponent(
    this.sim, {
    required this.familyLetters,
    required this.teamColors,
    required this.unitNames,
  }) : super(priority: 4);

  final SimWorld sim;

  /// Localized first letter of each family name, by family id.
  final Map<String, String> familyLetters;

  /// Colour (0xAARRGGBB) of each sim team.
  final List<int> teamColors;

  /// Display name of each unit, by unit id.
  final List<String> unitNames;

  final UnitPlaceholderPainter _painter = UnitPlaceholderPainter();
  final ui.Paint _marker = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
  final ui.Paint _markerEdge = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = const ui.Color(0xFF222222);

  late final List<TextPaint> _hpText = [
    for (final argb in teamColors)
      TextPaint(
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: ui.Color(argb),
          shadows: const [Shadow(color: ui.Color(0xFF000000), blurRadius: 3)],
        ),
      ),
  ];
  final TextPaint _nameText = TextPaint(
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: ui.Color(0xFFFFFFFF),
      shadows: [Shadow(color: ui.Color(0xFF000000), blurRadius: 3)],
    ),
  );

  double _time = 0;

  @override
  void update(double dt) => _time += dt;

  @override
  void render(ui.Canvas canvas) {
    final active = sim.activeUnit;
    final showMarker = sim.turn.phase == TurnPhase.turnStart ||
        sim.turn.phase == TurnPhase.action;

    for (final u in sim.units) {
      if (!u.alive) continue;
      _painter.paint(
        canvas,
        center: ui.Offset(u.centerX, u.centerY),
        radius: u.stats.hitRadius,
        facing: u.facing,
        teamArgb: teamColors[u.team],
        familyId: u.familyId,
        breedId: u.breedId,
        letter: u.familyId == null ? null : familyLetters[u.familyId],
      );

      final top = u.centerY - u.stats.hitRadius;
      final hpY = top - 10;
      _hpText[u.team].render(
        canvas,
        '${math.max(0, u.hp)}',
        Vector2(u.centerX, hpY),
        anchor: Anchor.bottomCenter,
      );
      final name = u.id < unitNames.length ? unitNames[u.id] : '';
      if (name.isNotEmpty) {
        _nameText.render(canvas, name, Vector2(u.centerX, hpY - 15),
            anchor: Anchor.bottomCenter);
      }

      if (showMarker && u == active) {
        final bob = math.sin(_time * 6) * 3;
        final tipY = hpY - (name.isEmpty ? 22 : 34) + bob;
        final cx = u.centerX;
        final path = ui.Path()
          ..moveTo(cx, tipY)
          ..lineTo(cx - 8, tipY - 12)
          ..lineTo(cx + 8, tipY - 12)
          ..close();
        canvas
          ..drawPath(path, _marker)
          ..drawPath(path, _markerEdge);
      }
    }
  }
}
