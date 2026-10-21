import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../config/teams.dart';
import '../../config/units.dart';
import '../../sim/turn_manager.dart';
import '../../sim/unit.dart';
import '../../sim/world.dart';
import '../art/animal_art.dart';

/// Draws every unit with its pet art and, as in the redesign's arena
/// (redesign/ArenaScene.dc.html), a dark translucent tag above it: the
/// team mark, the name, the HP and a thin HP bar; a small cream arrow over
/// the active unit; a little gravestone with a band in the team colour
/// where a unit fell. Poses follow the sim: walking waddles, airborne
/// units stretch; idle units breathe a little.
class UnitsComponent extends Component {
  UnitsComponent(
    this.sim, {
    required this.teamColors,
    required this.unitNames,
    this.teamSymbols = const [],
  }) : super(priority: 4);

  final SimWorld sim;

  /// Colour (0xAARRGGBB) of each sim team.
  final List<int> teamColors;

  /// Each team's mark (circle, triangle, ...).
  final List<TeamSymbol> teamSymbols;

  /// Display name of each unit, by unit id.
  final List<String> unitNames;

  final Map<int, double> _lastX = {};
  final Map<int, double> _walkTime = {};
  double _time = 0;

  static const _cream = ui.Color(0xFFFFEBD2);
  static const _crit = ui.Color(0xFFFF8A8D);

  final ui.Paint _tag = ui.Paint()..color = const ui.Color(0xD616101C);
  final ui.Paint _ring = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 0.8
    ..color = const ui.Color(0x40FFD6AA);
  final ui.Paint _barBack = ui.Paint()..color = const ui.Color(0x2EFFEBD2);
  final ui.Paint _fill = ui.Paint();
  final ui.Paint _shadow = ui.Paint()
    ..color = const ui.Color(0x66000000)
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 1);

  final TextPaint _name = TextPaint(
    style: const TextStyle(
      fontFamily: 'Nunito',
      fontVariations: [ui.FontVariation('wght', 800)],
      fontWeight: FontWeight.w700,
      fontSize: 9.5,
      color: _cream,
      height: 1,
    ),
  );
  final TextPaint _hp = TextPaint(
    style: const TextStyle(
      fontFamily: 'Baloo2',
      fontVariations: [ui.FontVariation('wght', 800)],
      fontWeight: FontWeight.w700,
      fontSize: 10.5,
      color: _cream,
      height: 1,
    ),
  );
  final TextPaint _hpCrit = TextPaint(
    style: const TextStyle(
      fontFamily: 'Baloo2',
      fontVariations: [ui.FontVariation('wght', 800)],
      fontWeight: FontWeight.w700,
      fontSize: 10.5,
      color: _crit,
      height: 1,
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
    final showMarker =
        sim.turn.phase == TurnPhase.turnStart ||
        sim.turn.phase == TurnPhase.action;

    for (final u in sim.units) {
      if (!u.alive) {
        if (u.y < sim.waterLevel) _grave(canvas, u);
        continue;
      }
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
      if (u.frozen) _iceBlock(canvas, u, scale);
      if (u.shielded) _bubble(canvas, u, scale);
      if (u.poisoned) _poisonBubbles(canvas, u, scale);

      final top = u.y - AnimalArt.height * scale - 3;
      final tagTop = _drawTag(canvas, u, top);
      if (showMarker && u == active) {
        final bob = math.sin(_time * 6) * 2.5;
        final tip = tagTop - 3 + bob;
        final cx = u.centerX;
        final arrow = ui.Path()
          ..moveTo(cx, tip)
          ..lineTo(cx - 5.5, tip - 7)
          ..lineTo(cx + 5.5, tip - 7)
          ..close();
        canvas
          ..drawPath(arrow.shift(const ui.Offset(0, 1)), _shadow)
          ..drawPath(arrow, _fill..color = _cream);
      }
    }
  }

  /// A frozen pet: encased in a block of translucent ice with frosty
  /// edges and a couple of glints.
  void _iceBlock(ui.Canvas canvas, Unit u, double scale) {
    final h = AnimalArt.height * scale + 6;
    final w = u.stats.hitRadius * 2.6;
    final block = ui.RRect.fromLTRBR(u.centerX - w / 2, u.y - h,
        u.centerX + w / 2, u.y + 1, const ui.Radius.circular(6));
    canvas
      ..drawRRect(block, _fill..color = const ui.Color(0x99A6E2FF))
      ..drawRRect(block, _iceEdge)
      ..drawLine(
          ui.Offset(block.left + 5, block.top + 6),
          ui.Offset(block.left + 5, block.top + h * 0.45),
          _iceGlint)
      ..drawLine(
          ui.Offset(block.left + 9, block.top + 5),
          ui.Offset(block.left + 13, block.top + 5),
          _iceGlint);
  }

  /// A shield: a soap-bubble dome around the pet, its rim shimmering.
  void _bubble(ui.Canvas canvas, Unit u, double scale) {
    final r = AnimalArt.height * scale * 0.62 + 4;
    final c = ui.Offset(u.centerX, u.y - r + 3);
    final shimmer = 0.5 + 0.5 * math.sin(_time * 3 + u.id);
    canvas
      ..drawCircle(c, r, _bubbleFill)
      ..drawCircle(
          c,
          r,
          _bubbleRim
            ..color = ui.Color.lerp(const ui.Color(0xCC9FE3FF),
                const ui.Color(0xCCE3C6FF), shimmer)!)
      ..drawArc(ui.Rect.fromCircle(center: c, radius: r - 4), math.pi * 1.1,
          math.pi * 0.35, false, _iceGlint);
  }

  /// Poisoned: small green bubbles rising off the pet and a green skull
  /// badge by its head.
  void _poisonBubbles(ui.Canvas canvas, Unit u, double scale) {
    final top = u.y - AnimalArt.height * scale;
    for (var i = 0; i < 3; i++) {
      final t = (_time * 0.8 + i / 3 + u.id * 0.13) % 1;
      canvas.drawCircle(
          ui.Offset(u.centerX + (i - 1) * 6 + math.sin(t * 6 + i) * 2,
              top + 6 - t * 16),
          1.6 + i * 0.4,
          _fill
            ..color = ui.Color.fromARGB((200 * (1 - t)).round(), 150, 214, 90));
    }
    final b = ui.Offset(u.centerX + u.stats.hitRadius + 2, top + 4);
    canvas
      ..drawCircle(b, 5.5, _fill..color = const ui.Color(0xFF4E8F2A))
      ..drawCircle(b + const ui.Offset(0, -0.6), 3.2,
          _fill..color = const ui.Color(0xFFF2FFE6))
      ..drawRect(ui.Rect.fromCenter(center: b + const ui.Offset(0, 2.6), width: 3.4, height: 1.8),
          _fill..color = const ui.Color(0xFFF2FFE6))
      ..drawCircle(b + const ui.Offset(-1.2, -0.8), 0.9,
          _fill..color = const ui.Color(0xFF2B2118))
      ..drawCircle(b + const ui.Offset(1.2, -0.8), 0.9, _fill);
  }

  final ui.Paint _bubbleFill = ui.Paint()..color = const ui.Color(0x409FE3FF);
  final ui.Paint _bubbleRim = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 2.6;

  final ui.Paint _iceEdge = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = const ui.Color(0xDDE6F9FF);
  final ui.Paint _iceGlint = ui.Paint()
    ..strokeWidth = 2
    ..strokeCap = ui.StrokeCap.round
    ..color = const ui.Color(0xEEFFFFFF);

  /// The name tag; returns its top edge (for the active arrow).
  double _drawTag(ui.Canvas canvas, Unit u, double bottom) {
    final name = u.id < unitNames.length ? unitNames[u.id] : '';
    final hpValue = math.max(0, u.hp);
    final crit = hpValue <= 25;
    final hp = '$hpValue';
    final hpText = crit ? _hpCrit : _hp;
    final nameW = name.isEmpty ? 0.0 : _name.getLineMetrics(name).width;
    final hpW = hpText.getLineMetrics(hp).width;
    const sym = 7.5;
    final width = 5 + sym + 4 + nameW + (name.isEmpty ? 0 : 4) + hpW + 6;
    const height = 19.0;
    final left = u.centerX - width / 2;
    final top = bottom - height;
    final box = ui.RRect.fromLTRBR(
      left,
      top,
      left + width,
      bottom,
      const ui.Radius.circular(7),
    );
    canvas
      ..drawRRect(box, _tag)
      ..drawRRect(box, _ring);
    // Team mark.
    final symbol = u.team < teamSymbols.length
        ? teamSymbols[u.team]
        : TeamSymbol.circle;
    canvas
      ..save()
      ..translate(left + 5, top + 3.2)
      ..scale(sym / 20)
      ..drawPath(
        _symbolPath(symbol),
        _fill
          ..color = ui.Color.lerp(ui.Color(teamColors[u.team]), _cream, 0.15)!,
      )
      ..restore();
    var x = left + 5 + sym + 4;
    if (name.isNotEmpty) {
      _name.render(canvas, name, Vector2(x, top + 3), anchor: Anchor.topLeft);
      x += nameW + 4;
    }
    hpText.render(canvas, hp, Vector2(x, top + 2.4), anchor: Anchor.topLeft);
    // HP bar.
    final barLeft = left + 5;
    final barW = width - 10;
    final bar = ui.RRect.fromLTRBR(
      barLeft,
      bottom - 5,
      barLeft + barW,
      bottom - 2.6,
      const ui.Radius.circular(1.5),
    );
    canvas.drawRRect(bar, _barBack);
    final frac = (hpValue / math.max(1, u.stats.maxHp)).clamp(0.0, 1.0);
    canvas.drawRRect(
      ui.RRect.fromLTRBR(
        barLeft,
        bottom - 5,
        barLeft + barW * frac,
        bottom - 2.6,
        const ui.Radius.circular(1.5),
      ),
      _fill
        ..color = crit
            ? const ui.Color(0xFFE5484D)
            : ui.Color(teamColors[u.team]),
    );
    return top;
  }

  void _grave(ui.Canvas canvas, Unit u) {
    final x = u.centerX;
    final y = u.y;
    final stone = ui.RRect.fromLTRBAndCorners(
      x - 5,
      y - 12,
      x + 5,
      y,
      topLeft: const ui.Radius.circular(5),
      topRight: const ui.Radius.circular(5),
      bottomLeft: const ui.Radius.circular(1.3),
      bottomRight: const ui.Radius.circular(1.3),
    );
    canvas
      ..drawRRect(stone.shift(const ui.Offset(0.6, 1.3)), _shadow)
      ..drawRRect(
        stone,
        ui.Paint()
          ..shader = ui.Gradient.linear(
            ui.Offset(x - 5, y - 12),
            ui.Offset(x + 5, y),
            const [ui.Color(0xFF9C9590), ui.Color(0xFF5A5552)],
          ),
      )
      ..drawRect(
        ui.Rect.fromLTWH(x - 5, y - 6.8, 10, 2.2),
        _fill..color = ui.Color(teamColors[u.team]),
      );
  }

  static final Map<TeamSymbol, ui.Path> _paths = {};

  /// The team mark in a 20 × 20 box (same shapes as the HUD badges).
  static ui.Path _symbolPath(TeamSymbol s) => _paths.putIfAbsent(s, () {
    switch (s) {
      case TeamSymbol.circle:
        return ui.Path()..addOval(
          ui.Rect.fromCircle(center: const ui.Offset(10, 10), radius: 8),
        );
      case TeamSymbol.triangle:
        return ui.Path()
          ..moveTo(10, 2.5)
          ..lineTo(18.5, 17)
          ..lineTo(1.5, 17)
          ..close();
      case TeamSymbol.square:
        return ui.Path()..addRect(const ui.Rect.fromLTRB(3, 3, 17, 17));
      case TeamSymbol.star:
        final p = ui.Path();
        for (var i = 0; i < 10; i++) {
          final a = -math.pi / 2 + i * math.pi / 5;
          final r = i.isEven ? 8.6 : 3.9;
          final x = 10 + math.cos(a) * r;
          final y = 10.6 + math.sin(a) * r;
          i == 0 ? p.moveTo(x, y) : p.lineTo(x, y);
        }
        return p..close();
      case TeamSymbol.diamond:
        return ui.Path()
          ..moveTo(10, 1.5)
          ..lineTo(18, 10)
          ..lineTo(10, 18.5)
          ..lineTo(2, 10)
          ..close();
      case TeamSymbol.heart:
        return ui.Path()
          ..moveTo(10, 17.5)
          ..cubicTo(2, 12, 1, 7, 4, 4.2)
          ..cubicTo(6.5, 2, 9, 3.2, 10, 5.4)
          ..cubicTo(11, 3.2, 13.5, 2, 16, 4.2)
          ..cubicTo(19, 7, 18, 12, 10, 17.5)
          ..close();
    }
  });
}
