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

  final ui.Paint _tag = ui.Paint()..color = const ui.Color(0xF2EFE6D2);
  final ui.Paint _tagEdge = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1.2;
  final ui.Paint _marker = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
  final ui.Paint _markerEdge = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..color = const ui.Color(0xAA000000);

  // The field-guide face (docs/art_style_guide.md): HP in the team's ink
  // on a paper tag, the name in italic ink above.
  late final List<TextPaint> _hpText = [
    for (final argb in teamColors)
      TextPaint(
        style: TextStyle(
          fontFamily: 'OldStandard',
          fontSize: 11,
          color: ui.Color(argb),
        ),
      ),
  ];
  final TextPaint _nameText = TextPaint(
    style: const TextStyle(
      fontFamily: 'OldStandard',
      fontSize: 10.5,
      fontStyle: FontStyle.italic,
      color: ui.Color(0xFF2B2620),
      shadows: [Shadow(color: ui.Color(0xCCEFE6D2), blurRadius: 3)],
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
    final width = 10.0 + hp.length * 6.5;
    final tag = ui.RRect.fromRectAndRadius(
      ui.Rect.fromCenter(
          center: ui.Offset(u.centerX, top - 6), width: width, height: 13),
      const ui.Radius.circular(1.5),
    );
    _tagEdge.color = ui.Color(teamColors[u.team]);
    canvas
      ..drawRRect(tag, _tag)
      ..drawRRect(tag, _tagEdge);
    _hpText[u.team].render(canvas, hp, Vector2(u.centerX, top - 6),
        anchor: Anchor.center);
    final name = u.id < unitNames.length ? unitNames[u.id] : '';
    if (name.isNotEmpty) {
      _nameText.render(canvas, name, Vector2(u.centerX, top - 13.5),
          anchor: Anchor.bottomCenter);
    }
  }
}
