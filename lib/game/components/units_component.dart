import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../config/units.dart';
import '../../sim/turn_manager.dart';
import '../../sim/unit.dart';
import '../../sim/world.dart';
import '../art/animal_art.dart';

/// Draws every living unit with its animal art, a team-coloured HP label
/// and name above it, and a marker over the active unit. Poses follow the
/// sim: walking alternates legs, airborne units tuck them in; idle units
/// breathe a little.
class UnitsComponent extends Component {
  UnitsComponent(
    this.sim, {
    required this.teamColors,
    required this.unitNames,
  }) : super(priority: 4);

  final SimWorld sim;

  /// Colour (0xAARRGGBB) of each sim team.
  final List<int> teamColors;

  /// Display name of each unit, by unit id.
  final List<String> unitNames;

  final Map<int, double> _lastX = {};
  final Map<int, double> _walkTime = {};
  double _time = 0;

  final ui.Paint _pill = ui.Paint();
  final ui.Paint _pillEdge = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = const ui.Color(0x66000000);
  final ui.Paint _marker = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
  final ui.Paint _markerEdge = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..color = const ui.Color(0xAA000000);

  final TextPaint _hpText = TextPaint(
    style: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w800,
      color: ui.Color(0xFFFFFFFF),
    ),
  );
  final TextPaint _nameText = TextPaint(
    style: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: ui.Color(0xFFFFFFFF),
      shadows: [Shadow(color: ui.Color(0xCC000000), blurRadius: 2)],
    ),
  );

  @override
  void update(double dt) {
    _time += dt;
    for (final u in sim.units) {
      final last = _lastX[u.id];
      final moving = last != null && (u.x - last).abs() > 0.01 && u.grounded;
      _walkTime[u.id] = moving ? (_walkTime[u.id] ?? 0) + dt : 0;
      _lastX[u.id] = u.x;
    }
  }

  AnimalPose _pose(Unit u) {
    if (!u.grounded || u.isDashing) return AnimalPose.air;
    final t = _walkTime[u.id] ?? 0;
    if (t == 0) return AnimalPose.idle;
    return (t * 8).floor().isEven ? AnimalPose.walkA : AnimalPose.walkB;
  }

  @override
  void render(ui.Canvas canvas) {
    final active = sim.activeUnit;
    final showMarker = sim.turn.phase == TurnPhase.turnStart ||
        sim.turn.phase == TurnPhase.action;

    for (final u in sim.units) {
      if (!u.alive) continue;
      final scale = u.stats.hitRadius / UnitConfig.hitRadius;
      final pose = _pose(u);
      final breathe = pose == AnimalPose.idle
          ? 1 + 0.025 * math.sin(_time * 2.6 + u.id)
          : 1.0;
      canvas
        ..save()
        ..translate(u.centerX, u.y)
        ..scale(scale * u.facing, scale * breathe);
      AnimalArt.draw(
        canvas,
        familyId: u.familyId,
        breedId: u.breedId,
        teamArgb: teamColors[u.team],
        pose: pose,
      );
      canvas.restore();

      final top = u.y - AnimalArt.height * scale;
      _drawLabels(canvas, u, top);

      if (showMarker && u == active) {
        final bob = math.sin(_time * 6) * 2.5;
        final tipY = top - 30 + bob;
        final cx = u.centerX;
        final path = ui.Path()
          ..moveTo(cx, tipY)
          ..lineTo(cx - 6, tipY - 9)
          ..lineTo(cx + 6, tipY - 9)
          ..close();
        canvas
          ..drawPath(path, _marker)
          ..drawPath(path, _markerEdge);
      }
    }
  }

  void _drawLabels(ui.Canvas canvas, Unit u, double top) {
    final hp = '${math.max(0, u.hp)}';
    final width = 8.0 + hp.length * 6.5;
    final pill = ui.RRect.fromRectAndRadius(
      ui.Rect.fromCenter(
          center: ui.Offset(u.centerX, top - 6), width: width, height: 12),
      const ui.Radius.circular(6),
    );
    _pill.color = ui.Color(teamColors[u.team]).withValues(alpha: 0.92);
    canvas
      ..drawRRect(pill, _pill)
      ..drawRRect(pill, _pillEdge);
    _hpText.render(canvas, hp, Vector2(u.centerX, top - 6),
        anchor: Anchor.center);
    final name = u.id < unitNames.length ? unitNames[u.id] : '';
    if (name.isNotEmpty) {
      _nameText.render(canvas, name, Vector2(u.centerX, top - 13),
          anchor: Anchor.bottomCenter);
    }
  }
}
