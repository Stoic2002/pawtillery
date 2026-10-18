import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../config/teams.dart';
import '../../sim/turn_manager.dart';
import '../../sim/world.dart';

/// Placeholder units: a light body with a team-colour outline, an eye on the
/// facing side, HP above, and a bobbing marker over the active unit.
/// Family shapes and breed colours arrive in M3.
class UnitsComponent extends Component {
  UnitsComponent(this.sim) : super(priority: 4);

  final SimWorld sim;

  static const _bodyArgb = 0xFFF4E4CF;

  final ui.Paint _body = ui.Paint()..color = const ui.Color(_bodyArgb);
  final ui.Paint _outline = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 3;
  final ui.Paint _eye = ui.Paint()..color = const ui.Color(0xFF222222);
  final ui.Paint _marker = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
  final ui.Paint _markerEdge = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = const ui.Color(0xFF222222);

  late final List<TextPaint> _hpText = [
    for (final style in Teams.styles)
      TextPaint(
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: ui.Color(style.colorArgb),
          shadows: const [
            Shadow(color: ui.Color(0xFF000000), blurRadius: 3),
          ],
        ),
      ),
  ];

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
      final cx = u.centerX;
      final cy = u.centerY;
      final r = u.stats.hitRadius;
      _outline.color = ui.Color(Teams.styles[u.team].colorArgb);
      canvas
        ..drawCircle(ui.Offset(cx, cy), r, _body)
        ..drawCircle(ui.Offset(cx, cy), r, _outline)
        ..drawCircle(ui.Offset(cx + u.facing * r * 0.45, cy - r * 0.2),
            r * 0.18, _eye);

      final hpY = cy - r - 12;
      _hpText[u.team].render(
        canvas,
        '${math.max(0, u.hp)}',
        Vector2(cx, hpY),
        anchor: Anchor.bottomCenter,
      );

      if (showMarker && u == active) {
        final bob = math.sin(_time * 6) * 3;
        final tipY = hpY - 22 + bob;
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
