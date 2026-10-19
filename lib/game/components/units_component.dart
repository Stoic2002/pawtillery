import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../config/units.dart';
import '../../sim/turn_manager.dart';
import '../../sim/unit.dart';
import '../../sim/world.dart';
import '../art/animal_art.dart';

/// Draws every living unit with its animal art, its name and HP above it
/// in team colour, and a bouncing arrow over the active unit. Poses follow the
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

  final ui.Paint _box = ui.Paint()..color = const ui.Color(0xB3101820);
  final ui.Paint _marker = ui.Paint();
  final ui.Paint _markerEdge = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeJoin = ui.StrokeJoin.round
    ..color = const ui.Color(0xFF2A1A12);

  // Name and HP in bold team-colour text with a dark outline, each on its
  // own translucent rounded box (docs/art_style_guide.md).
  static List<Shadow> _outline(double w) => [
    for (final (dx, dy) in const [
      (1.0, 0.0),
      (-1.0, 0.0),
      (0.0, 1.0),
      (0.0, -1.0),
      (0.7, 0.7),
      (-0.7, 0.7),
      (0.7, -0.7),
      (-0.7, -0.7),
    ])
      Shadow(color: const ui.Color(0xFF2A1A12), offset: ui.Offset(dx * w, dy * w)),
  ];

  late final List<ui.Color> _labelColors = [
    for (final argb in teamColors)
      ui.Color.lerp(ui.Color(argb), const ui.Color(0xFFFFFFFF), 0.22)!,
  ];
  late final List<TextPaint> _nameText = [
    for (final c in _labelColors)
      TextPaint(
        style: TextStyle(
          fontFamily: 'LilitaOne',
          fontSize: 9.5,
          color: c,
          shadows: _outline(1),
        ),
      ),
  ];
  late final List<TextPaint> _hpText = [
    for (final c in _labelColors)
      TextPaint(
        style: TextStyle(
          fontFamily: 'LilitaOne',
          fontSize: 10,
          color: c,
          shadows: _outline(1),
        ),
      ),
  ];

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
        // A bouncing arrow in the team's colour over the labels.
        final bob = math.sin(_time * 6) * 3;
        final tipY = top - 34 + bob;
        final cx = u.centerX;
        final path = ui.Path()
          ..moveTo(cx, tipY)
          ..lineTo(cx - 8, tipY - 9)
          ..lineTo(cx - 3.5, tipY - 9)
          ..lineTo(cx - 3.5, tipY - 17)
          ..lineTo(cx + 3.5, tipY - 17)
          ..lineTo(cx + 3.5, tipY - 9)
          ..lineTo(cx + 8, tipY - 9)
          ..close();
        _marker.color = _labelColors[u.team];
        canvas
          ..drawPath(path, _marker)
          ..drawPath(path, _markerEdge);
      }
    }
  }

  void _drawLabels(ui.Canvas canvas, Unit u, double top) {
    final hp = '${math.max(0, u.hp)}';
    final hpWidth = _hpText[u.team].getLineMetrics(hp).width + 8;
    final hpBox = ui.RRect.fromRectAndRadius(
      ui.Rect.fromCenter(
        center: ui.Offset(u.centerX, top - 7),
        width: hpWidth,
        height: 12,
      ),
      const ui.Radius.circular(4),
    );
    canvas.drawRRect(hpBox, _box);
    _hpText[u.team].render(
      canvas,
      hp,
      Vector2(u.centerX, top - 7),
      anchor: Anchor.center,
    );
    final name = u.id < unitNames.length ? unitNames[u.id] : '';
    if (name.isEmpty) return;
    final nameWidth = _nameText[u.team].getLineMetrics(name).width + 8;
    final nameBox = ui.RRect.fromRectAndRadius(
      ui.Rect.fromCenter(
        center: ui.Offset(u.centerX, top - 21),
        width: nameWidth,
        height: 12,
      ),
      const ui.Radius.circular(4),
    );
    canvas.drawRRect(nameBox, _box);
    _nameText[u.team].render(
      canvas,
      name,
      Vector2(u.centerX, top - 21),
      anchor: Anchor.center,
    );
  }
}
